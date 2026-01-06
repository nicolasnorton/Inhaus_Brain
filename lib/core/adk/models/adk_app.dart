import '../../../../features/chat/agents/base_agent.dart';
import '../../mcp/agent_tool.dart';

/// Represents a specialized application built on the ADK.
/// Bundles specific agents and tools for a domain (e.g., "MarketingWizard").
class AdkApp {
  final String id;
  final String name;
  final String description;
  final List<BaseAgent> agents;
  final List<AgentTool> globalTools;
  final String icon;

  AdkApp({
    required this.id,
    required this.name,
    required this.description,
    required this.agents,
    this.globalTools = const [],
    this.icon = 'apps',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'agentNames': agents.map((a) => a.name).toList(),
        'icon': icon,
      };
}
