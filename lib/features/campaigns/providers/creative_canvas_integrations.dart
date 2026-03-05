import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/architecture/blackboard.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/services/figma_service.dart';
import '../../../core/services/stitch_service.dart';

/// Aggregation provider for Creative Campaign Canvas integrations.
///
/// Wires together BrainWeave brand rules, Blackboard auto-save,
/// Stitch→Figma roundtrip, and client brief generation.
final creativeCanvasIntegrationsProvider =
    Provider<CreativeCanvasIntegrations>((ref) {
  return CreativeCanvasIntegrations(ref);
});

class CreativeCanvasIntegrations {
  final Ref _ref;

  CreativeCanvasIntegrations(this._ref);

  /// Inject BrainWeave brand guardrails as default config values
  /// for creative nodes. Call on canvas load.
  Map<String, dynamic> loadBrainWeaveBrandRules() {
    try {
      final blackboard = _ref.read(blackboardProvider);
      final brandRules = blackboard.facts['brainweave_brand_rules'];
      if (brandRules is Map<String, dynamic>) {
        return brandRules;
      }
    } catch (_) {
      // BrainWeave may not have run yet
    }
    return {};
  }

  /// Batch-save all node outputs to Blackboard under a campaign key.
  void saveAllOutputs(
      String campaignId, Map<String, dynamic> nodeOutputs) {
    _ref.read(blackboardProvider.notifier).postFact(
      'campaign_canvas_outputs_$campaignId',
      {
        'savedAt': DateTime.now().toIso8601String(),
        'outputs': nodeOutputs,
      },
    );
  }

  /// Stitch → Figma roundtrip: export a Stitch screen render to Figma.
  /// Only executes when both Stitch and Figma flags are enabled.
  Future<void> stitchToFigmaRoundtrip({
    required String stitchImageUrl,
    required String figmaFileKey,
    required String figmaToken,
    String? message,
  }) async {
    if (!FeatureFlags.enableStitch || !FeatureFlags.enableFigmaIntegration) {
      return;
    }

    final figma = _ref.read(figmaServiceProvider);
    await figma.postComment(
      figmaFileKey,
      message ?? 'Stitch screen render from Creative Canvas',
      imageUrl: stitchImageUrl,
      token: figmaToken,
    );
  }

  /// Generate a stub client brief from campaign canvas outputs.
  /// Can be extended to push to GoHighLevel / Notion connectors.
  Map<String, dynamic> generateClientBriefStub(
      String campaignName, Map<String, dynamic> outputs) {
    return {
      'campaignName': campaignName,
      'generatedAt': DateTime.now().toIso8601String(),
      'assets': outputs.keys.toList(),
      'status': 'draft',
      'deliverables': outputs.entries
          .where((e) =>
              e.key.contains('image') ||
              e.key.contains('video') ||
              e.key.contains('composite'))
          .map((e) => {'type': e.key, 'url': e.value})
          .toList(),
    };
  }
}
