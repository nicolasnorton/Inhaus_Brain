import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/proposal_model.dart';
import 'pdf_styles.dart';

class ProposalPdfService {

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
      debugPrint('Warning: Failed to load Google Fonts, falling back to standard fonts.');
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    // Load assets
    final (inhausLogo, clientLogo) = await _loadLogos(data.header.clientLogoUrl);

    if (data.type == 'one_page') {
      _generateOnePage(pdf, data, fontRegular, fontBold, inhausLogo, clientLogo);
    } else {
      _generateDetailed(pdf, data, fontRegular, fontBold, inhausLogo, clientLogo);
    }

    return pdf.save();
  }

  static Future<(pw.ImageProvider?, pw.ImageProvider?)> _loadLogos(String? clientLogoUrl) async {
    pw.ImageProvider? inhausLogo;
    pw.ImageProvider? clientLogo;

    // 1. INHAUS Logo
    try {
      final logoBytes = await rootBundle.load('assets/images/Dark_Background_Logo.png');
      inhausLogo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('ProposalPdfService: Failed to load INHAUS logo asset: $e');
    }

    // 2. Client Logo
    if (clientLogoUrl != null && clientLogoUrl.isNotEmpty) {
      try {
        final netBundle = NetworkAssetBundle(Uri.parse(clientLogoUrl));
        final data = await netBundle.load(clientLogoUrl);
        clientLogo = pw.MemoryImage(data.buffer.asUint8List());
      } catch (e) {
        debugPrint('ProposalPdfService: Failed to load client logo from URL ($clientLogoUrl): $e');
      }
    }

    return (inhausLogo, clientLogo);
  }

  static void _generateOnePage(pw.Document pdf, ProposalData data, pw.Font regular, pw.Font bold, pw.ImageProvider? inhausLogo, pw.ImageProvider? clientLogo) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            color: PdfStyles.inhausDark,
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(data, regular, bold, inhausLogo, clientLogo),
                pw.SizedBox(height: 40),
                pw.Text("ONE-PAGE SUMMARY", style: PdfStyles.labelText(bold).copyWith(fontSize: 12)),
                pw.SizedBox(height: 20),
                pw.Text(data.summary?.intro ?? '', style: PdfStyles.bodyText(regular).copyWith(fontSize: 16, height: 1.5)),
                pw.SizedBox(height: 40),
                pw.Text("KEY SERVICES", style: PdfStyles.labelText(bold)),
                pw.SizedBox(height: 10),
                if (data.summary != null)
                  ...data.summary!.keyServices.map((service) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(children: [
                          pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: PdfStyles.inhausTextSecondary, shape: pw.BoxShape.circle)),
                          pw.SizedBox(width: 12),
                          pw.Text(service, style: PdfStyles.bodyText(regular).copyWith(fontSize: 13)),
                        ]),
                      )),
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.all(24),
                  decoration: pw.BoxDecoration(
                    color: PdfStyles.inhausPurple,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: PdfStyles.inhausCard, width: 1),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(data.summary?.totalPrice.label ?? 'TOTAL:', style: PdfStyles.sectionTitle(bold)),
                      pw.Text(data.summary?.totalPrice.amount ?? 'TBD', style: PdfStyles.priceText(bold)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(data.footer ?? 'inhauscorp.com', style: PdfStyles.labelText(regular)),
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
            color: PdfStyles.inhausDark,
            child: pw.Stack(
              children: [
                 // Design element
                 pw.Positioned(
                   top: -100,
                   right: -100,
                   child: pw.Container(width: 400, height: 400, decoration: pw.BoxDecoration(color: PdfStyles.withOpacity(PdfStyles.inhausPurple, 0.3), shape: pw.BoxShape.circle)),
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
                           pw.Text(data.header.agencyTitle, style: PdfStyles.sectionTitle(bold)),
                        pw.SizedBox(height: 60),
                        pw.Text("BUSINESS\nPROPOSAL", style: PdfStyles.headerTitle(bold)),
                        pw.SizedBox(height: 40),
                        pw.Container(height: 4, width: 60, color: PdfStyles.inhausPurple),
                        pw.SizedBox(height: 40),
                        pw.Text("PREPARED FOR:", style: PdfStyles.labelText(bold)),
                        pw.Text(data.header.clientName, style: PdfStyles.priceText(bold)),
                        pw.SizedBox(height: 10),
                        pw.Text(data.header.date, style: PdfStyles.bodyText(regular)),
                     ],
                   ),
                 ),
                 pw.Positioned(
                   bottom: 60,
                   right: 60,
                   child: pw.Text(data.footer ?? 'inhauscorp.com', style: PdfStyles.labelText(regular)),
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
                color: PdfStyles.inhausDark,
                padding: const pw.EdgeInsets.all(60),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                     _buildHeader(data, regular, bold, inhausLogo, clientLogo),
                    pw.SizedBox(height: 30),
                    // Service Header (Purple Rounded Bar)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: pw.BoxDecoration(
                        color: PdfStyles.inhausPurple,
                        borderRadius: pw.BorderRadius.circular(50),
                      ),
                      child: pw.Text(section.title.toUpperCase(), style: PdfStyles.sectionTitle(bold)),
                    ),
                    pw.SizedBox(height: 40),
                    
                    // Header Info
                    if (section.content.headerInfo.isNotEmpty)
                      ...section.content.headerInfo.map((info) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 12),
                        child: pw.Text(info, style: PdfStyles.bodyText(regular).copyWith(fontSize: 14, height: 1.5)),
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
                            color: PdfStyles.inhausPurple,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(color: PdfStyles.inhausCard, width: 1),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(section.price.label.toUpperCase(), style: PdfStyles.labelText(bold)),
                              pw.SizedBox(height: 4),
                              pw.Text(section.price.amount, style: PdfStyles.priceText(bold)),
                              if (section.price.terms != null)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(top: 4),
                                  child: pw.Text(section.price.terms!, style: PdfStyles.labelText(regular).copyWith(fontSize: 9)),
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
                        pw.Text(data.footer ?? 'inhauscorp.com', style: PdfStyles.labelText(regular).copyWith(fontSize: 8)),
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
            pw.Expanded(child: pw.Text(item, style: PdfStyles.bodyText(regular))),
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
          color: PdfStyles.inhausCard,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(col.title.toUpperCase(), style: PdfStyles.labelText(bold)),
            pw.SizedBox(height: 8),
            pw.Text(col.value, style: PdfStyles.bodyText(regular)),
          ],
        ),
      )).toList(),
    );
  }

  static pw.Widget _buildHeader(ProposalData data, pw.Font regular, pw.Font bold, pw.ImageProvider? inhausLogo, pw.ImageProvider? clientLogo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (inhausLogo != null)
          pw.Image(inhausLogo, height: 60)
        else
          pw.Text(data.header.agencyTitle, style: PdfStyles.sectionTitle(bold)),
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
                pw.Text(data.header.clientName, style: PdfStyles.labelText(bold)),
                pw.Text(data.header.date, style: PdfStyles.labelText(regular).copyWith(fontSize: 8)),
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
