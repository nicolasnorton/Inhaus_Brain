
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inhaus_brain/features/agency/models/proposal_model.dart';

class ProposalPdfGenerator {
  
  /// Helper to create a PdfColor with opacity
  static PdfColor _withOpacity(PdfColor color, double opacity) {
    return PdfColor(color.red, color.green, color.blue, opacity);
  }
  
  static const PdfColor _darkBackground = PdfColor.fromInt(0xFF0F0F12); // Near Black
  static const PdfColor _cardBackground = PdfColor.fromInt(0xFF16161A); // Dark Grey
  static const PdfColor _accentGold = PdfColor.fromInt(0xFFE5B15D); // Premium Gold
  static const PdfColor _textWhite = PdfColors.white;
  static const PdfColor _textGrey = PdfColor.fromInt(0xFF94A3B8); // Slate-ish grey

  static Future<Uint8List> generate(ProposalData data, {Uint8List? agencyLogo, Uint8List? clientLogo}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              color: _darkBackground,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(data, agencyLogo: agencyLogo, clientLogo: clientLogo),
                  pw.SizedBox(height: 20),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                    child: pw.Text("PROPUESTA DE SERVICIOS", style: pw.TextStyle(color: _accentGold, fontSize: 10, letterSpacing: 2, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                    child: pw.Divider(color: _withOpacity(_accentGold, 0.3), thickness: 0.5),
                  ),
                  pw.SizedBox(height: 10),
                  ...data.sections.map((s) => _buildSection(s)),
                  pw.Spacer(),
                  _buildFooter(data),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(ProposalData data, {Uint8List? agencyLogo, Uint8List? clientLogo}) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 50, left: 40, right: 40, bottom: 40),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                pw.Text('INHAUS', style: pw.TextStyle(color: _textWhite, fontSize: 24, fontWeight: pw.FontWeight.bold, letterSpacing: 4)),
                pw.Text('BRAIN - CORE SYSTEMS', style: pw.TextStyle(color: _accentGold, fontSize: 8, letterSpacing: 2)),
              ],
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (clientLogo != null)
                 pw.Container(
                   height: 30,
                   margin: const pw.EdgeInsets.only(bottom: 10),
                   child: pw.Image(pw.MemoryImage(clientLogo)),
                 ),
              pw.Text('CLIENTE', style: const pw.TextStyle(color: _textGrey, fontSize: 8, letterSpacing: 1.5)),
              pw.Text(data.clientName.toUpperCase(), style: pw.TextStyle(color: _textWhite, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text(data.date, style: pw.TextStyle(color: _accentGold, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSection(ProposalSection section) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _cardBackground,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _withOpacity(_accentGold, 0.1)),
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
                    pw.Container(width: 3, height: 14, color: _accentGold),
                    pw.SizedBox(width: 10),
                    pw.Text(section.title.toUpperCase(), style: pw.TextStyle(color: _textWhite, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ]
                ),
                pw.SizedBox(height: 10),
                pw.Text(section.description, style: pw.TextStyle(color: _textGrey, fontSize: 9)),
                pw.SizedBox(height: 12),
                ...section.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(color: _accentGold, fontSize: 10)),
                      pw.Expanded(child: pw.Text(item, style: const pw.TextStyle(color: _textWhite, fontSize: 9))),
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
              pw.Text('INVERSIÓN', style: pw.TextStyle(color: _accentGold, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text(section.price, style: pw.TextStyle(color: _textWhite, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(section.frequency.toUpperCase(), style: pw.TextStyle(color: _textGrey, fontSize: 7)),
            ],
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
