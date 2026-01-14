import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Inhaus Brain'**
  String get appTitle;

  /// Title for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Personal Settings'**
  String get settingsTitle;

  /// Subtitle for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Manage your profile and preferences across all workspaces'**
  String get settingsSubtitle;

  /// Label for the Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// Label for the Preferences tab
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get tabPreferences;

  /// Label for the Security tab
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get tabSecurity;

  /// Label for profile picture section
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// Button text to upload a new picture
  ///
  /// In en, this message translates to:
  /// **'Upload New Picture'**
  String get uploadNewPicture;

  /// Snackbar message for avatar upload
  ///
  /// In en, this message translates to:
  /// **'Avatar upload coming soon'**
  String get uploadComingSoon;

  /// Label for name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Hint text for name field
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameHint;

  /// Error message for empty name
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameEmptyError;

  /// Label for email field
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// Hint text for email field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// Error message for invalid email
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalidError;

  /// Warning text about changing email
  ///
  /// In en, this message translates to:
  /// **'Changing your email affects all workspaces'**
  String get emailChangeWarning;

  /// Button text to save changes
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Snackbar message for successful profile update
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// Label for display language setting
  ///
  /// In en, this message translates to:
  /// **'Display Language'**
  String get displayLanguage;

  /// Snackbar message for language update
  ///
  /// In en, this message translates to:
  /// **'Language updated to {language}'**
  String languageUpdated(String language);

  /// Label for email notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// Subtitle for email notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Receive updates and alerts via email'**
  String get emailNotificationsSubtitle;

  /// Label for dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Subtitle for dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Use a high-contrast dark theme'**
  String get darkModeSubtitle;

  /// Header for developer settings
  ///
  /// In en, this message translates to:
  /// **'Developer Settings'**
  String get developerSettings;

  /// Label for mock AI models toggle
  ///
  /// In en, this message translates to:
  /// **'Mock AI Models'**
  String get mockAIModels;

  /// Subtitle for mock AI models toggle
  ///
  /// In en, this message translates to:
  /// **'Force all generative AI to use simulated edge mock for testing'**
  String get mockAIModelsSubtitle;

  /// Snackbar message for AI mock mode toggle
  ///
  /// In en, this message translates to:
  /// **'AI Mock Mode: {status}'**
  String aiMockMode(String status);

  /// Header for connected accounts section
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get connectedAccounts;

  /// Status text for connected account
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Status text for disconnected account
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// Button text to disconnect an account
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Button text to connect an account
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Snackbar message for account disconnection
  ///
  /// In en, this message translates to:
  /// **'{account} disconnected'**
  String accountDisconnected(String account);

  /// Snackbar message for account connection
  ///
  /// In en, this message translates to:
  /// **'{account} connected'**
  String accountConnected(String account);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
