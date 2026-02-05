import '../agent_tool.dart';
import '../../services/edge_ai_service.dart';

class AudioGenerationTool extends AgentTool {
  final String? lyriaKey;

  AudioGenerationTool({this.lyriaKey})
      : super(
          name: 'audio_generation',
          description: 'Compose advanced music or soundtracks.',
          inputSchema: {
            'prompt': {
              'type': 'string',
              'description': 'The prompt to compose audio for.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final prompt = parameters['prompt'] as String?;
    if (prompt == null || prompt.isEmpty) {
      return ToolResult.failure('Missing required parameter: prompt');
    }

    final url = await EdgeAIService.generateAudio(prompt, lyriaKey: lyriaKey);
    return ToolResult.success({'url': url});
  }
}
