import '../agent_tool.dart';
import '../../services/edge_ai_service.dart';

class VideoGenerationTool extends AgentTool {
  final String? veoKey;

  VideoGenerationTool({this.veoKey})
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

    final url = await EdgeAIService.generateVideo(prompt, veoKey: veoKey);
    return ToolResult.success({'url': url});
  }
}
