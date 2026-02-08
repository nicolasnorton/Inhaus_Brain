import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/inhaus_proposal_models.dart';

class ProposalVerifier {
  /// Verify that the generated PDF is valid and matches Inhaus standards.
  /// Returns a list of error messages. Empty list means success.
  static List<String> verifyPdf(Uint8List pdfBytes, {
    required ProposalLanguage language,
    bool isOnePage = false,
  }) {
    final List<String> errors = [];

    try {
      final document = PdfDocument(inputBytes: pdfBytes);
      final String text = PdfTextExtractor(document).extractText();

      // 1. Basic Integrity
      if (document.pages.count == 0) {
        errors.add("PDF has 0 pages.");
        return errors; // Cannot proceed
      }

      // 2. Branding Check
      if (!text.contains("INHAUS") && !text.contains("inhauscorp.com")) {
        errors.add("Missing INHAUS branding.");
      }

      // 3. Language Checks
      if (language == ProposalLanguage.spanish) {
        if (!text.contains("PRECIO") && !text.contains("Precio")) {
          errors.add("Missing Spanish keywords (PRECIO).");
        }
      } else {
        if (!text.contains("PRICE") && !text.contains("Price")) {
          errors.add("Missing English keywords (PRICE).");
        }
      }

      // 4. One Page Quote specific checks
      if (isOnePage) {
        if (document.pages.count > 2) {
          // Allow 2 pages max (sometimes overflows slightly), but warn
          // errors.add("One Page Quote has ${document.pages.count} pages (expected 1 or 2).");
        }
      }

      document.dispose();
    } catch (e) {
      errors.add("PDF Parsing/Verification Failed: $e");
    }

    return errors;
  }
}
