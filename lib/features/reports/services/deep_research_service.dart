import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_proxy_service.dart';

// Deep Research Service: Handles multi-turn research interactions with Gemini 3 Deep Research
class DeepResearchService {
  final Ref _ref;

  DeepResearchService(this._ref);

  /// Starts a Deep Research task
  Future<String> startDeepResearch(String prompt) async {
    final result = await AIProxyService.startResearch(
      prompt: prompt,
      model: 'gemini-2.0-flash-thinking-exp-01-21', // Best available thinking model for research
    );
    return result['interactionId'];
  }

  /// Polls for Deep Research status
  /// Returns null if still processing, or final text result if complete.
  Future<String?> pollDeepResearch(String interactionId) async {
    final result = await AIProxyService.pollResearch(interactionId);
    
    final status = result['status']; // 'processing' or 'complete'
    if (status == 'complete' || status == 'completed') {
      return result['output'];
    }
    return null;
  }
  
  /// Helper: Start and wait for completion (use with caution, can be long-running)
  Future<String> executeResearch(String prompt) async {
    final id = await startDeepResearch(prompt);
    
    String? output;
    int attempts = 0;
    while (output == null && attempts < 60) { // Max 5 minutes (60 * 5s)
      await Future.delayed(const Duration(seconds: 5));
      output = await pollDeepResearch(id);
      attempts++;
    }
    
    if (output == null) {
      throw Exception("Deep Research timed out.");
    }
    
    return output;
  }
}

final deepResearchServiceProvider = Provider<DeepResearchService>((ref) {
  return DeepResearchService(ref);
});
