import 'package:intl/intl.dart';

import 'quote.dart';

// ---------------------------------------------------------------------------
// IVA
// ---------------------------------------------------------------------------
const double ivaRate = 0.15;

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------
const List<String> categories = [
  'Redes Sociales',
  'Producción Audiovisual',
  'Diseño Web',
  'Branding',
  'Pauta Publicitaria',
  'Diseño Gráfico',
];

// ---------------------------------------------------------------------------
// Billing options
// ---------------------------------------------------------------------------
const List<Map<String, String>> billingOptions = [
  {'value': '', 'label': 'Sin especificar'},
  {'value': 'Pago único', 'label': 'Pago único'},
  {'value': 'Pago mensual', 'label': 'Pago mensual'},
  {'value': 'Cada dos meses', 'label': 'Cada dos meses'},
  {'value': 'Trimestral', 'label': 'Trimestral'},
  {'value': 'Semestral', 'label': 'Semestral'},
  {'value': 'Anual', 'label': 'Anual'},
];

// ---------------------------------------------------------------------------
// Logo variants
// ---------------------------------------------------------------------------
const List<String> logoVariants = [
  'ESTUDIO',
  'CORP',
  'MEDIA',
  'INHAUS',
  'NUHAUS',
  'TALENTS',
  'PRODUCCION',
];

// ---------------------------------------------------------------------------
// Package groups  (matches PACKAGE_GROUPS in schema.ts)
// ---------------------------------------------------------------------------
const List<String> packageGroups = [
  'Estudio',
  'Media',
  'Producción',
  'Nuhaus',
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Formats a number as `$1,000.00` using es-EC locale.
String formatCurrency(double n) {
  final fmt = NumberFormat.currency(locale: 'es_EC', symbol: r'$', decimalDigits: 2);
  return fmt.format(n);
}

/// Returns today as "20 febrero 2026" (es-EC long date).
String todayStr() {
  final now = DateTime.now();
  return DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(now);
}

/// Totals calculation matching the web version's `calcTotals`.
({double sub, double disc, double base, double iva, double total}) calcTotals({
  required List<QuoteItem> items,
  required double discount,
  required bool applyIva,
}) {
  final sub = items.fold<double>(0, (s, i) => s + i.price);
  final disc = discount > 0 ? sub * (discount / 100) : 0.0;
  final base = sub - disc;
  final iva = applyIva ? base * ivaRate : 0.0;
  return (sub: sub, disc: disc, base: base, iva: iva, total: base + iva);
}
