import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/design_concept.dart';
import '../../campaigns/models/campaign.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/services/firebase_service_provider.dart';

class CreativeNotifier extends Notifier<List<DesignConcept>> {
  @override
  List<DesignConcept> build() => [];

  Future<void> generateConceptForCampaign(Campaign campaign) async {
    final title = campaign.title;
    final attachments = campaign.attachments;
    
    try {
      debugPrint('CreativeAgent: Starting local concept generation for $title');
      
      String visualContext = '';
      if (attachments.any((a) => a.type == AttachmentType.image || a.type == AttachmentType.video)) {
        visualContext = ' based on the provided visual assets (brand style/product shots)';
      }

      final creativePrompt = """
You are a Creative Director. Based on the campaign "$title" and $visualContext, generate:
1. Two sentences of compelling ad copy.
2. A technical visual prompt for an image generator.
3. A description of the ideal color palette and mood.

Format your response clearly.
""";

      final res1 = await EdgeAIService.generateText(
        creativePrompt,
        ref: ref,
      );
      
      // Parse the combined response or keep it simple if parsing fails
      final output = res1.text;
      
      final newConcept = DesignConcept(
        id: const Uuid().v4(),
        campaignId: campaign.id,
        title: 'Visual Direction: $title',
        copy: output.split('\n').take(3).join('\n'), // Simple heuristic
        visualPrompt: output.contains('Visual Prompt') ? output.split('Visual Prompt').last.split('\n').first : output,
        moodboards: [
          Moodboard(
            id: 'mb1',
            title: 'Mood & Color',
            imageUrls: [
              'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1000&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?q=80&w=1000&auto=format&fit=crop',
            ],
            description: output.contains('Mood') ? output.split('Mood').last : "Vibrant and impactful aesthetic direction.",
          ),
        ],
      );
      state = [...state, newConcept];
      debugPrint('CreativeAgent: Concept generated with real-feel imagery.');
    } catch (e, stack) {
      debugPrint('CreativeAgent ERROR: Failed to generate local concept: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> generateHighTierAssets(DesignConcept concept) async {
    try {
      debugPrint('CreativeAgent: Initiating High-Tier Cloud Generation for ${concept.id}');
      final firebaseService = ref.read(firebaseServiceProvider);
      
      // Update proximity to Cloud for this high-tier operation
      ref.read(aiProximityProvider.notifier).setProximity(AIProximity.cloud);

      final results = await firebaseService.generateFinalAssets(
        campaignId: concept.campaignId,
        creativeBrief: concept.copy,
        visualPrompt: concept.visualPrompt,
      );

      final updatedConcept = concept.copyWith(
        finalCopy: results['finalCopy'],
        finalImageURL: results['finalImageURL'],
        isFinalReady: true,
      );

      updateConcept(updatedConcept);
      debugPrint('CreativeAgent: High-Tier assets generated and updated.');
    } catch (e, stack) {
      debugPrint('CreativeAgent ERROR: High-Tier generation failed: $e');
      debugPrint(stack.toString());
    }
  }

  void updateConcept(DesignConcept concept) {
    state = [
      for (final item in state)
        if (item.id == concept.id) concept else item
    ];
  }
}

final creativeProvider = NotifierProvider<CreativeNotifier, List<DesignConcept>>(CreativeNotifier.new);
