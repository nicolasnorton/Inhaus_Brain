// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Inhaus Brain';

  @override
  String get settingsTitle => 'Personal Settings';

  @override
  String get settingsSubtitle =>
      'Manage your profile and preferences across all workspaces';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabPreferences => 'Preferences';

  @override
  String get tabSecurity => 'Security';

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get uploadNewPicture => 'Upload New Picture';

  @override
  String get uploadComingSoon => 'Avatar upload coming soon';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'Enter your name';

  @override
  String get nameEmptyError => 'Name cannot be empty';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get emailInvalidError => 'Invalid email';

  @override
  String get emailChangeWarning => 'Changing your email affects all workspaces';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get displayLanguage => 'Display Language';

  @override
  String languageUpdated(String language) {
    return 'Language updated to $language';
  }

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get emailNotificationsSubtitle =>
      'Receive updates and alerts via email';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Use a high-contrast dark theme';

  @override
  String get developerSettings => 'Developer Settings';

  @override
  String get mockAIModels => 'Mock AI Models';

  @override
  String get mockAIModelsSubtitle =>
      'Force all generative AI to use simulated edge mock for testing';

  @override
  String aiMockMode(String status) {
    return 'AI Mock Mode: $status';
  }

  @override
  String get connectedAccounts => 'Connected Accounts';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not connected';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connect => 'Connect';

  @override
  String accountDisconnected(String account) {
    return '$account disconnected';
  }

  @override
  String accountConnected(String account) {
    return '$account connected';
  }
}
