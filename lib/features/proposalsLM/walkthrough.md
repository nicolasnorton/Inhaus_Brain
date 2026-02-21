# ProposalsLM Flutter Module — Integration Walkthrough

This document explains how to integrate the **proposalsLM** Flutter module (located at `flutter_export/lib/features/proposalsLM/`) into the [Inhaus_Brain](https://github.com/nicolasnorton/Inhaus_Brain/tree/staging) Flutter application.

---

## 1. Overview — What Was Ported

The original **INHAUS Cotizador** is a React + Express + PostgreSQL web app for building branded quotations. This Flutter module recreates the front-end layer in Dart/Flutter while reusing the same Express REST API backend.

### Files Created

```
flutter_export/lib/features/proposalsLM/
├── proposals_lm.dart                    # barrel export
├── models/
│   ├── section.dart                     # Section {title, content}
│   ├── package.dart                     # Package model (slug, name, price, sections, group…)
│   ├── quote.dart                       # Quote, QuoteItem, ExtraBlock
│   ├── proforma_style.dart              # ProformaStyle + StyleColors (7-color palette)
│   └── constants.dart                   # IVA_RATE, categories, billingOptions, logoVariants,
│                                        #   packageGroups, formatCurrency(), todayStr(), calcTotals()
├── services/
│   └── proposals_service.dart           # HTTP client — all REST endpoints
├── views/
│   ├── quotes_dashboard_view.dart       # Quote history list  (← history-view.tsx)
│   ├── quote_editor_view.dart           # Sidebar editor       (← editor-modal.tsx)
│   ├── packages_manager_view.dart       # Package catalog/CRUD (← packages-view.tsx)
│   ├── tuneador_view.dart               # AI text-to-quote     (← tuneador-view.tsx)
│   └── styles_config_view.dart          # Color style config    (← styles-view.tsx)
└── walkthrough.md                       # ← you are here
```

### React → Flutter mapping

| React Component           | Flutter Widget               | Key Features                                                |
|---------------------------|------------------------------|-------------------------------------------------------------|
| `history-view.tsx`        | `QuotesDashboardView`        | List of saved quotes, delete, preview/edit/print actions    |
| `editor-modal.tsx`        | `QuoteEditorView`            | Sidebar nav, style/logo pickers, item/section editing       |
| `packages-view.tsx`       | `PackagesManagerView`        | Group tabs, category grid, soft-delete dialog, restore      |
| `tuneador-view.tsx`       | `TuneadorView`               | Paste text → AI parse → review/edit items → open in editor  |
| `styles-view.tsx`         | `StylesConfigView`           | Create/edit color palettes, preview mini-card               |
| `lib/constants.ts`        | `models/constants.dart`      | `formatCurrency`, `calcTotals`, `todayStr`, enums           |
| `lib/store.ts`            | (state in StatefulWidgets)   | Quote state managed locally; convert to Riverpod for Brain  |
| `shared/schema.ts`        | `models/*.dart`              | All Drizzle schemas → Dart classes with JSON serialization  |

---

## 2. Prerequisites

### pubspec.yaml additions
```yaml
dependencies:
  http: ^1.2.0
  intl: ^0.19.0          # for NumberFormat / DateFormat in constants.dart
```

If switching to Riverpod state management (recommended for Inhaus_Brain):
```yaml
  flutter_riverpod: ^2.5.1
```

---

## 3. Merge into Inhaus_Brain workspace

First, navigate to your local `Inhaus_Brain` repository and create a new feature branch for the proposalsLM module:

```bash
cd /path/to/Inhaus_Brain
git checkout -b feature/proposals-lm-module
```

Then, copy the exported Flutter files into the `features` directory:

```bash
# From the Asset-Manager repo root:
cp -r /Users/nicolasnorton/Documents/Asset-Manager/flutter_export/lib/features/proposalsLM \
      /path/to/Inhaus_Brain/lib/features/proposalsLM
```

Next, copy the Python Cloud Functions into the backend:

```bash
# From the Asset-Manager repo root:
cp /Users/nicolasnorton/Documents/Asset-Manager/flutter_export/lib/features/proposalsLM/cloud_functions/*.py \
   /path/to/Inhaus_Brain/functions-python/
```

The barrel file `proposals_lm.dart` lets you import everything with:
```dart
import 'package:inhaus_brain/features/proposalsLM/proposals_lm.dart';
```

---

## 4. Wire Up the Backend URL

The `ProposalsService` requires a `baseUrl` pointing to the Express backend.  
In Inhaus_Brain you likely already have an environment/config mechanism. Example:

```dart
final service = ProposalsService(
  baseUrl: 'https://cotizador.inhauscorp.com',  // or your staging URL
);
```

If using Riverpod:
```dart
final proposalsServiceProvider = Provider((ref) {
  final config = ref.read(appConfigProvider);
  return ProposalsService(baseUrl: config.cotizadorUrl);
});
```

---

## 5. Add to Navigation

In Inhaus_Brain, register the proposalsLM views in your main navigation (e.g. sidebar or bottom nav):

```dart
// Example MaterialApp route registration
GoRoute(
  path: '/proposals',
  builder: (context, state) => QuotesDashboardView(service: service),
),
GoRoute(
  path: '/proposals/editor',
  builder: (context, state) => QuoteEditorView(service: service),
),
GoRoute(
  path: '/proposals/packages',
  builder: (context, state) => PackagesManagerView(service: service),
),
GoRoute(
  path: '/proposals/tuneador',
  builder: (context, state) => TuneadorView(service: service),
),
GoRoute(
  path: '/proposals/styles',
  builder: (context, state) => StylesConfigView(service: service),
),
```

---

## 6. Data Models — API Contract

All models use `fromJson` / `toJson` and match the Express API's JSON shape exactly:

| Dart Class       | DB Table          | Key Fields                                                          |
|------------------|-------------------|---------------------------------------------------------------------|
| `Quote`          | `quotes`          | id, client, date, discount, applyIva, items[], extraBlocks[], …     |
| `QuoteItem`      | (JSONB in quotes) | id, name, category, price, billing, sections[]                      |
| `ExtraBlock`     | (JSONB in quotes) | id, title, content                                                  |
| `Section`        | (JSONB)           | title, content                                                      |
| `Package`        | `packages`        | id, slug, name, category, price, billing, sections[], packageGroup  |
| `ProformaStyle`  | `proforma_styles` | id, name, colors (StyleColors), referenceImages[], isDefault        |
| `StyleColors`    | (JSONB)           | background, cardBg, accent, textPrimary, textSecondary, textMuted, border |

---

## 7. REST Endpoints Supported by ProposalsService

| Method   | Path                           | Purpose                          |
|----------|--------------------------------|----------------------------------|
| GET      | `/api/quotes`                  | List all quotes                  |
| POST     | `/api/quotes`                  | Create a new quote               |
| DELETE   | `/api/quotes/:id`              | Delete a quote                   |
| GET      | `/api/packages`                | List active packages             |
| POST     | `/api/packages`                | Create a package                 |
| PUT      | `/api/packages/:slug`          | Update a package                 |
| DELETE   | `/api/packages/:slug`          | Soft-delete (requires masterKey) |
| GET      | `/api/packages/deleted`        | List soft-deleted packages       |
| POST     | `/api/packages/:slug/restore`  | Restore a soft-deleted package   |
| GET      | `/api/styles`                  | List proforma styles             |
| POST     | `/api/styles`                  | Create a style                   |
| PUT      | `/api/styles/:id`              | Update a style                   |
| DELETE   | `/api/styles/:id`              | Delete a style                   |
| POST     | `/api/tune-proforma`           | AI text → quote (Claude)         |
| POST     | `/api/import-packages`         | AI text → packages (Claude)      |

---

## 8. Design System & Color Tokens

All views use the INHAUS dark theme:
- **Background** `#111111`
- **Card BG** `#1A1A1A`
- **Accent/Primary** `#E8006A` (brand pink)
- **Border** `#2A2A2A`
- **Text Primary** `#FFFFFF`
- **Text Muted** `#888888`

These can be overridden through `ProformaStyle` objects for user-customized branding.

---

## 9. Next Steps

1. **State Management** — Convert the `StatefulWidget` state in each view to Riverpod providers to match Inhaus_Brain patterns.
2. **PDF Generation** — Port `client/src/lib/pdf.ts` using the `pdf` (or `printing`) Flutter package.
3. **File Upload** — The Tuneador's upload mode needs platform-specific file picking (use `file_picker` package).
4. **Chat Integration** — Connect the AI chat view through Inhaus_Brain's existing orchestration layer.
5. **Authentication** — Wrap `ProposalsService` with auth headers from Inhaus_Brain's auth system.

---

## 10. Testing

All models include `fromJson` / `toJson` round-trip support. Example unit test:

```dart
import 'package:test/test.dart';
import 'package:inhaus_brain/features/proposalsLM/models/quote.dart';

void main() {
  test('Quote JSON round-trip', () {
    final json = {
      'id': 1,
      'client': 'ACME Corp',
      'date': '20 febrero 2026',
      'discount': 10.0,
      'applyIva': true,
      'items': [],
      'extraBlocks': [],
      'extraAmount': 0,
      'totalNote': '',
      'logoVariant': 'ESTUDIO',
      'styleId': null,
      'createdAt': '2026-02-20T00:00:00.000Z',
    };
    final quote = Quote.fromJson(json);
    expect(quote.client, 'ACME Corp');
    expect(quote.toJson()['discount'], 10.0);
  });
}
```
