import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfStyles {
  // Official INHAUS v2.0 Colors
  static final PdfColor inhausDark = PdfColor.fromInt(0xFF05050B); // #05050B
  static final PdfColor inhausCard = PdfColor.fromInt(0xFF0F0F16); // #0F0F16
  static final PdfColor inhausPurple = PdfColor.fromInt(0xFF1A1423); // #1A1423 (Dark Purple Bar)
  static final PdfColor inhausTextPrimary = PdfColors.white; // #FFFFFF
  static final PdfColor inhausTextSecondary = PdfColor.fromInt(0xFFA0A0A0); // #A0A0A0

  static PdfColor withOpacity(PdfColor color, double opacity) {
    return PdfColor(color.red, color.green, color.blue, opacity);
  }

  // Text Styles
  static pw.TextStyle headerTitle(pw.Font font) => pw.TextStyle(font: font, fontSize: 48, color: inhausTextPrimary, height: 0.9);
  static pw.TextStyle sectionTitle(pw.Font font) => pw.TextStyle(font: font, fontSize: 14, color: inhausTextPrimary, letterSpacing: 1);
  static pw.TextStyle bodyText(pw.Font font) => pw.TextStyle(font: font, fontSize: 12, color: inhausTextPrimary);
  static pw.TextStyle labelText(pw.Font font) => pw.TextStyle(font: font, fontSize: 10, color: inhausTextSecondary);
  static pw.TextStyle priceText(pw.Font font) => pw.TextStyle(font: font, fontSize: 24, color: inhausTextPrimary);
}
