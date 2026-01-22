import '../agent_tool.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/edge_ai_service.dart';

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
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final prompt = parameters['prompt'] as String?;
    if (prompt == null || prompt.isEmpty) {
      return ToolResult.failure('Missing required parameter: prompt');
    }

    final url = await EdgeAIService.generateVideo(prompt, veoKey: veoKey, vertexKey: vertexKey, ref: ref);
    return ToolResult.success({'url': url});
  }
}
