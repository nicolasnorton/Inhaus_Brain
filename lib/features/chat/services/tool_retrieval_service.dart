import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../assistant/services/assistant_tool_registry.dart';
import '../agents/router_agent.dart';

class ToolRetrievalService {
  final Ref _ref;

  ToolRetrievalService(this._ref);

  List<AgentTool> getToolsForIntent(RouterIntent intent) {
    final allTools = _ref.read(assistantToolRegistryProvider);
    
    // Define tool categories
    final Set<String> researchTools = {'extract_pdf', 'read_url'};
    final Set<String> creativeTools = {'image_generation', 'video_generation', 'create_campaign'}; // Add creative tools
    final Set<String> managementTools = {
      'create_client', 'update_client', 'create_project', 'create_task', 
      'navigate_to', 'create_campaign', 'create_knowledge_source',
      'read_url'
    };
    final Set<String> devTools = {'read_file', 'list_dir', 'grep_search'}; // Hypothetical dev tools
    final Set<String> seoTools = {'KeywordResearcher', 'CompetitorSEOAnalyzer', 'TechnicalAuditor', 'LocalSEOOptimizer', 'read_url', 'web_search'};
    final Set<String> aeoTools = {'AnswerIntentAnalyzer', 'SnippetOptimizer', 'SchemaGenerator', 'VoiceTester', 'read_url', 'web_search'};

    switch (intent) {
      case RouterIntent.research:
        return allTools.where((t) => researchTools.contains(t.name) || t.name == 'gen_ui_component').toList();
      case RouterIntent.creative:
      case RouterIntent.creativeImage:
      case RouterIntent.creativeVideo:
        return allTools.where((t) => creativeTools.contains(t.name) || t.name == 'image_generation' || t.name == 'video_generation' || t.name == 'gen_ui_component').toList();
      case RouterIntent.genUiReport:
        return allTools.where((t) => t.name == 'gen_ui_component' || researchTools.contains(t.name)).toList();
      case RouterIntent.management:
        return allTools.where((t) => managementTools.contains(t.name) || t.name == 'gen_ui_component').toList();
      case RouterIntent.development:
        return allTools.where((t) => devTools.contains(t.name) || t.name == 'gen_ui_component').toList();
      case RouterIntent.seo:
        return allTools.where((t) => seoTools.contains(t.name) || t.name == 'gen_ui_component').toList();
      case RouterIntent.aeo:
        return allTools.where((t) => aeoTools.contains(t.name) || t.name == 'gen_ui_component').toList();
      case RouterIntent.pipeline:
      case RouterIntent.directChat:
      default:
        // For general chat, provide a lightweight set or everything if small
        return allTools; 
    }
  }
}

final toolRetrievalServiceProvider = Provider<ToolRetrievalService>((ref) => ToolRetrievalService(ref));
