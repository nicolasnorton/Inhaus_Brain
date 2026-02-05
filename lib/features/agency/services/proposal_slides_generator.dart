
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inhaus_brain/features/agency/services/proposal_pdf_generator.dart';

class ProposalSlidesGenerator {
  
  static const PdfColor _darkBackground = PdfColor.fromInt(0xFF0F0E17); // Deep Black/Purple
  static const PdfColor _accentPink = PdfColor.fromInt(0xFFD6335C);
  static const PdfColor _textWhite = PdfColors.white;
  static const PdfColor _textGrey = PdfColor.fromInt(0xFFAAAAAA);

  static Future<Uint8List> generate(ProposalData data, {Uint8List? agencyLogo}) async {
    final pdf = pw.Document();

    // 1. Title Slide
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            color: _darkBackground,
            child: pw.Stack(
              children: [
                pw.Positioned(
                  right: -100,
                  top: -100,
                  child: pw.Container(
                    width: 400,
                    height: 400,
                    decoration: pw.BoxDecoration(
                      color: PdfColor(_accentPink.red, _accentPink.green, _accentPink.blue, 0.1),

                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(60),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (agencyLogo != null)
                        pw.SizedBox(height: 60, child: pw.Image(pw.MemoryImage(agencyLogo)))
                      else
                        pw.Text('INHAUS', style: pw.TextStyle(color: _textWhite, fontSize: 48, fontWeight: pw.FontWeight.bold, letterSpacing: 5)),
                      pw.SizedBox(height: 40),
                      pw.Container(width: 80, height: 4, color: _accentPink),
                      pw.SizedBox(height: 20),
                      pw.Text('PROPUESTA ESTRATÉGICA', style: pw.TextStyle(color: _textGrey, fontSize: 14, letterSpacing: 2)),
                      pw.Text(data.clientName.toUpperCase(), style: pw.TextStyle(color: _textWhite, fontSize: 64, fontWeight: pw.FontWeight.bold)),
                      pw.Spacer(),
                      pw.Text(data.date, style: const pw.TextStyle(color: _textGrey, fontSize: 12)),
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
          build: (pw.Context context) {
            return pw.Container(
              color: _darkBackground,
              padding: const pw.EdgeInsets.all(60),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Row(
                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                     children: [
                        pw.Text(section.title.toUpperCase(), style: pw.TextStyle(color: _accentPink, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        if (agencyLogo != null) pw.SizedBox(height: 20, child: pw.Image(pw.MemoryImage(agencyLogo))),
                     ]
                   ),
                   pw.SizedBox(height: 10),
                   pw.Container(width: double.infinity, height: 1, color: const PdfColor(1, 1, 1, 0.1)),


                   pw.SizedBox(height: 40),
                   pw.Expanded(
                     child: pw.Row(
                       children: [
                         pw.Expanded(
                           flex: 2,
                           child: pw.Column(
                             crossAxisAlignment: pw.CrossAxisAlignment.start,
                             children: [
                               pw.Text(section.description, style: pw.TextStyle(color: _textWhite, fontSize: 18)),

                               pw.SizedBox(height: 30),
                               ...section.items.map((item) => pw.Padding(
                                 padding: const pw.EdgeInsets.only(bottom: 10),
                                 child: pw.Row(
                                   children: [
                                      pw.Container(width: 8, height: 8, decoration: const pw.BoxDecoration(color: _accentPink, shape: pw.BoxShape.circle)),
                                      pw.SizedBox(width: 12),
                                      pw.Text(item, style: const pw.TextStyle(color: _textGrey, fontSize: 14)),
                                   ]
                                 )
                               )),
                             ],
                           ),
                         ),
                         pw.SizedBox(width: 40),
                         pw.Container(
                           width: 200,
                           padding: const pw.EdgeInsets.all(30),
                           decoration: pw.BoxDecoration(
                             color: PdfColor(_accentPink.red, _accentPink.green, _accentPink.blue, 0.05),
                             border: pw.Border.all(color: PdfColor(_accentPink.red, _accentPink.green, _accentPink.blue, 0.2)),

                             borderRadius: pw.BorderRadius.circular(20),
                           ),
                           child: pw.Column(
                             mainAxisAlignment: pw.MainAxisAlignment.center,
                             children: [
                               pw.Text('INVERSIÓN', style: pw.TextStyle(color: _textGrey, fontSize: 10, letterSpacing: 2)),
                               pw.SizedBox(height: 10),
                               pw.Text(section.price, style: pw.TextStyle(color: _textWhite, fontSize: 32, fontWeight: pw.FontWeight.bold)),
                               pw.Text(section.frequency, style: pw.TextStyle(color: _accentPink, fontSize: 10, fontWeight: pw.FontWeight.bold)),
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
