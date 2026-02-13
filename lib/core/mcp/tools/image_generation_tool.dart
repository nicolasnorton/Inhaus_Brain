import '../agent_tool.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/edge_ai_service.dart';

class ImageGenerationTool extends AgentTool {
  final String? imagenKey;
  final String? vertexKey;
  // final String? bananaKey; // Removed
  final Ref ref;

  ImageGenerationTool(this.ref, {this.imagenKey, this.vertexKey})
      : super(
          name: 'image_generation',
          description: 'Generate a production-grade image concept.',
          inputSchema: {
            'prompt': {
              'type': 'string',
              'description': 'The prompt to generate the image for.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final prompt = parameters['prompt'] as String?;
    if (prompt == null || prompt.isEmpty) {
      return ToolResult.failure('Missing required parameter: prompt');
    }

    try {
      final url = await EdgeAIService.generateImage(prompt, imagenKey: imagenKey, vertexKey: vertexKey, ref: ref);
      return ToolResult.success({'url': url});
    } catch (e) {
      return ToolResult.failure('Image generation failed: $e');
    }
  }
}
