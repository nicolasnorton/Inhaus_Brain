import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/campaigns/campaign_list_screen.dart';
import '../../features/campaigns/campaign_wizard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
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
            ],
          ),
          GoRoute(
            path: '/creative',
            builder: (context, state) => const Center(child: Text('Creative Studio - Coming Soon')),
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
