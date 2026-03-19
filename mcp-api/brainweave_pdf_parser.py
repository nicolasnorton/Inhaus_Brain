"""
BrainWeave PDF Parser — Hybrid Extraction Module
═══════════════════════════════════════════════════
Pure evolution of arscontexta (Markdown vault) + GitNexus (Spanner graph).

Architecture:
  1. Fast deterministic extraction via PyMuPDF (fitz)
  2. XY-Cut++ recursive layout analysis for reading order
  3. Per-element bounding boxes for provenance
  4. AI safety filters (hidden text, off-page, invisible chars)
  5. Vertex AI Gemini fallback for complex pages (tables, OCR, formulas)
  6. Structured output: clean Markdown + JSON with semantic types + bboxes

Zero external dependencies beyond PyMuPDF and google-cloud-aiplatform
(both already in the project stack).
"""

import io
import json
import logging
import math
import re
import uuid
from dataclasses import dataclass, field, asdict
from typing import List, Optional, Tuple

import fitz  # PyMuPDF

import vertexai
from vertexai.generative_models import GenerativeModel, Part

logger = logging.getLogger(__name__)

# ─── Data Structures ──────────────────────────────────────────────────────────

@dataclass
class BoundingBox:
    """Absolute coordinates of an element on the page."""
    x0: float
    y0: float
    x1: float
    y1: float
    page: int

    @property
    def width(self) -> float:
        return self.x1 - self.x0

    @property
    def height(self) -> float:
        return self.y1 - self.y0

    @property
    def area(self) -> float:
        return self.width * self.height

    @property
    def cx(self) -> float:
        return (self.x0 + self.x1) / 2

    @property
    def cy(self) -> float:
        return (self.y0 + self.y1) / 2

    def to_dict(self) -> dict:
        return {
            "x0": round(self.x0, 2),
            "y0": round(self.y0, 2),
            "x1": round(self.x1, 2),
            "y1": round(self.y1, 2),
            "page": self.page,
            "width": round(self.width, 2),
            "height": round(self.height, 2),
        }


@dataclass
class PdfElement:
    """A single extracted element from the PDF."""
    id: str
    element_type: str  # heading, paragraph, table, image, list_item, caption, formula
    text: str
    bbox: BoundingBox
    font_size: float = 12.0
    font_name: str = ""
    is_bold: bool = False
    confidence: float = 1.0
    reading_order: int = 0
    metadata: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "element_type": self.element_type,
            "text": self.text,
            "bounding_box": self.bbox.to_dict(),
            "font_size": self.font_size,
            "font_name": self.font_name,
            "is_bold": self.is_bold,
            "confidence": self.confidence,
            "reading_order": self.reading_order,
            "metadata": self.metadata,
        }


@dataclass
class PdfParseResult:
    """Complete result from parsing a PDF."""
    filename: str
    page_count: int
    elements: List[PdfElement]
    markdown: str
    structured_json: List[dict]
    stats: dict

    def to_dict(self) -> dict:
        return {
            "filename": self.filename,
            "page_count": self.page_count,
            "element_count": len(self.elements),
            "markdown": self.markdown,
            "structured_json": self.structured_json,
            "stats": self.stats,
        }


# ─── Constants ────────────────────────────────────────────────────────────────

# Thresholds for page complexity classification
COMPLEX_TABLE_THRESHOLD = 2       # Tables per page to trigger AI fallback
COMPLEX_IMAGE_RATIO = 0.4         # Image area / page area ratio
MIN_VISIBLE_FONT_SIZE = 1.0       # Below this = hidden text
MIN_ELEMENT_AREA = 4.0            # Minimum bbox area to keep (filters noise)
XY_CUT_MIN_GAP = 10.0             # Minimum whitespace gap for XY-Cut splits

# Safety filter patterns
HIDDEN_TEXT_PATTERNS = [
    re.compile(r"^\s*$"),                        # Whitespace-only
    re.compile(r"^[\x00-\x08\x0b-\x0c\x0e-\x1f]+$"),  # Control chars
]


# ─── XY-Cut++ Layout Analysis ────────────────────────────────────────────────

def _xy_cut_sort(elements: List[PdfElement], depth: int = 0) -> List[PdfElement]:
    """
    XY-Cut++ recursive layout analysis for accurate reading order.
    
    Handles multi-column layouts, sidebars, and mixed layouts by
    recursively splitting element groups along horizontal and vertical
    whitespace gaps.
    """
    if len(elements) <= 1 or depth > 10:
        return elements

    # Try horizontal cut first (top-to-bottom reading)
    h_groups = _find_horizontal_cuts(elements)
    if len(h_groups) > 1:
        result = []
        for group in h_groups:
            result.extend(_xy_cut_sort(group, depth + 1))
        return result

    # Try vertical cut (left-to-right columns)
    v_groups = _find_vertical_cuts(elements)
    if len(v_groups) > 1:
        result = []
        for group in v_groups:
            result.extend(_xy_cut_sort(group, depth + 1))
        return result

    # No splits found — sort remaining by position (top→bottom, left→right)
    return sorted(elements, key=lambda e: (e.bbox.y0, e.bbox.x0))


def _find_horizontal_cuts(elements: List[PdfElement]) -> List[List[PdfElement]]:
    """Find horizontal whitespace gaps that separate element groups."""
    if not elements:
        return [elements]

    sorted_elems = sorted(elements, key=lambda e: e.bbox.y0)
    groups: List[List[PdfElement]] = [[sorted_elems[0]]]

    for elem in sorted_elems[1:]:
        prev_bottom = max(e.bbox.y1 for e in groups[-1])
        gap = elem.bbox.y0 - prev_bottom

        if gap > XY_CUT_MIN_GAP:
            groups.append([elem])
        else:
            groups[-1].append(elem)

    return groups


def _find_vertical_cuts(elements: List[PdfElement]) -> List[List[PdfElement]]:
    """Find vertical whitespace gaps that separate columns."""
    if not elements:
        return [elements]

    sorted_elems = sorted(elements, key=lambda e: e.bbox.x0)

    # Find the largest vertical gap
    gaps = []
    for i in range(len(sorted_elems) - 1):
        right_edge = sorted_elems[i].bbox.x1
        left_edge = sorted_elems[i + 1].bbox.x0
        gap = left_edge - right_edge
        if gap > XY_CUT_MIN_GAP:
            gaps.append((gap, i))

    if not gaps:
        return [elements]

    # Split at the largest gap
    gaps.sort(reverse=True)
    split_idx = gaps[0][1]

    left = sorted_elems[:split_idx + 1]
    right = sorted_elems[split_idx + 1:]

    return [left, right]


# ─── Safety Filters ──────────────────────────────────────────────────────────

def _apply_safety_filters(elements: List[PdfElement], page_width: float, page_height: float) -> List[PdfElement]:
    """
    AI Safety Filters — Remove hidden text, off-page content,
    and sanitize before graph insertion.
    """
    safe_elements = []

    for elem in elements:
        # 1. Skip elements with invisible font size
        if elem.font_size < MIN_VISIBLE_FONT_SIZE:
            logger.debug(f"Safety: Removed hidden text (font_size={elem.font_size}): {elem.text[:50]}")
            continue

        # 2. Skip off-page content (outside page boundaries)
        if (elem.bbox.x1 < 0 or elem.bbox.y1 < 0 or
            elem.bbox.x0 > page_width or elem.bbox.y0 > page_height):
            logger.debug(f"Safety: Removed off-page element: {elem.text[:50]}")
            continue

        # 3. Skip elements that are too small (likely artifacts)
        if elem.bbox.area < MIN_ELEMENT_AREA and elem.element_type != "caption":
            continue

        # 4. Skip hidden text patterns
        is_hidden = False
        for pattern in HIDDEN_TEXT_PATTERNS:
            if pattern.match(elem.text):
                is_hidden = True
                break
        if is_hidden:
            continue

        # 5. Sanitize the text content
        text = elem.text
        # Remove null bytes and control characters
        text = re.sub(r"[\x00-\x08\x0b-\x0c\x0e-\x1f]", "", text)
        # Collapse excessive whitespace
        text = re.sub(r" {4,}", "  ", text)
        elem.text = text.strip()

        if elem.text:
            safe_elements.append(elem)

    return safe_elements


# ─── Page Complexity Classifier ───────────────────────────────────────────────

def _classify_page_complexity(page: fitz.Page, elements: List[PdfElement]) -> str:
    """
    Classify page complexity to decide fast vs AI path.
    Returns: 'simple' or 'complex'
    """
    page_area = page.rect.width * page.rect.height
    if page_area == 0:
        return "simple"

    # Count tables (heuristic: look for grid-like line patterns)
    tables = page.find_tables()
    table_count = len(tables.tables) if tables else 0

    # Count images and their total area
    image_list = page.get_images(full=True)
    total_image_area = 0
    for img in image_list:
        try:
            rects = page.get_image_rects(img[0])
            for rect in rects:
                total_image_area += rect.width * rect.height
        except Exception:
            pass

    image_ratio = total_image_area / page_area

    # Check for formula indicators
    has_formulas = any(
        elem.font_name and ("math" in elem.font_name.lower() or "symbol" in elem.font_name.lower())
        for elem in elements
    )

    # Decision
    if table_count >= COMPLEX_TABLE_THRESHOLD:
        return "complex"
    if image_ratio > COMPLEX_IMAGE_RATIO:
        return "complex"
    if has_formulas:
        return "complex"

    return "simple"


# ─── Fast Deterministic Extraction ────────────────────────────────────────────

def _extract_elements_fast(page: fitz.Page, page_num: int) -> List[PdfElement]:
    """
    Fast deterministic extraction using PyMuPDF.
    Extracts text blocks with bounding boxes and font metadata.
    """
    elements = []

    # Extract text blocks with position and font info
    blocks = page.get_text("dict", flags=fitz.TEXT_PRESERVE_WHITESPACE)["blocks"]

    for block in blocks:
        if block["type"] == 0:  # Text block
            for line in block.get("lines", []):
                spans = line.get("spans", [])
                if not spans:
                    continue

                # Merge spans into a single line
                text = "".join(span["text"] for span in spans)
                if not text.strip():
                    continue

                # Use the first span's font info as representative
                first_span = spans[0]
                font_size = first_span.get("size", 12.0)
                font_name = first_span.get("font", "")
                flags = first_span.get("flags", 0)
                is_bold = bool(flags & 2**4)  # Bit 4 = bold

                bbox = BoundingBox(
                    x0=line["bbox"][0],
                    y0=line["bbox"][1],
                    x1=line["bbox"][2],
                    y1=line["bbox"][3],
                    page=page_num,
                )

                # Classify element type based on font characteristics
                element_type = _classify_element_type(text, font_size, is_bold, font_name)

                elements.append(PdfElement(
                    id=str(uuid.uuid4())[:8],
                    element_type=element_type,
                    text=text.strip(),
                    bbox=bbox,
                    font_size=font_size,
                    font_name=font_name,
                    is_bold=is_bold,
                    confidence=1.0,
                ))

        elif block["type"] == 1:  # Image block
            bbox = BoundingBox(
                x0=block["bbox"][0],
                y0=block["bbox"][1],
                x1=block["bbox"][2],
                y1=block["bbox"][3],
                page=page_num,
            )
            elements.append(PdfElement(
                id=str(uuid.uuid4())[:8],
                element_type="image",
                text="[Image]",
                bbox=bbox,
                confidence=1.0,
                metadata={"image_index": block.get("number", -1)},
            ))

    # Extract tables separately
    tables = page.find_tables()
    if tables and tables.tables:
        for table in tables.tables:
            table_bbox = BoundingBox(
                x0=table.bbox[0],
                y0=table.bbox[1],
                x1=table.bbox[2],
                y1=table.bbox[3],
                page=page_num,
            )

            # Convert table to Markdown
            rows = table.extract()
            md_rows = []
            for i, row in enumerate(rows):
                cells = [str(cell) if cell else "" for cell in row]
                md_rows.append("| " + " | ".join(cells) + " |")
                if i == 0:
                    md_rows.append("| " + " | ".join(["---"] * len(cells)) + " |")

            table_md = "\n".join(md_rows)

            elements.append(PdfElement(
                id=str(uuid.uuid4())[:8],
                element_type="table",
                text=table_md,
                bbox=table_bbox,
                confidence=0.9,
                metadata={"rows": len(rows), "cols": len(rows[0]) if rows else 0},
            ))

    return elements


def _classify_element_type(text: str, font_size: float, is_bold: bool, font_name: str) -> str:
    """Classify element type based on font characteristics and content."""
    text_stripped = text.strip()

    # Heading detection (large or bold text)
    if font_size >= 18 and is_bold:
        return "heading"
    if font_size >= 16 and is_bold:
        return "heading"
    if font_size >= 14 and is_bold and len(text_stripped) < 100:
        return "heading"

    # List item detection
    if re.match(r"^[\s]*[•\-\*\u2022\u2023\u25E6]\s", text_stripped):
        return "list_item"
    if re.match(r"^[\s]*\d+[\.\)]\s", text_stripped):
        return "list_item"

    # Caption (short italic/small text near images)
    if font_size <= 9 and len(text_stripped) < 200:
        return "caption"

    # Formula indicators
    if font_name and ("math" in font_name.lower() or "symbol" in font_name.lower()):
        return "formula"

    return "paragraph"


# ─── Vertex AI Gemini Fallback ────────────────────────────────────────────────

def _fallback_vertex_ai(page: fitz.Page, page_num: int, model_id: str = "gemini-2.0-flash") -> List[PdfElement]:
    """
    Vertex AI Gemini multimodal fallback for complex pages.
    Renders the page as an image and uses Gemini vision to extract
    structured content including tables, formulas, and OCR text.
    """
    try:
        # Render page to PNG
        pix = page.get_pixmap(dpi=200)
        img_bytes = pix.tobytes("png")

        model = GenerativeModel(model_id)

        prompt = """Analyze this PDF page image and extract ALL content in structured JSON.

Return ONLY valid JSON with this structure:
{
  "elements": [
    {
      "element_type": "heading|paragraph|table|list_item|caption|formula|image",
      "text": "The extracted text content. For tables, use Markdown table format.",
      "bbox_estimate": {"x0": 0.0, "y0": 0.0, "x1": 1.0, "y1": 0.1},
      "confidence": 0.95
    }
  ]
}

bbox_estimate should be normalized coordinates (0.0 to 1.0) relative to page dimensions.
Extract EVERY piece of text, table, and meaningful element. Preserve reading order.
For tables, convert them to clean Markdown table format.
For formulas, write them in LaTeX notation."""

        response = model.generate_content([
            prompt,
            Part.from_data(img_bytes, mime_type="image/png"),
        ])

        # Parse the Gemini response
        response_text = response.text.strip()
        # Remove markdown code fences if present
        if response_text.startswith("```"):
            response_text = re.sub(r"^```\w*\n?", "", response_text)
            response_text = re.sub(r"\n?```$", "", response_text)

        data = json.loads(response_text)
        page_width = page.rect.width
        page_height = page.rect.height

        elements = []
        for item in data.get("elements", []):
            bbox_est = item.get("bbox_estimate", {})
            bbox = BoundingBox(
                x0=bbox_est.get("x0", 0) * page_width,
                y0=bbox_est.get("y0", 0) * page_height,
                x1=bbox_est.get("x1", 1) * page_width,
                y1=bbox_est.get("y1", 1) * page_height,
                page=page_num,
            )

            elements.append(PdfElement(
                id=str(uuid.uuid4())[:8],
                element_type=item.get("element_type", "paragraph"),
                text=item.get("text", ""),
                bbox=bbox,
                confidence=item.get("confidence", 0.8),
                metadata={"source": "vertex_ai_fallback"},
            ))

        return elements

    except Exception as e:
        logger.error(f"Vertex AI fallback failed for page {page_num}: {e}")
        return []


# ─── Markdown Generation ─────────────────────────────────────────────────────

def _to_markdown(elements: List[PdfElement]) -> str:
    """Convert sorted elements to clean arscontexta-compatible Markdown."""
    lines = []
    current_page = -1

    for elem in elements:
        # Page separator
        if elem.bbox.page != current_page:
            if current_page >= 0:
                lines.append("")
                lines.append("---")
                lines.append("")
            current_page = elem.bbox.page

        if elem.element_type == "heading":
            # Determine heading level from font size
            if elem.font_size >= 18:
                lines.append(f"# {elem.text}")
            elif elem.font_size >= 16:
                lines.append(f"## {elem.text}")
            else:
                lines.append(f"### {elem.text}")
            lines.append("")

        elif elem.element_type == "table":
            lines.append("")
            lines.append(elem.text)
            lines.append("")

        elif elem.element_type == "list_item":
            lines.append(f"- {elem.text.lstrip('•-*⁃◦ ')}")

        elif elem.element_type == "image":
            lines.append("")
            lines.append(f"![{elem.text}]")
            lines.append("")

        elif elem.element_type == "caption":
            lines.append(f"*{elem.text}*")
            lines.append("")

        elif elem.element_type == "formula":
            lines.append(f"$$\n{elem.text}\n$$")
            lines.append("")

        else:  # paragraph
            lines.append(elem.text)
            lines.append("")

    return "\n".join(lines).strip()


def _to_structured_json(elements: List[PdfElement]) -> List[dict]:
    """Convert elements to structured JSON with semantic types and bounding boxes."""
    return [elem.to_dict() for elem in elements]


# ─── Main Parser Class ───────────────────────────────────────────────────────

class BrainWeavePdfParser:
    """
    BrainWeave Hybrid PDF Parser.
    
    Combines fast deterministic extraction with AI fallback for
    accurate, provenance-rich knowledge extraction from PDFs.
    """

    def __init__(self, gemini_model_id: str = "gemini-2.0-flash"):
        self.gemini_model_id = gemini_model_id

    def parse(self, pdf_bytes: bytes, filename: str = "document.pdf") -> PdfParseResult:
        """
        Parse a PDF and return structured content with bounding boxes.
        
        Args:
            pdf_bytes: Raw PDF file bytes
            filename: Original filename for metadata
            
        Returns:
            PdfParseResult with Markdown, JSON, and element data
        """
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")

        all_elements: List[PdfElement] = []
        stats = {
            "total_pages": doc.page_count,
            "simple_pages": 0,
            "complex_pages": 0,
            "ai_fallback_pages": 0,
            "elements_extracted": 0,
            "elements_filtered": 0,
            "tables_found": 0,
            "images_found": 0,
        }

        for page_num in range(doc.page_count):
            page = doc[page_num]
            page_width = page.rect.width
            page_height = page.rect.height

            # Step 1: Fast deterministic extraction
            fast_elements = _extract_elements_fast(page, page_num)

            # Step 2: Classify page complexity
            complexity = _classify_page_complexity(page, fast_elements)

            if complexity == "complex":
                stats["complex_pages"] += 1
                # Step 3a: AI fallback for complex pages
                ai_elements = _fallback_vertex_ai(page, page_num, self.gemini_model_id)
                if ai_elements:
                    stats["ai_fallback_pages"] += 1
                    # Merge: prefer AI elements for tables/formulas, keep fast for text
                    page_elements = self._merge_extractions(fast_elements, ai_elements)
                else:
                    # AI failed — use fast extraction only
                    page_elements = fast_elements
            else:
                stats["simple_pages"] += 1
                page_elements = fast_elements

            # Step 4: Apply safety filters
            pre_filter_count = len(page_elements)
            page_elements = _apply_safety_filters(page_elements, page_width, page_height)
            stats["elements_filtered"] += (pre_filter_count - len(page_elements))

            # Step 5: XY-Cut++ reading order
            page_elements = _xy_cut_sort(page_elements)

            # Assign reading order indices
            for idx, elem in enumerate(page_elements):
                elem.reading_order = len(all_elements) + idx

            all_elements.extend(page_elements)

        doc.close()

        # Update stats
        stats["elements_extracted"] = len(all_elements)
        stats["tables_found"] = sum(1 for e in all_elements if e.element_type == "table")
        stats["images_found"] = sum(1 for e in all_elements if e.element_type == "image")

        # Step 6: Generate outputs
        markdown = _to_markdown(all_elements)
        structured_json = _to_structured_json(all_elements)

        return PdfParseResult(
            filename=filename,
            page_count=stats["total_pages"],
            elements=all_elements,
            markdown=markdown,
            structured_json=structured_json,
            stats=stats,
        )

    def _merge_extractions(
        self,
        fast: List[PdfElement],
        ai: List[PdfElement],
    ) -> List[PdfElement]:
        """
        Merge fast and AI extractions.
        Prefer AI for tables and formulas, fast for regular text.
        """
        # Collect AI tables and formulas
        ai_tables_formulas = [e for e in ai if e.element_type in ("table", "formula")]

        # Remove fast elements that overlap with AI tables/formulas
        merged = []
        for fast_elem in fast:
            overlaps = False
            for ai_elem in ai_tables_formulas:
                if self._bbox_overlap(fast_elem.bbox, ai_elem.bbox) > 0.5:
                    overlaps = True
                    break
            if not overlaps:
                merged.append(fast_elem)

        # Add AI tables/formulas
        merged.extend(ai_tables_formulas)

        # For AI paragraphs with higher confidence, replace overlapping fast ones
        ai_text = [e for e in ai if e.element_type not in ("table", "formula")]
        for ai_elem in ai_text:
            if ai_elem.confidence > 0.9:
                # Check if it adds new content not in fast extraction
                has_match = any(
                    self._text_similarity(ai_elem.text, f.text) > 0.8
                    for f in merged
                )
                if not has_match and ai_elem.text.strip():
                    merged.append(ai_elem)

        return merged

    @staticmethod
    def _bbox_overlap(a: BoundingBox, b: BoundingBox) -> float:
        """Calculate IoU (Intersection over Union) of two bounding boxes."""
        if a.page != b.page:
            return 0.0

        x_overlap = max(0, min(a.x1, b.x1) - max(a.x0, b.x0))
        y_overlap = max(0, min(a.y1, b.y1) - max(a.y0, b.y0))
        intersection = x_overlap * y_overlap

        union = a.area + b.area - intersection
        if union == 0:
            return 0.0

        return intersection / union

    @staticmethod
    def _text_similarity(a: str, b: str) -> float:
        """Simple word-overlap similarity between two strings."""
        words_a = set(a.lower().split())
        words_b = set(b.lower().split())
        if not words_a or not words_b:
            return 0.0
        intersection = words_a & words_b
        union = words_a | words_b
        return len(intersection) / len(union)
