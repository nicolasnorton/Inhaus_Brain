
import 'package:uuid/uuid.dart';
import '../../../features/chat/models/chat_models.dart';
import '../models/pipeline_models.dart';

class DefaultPipelines {
  static final List<Pipeline> defaults = [
    Pipeline(
      id: 'campaign-strategy-v1',
      name: 'Comprehensive Campaign Strategy',
      description: 'End-to-end strategic planning involving Trend analysis, Strategy formation, and Account Director review.',
      steps: [
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.agent,
          agentType: MessageSender.trendScoutAgent,
          instruction: 'Analyze current market trends, competitor activities, and cultural shifts relevant to the client.',
          type: PipelineStepType.sequential,
        ),
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.agent,
          agentType: MessageSender.strategistAgent,
          instruction: 'Based on the trend analysis, develop a core "Big Idea" and strategic positioning for the campaign.',
          type: PipelineStepType.sequential,
        ),
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.agent,
          agentType: MessageSender.accountDirectorAgent,
          instruction: 'Review the strategy against client business objectives and format into a formal agency brief.',
          requiresApproval: true,
          type: PipelineStepType.sequential,
        ),
      ],
    ),
    Pipeline(
      id: 'creative-concept-v1',
      name: 'Creative Concept Development',
      description: 'Generates visual concepts with AI vision verification.',
      steps: [
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.agent,
          agentType: MessageSender.creativeAgent,
          instruction: 'Draft 3 initial visual concepts and a moodboard description based on the brief.',
          type: PipelineStepType.sequential,
        ),
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.agent,
          agentType: MessageSender.visionAgent,
          instruction: 'Analyze the proposed visual descriptions for feasibility and brand alignment.',
          type: PipelineStepType.sequential,
        ),
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.agent,
          agentType: MessageSender.creativeAgent,
          instruction: 'Refine the best concept into a final visual direction.',
          type: PipelineStepType.sequential,
        ),
      ],
    ),
    Pipeline(
      id: 'content-production-v1',
      name: 'Social Media Content Production',
      description: 'High-volume content creation with editorial oversight.',
      steps: [
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.agent,
          agentType: MessageSender.copywriterAgent,
          instruction: 'Draft 5 social media post variations (Caption + Visual Directive).',
          type: PipelineStepType.sequential,
        ),
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.agent,
          agentType: MessageSender.editorialManagerAgent,
          instruction: 'Review posts for tone, voice, and grammar. Approve or request edits.',
          requiresApproval: true,
          type: PipelineStepType.sequential,
        ),
      ],
    ),
    Pipeline(
      id: 'dialoglab-pitch-v1',
      name: 'Client Pitch Simulation',
      description: 'Simulates a client pitch with multiple AI characters and 3D avatars.',
      steps: [
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.dialogueScene,
          instruction: 'Initialize 3D conference room with Client and Strategist.',
          config: {
            'action': 'init',
            'personas': [
              {'id': 'client_ceo', 'name': 'CEO (Client)', 'role': 'Decision Maker'},
              {'id': 'agency_lead', 'name': 'Strategy Lead', 'role': 'Presenter'}
            ]
          },
        ),
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.agent,
          agentType: MessageSender.strategistAgent,
          instruction: 'Present the value proposition of the campaign.',
          type: PipelineStepType.sequential,
        ),
      ],
    ),
    Pipeline(
      id: 'flawless-campaign-demo-v1',
      name: 'Flawless Campaign Overhaul',
      description: 'The ultimate AI-driven campaign workflow: Deep Research -> AI Creative -> Production -> PDF Export.',
      steps: [
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.deepResearch,
          instruction: 'Conduct deep market research on the target industry and audience.',
          config: {
            'topic': 'Next-gen sustainable fashion trends 2026',
            'clientId': 'flawless_demo'
          },
        ),
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.imageGeneration,
          instruction: 'Generate high-fidelity key visuals using Gemini Nano Banana.',
          config: {
            'prompt': 'Futuristic sustainable storefront, emerald green and recycled glass aesthetic, photorealistic, 8k',
            'aspectRatio': '16:9'
          },
        ),
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.videoGeneration,
          instruction: 'Produce a 5-second cinematic product teaser using Veo 3.1.',
          config: {
            'prompt': 'Cinematic slow motion of recycled fabric flowing in the wind, studio lighting, luxurious texture',
            'model': 'veo_3_1'
          },
        ),
        PipelineStep(
          id: const Uuid().v4(),
          nodeType: WorkflowNodeType.agent,
          agentType: MessageSender.editorialManagerAgent,
          instruction: 'Verify consistency across all assets and finalize the research report.',
          requiresApproval: true,
        ),
      ],
    ),
  ];

}
