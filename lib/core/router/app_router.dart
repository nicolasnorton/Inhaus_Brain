import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/campaigns/campaign_list_screen.dart';
import '../../features/campaigns/campaign_wizard_screen.dart';
import '../../features/campaigns/campaign_detail_screen.dart';
import '../../features/creative/creative_studio_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

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
        builder: (context, state) => const LoginScreen(),
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
        ],
      ),
    ],
  );
});



