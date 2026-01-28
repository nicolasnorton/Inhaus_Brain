import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../monitor/screens/logs_screen.dart';
import '../../monitor/providers/monitor_provider.dart';
import '../../monitor/models/monitor_models.dart';
import '../../monitor/services/monitor_api_service.dart';

class SystemLogsScreen extends ConsumerWidget {
  const SystemLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We reuse the LogsScreen but might want to pre-filter or wrap it.
    // However, LogsScreen logic currently fetches based on appId.
    // We need to support fetching SYSTEM logs.
    // The LogsScreen expects 'appId'. 
    // We should refactor LogsScreen to accept a `LogScope` or create a new dedicated screen for System Logs.
    // For speed, let's create a dedicated simplified view here that uses the same provider logic but passes 'system' scope.
    
    // Actually, provider `appLogsProvider` takes `appId` string.
    // We can overload `appId` with a special string or refactor provider.
    // Let's refactor provider to be more flexible? Or just make a new one?
    // Let's make a new provider `systemLogsProvider` in this file for simplicity.
    
    final logsAsync = ref.watch(systemLogsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: AppBar(
        title: const Text('System Kernel Logs'),
        backgroundColor: const Color(0xFF0F1116),
      ),
      body: logsAsync.when(
        data: (logs) {
           if (logs.isEmpty) return const Center(child: Text('No system logs found.', style: TextStyle(color: Colors.white54)));
           return ListView.separated(
             separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
             itemCount: logs.length,
             itemBuilder: (context, index) {
               final log = logs[index];
               return ListTile(
                 title: Text(log.message, style: const TextStyle(color: Colors.white, fontSize: 13)),
                 subtitle: Text('${log.level.name.toUpperCase()} • ${log.timestamp}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                 leading: Icon(
                    Icons.terminal, 
                    color: log.level.name == 'error' ? Colors.red : Colors.green, 
                    size: 16
                 ),
               );
             },
           );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

// Local provider for system logs
final systemLogsProvider = FutureProvider((ref) async {
  final api = ref.read(monitorApiServiceProvider);
  // We need to update getLogs to accept Scope. I did update the Service, but likely not the Interface/Models fully if I missed something.
  // Wait, I updated `getLogs` signature in `MonitorApiService`.
  // `getLogs(String appId, {..., LogScope scope = LogScope.user})`
  // so I can pass a dummy appId and scope=system.
  
  return api.getLogs('system_kernel', scope: LogScope.system); 
});
