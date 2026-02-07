import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/proposal_model.dart';

class ProposalPdfService {
  // official INHAUS v2.0 Colors
  static final PdfColor inhausDark = PdfColor.fromInt(0xFF05050B); // #05050B
  static final PdfColor inhausCard = PdfColor.fromInt(0xFF0F0F16); // #0F0F16
  static final PdfColor inhausPurple = PdfColor.fromInt(0xFF1A1423); // #1A1423 (Dark Purple Bar)
  static final PdfColor inhausTextPrimary = PdfColors.white; // #FFFFFF
  static final PdfColor inhausTextSecondary = PdfColor.fromInt(0xFFA0A0A0); // #A0A0A0

  // Helper to create a PdfColor with opacity
  static PdfColor _withOpacity(PdfColor color, double opacity) {
    return PdfColor(color.red * opacity, color.green * opacity, color.blue * opacity, opacity);
  }

  static Future<Uint8List> generateProposalPdf(ProposalData data) async {
    final pdf = pw.Document(
      title: 'INHAUS PROPOSAL - ${data.header.clientName}',
      author: 'INHAUS ESTUDIO CREATIVO',
    );

    // Try Montserrat, fallback to Inter
    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      fontRegular = await PdfGoogleFonts.montserratRegular();
      fontBold = await PdfGoogleFonts.montserratBold();
    } catch (e) {
      fontRegular = await PdfGoogleFonts.interRegular();
      fontBold = await PdfGoogleFonts.interBold();
    }

    // Load INHAUS logo PNG from assets (more stable for PDF generation)
    pw.ImageProvider? inhausLogo;
    try {
      final logoBytes = await rootBundle.load('assets/images/Dark_Background_Logo.png');
      inhausLogo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Failed to load INHAUS logo: $e');
    }

    // Fetch client logo if available
    pw.ImageProvider? clientLogo;
    if (data.header.clientLogoUrl != null && data.header.clientLogoUrl!.isNotEmpty) {
      try {
        final logoBytes = (await NetworkAssetBundle(Uri.parse(data.header.clientLogoUrl!)).load(data.header.clientLogoUrl!)).buffer.asUint8List();
        clientLogo = pw.MemoryImage(logoBytes);
      } catch (e) {
        debugPrint('Failed to load client logo: $e');
      }
    }

    if (data.type == 'one_page') {
      _generateOnePage(pdf, data, fontRegular, fontBold, inhausLogo, clientLogo);
    } else {
      _generateDetailed(pdf, data, fontRegular, fontBold, inhausLogo, clientLogo);
    }

    return pdf.save();
  }

  static void _generateOnePage(pw.Document pdf, ProposalData data, pw.Font regular, pw.Font bold, pw.ImageProvider? inhausLogo, pw.ImageProvider? clientLogo) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            color: inhausDark,
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(data, bold, inhausLogo, clientLogo),
                pw.SizedBox(height: 40),
                pw.Text("ONE-PAGE SUMMARY", style: pw.TextStyle(font: bold, fontSize: 12, color: inhausTextSecondary)),
                pw.SizedBox(height: 20),
                pw.Text(data.summary?.intro ?? '', style: pw.TextStyle(font: regular, fontSize: 16, color: inhausTextPrimary, height: 1.5)),
                pw.SizedBox(height: 40),
                pw.Text("KEY SERVICES", style: pw.TextStyle(font: bold, fontSize: 10, color: inhausTextSecondary)),
                pw.SizedBox(height: 10),
                if (data.summary != null)
                  ...data.summary!.keyServices.map((service) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(children: [
                          pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: inhausTextSecondary, shape: pw.BoxShape.circle)),
                          pw.SizedBox(width: 12),
                          pw.Text(service, style: pw.TextStyle(font: regular, fontSize: 13, color: inhausTextPrimary)),
                        ]),
                      )),
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.all(24),
                  decoration: pw.BoxDecoration(
                    color: inhausPurple,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: inhausCard, width: 1),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(data.summary?.totalPrice.label ?? 'TOTAL:', style: pw.TextStyle(font: bold, fontSize: 14, color: inhausTextPrimary)),
                      pw.Text(data.summary?.totalPrice.amount ?? 'TBD', style: pw.TextStyle(font: bold, fontSize: 24, color: inhausTextPrimary)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(data.footer ?? 'inhauscorp.com', style: pw.TextStyle(font: regular, fontSize: 10, color: inhausTextSecondary)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void _generateDetailed(pw.Document pdf, ProposalData data, pw.Font regular, pw.Font bold, pw.ImageProvider? inhausLogo, pw.ImageProvider? clientLogo) {
    // Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            color: inhausDark,
            child: pw.Stack(
              children: [
                 // Design element
                 pw.Positioned(
                   top: -100,
                   right: -100,
                   child: pw.Container(width: 400, height: 400, decoration: pw.BoxDecoration(color: _withOpacity(inhausPurple, 0.3), shape: pw.BoxShape.circle)),
                 ),
                 pw.Padding(
                   padding: const pw.EdgeInsets.all(60),
                   child: pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     mainAxisAlignment: pw.MainAxisAlignment.center,
                     children: [
                        if (clientLogo != null)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 20),
                            child: pw.Image(clientLogo, height: 60),
                          ),
                         if (inhausLogo != null)
                           pw.Image(inhausLogo, height: 100)
                         else
                           pw.Text(data.header.agencyTitle, style: pw.TextStyle(font: bold, fontSize: 14, color: inhausTextPrimary, letterSpacing: 2)),
                        pw.SizedBox(height: 60),
                        pw.Text("BUSINESS\nPROPOSAL", style: pw.TextStyle(font: bold, fontSize: 48, color: inhausTextPrimary, height: 0.9)),
                        pw.SizedBox(height: 40),
                        pw.Container(height: 4, width: 60, color: inhausPurple),
                        pw.SizedBox(height: 40),
                        pw.Text("PREPARED FOR:", style: pw.TextStyle(font: bold, fontSize: 12, color: inhausTextSecondary)),
                        pw.Text(data.header.clientName, style: pw.TextStyle(font: bold, fontSize: 24, color: inhausTextPrimary)),
                        pw.SizedBox(height: 10),
                        pw.Text(data.header.date, style: pw.TextStyle(font: regular, fontSize: 12, color: inhausTextSecondary)),
                     ],
                   ),
                 ),
                 pw.Positioned(
                   bottom: 60,
                   right: 60,
                   child: pw.Text(data.footer ?? 'inhauscorp.com', style: pw.TextStyle(font: regular, fontSize: 10, color: inhausTextSecondary)),
                 )
              ],
            ),
          );
        },
      ),
    );

    // Section Pages
    if (data.sections != null) {
      for (var section in data.sections!) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Container(
                color: inhausDark,
                padding: const pw.EdgeInsets.all(60),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                     _buildHeader(data, bold, inhausLogo, clientLogo),
                    pw.SizedBox(height: 30),
                    // Service Header (Purple Rounded Bar)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: pw.BoxDecoration(
                        color: inhausPurple,
                        borderRadius: pw.BorderRadius.circular(50),
                      ),
                      child: pw.Text(section.title.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 14, color: inhausTextPrimary, letterSpacing: 1)),
                    ),
                    pw.SizedBox(height: 40),
                    
                    // Header Info
                    if (section.content.headerInfo.isNotEmpty)
                      ...section.content.headerInfo.map((info) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 12),
                        child: pw.Text(info, style: pw.TextStyle(font: regular, fontSize: 14, color: inhausTextPrimary, height: 1.5)),
                      )),
                    
                    pw.SizedBox(height: 20),

                    // Content Layout
                    if (section.layoutType == 'grid_columns' && section.content.columns.isNotEmpty)
                      _buildGridColumns(section.content.columns, regular, bold)
                    else
                      _buildStandardList(section.content.items, regular, bold),

                    pw.Spacer(),

                    // Pricing Box (Right Aligned)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(20),
                          decoration: pw.BoxDecoration(
                            color: inhausPurple,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(color: inhausCard, width: 1),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(section.price.label.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 10, color: inhausTextSecondary)),
                              pw.SizedBox(height: 4),
                              pw.Text(section.price.amount, style: pw.TextStyle(font: bold, fontSize: 24, color: inhausTextPrimary)),
                              if (section.price.terms != null)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(top: 4),
                                  child: pw.Text(section.price.terms!, style: pw.TextStyle(font: regular, fontSize: 9, color: inhausTextSecondary)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(data.footer ?? 'inhauscorp.com', style: pw.TextStyle(font: regular, fontSize: 8, color: inhausTextSecondary)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    }
  }

  static pw.Widget _buildStandardList(List<String> items, pw.Font regular, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((item) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 4, right: 12),
              width: 6,
              height: 6,
              decoration: const pw.BoxDecoration(color: PdfColors.white, shape: pw.BoxShape.circle),
            ),
            pw.Expanded(child: pw.Text(item, style: pw.TextStyle(font: regular, fontSize: 12, color: inhausTextPrimary))),
          ],
        ),
      )).toList(),
    );
  }

  static pw.Widget _buildGridColumns(List<ProposalColumn> columns, pw.Font regular, pw.Font bold) {
    return pw.Wrap(
      spacing: 20,
      runSpacing: 20,
      children: columns.map((col) => pw.Container(
        width: 220,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: inhausCard,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(col.title.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 10, color: inhausTextSecondary, letterSpacing: 1)),
            pw.SizedBox(height: 8),
            pw.Text(col.value, style: pw.TextStyle(font: regular, fontSize: 12, color: inhausTextPrimary)),
          ],
        ),
      )).toList(),
    );
  }

  static pw.Widget _buildHeader(ProposalData data, pw.Font bold, pw.ImageProvider? inhausLogo, pw.ImageProvider? clientLogo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (inhausLogo != null)
          pw.Image(inhausLogo, height: 60)
        else
          pw.Text(data.header.agencyTitle, style: pw.TextStyle(font: bold, fontSize: 12, color: inhausTextPrimary, letterSpacing: 1)),
        pw.Row(
          children: [
            if (clientLogo != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(right: 12),
                child: pw.Image(clientLogo, height: 30),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(data.header.clientName, style: pw.TextStyle(font: bold, fontSize: 10, color: inhausTextPrimary)),
                pw.Text(data.header.date, style: pw.TextStyle(font: bold, fontSize: 8, color: inhausTextSecondary)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> saveAndOpenPdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
