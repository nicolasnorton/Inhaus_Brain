import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

  // INHAUS Color Palette (Exact Match)
  static const _bgDarkPurple = PdfColor.fromInt(0xFF1A0F2E); // Dark purple-black
  static const _sectionPurple = PdfColor.fromInt(0xFF6B46C1); // Purple headers
  static const _textWhite = PdfColors.white;
  static const _textGray = PdfColor.fromInt(0xFFA0AEC0); // Gray secondary

  /// Generate One Page Quote PDF
  static Future<Uint8List> generateOnePageQuote(
    InhausOnePageQuote quote, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    List<Uint8List>? additionalImages,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (context) {
          return pw.Container(
            color: _bgDarkPurple,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(quote.header, agencyLogo: agencyLogo, clientLogo: clientLogo),
                pw.SizedBox(height: 40),
                _buildOnePageContent(quote.summary),
                if (additionalImages != null && additionalImages.isNotEmpty) ...[
                  pw.SizedBox(height: 30),
                  _buildMoodboard(additionalImages),
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

    // First page with header and first sections
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (context) {
          return [
            pw.Container(
              color: _bgDarkPurple,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(proposal.header, agencyLogo: agencyLogo, clientLogo: clientLogo),
                  pw.SizedBox(height: 30),
                  ...proposal.sections.map((section) => _buildDetailedSection(section)),
                  if (additionalImages != null && additionalImages.isNotEmpty) ...[
                    pw.SizedBox(height: 40),
                    _buildMoodboard(additionalImages),
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
                    color: _textWhite,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
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
  static pw.Widget _buildOnePageContent(InhausQuoteSummary summary) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Intro
          pw.Text(
            summary.intro,
            style: pw.TextStyle(
              color: _textWhite,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          pw.SizedBox(height: 30),
          
          // Key Services
          pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: _withOpacity(_sectionPurple, 0.1),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: _withOpacity(_sectionPurple, 0.3)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SERVICIOS INCLUIDOS',
                  style: pw.TextStyle(
                    color: _sectionPurple,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 16),
                ...summary.keyServices.map((service) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 6,
                        height: 6,
                        decoration: const pw.BoxDecoration(
                          color: _sectionPurple,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Text(
                          service,
                          style: const pw.TextStyle(
                            color: _textWhite,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          
          // Total Price Box
          pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: _sectionPurple,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  summary.totalPrice.label,
                  style: pw.TextStyle(
                    color: _textWhite,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  summary.totalPrice.amount,
                  style: pw.TextStyle(
                    color: _textWhite,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          
          // CTA
          pw.Text(
            summary.cta,
            style: pw.TextStyle(
              color: _textGray,
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Detailed Section
  static pw.Widget _buildDetailedSection(InhausProposalSection section) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(left: 40, right: 40, bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Section Header (Purple Rounded Box)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: pw.BoxDecoration(
              color: _sectionPurple,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  section.title,
                  style: pw.TextStyle(
                    color: _textWhite,
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
                        color: _textWhite,
                        fontSize: 8,
                      ),
                    ),
                    pw.Text(
                      section.price.amount,
                      style: pw.TextStyle(
                        color: _textWhite,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
          pw.SizedBox(height: 12),
          
          // Description
          if (section.description != null && section.description!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 12),
              child: pw.Text(
                section.description!,
                style: const pw.TextStyle(
                  color: _textGray,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          
          // Bullets
          if (section.bullets.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: section.bullets.map((bullet) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '• ',
                        style: const pw.TextStyle(
                          color: _sectionPurple,
                          fontSize: 10,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          bullet,
                          style: const pw.TextStyle(
                            color: _textWhite,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          
          // Includes/Excludes
          if (section.includes != null || section.excludes != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, top: 12),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (section.includes != null)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'INCLUYE:',
                            style: pw.TextStyle(
                              color: _sectionPurple,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          ...section.includes!.map((item) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              '✓ $item',
                              style: const pw.TextStyle(
                                color: _textGray,
                                fontSize: 9,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  if (section.excludes != null)
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
                          ...section.excludes!.map((item) => pw.Padding(
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

  /// Build Moodboard Section
  static pw.Widget _buildMoodboard(List<Uint8List> images) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MOODBOARD & REFERENCIAS',
            style: pw.TextStyle(
              color: _sectionPurple,
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
