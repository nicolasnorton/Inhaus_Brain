import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/architecture/blackboard.dart';
import 'package:inhaus_brain/features/campaigns/providers/creative_canvas_integrations.dart';

void main() {
  group('CreativeCanvasIntegrations (M4)', () {
    test('generateClientBriefStub formats outputs correctly', () {
      final container = ProviderContainer();
      final integrations = container.read(creativeCanvasIntegrationsProvider);

      final outputs = {
        'imageGen_hero': 'https://image.com/1.png',
        'videoGen_teaser': 'https://video.com/1.mp4',
        'unrelated_text': 'some string',
      };

      final brief = integrations.generateClientBriefStub('Q3 Launch', outputs);

      expect(brief['campaignName'], 'Q3 Launch');
      expect(brief['status'], 'draft');
      expect(brief['assets'].length, 3);
      
      // Should filter to media types
      final deliverables = brief['deliverables'] as List;
      expect(deliverables.length, 2);
      expect(deliverables[0]['type'], 'imageGen_hero');
      expect(deliverables[1]['type'], 'videoGen_teaser');
    });

    test('saveAllOutputs posts to Blackboard', () {
      final container = ProviderContainer();
      final integrations = container.read(creativeCanvasIntegrationsProvider);
      
      final outputs = {'key': 'val'};
      integrations.saveAllOutputs('camp_123', outputs);

      final state = container.read(blackboardProvider);
      final fact = state.facts['campaign_canvas_outputs_camp_123'] as Map<String, dynamic>?;
      
      expect(fact, isNotNull);
      expect(fact!['outputs'], outputs);
      expect(fact['savedAt'], isNotNull);
    });

    test('loadBrainWeaveBrandRules returns map when available', () {
      final container = ProviderContainer();
      
      // Pre-seed the blackboard
      container.read(blackboardProvider.notifier).postFact('brainweave_brand_rules', {
        'colors': ['#FFF'],
        'tone': 'professional'
      });

      final integrations = container.read(creativeCanvasIntegrationsProvider);
      final rules = integrations.loadBrainWeaveBrandRules();

      expect(rules.length, 2);
      expect(rules['tone'], 'professional');
    });

    test('loadBrainWeaveBrandRules returns empty map when absent', () {
      final container = ProviderContainer();
      final integrations = container.read(creativeCanvasIntegrationsProvider);
      
      final rules = integrations.loadBrainWeaveBrandRules();
      expect(rules.isEmpty, isTrue);
    });
  });
}
