import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workspace/providers/apps_provider.dart';
import '../../workspace/models/app_models.dart';
import 'workflow_canvas_screen.dart';
import 'app_setup_screen.dart';

class AppEditorDispatcherScreen extends ConsumerWidget {
  final String appId;
  const AppEditorDispatcherScreen({super.key, required this.appId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(appsProvider);
    final app = apps.cast<App?>().firstWhere((a) => a?.id == appId, orElse: () => null);

    if (app == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF111111),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              SizedBox(height: 16),
              Text('App not found', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    switch (app.type) {
      case AppType.workflow:
      case AppType.chatflow:
        return WorkflowCanvasScreen(pipelineId: app.id);
      case AppType.chatbot:
      case AppType.agent:
      case AppType.textGenerator:
        return AppSetupScreen(appId: app.id);
    }
  }
}
