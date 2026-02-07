import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../models/inhaus_proposal_models.dart';

/// INHAUS-Style PDF Generator
/// Exact replication of INHAUS proposal visual style
class InhausProposalPdfGenerator {
  // Helper to create a PdfColor with opacity
  static PdfColor _withOpacity(PdfColor color, double opacity) {
    return PdfColor(color.red * opacity, color.green * opacity, color.blue * opacity, opacity);
  }

  // INHAUS Color Palette (Vibrant v2.0)
  static final _bgDark = PdfColor.fromInt(0xFF05050B);    // Dark/Black
  static final _cardDark = PdfColor.fromInt(0xFF0F0F16);  // Card elevation
  static final _accentPurple = PdfColor.fromInt(0xFF6E48AA); // Vibrant Purple for accents
  static final _deepPurple = PdfColor.fromInt(0xFF1A1423);   // Deep purple for backgrounds
  static const _textWhite = PdfColors.white;
  static const _textGray = PdfColor.fromInt(0xFFA0A0A0); // Light Gray

  /// Generate One Page Quote PDF
  static Future<Uint8List> generateOnePageQuote(
    InhausOnePageQuote quote, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    List<Uint8List>? additionalImages,
  }) async {
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
  }) async {
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
  static pw.Widget _buildHeader(
    InhausProposalHeader header, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    required pw.Font bold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Agency branding
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (agencyLogo != null)
                pw.SizedBox(
                  height: 35,
                  child: pw.Image(pw.MemoryImage(agencyLogo)),
                )
              else
                pw.Text(
                  header.agencyTitle,
                  style: pw.TextStyle(
                    color: _accentPurple,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ),
          // Right: Client info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (clientLogo != null)
                pw.Container(
                  height: 30,
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Image(pw.MemoryImage(clientLogo)),
                ),
              pw.Text(
                header.clientName.toUpperCase(),
                style: pw.TextStyle(
                  color: _textWhite,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                header.date,
                style: const pw.TextStyle(
                  color: _textGray,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build One Page Quote Content
  static pw.Widget _buildOnePageContent(InhausQuoteSummary summary, {required pw.Font bold}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Title Header
          pw.Text(
            'ONE-PAGE SUMMARY',
            style: pw.TextStyle(
              color: _accentPurple,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Intro Paragraph
          pw.Text(
            summary.introParagraph,
            style: pw.TextStyle(
              color: _textWhite,  // WHITE text for visibility
              fontSize: 13,
              height: 1.5,
            ),
          ),
          pw.SizedBox(height: 24),
          
          // EJECUCIÓN Section
          if (summary.ejecucion != null && summary.ejecucion!.isNotEmpty) ...[
            _buildSectionHeader('EJECUCIÓN'),
            pw.SizedBox(height: 8),
            pw.Text(
              summary.ejecucion!,
              style: const pw.TextStyle(
                color: _textWhite,  // WHITE text
                fontSize: 11,
                height: 1.4,
              ),
            ),
            pw.SizedBox(height: 20),
          ],
          
          // INCLUYE Section
          if (summary.incluye.isNotEmpty) ...[
            _buildSectionHeader('INCLUYE'),
            pw.SizedBox(height: 8),
            ...summary.incluye.map((item) => _buildBulletItem(item, isIncluded: true)),
            pw.SizedBox(height: 16),
          ],
          
          // NO INCLUYE Section
          if (summary.noIncluye.isNotEmpty) ...[
            _buildSectionHeader('NO INCLUYE'),
            pw.SizedBox(height: 8),
            ...summary.noIncluye.map((item) => _buildBulletItem(item, isIncluded: false)),
            pw.SizedBox(height: 16),
          ],
          
          // EQUIPO Section
          if (summary.equipo.isNotEmpty) ...[
            _buildSectionHeader('EQUIPO'),
            pw.SizedBox(height: 8),
            ...summary.equipo.map((member) => _buildBulletItem(member)),
            pw.SizedBox(height: 16),
          ],
          
          // ENTREGABLES Section
          if (summary.entregables.isNotEmpty) ...[
            _buildSectionHeader('ENTREGABLES'),
            pw.SizedBox(height: 8),
            ...summary.entregables.map((deliverable) => _buildBulletItem(deliverable)),
            pw.SizedBox(height: 20),
          ],
          
          // Total Price Box
          pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: _accentPurple,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  summary.precio.label,
                  style: pw.TextStyle(
                    color: _textWhite,  // WHITE text
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  summary.precio.amount,
                  style: pw.TextStyle(
                    color: _textWhite,  // WHITE text
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // CTA (if present)
          if (summary.cta.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              summary.cta,
              style: pw.TextStyle(
                color: _textGray,
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build Detailed Section
  static pw.Widget _buildDetailedSection(InhausProposalSection section, {required pw.Font bold}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(left: 40, right: 40, bottom: 30),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Section Header (Purple Rounded Box)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: pw.BoxDecoration(
              color: _accentPurple,
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
                      style: const pw.TextStyle(
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
                style: const pw.TextStyle(
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
                      color: _accentPurple,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    section.ejecucion!,
                    style: const pw.TextStyle(
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
                              color: _accentPurple,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          ...section.incluye!.map((item) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              '✓ $item',
                              style: const pw.TextStyle(
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
                              style: const pw.TextStyle(
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
                      color: _accentPurple,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...section.equipo!.map((member) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '• $member',
                      style: const pw.TextStyle(
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
                      color: _accentPurple,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...section.entregables!.map((deliverable) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '• $deliverable',
                      style: const pw.TextStyle(
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
  static pw.Widget _buildFooter(String footer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            footer,
            style: const pw.TextStyle(
              color: _textGray,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Section Header (for one-page quote sections)
  static pw.Widget _buildSectionHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _accentPurple,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Build Bullet Item (for lists)
  static pw.Widget _buildBulletItem(String text, {bool? isIncluded}) {
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

  /// Build Moodboard Section
  static pw.Widget _buildMoodboard(List<Uint8List> images, {required pw.Font bold}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MOODBOARD & REFERENCIAS',
            style: pw.TextStyle(
              color: _accentPurple,
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
