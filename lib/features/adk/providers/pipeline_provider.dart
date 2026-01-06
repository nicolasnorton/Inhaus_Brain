import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/adk/models/pipeline_models.dart';
import '../../chat/models/chat_models.dart';

class PipelineNotifier extends StateNotifier<List<Pipeline>> {
  PipelineNotifier() : super([]) {
    _initDefaults();
  }

  void _initDefaults() {
    state = [
      _buildMasterAgencyPipeline(),
      _buildResearchDeepDive(),
      _buildCreativeSprint(),
    ];
  }

  Pipeline _buildMasterAgencyPipeline() {
    return Pipeline(
      id: 'master_agency_v1',
      name: 'Master Agency Workflow',
      description: 'The full 11-step end-to-end agency process.',
      steps: [
        PipelineStep(
          id: 'step_1',
          agentType: MessageSender.trendScoutAgent,
          instruction: 'Analyze current market trends and competitors for the brand.',
        ),
        PipelineStep(
          id: 'step_2',
          agentType: MessageSender.accountDirectorAgent,
          instruction: 'Define the client objectives and campaign KPIs based on trends.',
        ),
        PipelineStep(
          id: 'step_3',
          agentType: MessageSender.strategistAgent,
          instruction: 'Develop a core strategic angle and positioning for the campaign.',
        ),
        PipelineStep(
          id: 'step_4',
          agentType: MessageSender.creativeAgent,
          instruction: 'Conceptualize visual directions and key creative assets.',
        ),
        PipelineStep(
          id: 'step_5',
          agentType: MessageSender.copywriterAgent,
          instruction: 'Draft high-impact copy for ads, social posts, and landing pages.',
        ),
        PipelineStep(
          id: 'step_6',
          agentType: MessageSender.editorialManagerAgent,
          instruction: 'Review all copy and creative concepts for brand voice consistency.',
        ),
        PipelineStep(
          id: 'step_7',
          agentType: MessageSender.mediaBuyerAgent,
          instruction: 'Structure the media plan, targeting parameters, and budget allocation.',
        ),
        PipelineStep(
          id: 'step_8',
          agentType: MessageSender.performanceAnalystAgent,
          instruction: 'Simulate campaign performance and suggest optimization tweaks.',
        ),
        PipelineStep(
          id: 'step_9',
          agentType: MessageSender.developerAgent,
          instruction: 'Generate the technical structure for a campaign landing page.',
        ),
        PipelineStep(
          id: 'step_10',
          agentType: MessageSender.dataEngineerAgent,
          instruction: 'Finalize data tracking schemas and integration requirements.',
        ),
        PipelineStep(
          id: 'step_11',
          agentType: MessageSender.summarizerAgent,
          instruction: 'Summarize the entire 11-step output into a final Campaign Brief.',
        ),
      ],
    );
  }

  Pipeline _buildResearchDeepDive() {
    return Pipeline(
      id: 'research_deep_dive',
      name: 'Research Deep Dive',
      description: 'Find, extract, and summarize deep market data.',
      steps: [
        PipelineStep(id: 'r1', agentType: MessageSender.researchAgent, instruction: 'Scan web for latest data on:'),
        PipelineStep(id: 'r2', agentType: MessageSender.extractorAgent, instruction: 'Extract structured facts as JSON.'),
        PipelineStep(id: 'r3', agentType: MessageSender.summarizerAgent, instruction: 'Synthesize findings into an exec summary.'),
      ],
    );
  }

  Pipeline _buildCreativeSprint() {
    return Pipeline(
      id: 'creative_sprint',
      name: 'Creative Sprint',
      description: 'Rapidly generate visuals and copy.',
      steps: [
        PipelineStep(id: 'c1', agentType: MessageSender.creativeAgent, instruction: 'Ideate visual concepts for:'),
        PipelineStep(id: 'c2', agentType: MessageSender.copywriterAgent, instruction: 'Write ad copy to match the visuals.'),
      ],
    );
  }

  void savePipeline(Pipeline pipeline) {
    state = [...state.where((p) => p.id != pipeline.id), pipeline];
  }

  void deletePipeline(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final pipelineProvider = StateNotifierProvider<PipelineNotifier, List<Pipeline>>((ref) => PipelineNotifier());
