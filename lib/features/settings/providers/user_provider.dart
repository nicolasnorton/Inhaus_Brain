import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';

/// Provider for current user profile
final currentUserProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});

/// Provider for user preferences
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  return UserPreferencesNotifier();
});

/// Provider for user workspaces
final userWorkspacesProvider =
    StateProvider<List<WorkspaceMembership>>((ref) {
  return _getMockWorkspaces();
});

/// Provider for current workspace
final currentWorkspaceProvider = StateProvider<String?>((ref) {
  final workspaces = ref.watch(userWorkspacesProvider);
  return workspaces.isNotEmpty ? workspaces.first.workspaceId : null;
});

/// State notifier for user profile
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(_getMockUser());

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updateAvatar(String? avatarUrl) {
    state = state.copyWith(avatarUrl: avatarUrl);
  }

  void linkAccount(LoginMethod method) {
    if (!state.linkedAccounts.contains(method)) {
      state = state.copyWith(
        linkedAccounts: [...state.linkedAccounts, method],
      );
    }
  }

  void unlinkAccount(LoginMethod method) {
    state = state.copyWith(
      linkedAccounts:
          state.linkedAccounts.where((a) => a != method).toList(),
    );
  }
}

/// State notifier for user preferences
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier() : super(const UserPreferences());

  void updateLanguage(Language language) {
    state = state.copyWith(language: language);
  }

  void updateVoiceLanguage(String voiceLanguage) {
    state = state.copyWith(voiceLanguage: voiceLanguage);
  }


  void toggleDarkMode() {
    state = state.copyWith(darkMode: !state.darkMode);
  }

  void toggleEmailNotifications() {
    state = state.copyWith(emailNotifications: !state.emailNotifications);
  }
}

/// Mock user for development
UserProfile _getMockUser() {
  return UserProfile(
    id: 'user-1',
    name: 'John Doe',
    email: 'john@example.com',
    avatarUrl: null,
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    linkedAccounts: [LoginMethod.google],
  );
}

/// Mock workspaces for development
List<WorkspaceMembership> _getMockWorkspaces() {
  return [
    WorkspaceMembership(
      workspaceId: 'ws-1',
      workspaceName: 'Inhaus Brain',
      role: UserRole.owner,
      joinedAt: DateTime.now().subtract(const Duration(days: 90)),
      lastAccessedAt: DateTime.now(),
    ),
    WorkspaceMembership(
      workspaceId: 'ws-2',
      workspaceName: 'Client Project',
      role: UserRole.editor,
      joinedAt: DateTime.now().subtract(const Duration(days: 30)),
      lastAccessedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    WorkspaceMembership(
      workspaceId: 'ws-3',
      workspaceName: 'Demo Workspace',
      role: UserRole.member,
      joinedAt: DateTime.now().subtract(const Duration(days: 7)),
      lastAccessedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
}
