import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mcp/agent_tool.dart';
import '../../../core/services/memory_service.dart';
import '../../monitor/services/monitor_api_service.dart';
import '../../monitor/models/monitor_models.dart';
import '../../monitor/providers/monitor_provider.dart';

class ReadGlobalMemoryTool extends AgentTool {
  final MemoryService _memoryService;

  ReadGlobalMemoryTool(this._memoryService)
      : super(
          name: 'read_global_memory',
          description: 'Reads the entire system memory (Super Admin scope). Use this to recall facts across ALL agents and users.',
          inputSchema: {
            'limit': {'type': 'integer', 'description': 'Max number of memories to retrieve (default 50)'},
            'category': {'type': 'string', 'description': 'Optional filter by category'}
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final memories = await _memoryService.getSuperAdminMemories();

      if (memories.isEmpty) {
        return ToolResult.success({'content': "No global memories found."});
      }

      final limit = parameters['limit'] as int? ?? 50;
      final category = parameters['category'] as String?;

      var filtered = memories;
      if (category != null) {
        filtered = filtered.where((m) => m.category == category).toList();
      }
      filtered = filtered.take(limit).toList();

      final formatted = filtered
          .map((m) =>
              "[${m.createdAt.toIso8601String()}] (${m.category}) ${m.key}: ${m.value} [User: ${m.userId}]")
          .join("\n");

      return ToolResult.success({'content': "Global System Memory:\n$formatted"});
    } catch (e) {
      return ToolResult.failure("Failed to read global memory: $e");
    }
  }
}

class ReadSystemLogsTool extends AgentTool {
  final MonitorApiService _monitorService;

  ReadSystemLogsTool(this._monitorService)
      : super(
          name: 'read_system_logs',
          description: 'Reads the system kernel logs. Use this to debug system-wide issues or monitor agent performance.',
          inputSchema: {
            'limit': {'type': 'integer', 'description': 'Max logs to retrieve'},
            'level': {'type': 'string', 'enum': ['info', 'warning', 'error'], 'description': 'Filter by log level'}
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final limit = parameters['limit'] as int? ?? 20;
      final levelStr = parameters['level'] as String?;
      final level = levelStr != null ? LogLevel.values.firstWhere((e) => e.name == levelStr) : null;

      final logs = await _monitorService.getLogs(
        'system_kernel', // Virtual app ID for system
        level: level,
        scope: LogScope.system,
        limit: limit,
      );

      if (logs.isEmpty) {
        return ToolResult.success({'content': "No system logs found."});
      }

      final formatted = logs
          .map((l) =>
              "[${l.timestamp.toIso8601String()}] [${l.level.name.toUpperCase()}] ${l.message}")
          .join("\n");

      return ToolResult.success({'content': "System Logs:\n$formatted"});
    } catch (e) {
      return ToolResult.failure("Failed to read system logs: $e");
    }
  }
}

final adminToolsProvider = Provider<List<AgentTool>>((ref) {
  final memoryService = ref.watch(memoryServiceProvider);
  final monitorService = ref.watch(monitorApiServiceProvider);

  return [
    ReadGlobalMemoryTool(memoryService),
    ReadSystemLogsTool(monitorService),
  ];
});
