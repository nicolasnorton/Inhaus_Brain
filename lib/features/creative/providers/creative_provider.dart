import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/design_concept.dart';
import '../../campaigns/models/campaign.dart';
import '../../../core/services/edge_ai_service.dart';


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
2. A technical visual prompt for an image generator (labeled "Visual Prompt:").
3. A description of the ideal color palette and mood (labeled "Mood:").

Format your response clearly.
""";

      final res1 = await EdgeAIService.generateText(
        creativePrompt,
        ref: ref,
      );
      
      // Parse the output
      final output = res1.text;
      
      String copy = output;
      String visualPrompt = "Cinematic, high detail, 8k resolution, photorealistic";
      String moodDescription = "Vibrant and impactful";

      // Basic parsing logic
      if (output.contains("Visual Prompt:")) {
        final parts = output.split("Visual Prompt:");
        copy = parts[0].trim();
        final rest = parts[1];
        if (rest.contains("Mood:")) {
           final visualParts = rest.split("Mood:");
           visualPrompt = visualParts[0].trim();
           moodDescription = visualParts[1].trim();
        } else {
           visualPrompt = rest.trim();
        }
      }

      // Generate visual assets for the moodboard in parallel
      final imageFutures = [
        EdgeAIService.generateImage(visualPrompt + ", wide angle, cinematic lighting"),
        EdgeAIService.generateImage(visualPrompt + ", close up detail, macro photography"),
      ];
      
      final imageUrls = await Future.wait(imageFutures);
      
      final newConcept = DesignConcept(
        id: const Uuid().v4(),
        campaignId: campaign.id,
        title: 'Visual Direction: $title',
        copy: copy.length > 500 ? copy.substring(0, 500) : copy,
        visualPrompt: visualPrompt,
        moodboards: [
          Moodboard(
            id: 'mb1',
            title: 'Mood & Color',
            imageUrls: imageUrls,
            description: moodDescription,
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

  Future<void> generateHighTierAssets(DesignConcept concept, {bool includeSubtitles = false}) async {
    try {
      debugPrint('CreativeAgent: Initiating High-Tier Cloud Generation for ${concept.id}');
      
      // Update proximity to Cloud for this high-tier operation
      ref.read(aiProximityProvider.notifier).setProximity(AIProximity.cloud);

      // 1. Refine Copy with Copywriter Agent (Gemini)
      final copyPrompt = """
Act as a Senior Copywriter. Refine the following draft copy for a high-impact ad campaign. 
Make it punchy, persuasive, and production-ready.

Draft: ${concept.copy}

Return ONLY the refined copy text.
""";
      final copyRes = await EdgeAIService.generateText(copyPrompt, ref: ref);
      
      // 2. Generate High-Quality Visual Mock (Imagen 3)
      final finalImagePrompt = "${concept.visualPrompt}, award winning, billboard quality, 8k, highly detailed";
      final finalImageUrl = await EdgeAIService.generateImage(finalImagePrompt);

      // 3. Generate Video Preview (Automatic with high-tier assets)
      final previewVideoUrl = await EdgeAIService.generateVideo(concept.visualPrompt, isFinal: false, includeSubtitles: includeSubtitles);

      final updatedConcept = concept.copyWith(
        finalCopy: copyRes.text,
        finalImageURL: finalImageUrl,
        previewVideoURL: previewVideoUrl,
        isVideoFinal: false,
        isFinalReady: true,
      );

      updateConcept(updatedConcept);
      debugPrint('CreativeAgent: High-Tier assets (including video preview) generated.');
    } catch (e, stack) {
      debugPrint('CreativeAgent ERROR: High-Tier generation failed: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> renderFinalVideo(DesignConcept concept, {bool includeSubtitles = false}) async {
    try {
      debugPrint('CreativeAgent: Rendering Final High-Quality Video for ${concept.id}');
      
      final finalVideoUrl = await EdgeAIService.generateVideo(concept.visualPrompt, isFinal: true, includeSubtitles: includeSubtitles);
      
      final updatedConcept = concept.copyWith(
        finalVideoURL: finalVideoUrl,
        isVideoFinal: true,
      );

      updateConcept(updatedConcept);
      debugPrint('CreativeAgent: Final video rendered successfully.');
    } catch (e) {
      debugPrint('CreativeAgent ERROR: Final video render failed: $e');
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
