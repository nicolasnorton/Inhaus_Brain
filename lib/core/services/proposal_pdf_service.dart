import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../features/campaigns/models/proposal_model.dart';

class ProposalPdfService {
  static Future<Uint8List> generateProposalPdf(ProposalData data) async {
    final pdf = pw.Document();

    // Load fonts if needed, for now use standard
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    // 1. Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(60),
            decoration: const pw.BoxDecoration(
              color: PdfColors.black,
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("INHAUS BRAIN", style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 12, letterSpacing: 2)),
                pw.SizedBox(height: 100),
                pw.Text(data.cover.title.toUpperCase(), style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 40)),
                pw.SizedBox(height: 20),
                pw.Text(data.cover.subtitle, style: pw.TextStyle(font: fontRegular, color: PdfColor.fromInt(0xB3FFFFFF), fontSize: 18)),
                pw.Spacer(),
                pw.Divider(color: PdfColor.fromInt(0x3DFFFFFF)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("PREPARED FOR: ${data.client.toUpperCase()}", style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 10)),
                    pw.Text(DateTime.now().toString().split(' ')[0], style: pw.TextStyle(font: fontRegular, color: PdfColor.fromInt(0x8AFFFFFF), fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // 2. Content Pages
    for (var section in data.sections) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text("Inhaus Brain - Confidential", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ),
          footer: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ),
          build: (pw.Context context) {
            return [
               _buildSectionHeader(section.type, fontBold),
               pw.SizedBox(height: 20),
               if (section.contentEn != null) ...[
                 _buildBilingualText(section.contentEn!, section.contentEs ?? '', fontRegular, fontBold),
                 pw.SizedBox(height: 30),
               ],
               if (section.items != null) ...[
                 ...section.items!.map((item) => _buildServiceItem(item, fontRegular, fontBold)),
               ],
               if (section.pricingTable != null) ...[
                 _buildPricingTable(section.pricingTable!, fontRegular, fontBold),
                 if (section.contentEn != null) pw.SizedBox(height: 10),
               ],
               if (section.milestones != null) ...[
                 _buildTimeline(section.milestones!, fontRegular, fontBold),
               ],
            ];
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildSectionHeader(String type, pw.Font fontBold) {
     String title = type.toUpperCase();
     return pw.Column(
       crossAxisAlignment: pw.CrossAxisAlignment.start,
       children: [
         pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blue)),
         pw.Container(height: 2, width: 40, color: PdfColors.blue, margin: const pw.EdgeInsets.only(top: 4)),
       ],
     );
  }

  static pw.Widget _buildBilingualText(String en, String es, pw.Font regular, pw.Font bold) {
     return pw.Column(
       crossAxisAlignment: pw.CrossAxisAlignment.start,
       children: [
         pw.Text(en, style: pw.TextStyle(font: regular, fontSize: 12)),
         pw.SizedBox(height: 10),
         pw.Container(
           padding: const pw.EdgeInsets.all(10),
           decoration: const pw.BoxDecoration(color: PdfColors.grey200),
           child: pw.Text(es, style: pw.TextStyle(font: regular, fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey)),
         ),
       ],
     );
  }

  static pw.Widget _buildServiceItem(ProposalServiceItem item, pw.Font regular, pw.Font bold) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(item.name, style: pw.TextStyle(font: bold, fontSize: 14)),
          pw.SizedBox(height: 5),
          pw.Text(item.descriptionEn, style: pw.TextStyle(font: regular, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(item.descriptionEs, style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey600)),
          if (item.benefits.isNotEmpty) ...[
             pw.SizedBox(height: 4),
             pw.Text("✓ ${item.benefits}", style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.green)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildPricingTable(List<Map<String, dynamic>> table, pw.Font regular, pw.Font bold) {
    return pw.TableHelper.fromTextArray(
      context: null,
      cellStyle: pw.TextStyle(font: regular, fontSize: 10),
      headerStyle: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
      data: <List<String>>[
        <String>['Item', 'Price', 'Frequency'],
        ...table.map((row) => [
          row['item']?.toString() ?? '',
          row['price']?.toString() ?? '',
          row['frequency']?.toString() ?? '',
        ]),
      ],
    );
  }

  static pw.Widget _buildTimeline(List<ProposalMilestone> milestones, pw.Font regular, pw.Font bold) {
    return pw.Column(
      children: milestones.map((m) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 80,
              child: pw.Text(m.date, style: pw.TextStyle(font: bold, fontSize: 10)),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(m.eventEn, style: pw.TextStyle(font: regular, fontSize: 11)),
                  pw.Text(m.eventEs, style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  static Future<void> saveAndOpenPdf(Uint8List bytes, String filename) async {
    // This is for mobile/desktop, on web it might be different
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
