import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report_model.dart';
import '../../proposals/services/pdf_styles.dart';

class ReportPdfService {

  static Future<Uint8List> generateReportPdf(Report report) async {
    final pdf = pw.Document(
      title: 'INHAUS REPORT - ${report.title}',
      author: 'INHAUS ESTUDIO CREATIVO',
    );

    // Fonts
    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      fontRegular = await PdfGoogleFonts.montserratRegular();
      fontBold = await PdfGoogleFonts.montserratBold();
    } catch (e) {
      fontRegular = pw.Font.courier();
      fontBold = pw.Font.courierBold();
    }

    // Logo
    pw.ImageProvider? inhausLogo;
    try {
       final logoBytes = await rootBundle.load('assets/images/Dark_Background_Logo.png');
       inhausLogo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // Parse Data
    Map<String, dynamic> data = {};
    if (report.outputs.isNotEmpty) {
      try {
        data = jsonDecode(report.outputs[0].content ?? '{}');
      } catch (e) {
        data = {'detailed_analysis': report.outputs[0].content};
      }
    }

    // 1. Cover Page
    _buildCoverPage(pdf, report, fontRegular, fontBold, inhausLogo);

    // 2. Executive Summary & Metrics
    _buildExecutivePage(pdf, data, fontRegular, fontBold);

    // 3. Insights & Recommendations
    _buildInsightsPage(pdf, data, fontRegular, fontBold);

    // 4. Detailed Analysis
    _buildAnalysisPage(pdf, data['detailed_analysis'] as String? ?? '', fontRegular, fontBold);

    return pdf.save();
  }

  static Future<Uint8List> generateReportPdfFromData(Map<String, dynamic> data) async {
    final title = data['title'] ?? 'Research Report';
    final clientId = data['client_id'] ?? 'INHAUS CLIENT';
    final createdAtStr = data['created_at'];
    final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();

    // Reconstruct Report for cover page
    final report = Report(
      id: data['id'] ?? 'temp',
      title: title,
      clientId: clientId,
      createdAt: createdAt,
      updatedAt: createdAt,
      outputs: []
    );
    
    // We can reuse the main method logic by duplicating it or extracting builder.
    // For simplicity, let's just reuse the builders.
    
    final pdf = pw.Document(
      title: 'INHAUS REPORT - $title',
      author: 'INHAUS ESTUDIO CREATIVO',
    );

    // Fonts
    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      fontRegular = await PdfGoogleFonts.montserratRegular();
      fontBold = await PdfGoogleFonts.montserratBold();
    } catch (e) {
      fontRegular = pw.Font.courier();
      fontBold = pw.Font.courierBold();
    }

    pw.ImageProvider? inhausLogo;
    try {
       final logoBytes = await rootBundle.load('assets/images/Dark_Background_Logo.png');
       inhausLogo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    _buildCoverPage(pdf, report, fontRegular, fontBold, inhausLogo);
    _buildExecutivePage(pdf, data, fontRegular, fontBold);
    _buildInsightsPage(pdf, data, fontRegular, fontBold);
    _buildAnalysisPage(pdf, data['detailed_analysis'] as String? ?? '', fontRegular, fontBold);

    return pdf.save();
  }

  static void _buildCoverPage(pw.Document pdf, Report report, pw.Font regular, pw.Font bold, pw.ImageProvider? logo) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            color: PdfStyles.inhausDark,
            child: pw.Stack(
              children: [
                 pw.Positioned(
                   top: -150,
                   right: -150,
                   child: pw.Container(
                     width: 500, height: 500, 
                     decoration: pw.BoxDecoration(color: PdfStyles.withOpacity(PdfColor.fromInt(0xFF1A1423), 0.5), shape: pw.BoxShape.circle)
                   ),
                 ),
                 pw.Padding(
                   padding: const pw.EdgeInsets.all(60),
                   child: pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     mainAxisAlignment: pw.MainAxisAlignment.center,
                     children: [
                        if (logo != null) pw.Image(logo, height: 80),
                        pw.Spacer(),
                        pw.Text("RESEARCH\nREPORT", style: PdfStyles.headerTitle(bold)),
                        pw.SizedBox(height: 40),
                        pw.Container(height: 4, width: 80, color: PdfColors.cyanAccent),
                        pw.SizedBox(height: 40),
                        pw.Text("TOPIC:", style: PdfStyles.labelText(bold)),
                        pw.Text(report.title.toUpperCase(), style: PdfStyles.priceText(bold)),
                        pw.SizedBox(height: 20),
                        pw.Text("PREPARED FOR:", style: PdfStyles.labelText(bold)),
                        pw.Text(report.clientId.toUpperCase(), style: PdfStyles.bodyText(regular).copyWith(fontSize: 16)),
                        pw.SizedBox(height: 10),
                        pw.Text(report.createdAt.toIso8601String().split('T')[0], style: PdfStyles.labelText(regular)),
                        pw.Spacer(),
                     ],
                   ),
                 ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void _buildExecutivePage(pw.Document pdf, Map<String, dynamic> data, pw.Font regular, pw.Font bold) {
     final execSummary = data['executive_summary'] as String? ?? '';
     final metrics = List<Map<String, dynamic>>.from(data['metrics'] ?? []);

     if (execSummary.isEmpty && metrics.isEmpty) return;

     pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            color: PdfStyles.inhausDark,
            padding: const pw.EdgeInsets.all(60),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("EXECUTIVE SUMMARY", style: PdfStyles.sectionTitle(bold)),
                pw.SizedBox(height: 20),
                pw.Text(execSummary, style: PdfStyles.bodyText(regular).copyWith(fontSize: 14, lineSpacing: 4)),
                
                pw.SizedBox(height: 40),
                
                if (metrics.isNotEmpty) ...[
                   pw.Text("KEY METRICS", style: PdfStyles.sectionTitle(bold)),
                   pw.SizedBox(height: 20),
                   pw.Wrap(
                     spacing: 20,
                     runSpacing: 20,
                     children: metrics.map((m) => _buildMetricCard(m, regular, bold)).toList(),
                   ),
                ]
              ],
            ),
          );
        }
      )
     );
  }

  static pw.Widget _buildMetricCard(Map<String, dynamic> metric, pw.Font regular, pw.Font bold) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfStyles.inhausCard,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfStyles.inhausCard, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text((metric['name'] ?? 'METRIC').toString().toUpperCase(), style: PdfStyles.labelText(bold)),
          pw.SizedBox(height: 8),
          pw.Text(metric['value'] ?? '-', style: PdfStyles.priceText(bold).copyWith(fontSize: 20)),
          pw.SizedBox(height: 4),
          pw.Text(metric['trend']?.toString().toUpperCase() ?? 'FLAT', style: PdfStyles.labelText(regular).copyWith(color: PdfColors.cyanAccent)),
        ],
      )
    );
  }

  static void _buildInsightsPage(pw.Document pdf, Map<String, dynamic> data, pw.Font regular, pw.Font bold) {
    final insights = List<String>.from(data['key_insights'] ?? []);
    final recs = List<String>.from(data['strategic_recommendations'] ?? []);

    if (insights.isEmpty && recs.isEmpty) return;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            color: PdfStyles.inhausDark,
            padding: const pw.EdgeInsets.all(60),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                 if (insights.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A1423), borderRadius: pw.BorderRadius.circular(20)),
                      child: pw.Text("KEY INSIGHTS", style: PdfStyles.sectionTitle(bold)),
                    ),
                    pw.SizedBox(height: 20),
                    ...insights.map((i) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(width: 4, height: 4, margin: const pw.EdgeInsets.only(top: 6, right: 10), decoration: pw.BoxDecoration(color: PdfColors.amberAccent, shape: pw.BoxShape.circle)),
                          pw.Expanded(child: pw.Text(i, style: PdfStyles.bodyText(regular))),
                        ],
                      ),
                    )),
                    pw.SizedBox(height: 40),
                 ],

                 if (recs.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A1423), borderRadius: pw.BorderRadius.circular(20)),
                      child: pw.Text("STRATEGIC RECOMMENDATIONS", style: PdfStyles.sectionTitle(bold)),
                    ),
                    pw.SizedBox(height: 20),
                    ...recs.map((r) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(width: 4, height: 4, margin: const pw.EdgeInsets.only(top: 6, right: 10), decoration: pw.BoxDecoration(color: PdfColors.greenAccent, shape: pw.BoxShape.circle)),
                          pw.Expanded(child: pw.Text(r, style: PdfStyles.bodyText(regular))),
                        ],
                      ),
                    )),
                 ],
              ],
            ),
          );
        }
      )
    );
  }

  static void _buildAnalysisPage(pw.Document pdf, String analysis, pw.Font regular, pw.Font bold) {
    if (analysis.isEmpty) return;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 20,
        margin: const pw.EdgeInsets.all(60),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        pageTheme: pw.PageTheme(
           pageFormat: PdfPageFormat.a4,
           margin: const pw.EdgeInsets.all(60),
           theme: pw.ThemeData.withFont(base: regular, bold: bold),
           buildBackground: (context) => pw.Container(color: PdfStyles.inhausDark), // Dark Background
        ),
        build: (context) => [
             pw.Header(
               level: 0, 
               text: "DETAILED ANALYSIS", 
               textStyle: PdfStyles.sectionTitle(bold),
               margin: const pw.EdgeInsets.only(bottom: 20),
               decoration: const pw.BoxDecoration()
             ),
             pw.Paragraph(
               text: analysis,
               style: PdfStyles.bodyText(regular).copyWith(lineSpacing: 2),
             ),
        ],
      )
    );
  }

  static Future<void> saveAndOpenPdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
