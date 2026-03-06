import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/core/adk/models/pipeline_models.dart';
import 'package:inhaus_brain/core/config/feature_flags.dart';
import 'package:inhaus_brain/core/models/figma_models.dart';

/// Milestone 3 Tests: Figma Integration
void main() {
  group('WorkflowNodeType — M3 additions', () {
    test('creativeFigmaSync is a valid enum value', () {
      expect(WorkflowNodeType.creativeFigmaSync, isNotNull);
      expect(
          WorkflowNodeType.values
              .contains(WorkflowNodeType.creativeFigmaSync),
          isTrue);
    });

    test('creativeFigmaSync deserializes from JSON', () {
      final json = {
        'id': 'figma-1',
        'nodeType': 'creativeFigmaSync',
        'instruction': 'Import from Figma',
        'config': {'figmaFileKey': 'abcdef123', 'direction': 'import'},
        'dependencies': <String>[],
        'inputMappings': <String, String>{},
      };
      final step = PipelineStep.fromJson(json);
      expect(step.nodeType, WorkflowNodeType.creativeFigmaSync);
    });

    test('all M1+M2+M3 types still deserialize correctly', () {
      for (final typeName in [
        'creativeImageGen',
        'creativeInpaintOutpaint',
        'creativeControlNet',
        'creativeRelightProduct',
        'creativeVideoLipsync',
        'creativeCompositingLayers',
        'creativeStitchDesign',
        'creativeFigmaSync',
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

  group('Feature flags — M3', () {
    test('enableFigmaIntegration defaults to false', () {
      expect(FeatureFlags.enableFigmaIntegration, isFalse);
    });
  });

  group('Figma Models', () {
    test('FigmaFile fromJson roundtrip', () {
      final json = {
        'key': 'abc123',
        'name': 'Test Design File',
        'lastModified': '2026-03-05T00:00:00Z',
        'thumbnailUrl': 'https://example.com/thumb.png',
        'version': '1234567',
        'document': {'children': []},
        'styles': {'color_style_1': {'key': '123'}},
      };
      final file = FigmaFile.fromJson(json);
      expect(file.key, 'abc123');
      expect(file.name, 'Test Design File');
      expect(file.styles.keys, contains('color_style_1'));

      final reJson = file.toJson();
      expect(reJson['key'], 'abc123');
    });

    test('FigmaProject fromJson', () {
      final json = {'id': '12345', 'name': 'My Project'};
      final project = FigmaProject.fromJson(json);
      expect(project.id, '12345');
      expect(project.name, 'My Project');
    });

    test('FigmaFileRef fromJson', () {
      final json = {
        'key': 'file-key-1',
        'name': 'Landing Page',
        'thumbnail_url': 'https://example.com/thumb.png',
        'last_modified': '2026-03-05',
      };
      final ref = FigmaFileRef.fromJson(json);
      expect(ref.key, 'file-key-1');
      expect(ref.name, 'Landing Page');
      expect(ref.thumbnailUrl, isNotEmpty);
    });

    test('FigmaNode fromJson with children', () {
      final json = {
        'id': '0:1',
        'name': 'Frame 1',
        'type': 'FRAME',
        'children': [
          {'id': '0:2', 'name': 'Text', 'type': 'TEXT'},
        ],
      };
      final node = FigmaNode.fromJson(json);
      expect(node.id, '0:1');
      expect(node.type, 'FRAME');
      expect(node.children.length, 1);
      expect(node.children.first.name, 'Text');
    });

    test('FigmaExportResult from empty map', () {
      final result = FigmaExportResult.fromImageMap({});
      expect(result.nodeId, '');
      expect(result.imageUrls, isEmpty);
    });

    test('FigmaExportResult from populated map', () {
      final result = FigmaExportResult.fromImageMap({
        '0:1': 'https://example.com/img1.png',
        '0:2': 'https://example.com/img2.png',
      });
      expect(result.imageUrls.length, 2);
    });
  });

  group('Figma + Creative node serialization roundtrip', () {
    test('PipelineStep with creativeFigmaSync roundtrip', () {
      final original = PipelineStep(
        id: 'figma-roundtrip-1',
        nodeType: WorkflowNodeType.creativeFigmaSync,
        instruction: 'Import mockups from Figma',
        config: {
          'figmaFileKey': 'test-key',
          'direction': 'import',
          'exportFormat': 'png',
        },
        dependencies: ['upstream-1'],
      );

      final json = original.toJson();
      final restored = PipelineStep.fromJson(json);
      expect(restored.nodeType, WorkflowNodeType.creativeFigmaSync);
      expect(restored.config['figmaFileKey'], 'test-key');
      expect(restored.config['direction'], 'import');
    });
  });
}
