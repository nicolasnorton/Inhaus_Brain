import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/edge_ai_service.dart';

class VerificationService {
  final Ref _ref;

  VerificationService(this._ref);

  Future<String> verifyOutput(String originalPrompt, String candidateOutput) async {
    const systemPrompt = """
You are the Verifier Agent (Agent B) for Inhaus Brain.
Your role is to critique and refine the output of the Primary Agent (Agent A).

CRITICAL:
1. PRESERVE JSON: If the output contains a JSON tool call (e.g., `gen_ui_component`, `tool_call`, etc.), you MUST PRESERVE the JSON structure EXACTLY.
2. REFINEMENT: You may only refine the "Final Output" text or the `summary_text` inside the JSON.
3. NO STRIPPING: Never remove a tool call to turn it into a plain text report.
4. If the output is good, return it AS IS.
5. If the output needs improvement, REWRITE it while keeping all tool logic intact.
6. Return ONLY the final output. Do not add "Here is the improved version:".
7. BRAND GUARDRAILS: Ensure tone is premium/editorial. Remove any unintended competitor mentions or non-inclusive language.
8. BILINGUAL CONSISTENCY: If the original prompt is in Spanish or asks for bilingual content, ensure the verification preserves or enforces that (e.g., providing translations if missing).
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
