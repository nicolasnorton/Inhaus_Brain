import '../agent_tool.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/edge_ai_service.dart';
import '../../../features/assistant/providers/assistant_provider.dart';

class VideoGenerationTool extends AgentTool {
  final String? veoKey;
  final String? vertexKey;
  final Ref ref;

  VideoGenerationTool(this.ref, {this.veoKey, this.vertexKey})
      : super(
          name: 'video_generation',
          description: 'Generate a high-fidelity video asset.',
          inputSchema: {
            'prompt': {
              'type': 'string',
              'description': 'The prompt to generate the video for.',
            },
            'model_id': {
              'type': 'string',
              'description': 'Optional. Specific Veo model ID (e.g., veo-3.1-generate-preview, veo-2.0-generate-001).',
            },
            'is_final': {
              'type': 'boolean',
              'description': 'Whether to generate a high-quality final render (slower) or a preview.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final prompt = parameters['prompt'] as String?;
    final modelId = parameters['model_id'] as String?;
    final isFinal = parameters['is_final'] as bool? ?? false;
    
    if (prompt == null || prompt.isEmpty) {
      return ToolResult.failure('Missing required parameter: prompt');
    }

    try {
      final url = await EdgeAIService.generateVideo(
        prompt, 
        modelId: modelId,
        isFinal: isFinal,
        veoKey: veoKey, 
        vertexKey: vertexKey, 
        ref: ref ?? this.ref, // Use passed ref or fallback to internal ref
        onStatusMessage: (msg) {
          // Agent 3: Update UI with "Generating real video..." status
          try {
            this.ref.read(assistantStatusProvider.notifier).state = msg;
          } catch (e) {
            // Ignore provider errors if disposed
          }
        }
      );
      return ToolResult.success({'url': url});
    } catch (e) {
      return ToolResult.failure('Video generation failed: $e');
    }
  }
}
