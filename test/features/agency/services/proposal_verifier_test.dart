import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/features/agency/services/proposal_verifier.dart';
import 'package:inhaus_brain/features/agency/models/inhaus_proposal_models.dart';
import 'dart:typed_data';

void main() {
  test('ProposalVerifier handles empty or invalid PDF bytes gracefully', () {
    final invalidPdf = Uint8List.fromList([0, 1, 2, 3]); // Not a valid PDF
    
    final errors = ProposalVerifier.verifyPdf(
      invalidPdf, 
      language: ProposalLanguage.spanish
    );

    expect(errors, isNotEmpty);
    expect(errors.first, contains("Verification Failed"));
  });

  // Note: Testing with valid PDFs requires generating one first, 
  // which is complex in unit tests due to font dependencies.
  // Ideally, we'd mock the PDF generation or load a test asset.
}
