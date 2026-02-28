import '../agent_tool.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/edge_ai_service.dart';

class ImageGenerationTool extends AgentTool {
  final Ref ref;

  ImageGenerationTool(this.ref, {String? imagenKey, String? vertexKey})
      : super(
          name: 'image_generation',
          description: 'Generate a production-grade image using Nano Banana 2 (Gemini native image generation).',
          inputSchema: {
            'prompt': {
              'type': 'string',
              'description': 'The prompt to generate the image for.',
            },
            'modelId': {
              'type': 'string',
              'description': 'Optional model ID. Defaults to gemini-3.1-flash-image-preview. Use gemini-3-pro-image-preview for higher quality.',
            },
            'aspectRatio': {
              'type': 'string',
              'description': 'Optional aspect ratio (e.g. "16:9", "1:1", "9:16", "4:3").',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final prompt = parameters['prompt'] as String?;
    if (prompt == null || prompt.isEmpty) {
      return ToolResult.failure('Missing required parameter: prompt');
    }

    final modelId = parameters['modelId'] as String?;
    final aspectRatio = parameters['aspectRatio'] as String?;

    try {
      final url = await EdgeAIService.generateImage(
        prompt,
        ref: ref ?? this.ref,
        modelId: modelId,
        generationParams: aspectRatio != null ? {'aspectRatio': aspectRatio} : null,
      );
      return ToolResult.success({'url': url});
    } catch (e) {
      return ToolResult.failure('Image generation failed: $e');
    }
  }
}
