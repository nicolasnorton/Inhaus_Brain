import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/proposal_model.dart';

class ProposalPdfService {
  static final PdfColor inhausDark = PdfColor.fromInt(0xFF1A0F2E); // #1A0F2E
  static final PdfColor inhausPurple = PdfColor.fromInt(0xFF6B46C1); // #6B46C1
  static final PdfColor inhausGray = PdfColor.fromInt(0xFFA0AEC0); // #A0AEC0

  static Future<Uint8List> generateProposalPdf(ProposalData data) async {
    final pdf = pw.Document(
      title: 'INHAUS PROPOSAL - ${data.header.clientName}',
      author: 'INHAUS ESTUDIO CREATIVO',
    );

    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    if (data.type == 'one_page') {
      _generateOnePage(pdf, data, fontRegular, fontBold);
    } else {
      _generateDetailed(pdf, data, fontRegular, fontBold);
    }

    return pdf.save();
  }

  static void _generateOnePage(pw.Document pdf, ProposalData data, pw.Font regular, pw.Font bold) {
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
                _buildHeader(data, bold),
                pw.SizedBox(height: 40),
                pw.Text("ONE-PAGE SUMMARY", style: pw.TextStyle(font: bold, fontSize: 12, color: inhausPurple)),
                pw.SizedBox(height: 20),
                pw.Text(data.summary?.intro ?? '', style: pw.TextStyle(font: regular, fontSize: 16, color: PdfColors.white, height: 1.5)),
                pw.SizedBox(height: 40),
                pw.Text("KEY SERVICES", style: pw.TextStyle(font: bold, fontSize: 10, color: inhausGray)),
                pw.SizedBox(height: 10),
                if (data.summary != null)
                  ...data.summary!.keyServices.map((service) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(children: [
                          pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: inhausPurple, shape: pw.BoxShape.circle)),
                          pw.SizedBox(width: 12),
                          pw.Text(service, style: pw.TextStyle(font: regular, fontSize: 13, color: PdfColors.white)),
                        ]),
                      )),
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.all(24),
                  decoration: pw.BoxDecoration(
                    color: inhausPurple,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(data.summary?.totalPrice.label ?? 'TOTAL:', style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.white)),
                      pw.Text(data.summary?.totalPrice.amount ?? 'TBD', style: pw.TextStyle(font: bold, fontSize: 24, color: PdfColors.white)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(data.footer ?? 'inhauscorp.com', style: pw.TextStyle(font: regular, fontSize: 10, color: inhausGray)),
              ],
            ),
          );
        },
      ),
    );
  }

  static void _generateDetailed(pw.Document pdf, ProposalData data, pw.Font regular, pw.Font bold) {
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
                   child: pw.Container(width: 400, height: 400, decoration: pw.BoxDecoration(color: PdfColor.fromInt(0x1A6B46C1), shape: pw.BoxShape.circle)),
                 ),
                 pw.Padding(
                   padding: const pw.EdgeInsets.all(60),
                   child: pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     mainAxisAlignment: pw.MainAxisAlignment.center,
                     children: [
                        pw.Text(data.header.agencyTitle, style: pw.TextStyle(font: bold, fontSize: 14, color: inhausPurple, letterSpacing: 2)),
                        pw.SizedBox(height: 60),
                        pw.Text("BUSINESS\nPROPOSAL", style: pw.TextStyle(font: bold, fontSize: 48, color: PdfColors.white, height: 0.9)),
                        pw.SizedBox(height: 40),
                        pw.Container(height: 2, width: 60, color: inhausPurple),
                        pw.SizedBox(height: 40),
                        pw.Text("PREPARED FOR:", style: pw.TextStyle(font: bold, fontSize: 12, color: inhausGray)),
                        pw.Text(data.header.clientName, style: pw.TextStyle(font: bold, fontSize: 24, color: PdfColors.white)),
                        pw.SizedBox(height: 10),
                        pw.Text(data.header.date, style: pw.TextStyle(font: regular, fontSize: 12, color: inhausGray)),
                     ],
                   ),
                 ),
                 pw.Positioned(
                   bottom: 60,
                   left: 60,
                   child: pw.Text(data.footer ?? 'inhauscorp.com', style: pw.TextStyle(font: regular, fontSize: 10, color: inhausGray)),
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
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: inhausPurple,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(section.title, style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.white)),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text(section.description, style: pw.TextStyle(font: regular, fontSize: 13, color: PdfColors.white, height: 1.6)),
                    pw.SizedBox(height: 30),
                    if (section.bullets.isNotEmpty) ...[
                       ...section.bullets.map((b) => pw.Padding(
                         padding: const pw.EdgeInsets.only(bottom: 8),
                         child: pw.Row(
                           crossAxisAlignment: pw.CrossAxisAlignment.start,
                           children: [
                             pw.Text("• ", style: pw.TextStyle(font: bold, color: inhausPurple, fontSize: 16)),
                             pw.Expanded(child: pw.Text(b, style: pw.TextStyle(font: regular, fontSize: 12, color: PdfColors.white))),
                           ],
                         ),
                       )),
                    ],
                    pw.Spacer(),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (section.includes.isNotEmpty) ...[
                                pw.Text("INCLUDES:", style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.green)),
                                ...section.includes.map((i) => pw.Text(i, style: pw.TextStyle(font: regular, fontSize: 9, color: inhausGray))),
                                pw.SizedBox(height: 12),
                              ],
                              if (section.excludes.isNotEmpty) ...[
                                pw.Text("EXCLUDES:", style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.red)),
                                ...section.excludes.map((e) => pw.Text(e, style: pw.TextStyle(font: regular, fontSize: 9, color: inhausGray))),
                              ],
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: inhausPurple,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(section.price.label, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColor.fromInt(0xB3FFFFFF))),
                              pw.Text(section.price.amount, style: pw.TextStyle(font: bold, fontSize: 18, color: PdfColors.white)),
                            ],
                          ),
                        ),
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

  static pw.Widget _buildHeader(ProposalData data, pw.Font bold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(data.header.agencyTitle, style: pw.TextStyle(font: bold, fontSize: 12, color: inhausPurple, letterSpacing: 1)),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(data.header.clientName, style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white)),
            pw.Text(data.header.date, style: pw.TextStyle(font: bold, fontSize: 8, color: inhausGray)),
          ],
        ),
      ],
    );
  }

  static Future<void> saveAndOpenPdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
