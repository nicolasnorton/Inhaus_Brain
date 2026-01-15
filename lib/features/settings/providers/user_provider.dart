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
  return []; // Production defaults to empty
});

/// Provider for current workspace
final currentWorkspaceProvider = StateProvider<String?>((ref) {
  final workspaces = ref.watch(userWorkspacesProvider);
  return workspaces.isNotEmpty ? workspaces.first.workspaceId : null;
});

/// State notifier for user profile
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile(
    id: '', 
    name: 'User', 
    email: '', 
    createdAt: DateTime.now(), 
    linkedAccounts: []
  ));

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
