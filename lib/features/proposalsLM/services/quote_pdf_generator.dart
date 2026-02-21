import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../models/quote.dart';
import '../models/proforma_style.dart';

class QuotePdfGenerator {
  /// Converts hex string like "#111111" to PdfColor
  static PdfColor _fromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return PdfColor.fromInt(int.parse(hexColor, radix: 16));
  }

  static Future<Uint8List> generate(Quote quote, ProformaStyle style) async {
    final pdf = pw.Document();

    final bg = _fromHex(style.colors.background);
    final cardBg = _fromHex(style.colors.cardBg);
    final accent = _fromHex(style.colors.accent);
    final textPrimary = _fromHex(style.colors.textPrimary);
    final textSecondary = _fromHex(style.colors.textSecondary);
    final textMuted = _fromHex(style.colors.textMuted);
    final border = _fromHex(style.colors.border);

    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: bg),
          ),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // HEADER
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('COTIZACIÓN', 
                            style: pw.TextStyle(color: textPrimary, fontSize: 24, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                        pw.SizedBox(height: 4),
                        pw.Text('INHAUS ESTUDIO CREATIVO', 
                            style: pw.TextStyle(color: accent, fontSize: 8, letterSpacing: 2)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('CLIENTE', style: pw.TextStyle(color: textMuted, fontSize: 8, letterSpacing: 1.5)),
                        pw.Text(quote.client.toUpperCase(), 
                            style: pw.TextStyle(color: textPrimary, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(DateFormat('dd MMM yyyy').format(quote.createdAt), 
                            style: pw.TextStyle(color: textSecondary, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Divider(color: border, thickness: 0.5),
                pw.SizedBox(height: 20),

                // ITEMS
                ...quote.items.map((pkg) => _buildPackageCard(
                      pkg: pkg,
                      cardBg: cardBg,
                      accent: accent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      border: border,
                      currency: currency,
                    )),

                pw.SizedBox(height: 20),

                // TOTALS
                _buildTotals(quote, cardBg, textPrimary, textSecondary, accent, border, currency),

                // FOOTER
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('info@inhauscorp.com | (+593) 98 656 6084', 
                        style: pw.TextStyle(color: textMuted, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPackageCard({
    required QuoteItem pkg,
    required PdfColor cardBg,
    required PdfColor accent,
    required PdfColor textPrimary,
    required PdfColor textSecondary,
    required PdfColor border,
    required NumberFormat currency,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: cardBg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(pkg.category.toUpperCase(), style: pw.TextStyle(color: accent, fontSize: 8, letterSpacing: 1)),
                    pw.SizedBox(height: 4),
                    pw.Text(pkg.name, style: pw.TextStyle(color: textPrimary, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(currency.format(pkg.price), style: pw.TextStyle(color: textPrimary, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  if (pkg.billing.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(pkg.billing.toUpperCase(), style: pw.TextStyle(color: textSecondary, fontSize: 8)),
                  ]
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          ...pkg.sections.map((sec) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (sec.title.isNotEmpty) ...[
                      pw.Text(sec.title, style: pw.TextStyle(color: textPrimary, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                    ],
                    pw.Text(sec.content, style: pw.TextStyle(color: textSecondary, fontSize: 9, lineSpacing: 1.5)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static pw.Widget _buildTotals(
    Quote quote,
    PdfColor cardBg,
    PdfColor textPrimary,
    PdfColor textSecondary,
    PdfColor accent,
    PdfColor border,
    NumberFormat currency,
  ) {
    double subtotal = 0;
    for (var pkg in quote.items) {
      subtotal += pkg.price;
    }

    final discountAmount = subtotal * (quote.discount / 100);
    final subtotalAfterDiscount = subtotal - discountAmount;
    final iva = quote.applyIva ? subtotalAfterDiscount * 0.15 : 0.0;
    final total = subtotalAfterDiscount + iva;

    pw.Widget totalRow(String label, double amount, {bool isTotal = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, 
                style: pw.TextStyle(
                  color: isTotal ? textPrimary : textSecondary, 
                  fontSize: isTotal ? 12 : 10,
                  fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                )),
            pw.Text(currency.format(amount), 
                style: pw.TextStyle(
                  color: isTotal ? accent : textPrimary, 
                  fontSize: isTotal ? 14 : 10,
                  fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                )),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: cardBg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: border, width: 0.5),
      ),
      child: pw.Column(
        children: [
          totalRow('Subtotal', subtotal),
          if (quote.discount > 0) totalRow('Descuento (${quote.discount.toStringAsFixed(1)}%)', -discountAmount),
          if (quote.applyIva) totalRow('IVA (15%)', iva),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Divider(color: border, thickness: 0.5),
          ),
          totalRow('TOTAL', total, isTotal: true),
        ],
      ),
    );
  }
}
