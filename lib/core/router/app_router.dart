import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/dashboard_home.dart';
import '../../features/campaigns/campaign_list_screen.dart';
import '../../features/campaigns/campaign_wizard_screen.dart';
import '../../features/campaigns/campaign_detail_screen.dart'; // Added
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/creative/creative_studio_screen.dart';
import '../../features/clients/client_management_screen.dart';
import '../../features/clients/screens/client_create_screen.dart';
import '../../features/clients/screens/client_detail_screen.dart';
import '../../features/clients/screens/client_edit_screen.dart';
import '../../features/analytics/screens/analytics_monitor_screen.dart'; // Ensure this exists
import '../../features/adk/screens/pipeline_builder_screen.dart';
import '../../features/adk/screens/workflow_start_screen.dart';
import '../../features/adk/screens/workflow_canvas_screen.dart';
import '../../features/adk/screens/app_editor_dispatcher_screen.dart';
import '../../features/adk/screens/run_history_screen.dart';
import '../../features/monitor/screens/logs_screen.dart';
import '../../features/workspace/screens/publish_dashboard_screen.dart';
import '../../features/adk/screens/debug_tools_screen.dart';
import '../../features/knowledge/knowledge_management_screen.dart';
import '../../features/reports/screens/reports_main_screen.dart';
import '../../features/reports/screens/report_detail_screen.dart';
import '../../features/campaigns/screens/camera_capture_screen.dart';
import '../../features/settings/screens/personal_settings_screen.dart';
import '../../features/settings/screens/user_secrets_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/system_secrets_screen.dart';
import '../../features/admin/screens/system_logs_screen.dart';
import '../../features/admin/screens/system_analytics_screen.dart';
import '../../features/admin/screens/super_copilot_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/audit_logs_screen.dart';
import '../../features/workspace/screens/model_providers_screen.dart';
import '../../features/workspace/screens/plugins_screen.dart';
import '../../features/workspace/screens/manage_apps_screen.dart';
import '../../features/copilot/presentation/copilot_view.dart';
import '../../core/auth/auth_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider).value;
  final onboardingCompleted = ref.watch(onboardingProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isOnboarding = state.uri.toString() == '/onboarding';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && !onboardingCompleted && !isOnboarding) return '/onboarding';
      if (isLoggedIn && isLoggingIn) return '/';
      
      // If completed but trying to go to onboarding, redirect home
      if (isLoggedIn && onboardingCompleted && isOnboarding) return '/';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const WelcomeScreen(),
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
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => ClientEditScreen(
                      clientId: state.pathParameters['id']!,
                    ),
                  ),
                ],
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
            path: '/reports',
            builder: (context, state) => const ReportsMainScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ReportDetailScreen(
                  reportId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/camera-capture',
            builder: (context, state) => const CameraCaptureScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const PersonalSettingsScreen(),
            routes: [
               GoRoute(
                path: 'secrets',
                builder: (context, state) => const UserSecretsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
            routes: [
               GoRoute(
                path: 'system-secrets',
                builder: (context, state) => const SystemSecretsScreen(),
              ),
              GoRoute(
                path: 'system-logs',
                builder: (context, state) => const SystemLogsScreen(),
              ),
              GoRoute(
                path: 'system-analytics',
                builder: (context, state) => const SystemAnalyticsScreen(),
              ),
              GoRoute(
                path: 'super-copilot',
                builder: (context, state) => const SuperCopilotScreen(),
              ),
              GoRoute(
                path: 'users',
                builder: (context, state) => const UserManagementScreen(),
              ),
              GoRoute(
                path: 'audit-logs',
                builder: (context, state) => const AuditLogsScreen(),
              ),
            ],
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
          GoRoute(
            path: '/copilot',
            builder: (context, state) => const CopilotView(),
          ),
          // Fallback routes for GenUI components if Assistant navigates
          GoRoute(
            path: '/kanban',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Project Board')),
              body: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Interact with the Assistant to populate this board.')),
              ),
            ),
          ),
          GoRoute(
            path: '/budget',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Budget Overview')),
              body: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Interact with the Assistant to visualize budget data.')),
              ),
            ),
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



