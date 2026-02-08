import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../models/inhaus_proposal_models.dart';

/// INHAUS-Style Slides Generator (Landscape Deck)
/// Mirrors INHAUS PDF content in presentation format
class InhausProposalSlidesGenerator {
  // Helper to create a PdfColor with opacity
  static PdfColor _withOpacity(PdfColor color, double opacity) {
    return PdfColor(color.red * opacity, color.green * opacity, color.blue * opacity, opacity);
  }

  // INHAUS Color Palette (Exact Match v2.0)
  static final _bgDark = PdfColor.fromInt(0xFF05050B);    // Dark/Black
  static final _cardDark = PdfColor.fromInt(0xFF0F0F16);  // Card elevation
  static final _accentPurple = PdfColor.fromInt(0xFF1A1423); // Rounded purple bars
  static const _textWhite = PdfColors.white;
  static const _textGray = PdfColor.fromInt(0xFFA0A0A0); // Light Gray

  /// Generate One Page Quote Slides
  static Future<Uint8List> generateOnePageQuote(
    InhausOnePageQuote quote, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    List<Uint8List>? additionalImages,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.montserratRegular();
    final fontBold = await PdfGoogleFonts.montserratBold();

    // Title Slide
    pdf.addPage(_buildTitleSlide(
      quote.header,
      agencyLogo: agencyLogo,
      clientLogo: clientLogo,
      bold: fontBold,
    ));

    // Summary Slide
    pdf.addPage(_buildSummarySlide(quote.summary, agencyLogo: agencyLogo, bold: fontBold));

    // Moodboard Slide
    if (additionalImages != null && additionalImages.isNotEmpty) {
      pdf.addPage(_buildMoodboardSlide(additionalImages, header: quote.header, agencyLogo: agencyLogo, clientLogo: clientLogo, bold: fontBold));
    }

    // Closing Slide
    pdf.addPage(_buildClosingSlide(quote.footer, agencyLogo: agencyLogo, bold: fontBold));

    return pdf.save();
  }

  /// Generate Detailed Proposal Slides
  static Future<Uint8List> generateDetailedProposal(
    InhausDetailedProposal proposal, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    List<Uint8List>? additionalImages,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.montserratRegular();
    final fontBold = await PdfGoogleFonts.montserratBold();

    // Title Slide
    pdf.addPage(_buildTitleSlide(
      proposal.header,
      agencyLogo: agencyLogo,
      clientLogo: clientLogo,
      bold: fontBold,
    ));

    // Section Slides
    for (var section in proposal.sections) {
      pdf.addPage(_buildSectionSlide(section, agencyLogo: agencyLogo, bold: fontBold));
    }

    // Moodboard Slide
    if (additionalImages != null && additionalImages.isNotEmpty) {
      pdf.addPage(_buildMoodboardSlide(additionalImages, header: proposal.header, agencyLogo: agencyLogo, clientLogo: clientLogo, bold: fontBold));
    }

    // Closing Slide
    pdf.addPage(_buildClosingSlide(proposal.footer, agencyLogo: agencyLogo, bold: fontBold));

    return pdf.save();
  }

  /// Build Title Slide
  static pw.Page _buildTitleSlide(
    InhausProposalHeader header, {
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    required pw.Font bold,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(0),
      build: (context) {
        return pw.Container(
          color: _bgDark,
          child: pw.Stack(
            children: [
              // Decorative circle
              pw.Positioned(
                right: -150,
                bottom: -150,
                child: pw.Container(
                  width: 500,
                  height: 500,
                  decoration: pw.BoxDecoration(
                    color: _withOpacity(_accentPurple, 0.05),
                    shape: pw.BoxShape.circle,
                  ),
                ),
              ),
              // Content
              pw.Padding(
                padding: const pw.EdgeInsets.all(60),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    // Agency Logo/Title
                    if (agencyLogo != null)
                      pw.SizedBox(
                        height: 50,
                        child: pw.Image(pw.MemoryImage(agencyLogo)),
                      )
                    else
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            header.agencyTitle,
                            style: pw.TextStyle(
                              color: _textWhite,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    pw.SizedBox(height: 60),
                    
                    // Divider
                    pw.Container(
                      width: 80,
                      height: 3,
                      color: _accentPurple,
                    ),
                    pw.SizedBox(height: 30),
                    
                    // Subtitle
                    pw.Text(
                      'PROPUESTA ESTRATÉGICA',
                      style: pw.TextStyle(
                        color: _textGray,
                        fontSize: 14,
                        letterSpacing: 3,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    
                    // Client Name
                    pw.Text(
                      header.clientName.toUpperCase(),
                      style: pw.TextStyle(
                        color: _textWhite,
                        fontSize: 48,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    
                    pw.Spacer(),
                    
                    // Footer info
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          header.date,
                          style: pw.TextStyle(
                            color: _accentPurple,
                            fontSize: 12,
                          ),
                        ),
                        if (clientLogo != null)
                          pw.SizedBox(
                            height: 40,
                            child: pw.Image(pw.MemoryImage(clientLogo)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build Summary Slide (for One Page Quote)
  static pw.Page _buildSummarySlide(
    InhausQuoteSummary summary, {
    Uint8List? agencyLogo,
    required pw.Font bold,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(0),
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
      build: (context) {
        return pw.Container(
          color: _bgDark,
          padding: const pw.EdgeInsets.all(60),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RESUMEN',
                        style: pw.TextStyle(
                          color: _accentPurple,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'SERVICIOS PROPUESTOS',
                        style: pw.TextStyle(
                          color: _textWhite,
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (agencyLogo != null)
                    pw.SizedBox(
                      height: 35,
                      child: pw.Image(pw.MemoryImage(agencyLogo)),
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: _withOpacity(_accentPurple, 0.3), thickness: 1),
              pw.SizedBox(height: 30),
              
              // Intro
              pw.Text(
                summary.intro,
                style: pw.TextStyle(
                  color: _textWhite,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Key Services
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: summary.keyServices.map((service) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 16),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: 8,
                                height: 8,
                                decoration: pw.BoxDecoration(
                                  color: _accentPurple,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.SizedBox(width: 16),
                              pw.Expanded(
                                child: pw.Text(
                                  service,
                                  style: const pw.TextStyle(
                                    color: _textWhite,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    pw.SizedBox(width: 40),
                    
                    // Price Box
                    pw.Container(
                      width: 280,
                      padding: const pw.EdgeInsets.all(32),
                      decoration: pw.BoxDecoration(
                        color: _accentPurple,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            summary.totalPrice.label,
                            style: pw.TextStyle(
                              color: _textWhite,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 16),
                          pw.Text(
                            summary.totalPrice.amount,
                            style: pw.TextStyle(
                              color: _textWhite,
                              fontSize: 36,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 20),
                          pw.Text(
                            summary.cta,
                            style: pw.TextStyle(
                              color: _withOpacity(_textWhite, 0.9),
                              fontSize: 11,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build Section Slide (for Detailed Proposal)
  static pw.Page _buildSectionSlide(
    InhausProposalSection section, {
    Uint8List? agencyLogo,
    required pw.Font bold,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(0),
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
      build: (context) {
        return pw.Container(
          color: _bgDark,
          padding: const pw.EdgeInsets.all(60),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SERVICIO',
                          style: pw.TextStyle(
                            color: _accentPurple,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          section.title.toUpperCase(),
                          style: pw.TextStyle(
                            color: _textWhite,
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (agencyLogo != null)
                    pw.SizedBox(
                      height: 30,
                      child: pw.Image(pw.MemoryImage(agencyLogo)),
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: _withOpacity(_accentPurple, 0.3), thickness: 1),
              pw.SizedBox(height: 30),
              
              // Content
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left: Description & Bullets
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (section.description != null && section.description!.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 24),
                              child: pw.Text(
                                section.description!,
                                style: pw.TextStyle(
                                  color: _withOpacity(_textWhite, 0.9),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          
                          // Bullets
                          ...section.bullets.take(6).map((bullet) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 12),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: 6,
                                  height: 6,
                                  margin: const pw.EdgeInsets.only(top: 6),
                                  decoration: pw.BoxDecoration(
                                    color: _accentPurple,
                                    shape: pw.BoxShape.circle,
                                  ),
                                ),
                                pw.SizedBox(width: 12),
                                pw.Expanded(
                                  child: pw.Text(
                                    bullet,
                                    style: const pw.TextStyle(
                                      color: _textGray,
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
                    pw.SizedBox(width: 40),
                    
                    // Right: Price Box
                    pw.Container(
                      width: 240,
                      padding: const pw.EdgeInsets.all(32),
                      decoration: pw.BoxDecoration(
                        color: _withOpacity(_accentPurple, 0.1),
                        border: pw.Border.all(color: _withOpacity(_accentPurple, 0.3)),
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            section.price.label,
                            style: pw.TextStyle(
                              color: _accentPurple,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          pw.SizedBox(height: 16),
                          pw.Text(
                            section.price.amount,
                            style: pw.TextStyle(
                              color: _textWhite,
                              fontSize: 32,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          
                          // Includes/Excludes (if space allows)
                          if (section.includes != null && section.includes!.isNotEmpty) ...[
                            pw.SizedBox(height: 20),
                            pw.Text(
                              'INCLUYE:',
                              style: pw.TextStyle(
                                color: _accentPurple,
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            ...section.includes!.take(3).map((item) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Text(
                                '✓ $item',
                                style: const pw.TextStyle(
                                  color: _textGray,
                                  fontSize: 8,
                                ),
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build Closing Slide
  static pw.Page _buildClosingSlide(
    String footer, {
    Uint8List? agencyLogo,
    required pw.Font bold,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(0),
      build: (context) {
        return pw.Container(
          color: _bgDark,
          padding: const pw.EdgeInsets.all(60),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              if (agencyLogo != null)
                pw.SizedBox(
                  height: 60,
                  child: pw.Image(pw.MemoryImage(agencyLogo)),
                ),
              pw.SizedBox(height: 40),
              pw.Text(
                '¡GRACIAS!',
                style: pw.TextStyle(
                  color: _textWhite,
                  fontSize: 48,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Estamos listos para comenzar',
                style: const pw.TextStyle(
                  color: _textGray,
                  fontSize: 18,
                ),
              ),
              pw.SizedBox(height: 60),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _withOpacity(_accentPurple, 0.3)),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      footer,
                      style: pw.TextStyle(
                        color: _accentPurple,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'info@inhauscorp.com | (+593) 98 656 6084',
                      style: const pw.TextStyle(
                        color: _textGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Add Moodboard Slide
  static pw.Page _buildMoodboardSlide(
    List<Uint8List> images, {
    required InhausProposalHeader header,
    Uint8List? agencyLogo,
    Uint8List? clientLogo,
    required pw.Font bold,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(0),
      build: (context) {
        return pw.Container(
          color: _bgDark,
          child: pw.Column(
            children: [
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(60),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MOODBOARD & REFERENCIAS',
                        style: pw.TextStyle(
                          color: _accentPurple,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Expanded(
                        child: pw.GridView(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          children: images.take(4).map((img) => pw.ClipRRect(
                            horizontalRadius: 12,
                            verticalRadius: 12,
                            child: pw.Image(pw.MemoryImage(img), fit: pw.BoxFit.cover),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      // Ignore error
    }
    return null;
  }
}
