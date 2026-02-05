# Proposal Template System

## Overview
The Inhaus Brain proposal system now supports customizable templates for both one-pager and multi-page PDF proposals. The **Brian Premium Gold/Dark template** is set as the default.

## Default Templates

### 1. Brian One-Pager (Default)
- **Style**: Premium dark background (#0F0F12) with gold accents (#E5B15D)
- **Layout**: Single page, executive summary format
- **Best For**: Quick proposals, service quotes, initial pitches
- **Features**:
  - Client and agency logos
  - Gold dividers and accents
  - Compact section layout
  - Professional footer with contact info

### 2. Brian Multi-Page
- **Style**: Same premium gold/dark aesthetic
- **Layout**: Cover page + individual section pages
- **Best For**: Comprehensive proposals, detailed service breakdowns
- **Features**:
  - Dedicated cover page
  - Full-page sections with detailed descriptions
  - Page headers and footers
  - Professional branding throughout

### 3. Classic One-Pager
- **Style**: Original Inhaus pink/purple theme
- **Layout**: Single page format
- **Best For**: Legacy clients, alternative aesthetic

### 4. Minimal One-Pager
- **Style**: Clean white background with blue accents
- **Layout**: Minimal, straightforward
- **Best For**: Corporate clients, simple service agreements

## Template Configuration

Each template includes:
- **Color Scheme**: Background, surface, accent, text colors
- **Typography**: Font families, sizes, letter spacing
- **Layout**: Margins, spacing, logo placement
- **Branding**: Agency name, tagline, contact information

## Custom Templates

### Uploading Custom Templates
1. Navigate to Proposal Generator → Studio
2. Click the palette icon (🎨) to open Template Manager
3. Click "Upload Custom Template"
4. Select a PDF or JSON template file
5. The template will be added to your library

### Template File Format (JSON)
```json
{
  "id": "custom-template-id",
  "name": "My Custom Template",
  "description": "Description of the template",
  "type": "onePager",
  "style": "custom",
  "config": {
    "colors": {
      "background": "0xFF000000",
      "surface": "0xFF1A1A1A",
      "accent": "0xFFFFD700",
      "textPrimary": "0xFFFFFFFF",
      "textSecondary": "0xFF999999"
    },
    "typography": {
      "headingFont": "Helvetica",
      "bodyFont": "Helvetica",
      "headingSize": 32,
      "bodySize": 14,
      "letterSpacing": 1.2
    },
    "layout": {
      "marginTop": 50,
      "marginBottom": 40,
      "marginLeft": 40,
      "marginRight": 40,
      "sectionSpacing": 20,
      "showClientLogo": true,
      "showAgencyLogo": true,
      "headerAlignment": "spaceBetween",
      "showDividers": true
    },
    "branding": {
      "agencyName": "INHAUS",
      "agencyTagline": "BRAIN - CORE SYSTEMS",
      "contactEmail": "info@inhauscorp.com",
      "contactPhone": "(+593) 98 656 6084",
      "website": "inhauscorp.com",
      "footerText": "APROBADO POR DIEGO ESPÍN"
    }
  }
}
```

## Using Templates

### In the UI
1. Open Proposal Generator
2. The current template is shown in the Studio pane
3. Click the palette icon to change templates
4. Select your desired template from the grid
5. Click "Apply Template"
6. Generate your proposal with the selected template

### Programmatically
```dart
// Get the current template
final template = ref.read(currentTemplateProvider);

// Generate PDF with template
final bytes = await ProposalService.generateProposalPdfBytes(
  proposal, 
  ref, 
  template: template
);
```

## Template Examples

The system includes templates matching the provided examples:
- **IBIS Example**: Dark theme with client logo, service sections, pricing
- **Majomi Example**: Similar layout with different client branding
- **NOSTOS Example**: Multi-service layout with detailed breakdowns

All examples use the premium Brian aesthetic as the foundation.

## Future Enhancements
- [ ] Template preview generation
- [ ] Template sharing across team
- [ ] Template versioning
- [ ] Advanced template editor
- [ ] Template marketplace
