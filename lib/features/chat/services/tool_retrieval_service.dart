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
    final Set<String> researchTools = {'web_search', 'extract_pdf', 'read_url'};
    final Set<String> creativeTools = {'image_generation', 'video_generation', 'create_campaign'}; // Add creative tools
    final Set<String> managementTools = {
      'add_client', 'update_client', 'add_project', 'add_task', 
      'navigate_to', 'create_campaign', 'create_knowledge_source'
    };
    final Set<String> devTools = {'read_file', 'list_dir', 'grep_search'}; // Hypothetical dev tools

    switch (intent) {
      case RouterIntent.research:
        return allTools.where((t) => researchTools.contains(t.name)).toList();
      case RouterIntent.creative:
        return allTools.where((t) => creativeTools.contains(t.name)).toList();
      case RouterIntent.management:
        return allTools.where((t) => managementTools.contains(t.name)).toList();
      case RouterIntent.development:
        return allTools.where((t) => devTools.contains(t.name)).toList();
      case RouterIntent.pipeline:
      case RouterIntent.directChat:
      default:
        // For general chat, provide a lightweight set or everything if small
        return allTools; 
    }
  }
}

final toolRetrievalServiceProvider = Provider<ToolRetrievalService>((ref) => ToolRetrievalService(ref));
