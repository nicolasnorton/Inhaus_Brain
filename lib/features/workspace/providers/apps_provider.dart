import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';

/// Provider for all apps
final appsProvider = StateNotifierProvider<AppsNotifier, List<App>>((ref) {
  return AppsNotifier();
});

/// Provider for selected apps (multi-select)
final selectedAppsProvider = StateProvider<Set<String>>((ref) => {});

/// Provider for app view mode
final appViewModeProvider = StateProvider<AppViewMode>((ref) => AppViewMode.grid);

/// Provider for app filter
final appFilterProvider = StateProvider<AppFilter?>((ref) => null);

/// Provider for app sort
final appSortProvider = StateProvider<AppSortBy>((ref) => AppSortBy.updated);

/// Provider for filtered and sorted apps
final filteredAppsProvider = Provider<List<App>>((ref) {
  final apps = ref.watch(appsProvider);
  final filter = ref.watch(appFilterProvider);
  final sortBy = ref.watch(appSortProvider);

  var filtered = apps;

  // Apply filter
  if (filter != null) {
    filtered = filtered.where((app) => filter.matches(app)).toList();
  }

  // Apply sort
  filtered.sort((a, b) {
    switch (sortBy) {
      case AppSortBy.name:
        return a.name.compareTo(b.name);
      case AppSortBy.created:
        return b.createdAt.compareTo(a.createdAt);
      case AppSortBy.updated:
        return b.updatedAt.compareTo(a.updatedAt);
      case AppSortBy.runs:
        return b.runCount.compareTo(a.runCount);
    }
  });

  return filtered;
});

/// State notifier for apps
class AppsNotifier extends StateNotifier<List<App>> {
  AppsNotifier() : super(_getMockApps());

  /// Create a new app
  void createApp(App app) {
    state = [...state, app];
  }

  /// Update app info
  void updateApp(String appId, App updatedApp) {
    final index = state.indexWhere((app) => app.id == appId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        updatedApp.copyWith(updatedAt: DateTime.now()),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Duplicate an app
  void duplicateApp(String appId, String newName) {
    final original = state.firstWhere((app) => app.id == appId);
    final duplicate = original.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: newName,
      status: AppStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      runCount: 0,
    );
    state = [...state, duplicate];
  }

  /// Delete an app
  void deleteApp(String appId) {
    state = state.where((app) => app.id != appId).toList();
  }

  /// Archive an app
  void archiveApp(String appId) {
    final index = state.indexWhere((app) => app.id == appId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(
          status: AppStatus.archived,
          updatedAt: DateTime.now(),
        ),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Publish an app
  void publishApp(String appId) {
    final index = state.indexWhere((app) => app.id == appId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(
          status: AppStatus.published,
          updatedAt: DateTime.now(),
        ),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Import app from DSL
  void importApp(App app) {
    state = [...state, app];
  }
}

/// Mock apps for development
List<App> _getMockApps() {
  return [
    App(
      id: 'app-1',
      name: 'Translate Chatbot',
      type: AppType.chatbot,
      description: 'AI-powered translation assistant for multiple languages',
      icon: AppType.chatbot.icon,
      status: AppStatus.published,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      runCount: 1250,
      tags: ['translation', 'language', 'chatbot'],
      createdBy: 'John Doe',
    ),
    App(
      id: 'app-7',
      name: 'Support Chatflow',
      type: AppType.chatflow,
      description: 'Multi-turn support flow with complex logic',
      icon: AppType.chatflow.icon,
      status: AppStatus.published,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      runCount: 890,
      tags: ['support', 'chatflow'],
      createdBy: 'John Doe',
    ),
    App(
      id: 'app-2',
      name: 'Content Generator',
      type: AppType.workflow,
      description: 'Generate blog posts, articles, and social media content',
      icon: AppType.workflow.icon,
      status: AppStatus.draft,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      runCount: 45,
      tags: ['content', 'writing', 'blog'],
      createdBy: 'Jane Smith',
      hasUnsavedChanges: true,
    ),
    App(
      id: 'app-3',
      name: 'Customer Support Agent',
      type: AppType.agent,
      description: 'Automated customer support with knowledge base integration',
      icon: AppType.agent.icon,
      status: AppStatus.published,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      runCount: 3420,
      tags: ['support', 'customer service', 'agent'],
      createdBy: 'John Doe',
    ),
    App(
      id: 'app-4',
      name: 'Email Writer',
      type: AppType.textGenerator,
      description: 'Professional email composition assistant',
      icon: AppType.textGenerator.icon,
      status: AppStatus.published,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      runCount: 890,
      tags: ['email', 'writing', 'business'],
      createdBy: 'Jane Smith',
    ),
    App(
      id: 'app-5',
      name: 'Data Analysis Workflow',
      type: AppType.workflow,
      description: 'Automated data analysis and reporting pipeline',
      icon: AppType.workflow.icon,
      status: AppStatus.draft,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      runCount: 12,
      tags: ['data', 'analysis', 'reporting'],
      createdBy: 'John Doe',
    ),
    App(
      id: 'app-6',
      name: 'Code Review Assistant',
      type: AppType.agent,
      description: 'AI-powered code review and suggestions',
      icon: AppType.agent.icon,
      status: AppStatus.archived,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      runCount: 567,
      tags: ['code', 'review', 'development'],
      createdBy: 'Jane Smith',
    ),
  ];
}
