import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import 'package:inhaus_brain/core/tools/navigation_tools.dart';
import 'package:inhaus_brain/core/ucp/services/ucp_mcp_tool.dart';
import 'package:inhaus_brain/core/ucp/services/ucp_service.dart';
import 'package:inhaus_brain/features/clients/tools/client_tools.dart';
import 'package:inhaus_brain/features/workspace/tools/app_tools.dart';
import 'package:inhaus_brain/features/campaigns/tools/campaign_tools.dart';
import 'package:inhaus_brain/features/knowledge/tools/knowledge_tools.dart';
import 'package:inhaus_brain/core/tools/system_tools.dart';
import 'package:inhaus_brain/features/adk/tools/workflow_tools.dart';
import 'package:inhaus_brain/core/mcp/tools/image_generation_tool.dart';
import 'package:inhaus_brain/core/mcp/tools/video_generation_tool.dart';
import 'package:inhaus_brain/core/mcp/tools/audio_generation_tool.dart';
import 'package:inhaus_brain/core/tools/web_tools.dart';
import 'package:inhaus_brain/core/tools/gen_ui_tools.dart';
import 'package:inhaus_brain/core/tools/data_tools.dart';
import 'package:inhaus_brain/core/tools/research_tools.dart';
import 'package:inhaus_brain/core/tools/director_tools.dart';
import 'package:inhaus_brain/core/mcp/tools/stitch_tools.dart';
import 'package:inhaus_brain/core/mcp/tools/figma_tools.dart';
import 'package:inhaus_brain/core/config/feature_flags.dart';
import 'package:inhaus_brain/core/auth/secret_vault_service.dart';

import 'package:inhaus_brain/features/marketing/tools/seo_aeo_tools.dart';

/// Aggregates all available tools for the assistant
final assistantToolRegistryProvider = Provider<List<AgentTool>>((ref) {
  final navTools = ref.watch(navigationToolsProvider);
  final clientTools = ref.watch(clientToolsProvider);
  final appTools = ref.watch(appToolsProvider);
  final campaignTools = ref.watch(campaignToolsProvider);
  final knowledgeTools = ref.watch(knowledgeToolsProvider);
  final systemTools = ref.watch(systemToolsProvider);
  final workflowTools = ref.watch(workflowToolsProvider);
  final webTools = ref.watch(webToolsProvider);
  final dataTools = ref.watch(dataToolsProvider);
  final marketingTools = ref.watch(marketingToolsProvider);
  final researchTools = ref.watch(researchToolsProvider);

  // Generation Tools
  final aiKeysAsync = ref.watch(aiKeysProvider);
  final aiKeys = aiKeysAsync.value;
  final generationTools = [
    ImageGenerationTool(ref, imagenKey: aiKeys?.imagen, vertexKey: aiKeys?.vertex),
    VideoGenerationTool(ref, veoKey: aiKeys?.veo, vertexKey: aiKeys?.vertex),
    AudioGenerationTool(lyriaKey: aiKeys?.lyria),
  ];

  // Stitch Tools
  final stitchTools = FeatureFlags.enableStitch ? [
    StitchCreateProjectTool(ref),
    StitchListProjectsTool(ref),
    StitchGenerateScreenTool(ref),
    StitchGetScreenCodeTool(ref),
    StitchExtractDesignContextTool(ref),
    StitchBuildSiteTool(ref),
  ] : <AgentTool>[];
  
  // Figma Tools (M3)
  final figmaTools = FeatureFlags.enableFigmaIntegration ? [
    FigmaGetFileTool(ref),
    FigmaExportNodesTool(ref),
    FigmaListProjectsTool(ref),
    FigmaPostCommentTool(ref),
  ] : <AgentTool>[];

  // UCP Tools
  final ucpService = ref.watch(ucpServiceProvider);
  final ucpTools = [
    UCPDiscoverTool(ucpService),
    UCPCheckoutTool(ucpService),
    UCPListCategoriesTool(),
    UCPListParticipantsTool(ucpService),
  ];

  return [
    ...navTools,
    ...clientTools,
    ...appTools,
    ...campaignTools,
    ...knowledgeTools,
    ...systemTools,
    ...workflowTools,
    ...webTools,
    ...dataTools,
    ...marketingTools,
    ...generationTools,
    ...stitchTools,
    ...figmaTools,
    ...researchTools,
    ...ucpTools,
    DirectorTool(),
    GenUIComponentTool(),
  ];
});
