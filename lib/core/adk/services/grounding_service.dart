import '../../../features/knowledge/models/knowledge_source.dart';
import '../../services/edge_ai_service.dart';

class GroundingResult {
  final bool isGrounded;
  final String justification;
  final List<String> citations;

  GroundingResult({
    required this.isGrounded,
    required this.justification,
    this.citations = const [],
  });
}

/// Service that verifies agent claims against trusted knowledge sources or search results.
class GroundingService {
  static Future<GroundingResult> verify(
    String claim, {
    required List<KnowledgeSource> knowledge,
    String? apiKey,
  }) async {
    final knowledgeContext = knowledge.map((k) => k.content).join("\n---\n");
    
    final prompt = """
VERIFY THE FOLLOWING CLAIM AGAINST THE PROVIDED KNOWLEDGE.
CLAIM: $claim

KNOWLEDGE:
$knowledgeContext

Does the knowledge support the claim? Return JSON:
{
  "isGrounded": bool,
  "justification": "string",
  "citations": ["source_title_1", ...]
}
""";

    final aiRes = await EdgeAIService.generateText(
      prompt,
      apiKey: apiKey,
    );

    // Simplified parsing for prototype
    final text = aiRes.text.toLowerCase();
    final isGrounded = text.contains('"isgrounded": true') || text.contains('"isgrounded":true');
    
    return GroundingResult(
      isGrounded: isGrounded,
      justification: "Verification performed via Grounding Service.",
      citations: knowledge.map((k) => k.title).toList(),
    );
  }
}
