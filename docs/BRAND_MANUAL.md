# InhausBrain Brand Manual

## 1. Overview & Aesthetics

InhausBrain employs a **Flat Weavy UI** aesthetic. It is designed to be a modern, flat, dark, and minimal AI-native application.

**Key Principles:**
- **Flat & Solid:** We avoid glassmorphism and heavy drop shadows in favor of solid surfaces and subtle border definitions.
- **High Contrast:** Using a super-dark background with vibrant primary and accent colors for clear visual hierarchy.
- **Minimalist:** Interfaces should feel uncluttered. Spacing, padding, and clean typography carry the design.

---

## 2. Color Palette

The color system is built around a dark base with vibrant, futuristic accents.

### Base Colors
- **Background:** `#0A0E17` — The foundational dark canvas for all screens.
- **Surface:** `#161B28` — Used for cards, elevated surfaces, and input fields.
- **INHAUS Purple:** `#1A1423` — Secondary dark tone for subtle layering.

### Brand Accents
- **Primary:** `#6C63FF` — Used for primary actions, active states, and primary buttons.
- **Secondary:** `#00D2FF` — Used for secondary highlights and gradients.
- **Accent (INHAUS Pink):** `#E8006A` — Used for critical alerts, special badges, and vibrant accents.

### Text Colors (Dark Mode)
- **Primary Text:** `White (#FFFFFF)` — High contrast for readability.
- **Secondary Text:** `White at 70% Opacity` — Used for subtitles, hints, and secondary information.

---

## 3. Typography

**Primary Typeface:** `Outfit` (via Google Fonts)

*Outfit* provides a modern, geometric, and clean tech feel that perfectly complements the AI-driven nature of InhausBrain. 

- **Usage:** Used uniformly across all text styles (Display, Headline, Title, Body, Label).
- **Styling:** Keep font weights distinct. Use `w600` (Semi-Bold) for prominent buttons and titles, and `w400` (Regular) for body text.

---

## 4. Component Styles

### Cards
- **Background:** Solid `#161B28` (Surface color).
- **Border:** `1px` solid White at `10%` opacity (`rgba(255,255,255,0.1)`).
- **Border Radius:** `16px`.
- **Elevation:** `0` (Completely flat).

### Image-Based Cards (Campaigns & Templates)
- **Imagery:** High-quality photography or 3D renders combined with a heavy dark overlay or vignette to ensure text legibility.
- **Content Alignment:** Icons often placed prominently (center or top-left) with titles and descriptions neatly aligned to the bottom.
- **Badges/Tags:** Small pill-shaped badges (e.g., "RECOMMENDED") placed at the top or corner of cards using bright solid colors (Primary or Accent) to draw attention.

### Input Fields
- **Container:** Filled with `#161B28` (Surface).
- **Border Radius:** `12px`.
- **Default State:** No outline border.
- **Enabled State:** `1px` border using White at `5%` opacity.
- **Focused State:** `1px` solid Primary (`#6C63FF`).
- **Hint Text:** `White at 30% Opacity`.

### Buttons (Elevated / Primary)
- **Background:** Primary (`#6C63FF`).
- **Text Color:** `White`.
- **Typography:** Outfit, `16px`, `w600` (Semi-Bold).
- **Padding:** `24px` horizontal, `16px` vertical.
- **Border Radius:** `12px`.
- **Elevation:** `0` (Completely flat).

---

## 5. Layout & Interface Patterns

### Left Sidebar Navigation
- **Active State:** Selected menu items are highlighted with a rounded capsule background using a muted Primary color tone, establishing a very clear navigation state.
- **Hierarchy:** Muted text and icons for unselected items. A prominent INHAUS wordmark serves as the top anchor.
- **Bottom Section:** User profile avatar (e.g., initials in a blue/colored circle) and tertiary actions anchored at the bottom.

### AI Assistant Integration (BrainWeave)
- **Persistent Access:** The AI assistant is universally accessible via a floating circular button located in the bottom right corner of the main content area.
- **Styling:** Circular FAB with a solid dark surface and a contrasting bright white brain icon.

---

## 6. Light Mode Considerations

While InhausBrain is primarily designed as a dark-mode native application, the light mode fallback relies on clean contrast:
- **Background:** `#F8F9FA`
- **Surface:** `White (#FFFFFF)`
- **Text:** Dark Grey (`#1A1A1A`) for primary, Lighter Grey (`#666666`) for secondary.
- **Card Borders:** Black at `5%` opacity.
