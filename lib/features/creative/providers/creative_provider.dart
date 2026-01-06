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

      final res1 = await EdgeAIService.generateText("Write 2 sentences of ad copy for a campaign titled $title$visualContext.");
      ref.read(aiProximityProvider.notifier).setProximity(res1.proximity);
      final copy = res1.text;

      final res2 = await EdgeAIService.generateText("Describe a visual atmosphere for a campaign titled $title$visualContext in one technical prompt.");
      ref.read(aiProximityProvider.notifier).setProximity(res2.proximity);
      final visualPrompt = res2.text;

      final res3 = await EdgeAIService.generateText("Describe a color palette for $title$visualContext.");
      ref.read(aiProximityProvider.notifier).setProximity(res3.proximity);
      final moodDesc = res3.text;

      final newConcept = DesignConcept(
        id: const Uuid().v4(),
        campaignId: campaign.id,
        title: 'Visual Direction: $title',
        copy: copy,
        visualPrompt: visualPrompt,
        moodboards: [
          Moodboard(
            id: 'mb1',
            title: 'Mood & Color',
            imageUrls: [],
            description: moodDesc,
          ),
        ],
      );
      state = [...state, newConcept];
      debugPrint('CreativeAgent: Local concept generated successfully.');
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
