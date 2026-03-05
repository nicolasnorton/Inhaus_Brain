import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/core/adk/models/pipeline_models.dart';
import 'package:inhaus_brain/core/config/feature_flags.dart';

/// Milestone 1 Tests: Creative Campaign Canvas Nodes
///
/// Tests cover:
/// - Enum regression: old pipelines deserialize safely with new enum values
/// - Enum fallback: unknown nodeType falls back to `agent`
/// - Feature flag default: enableDesignerCanvasMode defaults to false
/// - Node type existence: all 6 creative types exist in the enum
void main() {
  group('WorkflowNodeType enum regression', () {
    test('existing nodeType "agent" still deserializes correctly', () {
      final json = {
        'id': 'step-1',
        'nodeType': 'agent',
        'instruction': 'Test instruction',
        'config': <String, dynamic>{},
        'dependencies': <String>[],
        'inputMappings': <String, String>{},
      };

      final step = PipelineStep.fromJson(json);
      expect(step.nodeType, WorkflowNodeType.agent);
      expect(step.id, 'step-1');
    });

    test('existing nodeType "brainweavePipeline" still deserializes correctly', () {
      final json = {
        'id': 'step-bw',
        'nodeType': 'brainweavePipeline',
        'instruction': '',
        'config': <String, dynamic>{},
        'dependencies': <String>[],
        'inputMappings': <String, String>{},
      };

      final step = PipelineStep.fromJson(json);
      expect(step.nodeType, WorkflowNodeType.brainweavePipeline);
    });

    test('unknown nodeType falls back to WorkflowNodeType.agent', () {
      final json = {
        'id': 'step-future',
        'nodeType': 'futureNodeTypeThatDoesNotExist',
        'instruction': 'Some instruction',
        'config': <String, dynamic>{},
        'dependencies': <String>[],
        'inputMappings': <String, String>{},
      };

      final step = PipelineStep.fromJson(json);
      expect(step.nodeType, WorkflowNodeType.agent);
    });

    test('null nodeType falls back to WorkflowNodeType.agent', () {
      final json = {
        'id': 'step-null',
        'nodeType': null,
        'instruction': '',
        'config': <String, dynamic>{},
        'dependencies': <String>[],
        'inputMappings': <String, String>{},
      };

      final step = PipelineStep.fromJson(json);
      expect(step.nodeType, WorkflowNodeType.agent);
    });

    test('missing nodeType key falls back to WorkflowNodeType.agent', () {
      final json = {
        'id': 'step-missing',
        'instruction': '',
        'config': <String, dynamic>{},
        'dependencies': <String>[],
        'inputMappings': <String, String>{},
      };

      final step = PipelineStep.fromJson(json);
      expect(step.nodeType, WorkflowNodeType.agent);
    });
  });

  group('New creative node types exist', () {
    test('creativeImageGen is a valid enum value', () {
      expect(WorkflowNodeType.creativeImageGen, isNotNull);
      expect(WorkflowNodeType.values.contains(WorkflowNodeType.creativeImageGen), isTrue);
    });

    test('creativeInpaintOutpaint is a valid enum value', () {
      expect(WorkflowNodeType.creativeInpaintOutpaint, isNotNull);
    });

    test('creativeControlNet is a valid enum value', () {
      expect(WorkflowNodeType.creativeControlNet, isNotNull);
    });

    test('creativeRelightProduct is a valid enum value', () {
      expect(WorkflowNodeType.creativeRelightProduct, isNotNull);
    });

    test('creativeVideoLipsync is a valid enum value', () {
      expect(WorkflowNodeType.creativeVideoLipsync, isNotNull);
    });

    test('creativeCompositingLayers is a valid enum value', () {
      expect(WorkflowNodeType.creativeCompositingLayers, isNotNull);
    });

    test('new creative types deserialize from JSON', () {
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
        expect(step.nodeType.name, typeName,
            reason: '$typeName should deserialize to the matching enum value');
      }
    });
  });

  group('Feature flag defaults', () {
    test('enableDesignerCanvasMode defaults to false', () {
      // FeatureFlags is a static class; without Firestore init, _overrides is empty,
      // so this falls back to the hardcoded default.
      expect(FeatureFlags.enableDesignerCanvasMode, isFalse);
    });
  });

  group('Pipeline with creative nodes serialization roundtrip', () {
    test('PipelineStep with creative nodeType serializes and deserializes', () {
      final original = PipelineStep(
        id: 'creative-test-1',
        nodeType: WorkflowNodeType.creativeImageGen,
        instruction: 'Generate a hero image',
        config: {'prompt': 'A sunset over mountains', 'aspectRatio': '16:9'},
        dependencies: ['step-0'],
      );

      final json = original.toJson();
      final restored = PipelineStep.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.nodeType, WorkflowNodeType.creativeImageGen);
      expect(restored.config['prompt'], 'A sunset over mountains');
      expect(restored.dependencies, ['step-0']);
    });
  });
}
