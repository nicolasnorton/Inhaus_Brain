import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_settings_models.dart';

/// Provider for user settings
final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  return UserSettingsNotifier();
});

/// State notifier for user settings
class UserSettingsNotifier extends StateNotifier<UserSettings> {
  UserSettingsNotifier() : super(_getInitialSettings()) {
    // Migration Force Check on Boot
    if (state.preferredModelId == 'gemini-1.5-flash-001' || state.preferredModelId == 'gemini-1.5-flash') {
      state = state.copyWith(preferredModelId: 'gemini-1.5-flash');
    }
  }

  void updateProfile(UserProfile profile) {
    state = state.copyWith(profile: profile);
  }

  void updateTheme(ThemePreference theme) {
    state = state.copyWith(theme: theme);
  }

  void updateNotifications(NotificationSettings notifications) {
    state = state.copyWith(notifications: notifications);
  }

  void addApiKey(String name) {
    final newKey = WorkspaceApiKey(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      key: 'ih_${_generateRandomString(32)}',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(apiKeys: [...state.apiKeys, newKey]);
  }

  void deleteApiKey(String id) {
    state = state.copyWith(
      apiKeys: state.apiKeys.where((k) => k.id != id).toList(),
    );
  }

  static UserSettings _getInitialSettings() {
    return UserSettings(
      profile: const UserProfile(
        id: 'u1',
        name: 'John Doe',
        email: 'john@example.com',
        organization: 'Inhaus Corp',
        timezone: 'America/New_York',
      ),
      theme: ThemePreference.dark,
      notifications: const NotificationSettings(),
      apiKeys: [
        WorkspaceApiKey(
          id: 'k1',
          name: 'Default API Key',
          key: 'ih_********************************',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastUsed: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
    );
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[index % chars.length]).join();
  }
}
