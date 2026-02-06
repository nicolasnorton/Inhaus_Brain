---
description: IBIS-Style Proposal System Upgrade Implementation Plan
---

# IBIS-Style Proposal System Upgrade

## Overview
Upgrade the Client Proposal Specialist agent to support user-selectable proposal types and formats while EXACTLY replicating the visual style of the IBIS proposal example.

## Requirements Summary
- **Proposal Types**: One Page Quote, Detailed Proposal (Multi Page)
- **Output Formats**: PDF (portrait), Google Slides (landscape)
- **Visual Style**: Exact match to IBIS.pdf (dark purple-black, purple sections, white/gray text)
- **Language**: Spanish primary, optional EN/ES toggle
- **Preserve**: All existing functionality (Veo, orchestration, ReportsLM, Knowledge, Creative Studio, demos)

## Implementation Steps

### Phase 1: Data Models & Enums (30 min)
- [x] Review existing `proposal_model.dart` and `proposal_template.dart`
- [ ] Add `ProposalType` enum: `onePageQuote`, `detailedMultiPage`
- [ ] Add `ProposalFormat` enum: `pdf`, `googleSlides`
- [ ] Create IBIS-specific data models:
  - `IbisProposalHeader` (agency_title, client_name, client_logo_url, date)
  - `IbisProposalSection` (title, description, bullets, includes, excludes, price)
  - `IbisOnePageQuote` (header, summary, footer)
  - `IbisDetailedProposal` (header, sections[], footer)

### Phase 2: Agent Prompt Updates (45 min)
- [ ] Update `proposal_specialist.md` with new JSON schemas
- [ ] Add IBIS-specific styling instructions
- [ ] Include One Page Quote template
- [ ] Include Detailed Proposal template
- [ ] Add Spanish language emphasis
- [ ] Integrate Knowledge `/knowledge/services` references

### Phase 3: PDF Generator - IBIS Style (2 hours)
- [ ] Create `ibis_proposal_pdf_generator.dart`
- [ ] Implement exact IBIS visual style:
  - Dark purple-black background (#1A0F2E or similar)
  - Purple rounded section headers (#6B46C1 or similar)
  - White/gray text (sans-serif)
  - Right-aligned price boxes
  - Header: "INHAUS ESTUDIO CREATIVO" + client logo + date
  - Footer: "inhauscorp.com"
- [ ] Build One Page Quote PDF layout
- [ ] Build Detailed Multi-Page PDF layout
- [ ] Add bullet/list rendering
- [ ] Add includes/excludes sections
- [ ] Add price box styling

### Phase 4: Google Slides Generator (1.5 hours)
- [ ] Create `ibis_proposal_slides_generator.dart`
- [ ] Adapt IBIS JSON to landscape slide format
- [ ] Use ReportsLM Slide Deck as base
- [ ] Implement Google Slides API export (or PPTX fallback)
- [ ] Mirror content structure from PDF
- [ ] Apply IBIS color scheme to slides

### Phase 5: Service Layer Integration (1 hour)
- [ ] Update `proposal_service.dart`:
  - Add `generateIbisProposalPdf()` method
  - Add `generateIbisProposalSlides()` method
  - Add type/format selection logic
  - Integrate with existing Knowledge pulls
  - Add Creative Studio image embedding
- [ ] Update prompt routing to use IBIS templates

### Phase 6: UI Updates (1.5 hours)
- [ ] Update `proposal_generator_screen.dart`:
  - Add "Generate Proposal" button with modal
  - Add Type dropdown: "One Page Quote" / "Detailed Proposal"
  - Add Format dropdown: "PDF" / "Google Slides"
  - Add Language toggle: "ES" / "EN" (optional)
  - Wire up to new service methods
- [ ] Update Studio pane with new actions
- [ ] Add preview dialogs for both types

### Phase 7: Knowledge Integration (30 min)
- [ ] Verify `/knowledge/services` dataset structure
- [ ] Update Knowledge pulls to fetch service details
- [ ] Add pricing data retrieval
- [ ] Integrate service descriptions (ES/EN)

### Phase 8: Testing & Validation (1 hour)
- [ ] Test One Page Quote PDF generation
- [ ] Test Detailed Proposal PDF generation
- [ ] Test Google Slides export
- [ ] Verify IBIS visual match (colors, fonts, layout)
- [ ] Test with Bajaj Ecuador demo flow
- [ ] Test with Banco del Austro demo flow
- [ ] Verify Veo video stability preserved
- [ ] Verify ReportsLM integration intact

### Phase 9: Documentation & Deployment (30 min)
- [ ] Update `PROPOSAL_TEMPLATES.md` with IBIS templates
- [ ] Add IBIS example screenshots
- [ ] Update agent prompt documentation
- [ ] Create deployment checklist
- [ ] Update Docker/Firebase config for fonts/assets
- [ ] Prepare for Feb 20 deadline

## Technical Notes

### IBIS Color Palette
```dart
background: #1A0F2E (dark purple-black)
sectionHeader: #6B46C1 (purple)
textPrimary: #FFFFFF (white)
textSecondary: #A0AEC0 (gray)
priceBox: #6B46C1 (purple)
```

### Font Stack
- Sans-serif (Helvetica, Inter, or Roboto)
- Header: Bold, 18-24pt
- Body: Regular, 10-12pt
- Price: Bold, 14-16pt

### JSON Output Validation
- Agent MUST return valid JSON matching schemas
- Fallback to text if JSON parsing fails
- Log all generation attempts for debugging

### Backward Compatibility
- Preserve existing template system
- Keep Brian/Classic/Minimal templates
- Add IBIS as new template option
- Ensure no breaking changes to existing flows

## Success Criteria
- ✅ One Page Quote generates correctly (PDF + Slides)
- ✅ Detailed Proposal generates correctly (PDF + Slides)
- ✅ Visual style matches IBIS.pdf exactly
- ✅ Spanish language primary, EN optional
- ✅ Knowledge integration working
- ✅ Creative Studio images embedded
- ✅ All existing functionality preserved
- ✅ Demo flows working (Bajaj, Banco del Austro)
- ✅ Ready for production by Feb 20

## Timeline
- Phase 1-2: 1.5 hours
- Phase 3-4: 3.5 hours
- Phase 5-6: 2.5 hours
- Phase 7-9: 2 hours
- **Total: ~9.5 hours**

## Next Steps
1. Start with Phase 1: Update data models
2. Move to Phase 2: Update agent prompts
3. Build Phase 3: IBIS PDF generator
4. Continue sequentially through remaining phases
