
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inhaus_brain/features/agency/models/proposal_model.dart';

class ProposalPdfGenerator {
  
  static const PdfColor _darkBackground = PdfColor.fromInt(0xFF1E1B2E); // Dark Navy/Purple
  static const PdfColor _cardBackground = PdfColor.fromInt(0xFF252238); // Slightly lighter
  static const PdfColor _accentPink = PdfColor.fromInt(0xFFD6335C); // INHAUS Pink/Red
  static const PdfColor _textWhite = PdfColors.white;
  static const PdfColor _textGrey = PdfColor.fromInt(0xFFAAAAAA);

  static Future<Uint8List> generate(ProposalData data, {Uint8List? agencyLogo, Uint8List? clientLogo}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: _darkBackground,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(data, agencyLogo: agencyLogo, clientLogo: clientLogo),
                pw.SizedBox(height: 30),
                ...data.sections.map((s) => _buildSection(s)),
                pw.Spacer(),
                _buildFooter(data),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(ProposalData data, {Uint8List? agencyLogo, Uint8List? clientLogo}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      decoration: const pw.BoxDecoration(
        color: _accentPink,
        borderRadius: pw.BorderRadius.vertical(bottom: pw.Radius.circular(0)), // Top bar
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (agencyLogo != null)
                pw.SizedBox(
                  height: 40,
                  child: pw.Image(pw.MemoryImage(agencyLogo)),
                )
              else ...[
                pw.Text('INHAUS', style: pw.TextStyle(color: _textWhite, fontSize: 32, fontWeight: pw.FontWeight.bold, letterSpacing: 5)),
                pw.Text('ESTUDIO CREATIVO', style: pw.TextStyle(color: _textWhite, fontSize: 10, letterSpacing: 2)),
              ],
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (clientLogo != null)
                 pw.Container(
                   height: 40,
                   margin: const pw.EdgeInsets.only(bottom: 10),
                   child: pw.Image(pw.MemoryImage(clientLogo)),
                 ),
              pw.Text('Cliente:', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
              pw.Text(data.clientName, style: pw.TextStyle(color: _textWhite, fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Container(width: 1, height: 20, color: _textWhite),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Fecha:', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                      pw.Text(data.date, style: pw.TextStyle(color: _textWhite, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSection(ProposalSection section) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _cardBackground,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(section.title.toUpperCase(), style: pw.TextStyle(color: _textWhite, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text(section.description, style: pw.TextStyle(color: _textGrey, fontSize: 10)),
                pw.SizedBox(height: 10),
                ...section.items.map((item) => pw.Bullet(
                  text: item,
                  style: const pw.TextStyle(color: _textWhite, fontSize: 10),
                  bulletColor: _textWhite,
                )),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Container(
            width: 120,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: _accentPink,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(color: _textWhite, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                 pw.Spacer(),
                pw.Text(section.price, style: pw.TextStyle(color: _textWhite, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(section.frequency, style: pw.TextStyle(color: _textWhite, fontSize: 8, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(ProposalData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Contáctanos:', style: pw.TextStyle(color: _textWhite, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('(+593) 98 656 6084', style: const pw.TextStyle(color: _textGrey, fontSize: 10)),
              pw.Text('info@inhauscorp.com', style: const pw.TextStyle(color: _textGrey, fontSize: 10)),
            ],
          ),
          pw.Column(
             crossAxisAlignment: pw.CrossAxisAlignment.end,
             children: [
                pw.Text('APROBADO POR', style: pw.TextStyle(color: _textGrey, fontSize: 8)),
                pw.Text('DIEGO ESPÍN', style: pw.TextStyle(color: _textWhite, fontSize: 12, fontWeight: pw.FontWeight.bold)),
             ]
          )
        ],
      ),
    );
  }
}

// --- Data Models for the Generator ---

class ProposalData {
  final String clientName;
  final String? clientDomain;
  final String date;
  final List<ProposalSection> sections;

  ProposalData({required this.clientName, this.clientDomain, required this.date, required this.sections});
  
  // Factory from Map (for JSON parsing)
  factory ProposalData.fromJson(Map<String, dynamic> json) {
    return ProposalData(
      clientName: json['clientName'] ?? 'Cliente',
      clientDomain: json['clientDomain'],
      date: json['date'] ?? 'Fecha',
      sections: (json['sections'] as List?)?.map((x) => ProposalSection.fromJson(x)).toList() ?? [],
    );
  }
}

class ProposalSection {
  final String title;
  final String description;
  final List<String> items;
  final String price;
  final String frequency; // e.g., "Mensual" or "One-time"

  ProposalSection({
    required this.title,
    required this.description,
    required this.items,
    required this.price,
    required this.frequency,
  });

  factory ProposalSection.fromJson(Map<String, dynamic> json) {
     return ProposalSection(
       title: json['title'] ?? 'Service',
       description: json['description'] ?? '',
       items: List<String>.from(json['items'] ?? []),
       price: json['price'] ?? '\$0.00',
       frequency: json['frequency'] ?? '',
     );
  }
}
