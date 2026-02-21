import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../models/inhaus_proposal_models.dart';
import '../models/proposal_style.dart';

/// INHAUS-Style PDF Generator
/// Exact replication of INHAUS proposal visual style
class InhausProposalPdfGenerator {
  // Helper to create a PdfColor with opacity
  static PdfColor _withOpacity(PdfColor color, double opacity) {
    return PdfColor(color.red * opacity, color.green * opacity, color.blue * opacity, opacity);
  }

  final ProposalStyle style;
  late final PdfColor _bgDark = PdfColor.fromHex(style.fondoHex);
  late final PdfColor _cardDark = PdfColor.fromHex(style.tarjetasHex);
  late final PdfColor _accentColor = PdfColor.fromHex(style.acentoHex);
  late final PdfColor _textWhite = PdfColor.fromHex(style.textoPrincipalHex);
  late final PdfColor _textGray = PdfColor.fromHex(style.textoSecundarioHex);
  late final PdfColor _textSutil = PdfColor.fromHex(style.textoSutilHex);
  late final PdfColor _border = PdfColor.fromHex(style.bordesHex);

  InhausProposalPdfGenerator({ProposalStyle? style}) 
      : style = style ?? ProposalStyle.inhausClasico;

  static Uint8List? _cachedInhausLogo;

  static Future<Uint8List?> _getInhausLogo() async {
    if (_cachedInhausLogo != null) return _cachedInhausLogo;
    try {
      final ByteData data = await rootBundle.load('assets/images/inhaus_logo_white.png');
      _cachedInhausLogo = data.buffer.asUint8List();
    } catch (e) {
      // fallback
    }
    return _cachedInhausLogo;
  }

  /// Generate One Page Quote PDF
  static Future<Uint8List> generateOnePageQuote(
    InhausOnePageQuote quote, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    List<Uint8List>? additionalImages,
    ProposalStyle? style,
  }) async {
    return InhausProposalPdfGenerator(style: style)._generateOnePageQuote(
      quote,
      agencyLogo: agencyLogo,
      clientLogo: clientLogo,
      additionalImages: additionalImages,
    );
  }

  Future<Uint8List> _generateOnePageQuote(
    InhausOnePageQuote quote, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    List<Uint8List>? additionalImages,
  }) async {
    agencyLogo ??= await _getInhausLogo();
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.montserratRegular();
    final fontBold = await PdfGoogleFonts.montserratBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
build: (context) {
          return pw.Container(
            color: _bgDark,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(quote.header, agencyLogo: agencyLogo, clientLogo: clientLogo, bold: fontBold),
                pw.SizedBox(height: 40),
                _buildOnePageContent(quote.summary, bold: fontBold),
                if (additionalImages != null && additionalImages.isNotEmpty) ...[
                  pw.SizedBox(height: 30),
                  _buildMoodboard(additionalImages, bold: fontBold),
                ],
                pw.Spacer(),
                _buildFooter(quote.footer),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate Detailed Multi-Page PDF
  static Future<Uint8List> generateDetailedProposal(
    InhausDetailedProposal proposal, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    List<Uint8List>? additionalImages,
    ProposalStyle? style,
  }) async {
    return InhausProposalPdfGenerator(style: style)._generateDetailedProposal(
      proposal,
      agencyLogo: agencyLogo,
      clientLogo: clientLogo,
      additionalImages: additionalImages,
    );
  }

  Future<Uint8List> _generateDetailedProposal(
    InhausDetailedProposal proposal, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    List<Uint8List>? additionalImages,
  }) async {
    agencyLogo ??= await _getInhausLogo();
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.montserratRegular();
    final fontBold = await PdfGoogleFonts.montserratBold();

    // First page with header and first sections
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (context) {
          return [
            pw.Container(
              color: _bgDark,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(proposal.header, agencyLogo: agencyLogo, clientLogo: clientLogo, bold: fontBold),
                  pw.SizedBox(height: 30),
                  ...proposal.sections.map((section) => _buildDetailedSection(section, bold: fontBold)),
                  if (additionalImages != null && additionalImages.isNotEmpty) ...[
                    pw.SizedBox(height: 40),
                    _buildMoodboard(additionalImages, bold: fontBold),
                  ],
                ],
              ),
            ),
          ];
        },
        footer: (context) => _buildFooter(proposal.footer),
      ),
    );

    return pdf.save();
  }

  /// Build Header (Common for both types)
  pw.Widget _buildHeader(
    InhausProposalHeader header, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    required pw.Font bold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 40, right: 40, top: 40, bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Top: Agency branding
          if (agencyLogo != null)
            pw.SizedBox(
              height: 48,
              child: pw.Image(pw.MemoryImage(agencyLogo)),
            )
          else
            pw.Text(
              header.agencyTitle,
              style: pw.TextStyle(
                color: _textWhite,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 4.0,
              ),
            ),
          pw.SizedBox(height: 40),
          // Info Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CLIENTE:',
                    style: pw.TextStyle(
                      color: _textGray,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    header.clientName,
                    style: pw.TextStyle(
                      color: _textWhite,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(left: pw.BorderSide(color: _accentColor, width: 2)),
                ),
                padding: const pw.EdgeInsets.only(left: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FECHA:',
                      style: pw.TextStyle(
                        color: _textGray,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      header.date,
                      style: pw.TextStyle(
                        color: _textWhite,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build One Page Quote Content
  pw.Widget _buildOnePageContent(InhausQuoteSummary summary, {required pw.Font bold}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Intro Paragraph
          if (summary.introParagraph.isNotEmpty) ...[
            pw.Text(
              summary.introParagraph,
              style: pw.TextStyle(
                color: _textWhite,  // WHITE text for visibility
                fontSize: 11,
                height: 1.5,
              ),
            ),
            pw.SizedBox(height: 24),
          ],
          
          // Pricing Breakdown / Packages
          if (summary.lineItems.isNotEmpty) ...[
            ...summary.lineItems.map((item) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: _cardDark,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          item.serviceName.toUpperCase(),
                          style: pw.TextStyle(
                            color: _textWhite,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          if (item.paymentType != null)
                            pw.Text(
                              item.paymentType!,
                              style: pw.TextStyle(color: _textGray, fontSize: 8),
                            ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            item.price,
                            style: pw.TextStyle(
                              color: _accentColor,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (summary.applyIva)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                '*no incluye IVA',
                                style: pw.TextStyle(
                                  color: _withOpacity(_textGray, 0.7),
                                  fontSize: 8,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                            )
                        ],
                      ),
                    ],
                  ),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    pw.SizedBox(height: 12),
                    pw.Text(
                      item.description!,
                      style: pw.TextStyle(
                        color: _textWhite,
                        fontSize: 9,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            )),
            
            // Subtotal / Descuento rows
            if (summary.subtotal != null || summary.descuento != null || summary.ivaAmount != null)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: pw.Column(
                  children: [
                    if (summary.subtotal != null && summary.descuento != null)
                      _buildPricingRow('Subtotal', summary.subtotal!, bold: bold),
                    if (summary.descuento != null)
                      _buildPricingRow(
                        'Descuento${summary.descuentoPct != null ? ' (${summary.descuentoPct!.toStringAsFixed(0)}%)' : ''}',
                        '-${summary.descuento!}',
                        bold: bold, color: _accentColor
                      ),
                    if (summary.ivaAmount != null)
                      _buildPricingRow('IVA (15%)', summary.ivaAmount!, bold: bold),
                  ],
                ),
              ),

            // TOTAL row
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: pw.BoxDecoration(
                color: _cardDark,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      color: _accentColor,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    summary.precio.amount,
                    style: pw.TextStyle(
                      color: _accentColor,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // CTA (if present)
          if (summary.cta.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              summary.cta,
              style: pw.TextStyle(
                color: _textGray,
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build Detailed Section
  pw.Widget _buildDetailedSection(InhausProposalSection section, {required pw.Font bold}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(left: 40, right: 40, bottom: 30),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Section Header (Purple Rounded Box)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: pw.BoxDecoration(
              color: _accentColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  section.title,
                  style: pw.TextStyle(
                    color: _textWhite,  // WHITE text
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                // Price on header
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      section.price.label,
                      style: pw.TextStyle(
                        color: _textWhite,  // WHITE text
                        fontSize: 8,
                      ),
                    ),
                    pw.Text(
                      section.price.amount,
                      style: pw.TextStyle(
                        color: _textWhite,  // WHITE text
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          
          // Intro Paragraph
          if (section.introParagraph != null && section.introParagraph!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 16),
              child: pw.Text(
                section.introParagraph!,
                style: pw.TextStyle(
                  color: _textWhite,  // WHITE text for visibility
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          
          // EJECUCIÓN Section
          if (section.ejecucion != null && section.ejecucion!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EJECUCIÓN:',
                    style: pw.TextStyle(
                      color: _accentColor,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    section.ejecucion!,
                    style: pw.TextStyle(
                      color: _textWhite,  // WHITE text
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          
          // INCLUYE / NO INCLUYE (side by side)
          if ((section.incluye != null && section.incluye!.isNotEmpty) || 
              (section.noIncluye != null && section.noIncluye!.isNotEmpty))
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 16),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (section.incluye != null && section.incluye!.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'INCLUYE:',
                            style: pw.TextStyle(
                              color: _accentColor,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          ...section.incluye!.map((item) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              '✓ $item',
                              style: pw.TextStyle(
                                color: _textWhite,  // WHITE text
                                fontSize: 9,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  if (section.noIncluye != null && section.noIncluye!.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'NO INCLUYE:',
                            style: pw.TextStyle(
                              color: _textGray,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          ...section.noIncluye!.map((item) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              '✗ $item',
                              style: pw.TextStyle(
                                color: _textGray,
                                fontSize: 9,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          
          // EQUIPO Section
          if (section.equipo != null && section.equipo!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EQUIPO:',
                    style: pw.TextStyle(
                      color: _accentColor,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...section.equipo!.map((member) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '• $member',
                      style: pw.TextStyle(
                        color: _textWhite,  // WHITE text
                        fontSize: 9,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          
          // ENTREGABLES Section
          if (section.entregables != null && section.entregables!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ENTREGABLES:',
                    style: pw.TextStyle(
                      color: _accentColor,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...section.entregables!.map((deliverable) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '• $deliverable',
                      style: pw.TextStyle(
                        color: _textWhite,  // WHITE text
                        fontSize: 9,
                      ),
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build Footer
  pw.Widget _buildFooter(String footer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            footer,
            style: pw.TextStyle(
              color: _textGray,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Section Header (for one-page quote sections)
  pw.Widget _buildSectionHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _accentColor,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Build Bullet Item (for lists)
  pw.Widget _buildBulletItem(String text, {bool? isIncluded}) {
    final icon = isIncluded == null ? '•' : (isIncluded ? '✓' : '✗');
    final color = isIncluded == false ? _textGray : _textWhite;
    
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$icon ',
            style: pw.TextStyle(
              color: color,
              fontSize: 10,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                color: color,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a pricing summary row (Subtotal, Descuento, IVA)
  pw.Widget _buildPricingRow(String label, String value, {required pw.Font bold, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(color: _textGray, fontSize: 10),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(color: color ?? _textWhite, fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Build Moodboard Section
  pw.Widget _buildMoodboard(List<Uint8List> images, {required pw.Font bold}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MOODBOARD & REFERENCIAS',
            style: pw.TextStyle(
              color: _accentColor,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: images.take(4).map((img) => pw.ClipRRect(
              horizontalRadius: 8,
              verticalRadius: 8,
              child: pw.Image(pw.MemoryImage(img), fit: pw.BoxFit.cover),
            )).toList(),
          ),
        ],
      ),
    );
  }

  /// Helper to fetch image from URL
  static Future<Uint8List?> fetchImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      // Ignore error, fallback to null
    }
    return null;
  }
}
