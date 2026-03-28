import '../../../../core/mcp/agent_tool.dart';
import 'brainweave_tools.dart';

/// The System of Brains Tool Registry
/// 
/// This provides the central nervous system capabilities (Memory, external CLI,
/// Workspace integrations) to all agents inheriting from BaseAgent.
class GlobalToolRegistry {
  /// The baseline tools granted to ALL domain agents (The 'Memory' layer)
  static List<AgentTool> get systemBaselineTools => [
        QueryBrainWeaveTool(),
        GetNodeContextTool(),
        CreateAtomicNodeTool(),
      ];

  /// The advanced orchestration tools granted to the Chief of Staff (Brian)
  /// and specific high-level agents.
  static List<AgentTool> get orchestrationTools => [
        // BrainWeave Graph Analytics
        ImpactAnalysisTool(),
        ClusterAnalysisTool(),
        GraphRagTool(),
        MeetingSyncTool(),
        
        // External MCP Integrations (Pending implementation)
        // FirebaseCliTool(),
        // GmailTool(),
        // DriveTool(),
        // CalendarTool(),
      ];
}
