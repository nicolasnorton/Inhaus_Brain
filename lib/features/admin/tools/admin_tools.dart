import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mcp/agent_tool.dart';
import '../../../core/services/memory_service.dart';
import '../../monitor/services/monitor_api_service.dart';
import '../../monitor/models/monitor_models.dart';

final adminToolsProvider = Provider<List<AgentTool>>((ref) {
  return [
    AgentTool(
      name: 'read_global_memory',
      description: 'Reads the entire system memory (Super Admin scope). Use this to recall facts across ALL agents and users.',
      schema: {
        'type': 'object',
        'properties': {
          'limit': {'type': 'integer', 'description': 'Max number of memories to retrieve (default 50)'},
          'category': {'type': 'string', 'description': 'Optional filter by category'}
        }
      },
      execute: (args) async {
        try {
          // Note: Real filtering usually happens in DB, but getSuperAdminMemories currently fetches latest 100.
          // We'll rely on that for now.
          final memories = await ref.read(memoryServiceProvider).getSuperAdminMemories();
          
          if (memories.isEmpty) return ToolResult.success("No global memories found.");
          
          final limit = args['limit'] as int? ?? 50;
          final category = args['category'] as String?;
          
          var filtered = memories;
          if (category != null) {
            filtered = filtered.where((m) => m.category == category).toList();
          }
          filtered = filtered.take(limit).toList();

          final formatted = filtered.map((m) => 
            "[${m.createdAt.toIso8601String()}] (${m.category}) ${m.key}: ${m.value} [User: ${m.userId}]"
          ).join("\n");

          return ToolResult.success("Global System Memory:\n$formatted");
        } catch (e) {
          return ToolResult.error("Failed to read global memory: $e");
        }
      },
    ),
    AgentTool(
      name: 'read_system_logs',
      description: 'Reads the system kernel logs. Use this to debug system-wide issues or monitor agent performance.',
      schema: {
        'type': 'object',
        'properties': {
          'limit': {'type': 'integer', 'description': 'Max logs to retrieve'},
          'level': {'type': 'string', 'enum': ['info', 'warning', 'error'], 'description': 'Filter by log level'}
        }
      },
      execute: (args) async {
        try {
          final limit = args['limit'] as int? ?? 20;
          final levelStr = args['level'] as String?;
          final level = levelStr != null ? LogLevel.values.firstWhere((e) => e.name == levelStr) : null;

          final logs = await ref.read(monitorApiServiceProvider).getLogs(
            'system_kernel', // Virtual app ID for system
            level: level,
            scope: LogScope.system,
            limit: limit
          );

          if (logs.isEmpty) return ToolResult.success("No system logs found.");

          final formatted = logs.map((l) => 
            "[${l.timestamp.toIso8601String()}] [${l.level.name.toUpperCase()}] ${l.message}"
          ).join("\n");

          return ToolResult.success("System Logs:\n$formatted");
        } catch (e) {
          return ToolResult.error("Failed to read system logs: $e");
        }
      },
    ),
  ];
});
