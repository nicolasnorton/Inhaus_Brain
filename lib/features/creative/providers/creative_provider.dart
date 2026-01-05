import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/design_concept.dart';
import '../../../core/services/edge_ai_service.dart';

class CreativeNotifier extends Notifier<List<DesignConcept>> {
  @override
  List<DesignConcept> build() => [];

  Future<void> generateConceptForCampaign(String campaignId, String title) async {
    final copy = await EdgeAIService.generateText("Write 2 sentences of ad copy for a campaign titled $title.");
    final visualPrompt = await EdgeAIService.generateText("Describe a visual atmosphere for a campaign titled $title in one technical prompt.");
    final moodDesc = await EdgeAIService.generateText("Describe a color palette for $title.");

    final newConcept = DesignConcept(
      id: const Uuid().v4(),
      campaignId: campaignId,
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
  }

  void updateConcept(DesignConcept concept) {
    state = [
      for (final item in state)
        if (item.id == concept.id) concept else item
    ];
  }
}

final creativeProvider = NotifierProvider<CreativeNotifier, List<DesignConcept>>(CreativeNotifier.new);
