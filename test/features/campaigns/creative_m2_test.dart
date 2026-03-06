import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/core/adk/models/pipeline_models.dart';
import 'package:inhaus_brain/features/campaigns/templates/campaign_weavy_template.dart';

/// Milestone 2 Tests: Stitch Design Node, Templates, Campaign Entry
void main() {
  group('WorkflowNodeType — M2 additions', () {
    test('creativeStitchDesign is a valid enum value', () {
      expect(WorkflowNodeType.creativeStitchDesign, isNotNull);
      expect(
          WorkflowNodeType.values
              .contains(WorkflowNodeType.creativeStitchDesign),
          isTrue);
    });

    test('creativeStitchDesign deserializes from JSON', () {
      final json = {
        'id': 'stitch-1',
        'nodeType': 'creativeStitchDesign',
        'instruction': 'Generate a landing page',
        'config': {'prompt': 'modern minimalist landing page'},
        'dependencies': <String>[],
        'inputMappings': <String, String>{},
      };
      final step = PipelineStep.fromJson(json);
      expect(step.nodeType, WorkflowNodeType.creativeStitchDesign);
    });

    test('M1 enum values still deserialize after M2 addition', () {
      for (final typeName in [
        'creativeImageGen',
        'creativeInpaintOutpaint',
        'creativeControlNet',
        'creativeRelightProduct',
        'creativeVideoLipsync',
        'creativeCompositingLayers',
      ]) {
        final json = {
          'id': 'step-$typeName',
          'nodeType': typeName,
          'instruction': '',
          'config': <String, dynamic>{},
          'dependencies': <String>[],
          'inputMappings': <String, String>{},
        };
        final step = PipelineStep.fromJson(json);
        expect(step.nodeType.name, typeName);
      }
    });
  });

  group('Campaign Weavy Templates', () {
    test('defaultCampaignWorkflow returns 7 steps', () {
      final steps = CampaignWeavyTemplates.defaultCampaignWorkflow();
      expect(steps.length, 7);
    });

    test('heroProductRelightPreset returns 5 steps', () {
      final steps = CampaignWeavyTemplates.heroProductRelightPreset();
      expect(steps.length, 5);
    });

    test('socialMediaVariationsPreset returns 5 steps', () {
      final steps = CampaignWeavyTemplates.socialMediaVariationsPreset();
      expect(steps.length, 5);
    });

    test('videoAdLipsyncPreset returns 4 steps', () {
      final steps = CampaignWeavyTemplates.videoAdLipsyncPreset();
      expect(steps.length, 4);
    });

    test('multiAngle360Preset returns 6 steps', () {
      final steps = CampaignWeavyTemplates.multiAngle360Preset();
      expect(steps.length, 6);
    });

    test('each template has unique step IDs', () {
      for (final entry in CampaignWeavyTemplates.all.entries) {
        final steps = entry.value();
        final ids = steps.map((s) => s.id).toSet();
        expect(ids.length, steps.length,
            reason: '${entry.key} has duplicate step IDs');
      }
    });

    test('all steps have uiPosition set', () {
      for (final entry in CampaignWeavyTemplates.all.entries) {
        final steps = entry.value();
        for (final step in steps) {
          expect(step.uiPosition, isNotNull,
              reason:
                  '${entry.key} step ${step.id} missing uiPosition');
        }
      }
    });

    test('dependency references are valid step IDs within the template', () {
      for (final entry in CampaignWeavyTemplates.all.entries) {
        final steps = entry.value();
        final allIds = steps.map((s) => s.id).toSet();
        for (final step in steps) {
          for (final dep in step.dependencies) {
            expect(allIds.contains(dep), isTrue,
                reason:
                    '${entry.key}: step ${step.id} references unknown dep $dep');
          }
        }
      }
    });

    test('all templates serialize and deserialize without error', () {
      for (final entry in CampaignWeavyTemplates.all.entries) {
        final steps = entry.value();
        for (final step in steps) {
          final json = step.toJson();
          final restored = PipelineStep.fromJson(json);
          expect(restored.id, step.id,
              reason: '${entry.key}: roundtrip failed for ${step.id}');
          expect(restored.nodeType, step.nodeType);
        }
      }
    });

    test('templates map has 5 entries', () {
      expect(CampaignWeavyTemplates.all.length, 5);
    });
  });
}
