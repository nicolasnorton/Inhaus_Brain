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
import '../../features/settings/profile_settings_screen.dart';
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
            path: '/analytics',
            builder: (context, state) => const Center(child: Text('Analytics - Coming Soon')),
          ),
          GoRoute(
            path: '/camera-capture',
            builder: (context, state) => const CameraCaptureScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const ProfileSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});



