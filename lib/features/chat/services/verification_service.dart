import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/edge_ai_service.dart';

class VerificationService {
  final Ref _ref;

  VerificationService(this._ref);

  Future<String> verifyOutput(String originalPrompt, String candidateOutput) async {
    const systemPrompt = """
You are the Verifier Agent (Agent B) for Inhaus Brain.
Your role is to critique and refine the output of the Primary Agent (Agent A).
Check for:
1. Accuracy and Relevance to the user's prompt.
2. Tone and Style (Professional, Strategic, Creative).
3. Completeness.

If the output is good, return it AS IS.
If the output needs improvement, REWRITE it to be better, fixing the issues.
Return ONLY the final output (either original or improved). Do not add "Here is the improved version:" etc.
""";

    final prompt = """
Original Prompt: "$originalPrompt"

Candidate Output:
$candidateOutput
""";

    try {
      final response = await EdgeAIService.generateText(
        "$systemPrompt\n\n$prompt",
        ref: _ref,
      );
      return response.text;
    } catch (e) {
      // Fallback to original if verification fails
      return candidateOutput;
    }
  }
}

final verificationServiceProvider = Provider<VerificationService>((ref) => VerificationService(ref));
