import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/campaigns/campaign_list_screen.dart';
import '../../features/campaigns/campaign_wizard_screen.dart';
import '../../features/campaigns/campaign_detail_screen.dart';
import '../../features/creative/creative_studio_screen.dart';
import '../../features/campaigns/screens/camera_capture_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/settings/screens/personal_settings_screen.dart';
import '../../features/adk/screens/workflow_canvas_screen.dart';
import '../../features/adk/screens/workflow_start_screen.dart';
import '../../features/clients/client_management_screen.dart';
import '../../features/clients/screens/client_detail_screen.dart';
import '../../features/clients/screens/client_create_screen.dart';
import '../../features/knowledge/knowledge_management_screen.dart';
import '../../features/workspace/screens/model_providers_screen.dart';
import '../../features/workspace/screens/plugins_screen.dart';
import '../../features/workspace/screens/manage_apps_screen.dart';
import '../../features/workspace/screens/publish_dashboard_screen.dart';
import '../../features/adk/screens/debug_tools_screen.dart';
import '../../features/monitor/screens/logs_screen.dart';
import '../../features/adk/screens/app_editor_dispatcher_screen.dart';
import '../../features/adk/screens/run_history_screen.dart';
import '../../features/analytics/screens/analytics_monitor_screen.dart';
import '../../features/adk/screens/pipeline_builder_screen.dart';
import '../../core/auth/auth_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider).value;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return DashboardScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardHome(),
          ),
          GoRoute(
            path: '/campaigns',
            builder: (context, state) => const CampaignListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CampaignWizardScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => CampaignDetailScreen(
                  campaignId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/creative',
            builder: (context, state) => const CreativeStudioScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientManagementScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ClientCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ClientDetailScreen(
                  clientId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => AnalyticsMonitorScreen(
              appId: state.uri.queryParameters['appId'] ?? 'default-app',
            ),
          ),
          GoRoute(
            path: '/pipelines',
            builder: (context, state) => const PipelineBuilderScreen(),
          ),
          GoRoute(
            path: '/workflows',
            builder: (context, state) => const WorkflowStartScreen(),
          ),
          GoRoute(
            path: '/workflow-canvas',
            builder: (context, state) => WorkflowCanvasScreen(pipelineId: state.uri.queryParameters['id']),
          ),
          GoRoute(
            path: '/app-editor',
            builder: (context, state) => AppEditorDispatcherScreen(appId: state.uri.queryParameters['id']!),
          ),
          GoRoute(
            path: '/run-history/:appId',
            builder: (context, state) => RunHistoryScreen(appId: state.pathParameters['appId']!),
          ),
          GoRoute(
            path: '/publish',
            builder: (context, state) => PublishDashboardScreen(
              appId: state.uri.queryParameters['appId'] ?? 'default-app',
            ),
          ),
          GoRoute(
            path: '/debug',
            builder: (context, state) => const DebugToolsScreen(),
          ),
          GoRoute(
            path: '/knowledge',
            builder: (context, state) => const KnowledgeManagementScreen(),
          ),
          GoRoute(
            path: '/camera-capture',
            builder: (context, state) => const CameraCaptureScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const PersonalSettingsScreen(),
          ),
          GoRoute(
            path: '/workspace/model-providers',
            builder: (context, state) => const ModelProvidersScreen(),
          ),
          GoRoute(
            path: '/workspace/plugins',
            builder: (context, state) => const PluginsScreen(),
          ),
          GoRoute(
            path: '/workspace/apps',
            builder: (context, state) => const ManageAppsScreen(),
          ),
          GoRoute(
            path: '/monitor',
            builder: (context, state) => AnalyticsMonitorScreen(
              appId: state.uri.queryParameters['appId'] ?? 'default-app',
            ),
            routes: [
              GoRoute(
                path: 'logs',
                builder: (context, state) => LogsLayer(
                  appId: state.uri.queryParameters['appId'] ?? 'default-app',
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class LogsLayer extends StatelessWidget {
  final String appId;
  const LogsLayer({super.key, required this.appId});

  @override
  Widget build(BuildContext context) {
    return LogsScreen(appId: appId);
  }
}



