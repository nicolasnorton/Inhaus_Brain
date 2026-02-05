
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inhaus_brain/features/agency/services/proposal_pdf_generator.dart';

class ProposalSlidesGenerator {
  
  /// Helper to create a PdfColor with opacity
  static PdfColor _withOpacity(PdfColor color, double opacity) {
    return PdfColor(color.red, color.green, color.blue, opacity);
  }
  
  static const PdfColor _darkBackground = PdfColor.fromInt(0xFF0F0F12); // Near Black
  static const PdfColor _accentGold = PdfColor.fromInt(0xFFE5B15D); // Premium Gold
  static const PdfColor _textWhite = PdfColors.white;
  static const PdfColor _textGrey = PdfColor.fromInt(0xFF94A3B8); // Slate-ish grey

  static Future<Uint8List> generate(ProposalData data, {Uint8List? agencyLogo}) async {
    final pdf = pw.Document();

    // 1. Title Slide
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Container(
            color: _darkBackground,
            child: pw.Stack(
              children: [
                pw.Positioned(
                  right: -100,
                  bottom: -100,
                  child: pw.Container(
                    width: 400,
                    height: 400,
                    decoration: pw.BoxDecoration(
                      color: _withOpacity(_accentGold, 0.05),
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(80),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (agencyLogo != null)
                        pw.SizedBox(height: 50, child: pw.Image(pw.MemoryImage(agencyLogo)))
                      else ...[
                        pw.Text('INHAUS', style: pw.TextStyle(color: _textWhite, fontSize: 32, fontWeight: pw.FontWeight.bold, letterSpacing: 8)),
                        pw.Text('BRAIN - CORE SYSTEMS', style: pw.TextStyle(color: _accentGold, fontSize: 10, letterSpacing: 3)),
                      ],
                      pw.SizedBox(height: 60),
                      pw.Container(width: 60, height: 2, color: _accentGold),
                      pw.SizedBox(height: 30),
                      pw.Text('PROPUESTA ESTRATÉGICA', style: pw.TextStyle(color: _textGrey, fontSize: 12, letterSpacing: 4)),
                      pw.SizedBox(height: 10),
                      pw.Text(data.clientName.toUpperCase(), style: pw.TextStyle(color: _textWhite, fontSize: 56, fontWeight: pw.FontWeight.bold)),
                      pw.Spacer(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(data.date, style: pw.TextStyle(color: _accentGold, fontSize: 12)),
                          pw.Text('CONFIDENCIAL', style: pw.TextStyle(color: _withOpacity(_textGrey, 0.5), fontSize: 10, letterSpacing: 2)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 2. Section Slides
    for (var section in data.sections) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Container(
              color: _darkBackground,
              padding: const pw.EdgeInsets.all(60),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Row(
                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                     crossAxisAlignment: pw.CrossAxisAlignment.end,
                     children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('SOLUCIÓN', style: pw.TextStyle(color: _accentGold, fontSize: 10, letterSpacing: 2, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 5),
                            pw.Text(section.title.toUpperCase(), style: pw.TextStyle(color: _textWhite, fontSize: 32, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        if (agencyLogo != null) pw.SizedBox(height: 30, child: pw.Image(pw.MemoryImage(agencyLogo))),
                     ]
                   ),
                   pw.SizedBox(height: 20),
                   pw.Divider(color: _withOpacity(_accentGold, 0.2), thickness: 0.5),
                   pw.SizedBox(height: 40),
                   pw.Expanded(
                     child: pw.Row(
                       crossAxisAlignment: pw.CrossAxisAlignment.start,
                       children: [
                         pw.Expanded(
                           flex: 2,
                           child: pw.Column(
                             crossAxisAlignment: pw.CrossAxisAlignment.start,
                             children: [
                               pw.Text(section.description, style: pw.TextStyle(color: _withOpacity(_textWhite, 0.9), fontSize: 16, height: 1.4)),
                               pw.SizedBox(height: 40),
                               ...section.items.map((item) => pw.Padding(
                                 padding: const pw.EdgeInsets.only(bottom: 15),
                                 child: pw.Row(
                                   children: [
                                      pw.Container(width: 6, height: 6, decoration: const pw.BoxDecoration(color: _accentGold, shape: pw.BoxShape.circle)),
                                      pw.SizedBox(width: 15),
                                      pw.Expanded(child: pw.Text(item, style: pw.TextStyle(color: _textGrey, fontSize: 14))),
                                   ]
                                 )
                               )),
                             ],
                           ),
                         ),
                         pw.SizedBox(width: 60),
                         pw.Container(
                           width: 240,
                           padding: const pw.EdgeInsets.all(40),
                           decoration: pw.BoxDecoration(
                             color: _withOpacity(_accentGold, 0.03),
                             border: pw.Border.all(color: _withOpacity(_accentGold, 0.1)),
                             borderRadius: pw.BorderRadius.circular(10),
                           ),
                           child: pw.Column(
                             mainAxisSize: pw.MainAxisSize.min,
                             crossAxisAlignment: pw.CrossAxisAlignment.start,
                             children: [
                               pw.Text('INVERSIÓN', style: pw.TextStyle(color: _accentGold, fontSize: 10, letterSpacing: 2)),
                               pw.SizedBox(height: 20),
                               pw.Text(section.price, style: pw.TextStyle(color: _textWhite, fontSize: 32, fontWeight: pw.FontWeight.bold)),
                               pw.SizedBox(height: 5),
                               pw.Text(section.frequency.toUpperCase(), style: pw.TextStyle(color: _textGrey, fontSize: 9, letterSpacing: 1)),
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
        ),
      );
    }

    return pdf.save();
  }
}
