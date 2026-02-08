import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inhaus_brain/features/agency/models/proposal_template.dart';
import 'package:inhaus_brain/features/agency/services/proposal_pdf_generator.dart';
import 'package:inhaus_brain/features/proposals/models/proposal_model.dart';

class TemplatedProposalPdfGenerator {
  
  /// Helper to create a PdfColor with opacity
  static PdfColor _withOpacity(PdfColor color, double opacity) {
    return PdfColor(color.red, color.green, color.blue, opacity);
  }
  
  /// Generate PDF using a specific template
  static Future<Uint8List> generate(
    ProposalData data, 
    ProposalTemplate template, {
    Uint8List? agencyLogo, 
    Uint8List? clientLogo
  }) async {
    final pdf = pw.Document();
    
    // Parse colors from template
    final bgColor = _parseColor(template.config.colors.background);
    final surfaceColor = _parseColor(template.config.colors.surface);
    final accentColor = _parseColor(template.config.colors.accent);
    final textPrimary = _parseColor(template.config.colors.textPrimary);
    final textSecondary = _parseColor(template.config.colors.textSecondary);

    if (template.type == ProposalTemplateType.onePager) {
      // Single page layout
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(
                color: bgColor,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(data, template, agencyLogo: agencyLogo, clientLogo: clientLogo, accentColor: accentColor, textPrimary: textPrimary, textSecondary: textSecondary),
                    pw.SizedBox(height: 20),
                    pw.Padding(
                      padding: pw.EdgeInsets.symmetric(horizontal: template.config.layout.marginLeft),
                      child: pw.Text(
                        "PROPUESTA DE SERVICIOS", 
                        style: pw.TextStyle(
                          color: accentColor, 
                          fontSize: 10, 
                          letterSpacing: template.config.typography.letterSpacing, 
                          fontWeight: pw.FontWeight.bold
                        )
                      ),
                    ),
                    if (template.config.layout.showDividers)
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(horizontal: template.config.layout.marginLeft),
                        child: pw.Divider(color: _withOpacity(accentColor, 0.3), thickness: 0.5),
                      ),
                    pw.SizedBox(height: 10),
                    ...(data.sections ?? []).map((s) => _buildSection(s, template, surfaceColor: surfaceColor, accentColor: accentColor, textPrimary: textPrimary, textSecondary: textSecondary)),
                    pw.Spacer(),
                    _buildFooter(data, template, textPrimary: textPrimary, textSecondary: textSecondary),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Multi-page layout
      // Cover page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
          build: (pw.Context context) {
            return _buildCoverPage(data, template, agencyLogo: agencyLogo, clientLogo: clientLogo, bgColor: bgColor, accentColor: accentColor, textPrimary: textPrimary, textSecondary: textSecondary);
          },
        ),
      );

      // Section pages
      for (var section in (data.sections ?? [])) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(template.config.layout.marginTop),
            theme: pw.ThemeData.withFont(
              base: pw.Font.helvetica(),
              bold: pw.Font.helveticaBold(),
            ),
            build: (pw.Context context) {
              return pw.Container(
                color: bgColor,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _buildPageHeader(template, agencyLogo: agencyLogo, accentColor: accentColor, textPrimary: textPrimary),
                    pw.SizedBox(height: template.config.layout.sectionSpacing),
                    _buildSectionFull(section, template, surfaceColor: surfaceColor, accentColor: accentColor, textPrimary: textPrimary, textSecondary: textSecondary),
                    pw.Spacer(),
                    _buildPageFooter(data, template, textSecondary: textSecondary),
                  ],
                ),
              );
            },
          ),
        );
      }
    }

    return pdf.save();
  }

  static PdfColor _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('0xFF', '');
    return PdfColor.fromHex(hex);
  }

  static pw.Widget _buildHeader(ProposalData data, ProposalTemplate template, {Uint8List? agencyLogo, Uint8List? clientLogo, required PdfColor accentColor, required PdfColor textPrimary, required PdfColor textSecondary}) {
    return pw.Container(
      padding: pw.EdgeInsets.only(
        top: template.config.layout.marginTop, 
        left: template.config.layout.marginLeft, 
        right: template.config.layout.marginRight, 
        bottom: 40
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (template.config.layout.showAgencyLogo && agencyLogo != null)
                pw.SizedBox(
                  height: 40,
                  child: pw.Image(pw.MemoryImage(agencyLogo)),
                )
              else ...[
                pw.Text(
                  template.config.branding.agencyName, 
                  style: pw.TextStyle(
                    color: textPrimary, 
                    fontSize: 24, 
                    fontWeight: pw.FontWeight.bold, 
                    letterSpacing: 4
                  )
                ),
                pw.Text(
                  template.config.branding.agencyTagline, 
                  style: pw.TextStyle(
                    color: accentColor, 
                    fontSize: 8, 
                    letterSpacing: 2
                  )
                ),
              ],
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (template.config.layout.showClientLogo && clientLogo != null)
                 pw.Container(
                   height: 30,
                   margin: const pw.EdgeInsets.only(bottom: 10),
                   child: pw.Image(pw.MemoryImage(clientLogo)),
                 ),
              pw.Text('CLIENTE', style: pw.TextStyle(color: textSecondary, fontSize: 8, letterSpacing: 1.5)),
              pw.Text(data.header.clientName.toUpperCase(), style: pw.TextStyle(color: textPrimary, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text(data.header.date, style: pw.TextStyle(color: accentColor, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSection(ProposalSection section, ProposalTemplate template, {required PdfColor surfaceColor, required PdfColor accentColor, required PdfColor textPrimary, required PdfColor textSecondary}) {
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(horizontal: template.config.layout.marginLeft, vertical: 8),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: surfaceColor,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _withOpacity(accentColor, 0.1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(width: 3, height: 14, color: accentColor),
                    pw.SizedBox(width: 10),
                    pw.Text(section.title.toUpperCase(), style: pw.TextStyle(color: textPrimary, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ]
                ),
                pw.SizedBox(height: 10),
                pw.Text(section.content.headerInfo.join('\n'), style: pw.TextStyle(color: textSecondary, fontSize: 9)),
                pw.SizedBox(height: 12),
                ...section.content.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(color: accentColor, fontSize: 10)),
                      pw.Expanded(child: pw.Text(item, style: pw.TextStyle(color: textPrimary, fontSize: 9))),
                    ]
                  ),
                )),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('INVERSIÓN', style: pw.TextStyle(color: accentColor, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
               pw.Text(section.price.amount, style: pw.TextStyle(color: textPrimary, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              if (section.price.terms != null)
                pw.Text(section.price.terms!.toUpperCase(), style: pw.TextStyle(color: textSecondary, fontSize: 7)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(ProposalData data, ProposalTemplate template, {required PdfColor textPrimary, required PdfColor textSecondary}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(template.config.layout.marginBottom),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Contáctanos:', style: pw.TextStyle(color: textPrimary, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(template.config.branding.contactPhone, style: pw.TextStyle(color: textSecondary, fontSize: 10)),
              pw.Text(template.config.branding.contactEmail, style: pw.TextStyle(color: textSecondary, fontSize: 10)),
            ],
          ),
          if (template.config.branding.footerText.isNotEmpty)
            pw.Column(
               crossAxisAlignment: pw.CrossAxisAlignment.end,
               children: [
                  pw.Text('APROBADO POR', style: pw.TextStyle(color: textSecondary, fontSize: 8)),
                  pw.Text(template.config.branding.footerText.toUpperCase(), style: pw.TextStyle(color: textPrimary, fontSize: 12, fontWeight: pw.FontWeight.bold)),
               ]
            )
        ],
      ),
    );
  }

  // Multi-page specific builders
  static pw.Widget _buildCoverPage(ProposalData data, ProposalTemplate template, {Uint8List? agencyLogo, Uint8List? clientLogo, required PdfColor bgColor, required PdfColor accentColor, required PdfColor textPrimary, required PdfColor textSecondary}) {
    return pw.Container(
      color: bgColor,
      padding: pw.EdgeInsets.all(60),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          if (agencyLogo != null)
            pw.SizedBox(height: 50, child: pw.Image(pw.MemoryImage(agencyLogo)))
          else ...[
            pw.Text(template.config.branding.agencyName, style: pw.TextStyle(color: textPrimary, fontSize: 48, fontWeight: pw.FontWeight.bold)),
            pw.Text(template.config.branding.agencyTagline, style: pw.TextStyle(color: accentColor, fontSize: 14)),
          ],
          pw.SizedBox(height: 60),
          pw.Container(width: 80, height: 3, color: accentColor),
          pw.SizedBox(height: 30),
          pw.Text('PROPUESTA ESTRATÉGICA', style: pw.TextStyle(color: textSecondary, fontSize: 14, letterSpacing: 3)),
          pw.SizedBox(height: 10),
          pw.Text(data.header.clientName.toUpperCase(), style: pw.TextStyle(color: textPrimary, fontSize: 56, fontWeight: pw.FontWeight.bold)),
          pw.Spacer(),
          pw.Text(data.header.date, style: pw.TextStyle(color: accentColor, fontSize: 14)),
        ],
      ),
    );
  }

  static pw.Widget _buildPageHeader(ProposalTemplate template, {Uint8List? agencyLogo, required PdfColor accentColor, required PdfColor textPrimary}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(template.config.branding.agencyName, style: pw.TextStyle(color: accentColor, fontSize: 12, fontWeight: pw.FontWeight.bold)),
        if (agencyLogo != null) pw.SizedBox(height: 20, child: pw.Image(pw.MemoryImage(agencyLogo))),
      ],
    );
  }

  static pw.Widget _buildSectionFull(ProposalSection section, ProposalTemplate template, {required PdfColor surfaceColor, required PdfColor accentColor, required PdfColor textPrimary, required PdfColor textSecondary}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(section.title.toUpperCase(), style: pw.TextStyle(color: accentColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Divider(color: _withOpacity(accentColor, 0.3)),
        pw.SizedBox(height: 20),
        pw.Text(section.content.headerInfo.join('\n'), style: pw.TextStyle(color: textPrimary, fontSize: 14, height: 1.5)),
        pw.SizedBox(height: 20),
        ...section.content.items.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: accentColor, shape: pw.BoxShape.circle)),
              pw.SizedBox(width: 12),
              pw.Expanded(child: pw.Text(item, style: pw.TextStyle(color: textSecondary, fontSize: 12))),
            ],
          ),
        )),
        pw.SizedBox(height: 30),
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: surfaceColor,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('INVERSIÓN', style: pw.TextStyle(color: accentColor, fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(section.price.amount, style: pw.TextStyle(color: textPrimary, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  if (section.price.terms != null)
                    pw.Text(section.price.terms!.toUpperCase(), style: pw.TextStyle(color: textSecondary, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPageFooter(ProposalData data, ProposalTemplate template, {required PdfColor textSecondary}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(template.config.branding.website, style: pw.TextStyle(color: textSecondary, fontSize: 9)),
        pw.Text(data.header.date, style: pw.TextStyle(color: textSecondary, fontSize: 9)),
      ],
    );
  }
}
