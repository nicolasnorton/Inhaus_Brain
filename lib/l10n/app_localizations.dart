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

  /// No description provided for @nodeStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get nodeStart;

  /// No description provided for @nodeEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get nodeEnd;

  /// No description provided for @nodeFunction.
  ///
  /// In en, this message translates to:
  /// **'Function'**
  String get nodeFunction;

  /// No description provided for @nodeParallel.
  ///
  /// In en, this message translates to:
  /// **'Parallel'**
  String get nodeParallel;

  /// No description provided for @nodeCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get nodeCondition;

  /// No description provided for @moduleClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get moduleClient;

  /// No description provided for @moduleCampaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get moduleCampaign;

  /// No description provided for @mockAIModels.
  ///
  /// In en, this message translates to:
  /// **'Mock AI Models'**
  String get mockAIModels;

  /// No description provided for @mockAIModelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use simulated responses for testing'**
  String get mockAIModelsSubtitle;

  /// No description provided for @aiMockMode.
  ///
  /// In en, this message translates to:
  /// **'AI Mock Mode: {status}'**
  String aiMockMode(Object status);

  /// No description provided for @connectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get connectedAccounts;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get notConnected;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @accountDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from {account}'**
  String accountDisconnected(Object account);

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @accountConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to {account}'**
  String accountConnected(Object account);

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameHint;

  /// No description provided for @nameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameEmptyError;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @emailInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailInvalidError;

  /// No description provided for @emailChangeWarning.
  ///
  /// In en, this message translates to:
  /// **'Note: Changing email may require re-verification'**
  String get emailChangeWarning;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @displayLanguage.
  ///
  /// In en, this message translates to:
  /// **'Display Language'**
  String get displayLanguage;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageUpdated(Object language);

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @emailNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive updates and alerts via email'**
  String get emailNotificationsSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme for the application'**
  String get darkModeSubtitle;

  /// No description provided for @developerSettings.
  ///
  /// In en, this message translates to:
  /// **'Developer Settings'**
  String get developerSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile and preferences'**
  String get settingsSubtitle;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get tabPreferences;

  /// No description provided for @tabSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get tabSecurity;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @uploadNewPicture.
  ///
  /// In en, this message translates to:
  /// **'Upload New Picture'**
  String get uploadNewPicture;

  /// No description provided for @uploadComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Upload feature coming soon'**
  String get uploadComingSoon;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get navClients;

  /// No description provided for @navCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get navCampaigns;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navWorkflows.
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get navWorkflows;

  /// No description provided for @navPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get navPublish;

  /// No description provided for @navKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get navKnowledge;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get navDebug;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String welcomeBack(String name);

  /// No description provided for @readyForCampaign.
  ///
  /// In en, this message translates to:
  /// **'Inhaus Brain is ready for your next campaign.'**
  String get readyForCampaign;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @loggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Logged in as {role}'**
  String loggedInAs(String role);

  /// No description provided for @campaignsTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get campaignsTitle;

  /// No description provided for @creativeStudio.
  ///
  /// In en, this message translates to:
  /// **'Creative Studio'**
  String get creativeStudio;

  /// No description provided for @newCampaign.
  ///
  /// In en, this message translates to:
  /// **'New Campaign'**
  String get newCampaign;

  /// No description provided for @noActiveCampaigns.
  ///
  /// In en, this message translates to:
  /// **'No Active Campaigns'**
  String get noActiveCampaigns;

  /// No description provided for @createNewCampaign.
  ///
  /// In en, this message translates to:
  /// **'Create New Campaign'**
  String get createNewCampaign;

  /// No description provided for @noClient.
  ///
  /// In en, this message translates to:
  /// **'No Client'**
  String get noClient;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdOn(String date);

  /// No description provided for @statusResearching.
  ///
  /// In en, this message translates to:
  /// **'Researching'**
  String get statusResearching;

  /// No description provided for @statusDesigning.
  ///
  /// In en, this message translates to:
  /// **'Designing'**
  String get statusDesigning;

  /// No description provided for @statusInProduction.
  ///
  /// In en, this message translates to:
  /// **'In Production'**
  String get statusInProduction;

  /// No description provided for @statusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get statusPublished;

  /// No description provided for @researchWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Research Workshop'**
  String get researchWorkshop;

  /// No description provided for @campaignBrief.
  ///
  /// In en, this message translates to:
  /// **'Campaign Brief'**
  String get campaignBrief;

  /// No description provided for @tellAgentGoals.
  ///
  /// In en, this message translates to:
  /// **'Tell the AI Agent what you want to achieve.'**
  String get tellAgentGoals;

  /// No description provided for @campaignTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaign Title'**
  String get campaignTitle;

  /// No description provided for @campaignTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Summer Collection 2026'**
  String get campaignTitleHint;

  /// No description provided for @clientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientNameLabel;

  /// No description provided for @clientNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Acme Corp'**
  String get clientNameHint;

  /// No description provided for @detailedBrief.
  ///
  /// In en, this message translates to:
  /// **'Detailed Brief'**
  String get detailedBrief;

  /// No description provided for @detailedBriefHint.
  ///
  /// In en, this message translates to:
  /// **'Describe goals, target audience, and key messages...'**
  String get detailedBriefHint;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @startResearchChat.
  ///
  /// In en, this message translates to:
  /// **'Start Research Chat'**
  String get startResearchChat;

  /// No description provided for @confirmStrategyCreate.
  ///
  /// In en, this message translates to:
  /// **'Confirm Strategy & Create Campaign'**
  String get confirmStrategyCreate;

  /// Initial message to AI when starting a campaign
  ///
  /// In en, this message translates to:
  /// **'I want to start a new campaign: {title}. Brief: {description}'**
  String startNewCampaignMsg(String title, String description);

  /// No description provided for @agentResearchInsights.
  ///
  /// In en, this message translates to:
  /// **'Agent Research Insights'**
  String get agentResearchInsights;

  /// No description provided for @reviewApproveInsights.
  ///
  /// In en, this message translates to:
  /// **'Review and approve insights gathered by the Research Agent.'**
  String get reviewApproveInsights;

  /// No description provided for @proceedToDesignPlan.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Design Plan'**
  String get proceedToDesignPlan;

  /// No description provided for @campaignStrategyBrief.
  ///
  /// In en, this message translates to:
  /// **'Campaign Strategy Brief'**
  String get campaignStrategyBrief;

  /// No description provided for @clientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client:'**
  String get clientLabel;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @designPhaseActive.
  ///
  /// In en, this message translates to:
  /// **'Design Phase Active'**
  String get designPhaseActive;

  /// No description provided for @creativeProposedDirections.
  ///
  /// In en, this message translates to:
  /// **'The Creative Agent has proposed visual directions for this campaign.'**
  String get creativeProposedDirections;

  /// No description provided for @openCreativeStudio.
  ///
  /// In en, this message translates to:
  /// **'Open Creative Studio'**
  String get openCreativeStudio;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @proposeNewConcept.
  ///
  /// In en, this message translates to:
  /// **'Propose New Concept'**
  String get proposeNewConcept;

  /// No description provided for @noCreativeConceptsYet.
  ///
  /// In en, this message translates to:
  /// **'No creative concepts yet.'**
  String get noCreativeConceptsYet;

  /// No description provided for @completeResearchApprovalMsg.
  ///
  /// In en, this message translates to:
  /// **'Complete a campaign research approval to trigger the Design Agent.'**
  String get completeResearchApprovalMsg;

  /// No description provided for @designFeedback.
  ///
  /// In en, this message translates to:
  /// **'DESIGN FEEDBACK'**
  String get designFeedback;

  /// No description provided for @campaignIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Campaign ID: {id}'**
  String campaignIdLabel(String id);

  /// No description provided for @copyProposition.
  ///
  /// In en, this message translates to:
  /// **'Copy Proposition'**
  String get copyProposition;

  /// No description provided for @visualStrategyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Visual Strategy Prompt'**
  String get visualStrategyPrompt;

  /// No description provided for @finalProductionAssets.
  ///
  /// In en, this message translates to:
  /// **'Final Production Assets'**
  String get finalProductionAssets;

  /// No description provided for @generateHighTierAssets.
  ///
  /// In en, this message translates to:
  /// **'Generate High-Tier Assets'**
  String get generateHighTierAssets;

  /// No description provided for @finalHighFidelityCopy.
  ///
  /// In en, this message translates to:
  /// **'Final High-Fidelity Copy (Vertex AI)'**
  String get finalHighFidelityCopy;

  /// No description provided for @finalVisualMock.
  ///
  /// In en, this message translates to:
  /// **'Final Visual Mock (Imagen-3)'**
  String get finalVisualMock;

  /// No description provided for @conceptApprovedReadyProduction.
  ///
  /// In en, this message translates to:
  /// **'Concept approved. Ready for high-fidelity production.'**
  String get conceptApprovedReadyProduction;

  /// No description provided for @styleBoards.
  ///
  /// In en, this message translates to:
  /// **'Style Boards'**
  String get styleBoards;

  /// No description provided for @suggestedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Suggested'**
  String suggestedCount(int count);

  /// No description provided for @clientModule.
  ///
  /// In en, this message translates to:
  /// **'CLIENT MODULE'**
  String get clientModule;

  /// No description provided for @portfolioManagement.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Management'**
  String get portfolioManagement;

  /// No description provided for @addClient.
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get addClient;

  /// No description provided for @noClientsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No clients configured yet.'**
  String get noClientsConfigured;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @approveInsight.
  ///
  /// In en, this message translates to:
  /// **'Approve Insight'**
  String get approveInsight;

  /// No description provided for @designConcept.
  ///
  /// In en, this message translates to:
  /// **'DESIGN CONCEPT'**
  String get designConcept;

  /// No description provided for @campaignsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'CAMPAIGNS'**
  String get campaignsCountLabel;

  /// No description provided for @manageClient.
  ///
  /// In en, this message translates to:
  /// **'Manage Client'**
  String get manageClient;

  /// No description provided for @addNewClient.
  ///
  /// In en, this message translates to:
  /// **'Add New Client'**
  String get addNewClient;

  /// No description provided for @industryLabel.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get industryLabel;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get contactEmail;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @primaryContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Primary Contact Email'**
  String get primaryContactEmail;

  /// No description provided for @createClient.
  ///
  /// In en, this message translates to:
  /// **'Create Client'**
  String get createClient;

  /// No description provided for @clientNotFound.
  ///
  /// In en, this message translates to:
  /// **'Client Not Found'**
  String get clientNotFound;

  /// No description provided for @clientNotFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'The requested client could not be found.'**
  String get clientNotFoundMsg;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get tabContacts;

  /// No description provided for @tabProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get tabProjects;

  /// No description provided for @tabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// No description provided for @tabIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get tabIntegrations;

  /// No description provided for @tabUCP.
  ///
  /// In en, this message translates to:
  /// **'UCP Commerce'**
  String get tabUCP;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @industryLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get industryLabelShort;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// No description provided for @primaryContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Contact'**
  String get primaryContactLabel;

  /// No description provided for @performanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Performance Summary'**
  String get performanceSummary;

  /// No description provided for @activeCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Active Campaigns'**
  String get activeCampaigns;

  /// No description provided for @totalProjects.
  ///
  /// In en, this message translates to:
  /// **'Total Projects'**
  String get totalProjects;

  /// No description provided for @clientContacts.
  ///
  /// In en, this message translates to:
  /// **'Client Contacts'**
  String get clientContacts;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @noContactsAdded.
  ///
  /// In en, this message translates to:
  /// **'No contacts added yet.'**
  String get noContactsAdded;

  /// No description provided for @clientProjects.
  ///
  /// In en, this message translates to:
  /// **'Client Projects'**
  String get clientProjects;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @activeTasksLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Tasks'**
  String get activeTasksLabel;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @connectThirdPartyTools.
  ///
  /// In en, this message translates to:
  /// **'Connect Third-Party Tools'**
  String get connectThirdPartyTools;

  /// No description provided for @authorizeInhausBrainMsg.
  ///
  /// In en, this message translates to:
  /// **'Authorize Inhaus Brain to access data from these platforms.'**
  String get authorizeInhausBrainMsg;

  /// No description provided for @ucpTitle.
  ///
  /// In en, this message translates to:
  /// **'Universal Commerce Protocol (UCP)'**
  String get ucpTitle;

  /// No description provided for @ucpSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Seamless agentic commerce integration.'**
  String get ucpSubTitle;

  /// No description provided for @ucpStatusActive.
  ///
  /// In en, this message translates to:
  /// **'UCP Status: Active'**
  String get ucpStatusActive;

  /// No description provided for @discoveryServiceOnline.
  ///
  /// In en, this message translates to:
  /// **'Discovery Service: Online'**
  String get discoveryServiceOnline;

  /// No description provided for @discoverBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Discover Businesses'**
  String get discoverBusinesses;

  /// No description provided for @connectedCommerceAgents.
  ///
  /// In en, this message translates to:
  /// **'Connected Commerce Agents'**
  String get connectedCommerceAgents;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'Add Project'**
  String get addProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @createLabel.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createLabel;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitle;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// No description provided for @statusPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get statusPlanning;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get statusTodo;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @projectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project Not Found'**
  String get projectNotFound;

  /// No description provided for @projectNotFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'Project not found.'**
  String get projectNotFoundMsg;

  /// No description provided for @switchToListView.
  ///
  /// In en, this message translates to:
  /// **'Switch to List View'**
  String get switchToListView;

  /// No description provided for @switchToBoardView.
  ///
  /// In en, this message translates to:
  /// **'Switch to Board View'**
  String get switchToBoardView;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @operationsCenter.
  ///
  /// In en, this message translates to:
  /// **'Operations Center'**
  String get operationsCenter;

  /// No description provided for @secGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get secGeneral;

  /// No description provided for @secAgentBrain.
  ///
  /// In en, this message translates to:
  /// **'Agent Brain'**
  String get secAgentBrain;

  /// No description provided for @secAIModels.
  ///
  /// In en, this message translates to:
  /// **'AI Models'**
  String get secAIModels;

  /// No description provided for @secConnectors.
  ///
  /// In en, this message translates to:
  /// **'Connectors'**
  String get secConnectors;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'PROFILE & ACCOUNT'**
  String get profileAccount;

  /// No description provided for @profileAccountSub.
  ///
  /// In en, this message translates to:
  /// **'Manage your identity and access levels.'**
  String get profileAccountSub;

  /// No description provided for @agentBrainTitle.
  ///
  /// In en, this message translates to:
  /// **'AGENT BRAIN (MASTER PROMPTS)'**
  String get agentBrainTitle;

  /// No description provided for @agentBrainSub.
  ///
  /// In en, this message translates to:
  /// **'Configure the behavior, persona, and workflows for your workforce.'**
  String get agentBrainSub;

  /// No description provided for @agentStudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent Studio'**
  String get agentStudioTitle;

  /// No description provided for @agentStudioSub.
  ///
  /// In en, this message translates to:
  /// **'Access the advanced configuration panel to tune System Prompts, manage Pipeline connections, and configure tools for Campaign & Creative agents.'**
  String get agentStudioSub;

  /// No description provided for @launchAgentStudio.
  ///
  /// In en, this message translates to:
  /// **'Launch Agent Studio'**
  String get launchAgentStudio;

  /// No description provided for @aiModelVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'AI MODEL VAULT'**
  String get aiModelVaultTitle;

  /// No description provided for @aiModelVaultSub.
  ///
  /// In en, this message translates to:
  /// **'Securely store API keys for external providers. Keys never leave your device.'**
  String get aiModelVaultSub;

  /// No description provided for @saveKeysLabel.
  ///
  /// In en, this message translates to:
  /// **'Save Keys'**
  String get saveKeysLabel;

  /// No description provided for @toolConnectorsTitle.
  ///
  /// In en, this message translates to:
  /// **'TOOL CONNECTORS'**
  String get toolConnectorsTitle;

  /// No description provided for @toolConnectorsSub.
  ///
  /// In en, this message translates to:
  /// **'Integrate third-party services into your workflow.'**
  String get toolConnectorsSub;

  /// No description provided for @teamAccessRoles.
  ///
  /// In en, this message translates to:
  /// **'TEAM ACCESS & ROLES'**
  String get teamAccessRoles;

  /// No description provided for @systemRole.
  ///
  /// In en, this message translates to:
  /// **'System Role'**
  String get systemRole;

  /// No description provided for @assignedClients.
  ///
  /// In en, this message translates to:
  /// **'Assigned Clients'**
  String get assignedClients;

  /// No description provided for @saveAccessLevels.
  ///
  /// In en, this message translates to:
  /// **'Save Access Levels'**
  String get saveAccessLevels;

  /// No description provided for @keysSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Keys securely saved to Vault.'**
  String get keysSavedMsg;

  /// No description provided for @promptsUpdatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Master Prompts updated.'**
  String get promptsUpdatedMsg;

  /// No description provided for @profileUpdatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdatedMsg;

  /// No description provided for @pleaseLoginManage.
  ///
  /// In en, this message translates to:
  /// **'Please log in to manage settings.'**
  String get pleaseLoginManage;

  /// No description provided for @enterAgentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter agent instructions...'**
  String get enterAgentInstructions;

  /// No description provided for @enterApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter API Key...'**
  String get enterApiKey;

  /// No description provided for @unnamedUser.
  ///
  /// In en, this message translates to:
  /// **'Unnamed User'**
  String get unnamedUser;

  /// No description provided for @noClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found.'**
  String get noClientsFound;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @workspaceInfrastructure.
  ///
  /// In en, this message translates to:
  /// **'Workspace Infrastructure'**
  String get workspaceInfrastructure;

  /// No description provided for @modelProviders.
  ///
  /// In en, this message translates to:
  /// **'Model Providers'**
  String get modelProviders;

  /// No description provided for @modelProvidersSub.
  ///
  /// In en, this message translates to:
  /// **'Configure LLM and image generation keys'**
  String get modelProvidersSub;

  /// No description provided for @pluginsTools.
  ///
  /// In en, this message translates to:
  /// **'Plugins & Tools'**
  String get pluginsTools;

  /// No description provided for @pluginsToolsSub.
  ///
  /// In en, this message translates to:
  /// **'Connect external tools and MCP servers'**
  String get pluginsToolsSub;

  /// No description provided for @manageApps.
  ///
  /// In en, this message translates to:
  /// **'Manage Apps'**
  String get manageApps;

  /// No description provided for @manageAppsSub.
  ///
  /// In en, this message translates to:
  /// **'Deploy and organize your micro-apps'**
  String get manageAppsSub;

  /// No description provided for @analyticsMonitor.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Monitor'**
  String get analyticsMonitor;

  /// No description provided for @tabBusinessAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Business Analytics'**
  String get tabBusinessAnalytics;

  /// No description provided for @tabSystemMonitor.
  ///
  /// In en, this message translates to:
  /// **'System Monitor'**
  String get tabSystemMonitor;

  /// No description provided for @campaignPerformance.
  ///
  /// In en, this message translates to:
  /// **'Campaign Performance'**
  String get campaignPerformance;

  /// No description provided for @conversionOverTime.
  ///
  /// In en, this message translates to:
  /// **'Conversion over Time'**
  String get conversionOverTime;

  /// No description provided for @historicalDataAggregated.
  ///
  /// In en, this message translates to:
  /// **'Historical data being aggregated...'**
  String get historicalDataAggregated;

  /// No description provided for @statROI.
  ///
  /// In en, this message translates to:
  /// **'ROI'**
  String get statROI;

  /// No description provided for @statConversion.
  ///
  /// In en, this message translates to:
  /// **'Conversion'**
  String get statConversion;

  /// No description provided for @statCPA.
  ///
  /// In en, this message translates to:
  /// **'CPA'**
  String get statCPA;

  /// No description provided for @monitorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Monitor Dashboard'**
  String get monitorDashboard;

  /// No description provided for @statStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statStatistics;

  /// No description provided for @quickLogs.
  ///
  /// In en, this message translates to:
  /// **'Quick Logs'**
  String get quickLogs;

  /// No description provided for @viewAllLogs.
  ///
  /// In en, this message translates to:
  /// **'View All Logs'**
  String get viewAllLogs;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @totalMessages.
  ///
  /// In en, this message translates to:
  /// **'Total Messages'**
  String get totalMessages;

  /// No description provided for @activeUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsers;

  /// No description provided for @avgInteractions.
  ///
  /// In en, this message translates to:
  /// **'Avg. Interactions'**
  String get avgInteractions;

  /// No description provided for @tokenUsage.
  ///
  /// In en, this message translates to:
  /// **'Token Usage'**
  String get tokenUsage;

  /// No description provided for @tracingAppPerformance.
  ///
  /// In en, this message translates to:
  /// **'Tracing app performance'**
  String get tracingAppPerformance;

  /// No description provided for @tracingIntegration.
  ///
  /// In en, this message translates to:
  /// **'Tracing Integration'**
  String get tracingIntegration;

  /// No description provided for @connectExternalTracingMsg.
  ///
  /// In en, this message translates to:
  /// **'Connect external tracing providers to monitor agent performance.'**
  String get connectExternalTracingMsg;

  /// No description provided for @connectedToMsg.
  ///
  /// In en, this message translates to:
  /// **'Connected to {name} (Mock)'**
  String connectedToMsg(String name);

  /// No description provided for @statConvVolume.
  ///
  /// In en, this message translates to:
  /// **'Conversation volume'**
  String get statConvVolume;

  /// No description provided for @statMeaningfulExchange.
  ///
  /// In en, this message translates to:
  /// **'>1 meaningful exchange'**
  String get statMeaningfulExchange;

  /// No description provided for @statEngagementDepth.
  ///
  /// In en, this message translates to:
  /// **'Engagement depth'**
  String get statEngagementDepth;

  /// No description provided for @statResourceConsumption.
  ///
  /// In en, this message translates to:
  /// **'Resource consumption'**
  String get statResourceConsumption;

  /// No description provided for @knowledgeModule.
  ///
  /// In en, this message translates to:
  /// **'KNOWLEDGE'**
  String get knowledgeModule;

  /// No description provided for @createKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Create Knowledge'**
  String get createKnowledge;

  /// No description provided for @quickCreate.
  ///
  /// In en, this message translates to:
  /// **'Quick Create'**
  String get quickCreate;

  /// No description provided for @knowledgePipeline.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Pipeline'**
  String get knowledgePipeline;

  /// No description provided for @authorizeDataSource.
  ///
  /// In en, this message translates to:
  /// **'Authorize Data Source'**
  String get authorizeDataSource;

  /// No description provided for @connectToExternal.
  ///
  /// In en, this message translates to:
  /// **'Connect to External'**
  String get connectToExternal;

  /// No description provided for @externalBase.
  ///
  /// In en, this message translates to:
  /// **'External Base'**
  String get externalBase;

  /// No description provided for @apiReference.
  ///
  /// In en, this message translates to:
  /// **'API Reference'**
  String get apiReference;

  /// No description provided for @manageKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Manage Knowledge'**
  String get manageKnowledge;

  /// No description provided for @contentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get contentLabel;

  /// No description provided for @metadataLabel.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadataLabel;

  /// No description provided for @testRetrieval.
  ///
  /// In en, this message translates to:
  /// **'Test Retrieval'**
  String get testRetrieval;

  /// No description provided for @integrateApps.
  ///
  /// In en, this message translates to:
  /// **'Integrate within Apps'**
  String get integrateApps;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @kbDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get kbDocuments;

  /// No description provided for @kbRetrievalTest.
  ///
  /// In en, this message translates to:
  /// **'Retrieval Test'**
  String get kbRetrievalTest;

  /// No description provided for @knowledgeUsage.
  ///
  /// In en, this message translates to:
  /// **'USAGE'**
  String get knowledgeUsage;

  /// No description provided for @kbCloud.
  ///
  /// In en, this message translates to:
  /// **'CLOUD'**
  String get kbCloud;

  /// No description provided for @kbUsedMsg.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total} used'**
  String kbUsedMsg(String used, String total);

  /// No description provided for @welcomeBackAuth.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get welcomeBackAuth;

  /// No description provided for @createAccountAuth.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get createAccountAuth;

  /// No description provided for @signInAccessConsole.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access the agentic console'**
  String get signInAccessConsole;

  /// No description provided for @joinEcosystem.
  ///
  /// In en, this message translates to:
  /// **'Join the INHAUS ecosystem'**
  String get joinEcosystem;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInLabel.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get signInLabel;

  /// No description provided for @registerLabel.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get registerLabel;

  /// No description provided for @newAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW ACCOUNT'**
  String get newAccountLabel;

  /// No description provided for @existingUserLogin.
  ///
  /// In en, this message translates to:
  /// **'EXISTING USER? LOGIN'**
  String get existingUserLogin;

  /// No description provided for @googleLogin.
  ///
  /// In en, this message translates to:
  /// **'GOOGLE LOGIN'**
  String get googleLogin;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orLabel;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'BASIC INFORMATION'**
  String get basicInfo;

  /// No description provided for @knowledgeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Name'**
  String get knowledgeNameLabel;

  /// No description provided for @enableHybridSearch.
  ///
  /// In en, this message translates to:
  /// **'Enable Hybrid Search'**
  String get enableHybridSearch;

  /// No description provided for @metadataConfig.
  ///
  /// In en, this message translates to:
  /// **'METADATA CONFIGURATION'**
  String get metadataConfig;

  /// No description provided for @autoExtractAuthor.
  ///
  /// In en, this message translates to:
  /// **'Auto-extract author'**
  String get autoExtractAuthor;

  /// No description provided for @autoExtractDate.
  ///
  /// In en, this message translates to:
  /// **'Auto-extract publish date'**
  String get autoExtractDate;

  /// No description provided for @indexTablesAsText.
  ///
  /// In en, this message translates to:
  /// **'Index tables as text'**
  String get indexTablesAsText;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get dangerZone;

  /// No description provided for @deleteKnowledgeBase.
  ///
  /// In en, this message translates to:
  /// **'Delete Knowledge Base'**
  String get deleteKnowledgeBase;

  /// No description provided for @deleteKnowledgeBaseSub.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this knowledge base and all associated data.'**
  String get deleteKnowledgeBaseSub;

  /// No description provided for @knowledgeSettings.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Settings'**
  String get knowledgeSettings;

  /// No description provided for @knowledgeSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Manage your knowledge base configuration, indexing, and retrieval settings.'**
  String get knowledgeSettingsSub;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// No description provided for @externalKnowledgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to External Knowledge Base'**
  String get externalKnowledgeTitle;

  /// No description provided for @externalKnowledgeSub.
  ///
  /// In en, this message translates to:
  /// **'Integrate with external knowledge bases through API services or official plugins.'**
  String get externalKnowledgeSub;

  /// No description provided for @apiConnections.
  ///
  /// In en, this message translates to:
  /// **'API Connections'**
  String get apiConnections;

  /// No description provided for @pluginMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Plugin Marketplace'**
  String get pluginMarketplace;

  /// No description provided for @apiConnectionsSub.
  ///
  /// In en, this message translates to:
  /// **'Configure custom API endpoints to connect to your self-hosted or third-party knowledge bases.'**
  String get apiConnectionsSub;

  /// No description provided for @addApiConnection.
  ///
  /// In en, this message translates to:
  /// **'Add API Connection'**
  String get addApiConnection;

  /// No description provided for @noConnectionsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No connections configured'**
  String get noConnectionsConfigured;

  /// No description provided for @addFirstConnection.
  ///
  /// In en, this message translates to:
  /// **'Add your first connection'**
  String get addFirstConnection;

  /// No description provided for @retrievalSandbox.
  ///
  /// In en, this message translates to:
  /// **'Retrieval Sandbox'**
  String get retrievalSandbox;

  /// No description provided for @retrievalSandboxSub.
  ///
  /// In en, this message translates to:
  /// **'Test your retrieval settings and view raw chunks returned by the API.'**
  String get retrievalSandboxSub;

  /// No description provided for @selectConnection.
  ///
  /// In en, this message translates to:
  /// **'Select Connection'**
  String get selectConnection;

  /// No description provided for @chooseConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a connection'**
  String get chooseConnectionHint;

  /// No description provided for @queryLabel.
  ///
  /// In en, this message translates to:
  /// **'Query'**
  String get queryLabel;

  /// No description provided for @searchQueryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter search query...'**
  String get searchQueryHint;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @retrievalResults.
  ///
  /// In en, this message translates to:
  /// **'Retrieval Results'**
  String get retrievalResults;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String scoreLabel(String score);

  /// No description provided for @lastSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String lastSyncLabel(String time);

  /// No description provided for @testingStatus.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testingStatus;

  /// No description provided for @disconnectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnectedStatus;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get connectionSuccessful;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check your settings.'**
  String get connectionFailed;

  /// No description provided for @installedLabel.
  ///
  /// In en, this message translates to:
  /// **'INSTALLED'**
  String get installedLabel;

  /// No description provided for @configureLabel.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configureLabel;

  /// No description provided for @installLabel.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get installLabel;

  /// No description provided for @connectionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection Name'**
  String get connectionNameLabel;

  /// No description provided for @connectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Custom Vector Store'**
  String get connectionNameHint;

  /// No description provided for @apiEndpointLabel.
  ///
  /// In en, this message translates to:
  /// **'API Endpoint'**
  String get apiEndpointLabel;

  /// No description provided for @knowledgeIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Knowledge ID (Optional)'**
  String get knowledgeIdOptional;

  /// No description provided for @internalRefId.
  ///
  /// In en, this message translates to:
  /// **'Internal reference ID'**
  String get internalRefId;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyLabel;

  /// No description provided for @apiRequirements.
  ///
  /// In en, this message translates to:
  /// **'API Requirements'**
  String get apiRequirements;

  /// No description provided for @apiRequirementsSub.
  ///
  /// In en, this message translates to:
  /// **'Your API must accept POST requests with a query parameter and return results in JSON format with text content.'**
  String get apiRequirementsSub;

  /// No description provided for @testSave.
  ///
  /// In en, this message translates to:
  /// **'Test & Save'**
  String get testSave;

  /// No description provided for @configurePlugin.
  ///
  /// In en, this message translates to:
  /// **'Configure {plugin}'**
  String configurePlugin(String plugin);

  /// No description provided for @apiKeyOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: Specify a {label}'**
  String apiKeyOptionalHint(String label);

  /// No description provided for @needApiKey.
  ///
  /// In en, this message translates to:
  /// **'Need an API key?'**
  String get needApiKey;

  /// No description provided for @visitPluginHub.
  ///
  /// In en, this message translates to:
  /// **'Visit {url} to create one'**
  String visitPluginHub(String url);

  /// No description provided for @saveConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Save Configuration'**
  String get saveConfiguration;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @dataSourceStep.
  ///
  /// In en, this message translates to:
  /// **'DATA SOURCE'**
  String get dataSourceStep;

  /// No description provided for @processingStep.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT PROCESSING'**
  String get processingStep;

  /// No description provided for @executeFinishStep.
  ///
  /// In en, this message translates to:
  /// **'EXECUTE & FINISH'**
  String get executeFinishStep;

  /// No description provided for @selectDataSource.
  ///
  /// In en, this message translates to:
  /// **'Select Data Source'**
  String get selectDataSource;

  /// No description provided for @dataSourceChangeWarning.
  ///
  /// In en, this message translates to:
  /// **'Once a knowledge base is created, its data source cannot be changed later.'**
  String get dataSourceChangeWarning;

  /// No description provided for @importFromFile.
  ///
  /// In en, this message translates to:
  /// **'Import from file'**
  String get importFromFile;

  /// No description provided for @syncFromNotion.
  ///
  /// In en, this message translates to:
  /// **'Sync from Notion'**
  String get syncFromNotion;

  /// No description provided for @syncFromWebsite.
  ///
  /// In en, this message translates to:
  /// **'Sync from Website'**
  String get syncFromWebsite;

  /// No description provided for @chunkSettings.
  ///
  /// In en, this message translates to:
  /// **'Chunk Settings'**
  String get chunkSettings;

  /// No description provided for @chunkSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Configure how your data will be segmented and cleaned before indexing.'**
  String get chunkSettingsSub;

  /// No description provided for @chunkingMode.
  ///
  /// In en, this message translates to:
  /// **'CHUNKING MODE'**
  String get chunkingMode;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @chunkingRules.
  ///
  /// In en, this message translates to:
  /// **'CHUNKING RULES'**
  String get chunkingRules;

  /// No description provided for @separator.
  ///
  /// In en, this message translates to:
  /// **'Separator'**
  String get separator;

  /// No description provided for @maxChunkLength.
  ///
  /// In en, this message translates to:
  /// **'Max chunk length'**
  String get maxChunkLength;

  /// No description provided for @chunkOverlap.
  ///
  /// In en, this message translates to:
  /// **'Chunk overlap'**
  String get chunkOverlap;

  /// No description provided for @cleaningRules.
  ///
  /// In en, this message translates to:
  /// **'CLEANING RULES'**
  String get cleaningRules;

  /// No description provided for @cleanSpacesRule.
  ///
  /// In en, this message translates to:
  /// **'Replace consecutive spaces, newlines and tabs'**
  String get cleanSpacesRule;

  /// No description provided for @cleanUrlsRule.
  ///
  /// In en, this message translates to:
  /// **'Delete all URLs and email addresses'**
  String get cleanUrlsRule;

  /// No description provided for @chunksPreview.
  ///
  /// In en, this message translates to:
  /// **'CHUNKS PREVIEW'**
  String get chunksPreview;

  /// No description provided for @chunksIdentified.
  ///
  /// In en, this message translates to:
  /// **'{count} chunks identified'**
  String chunksIdentified(int count);

  /// No description provided for @indexRetrievalTitle.
  ///
  /// In en, this message translates to:
  /// **'Index & Retrieval'**
  String get indexRetrievalTitle;

  /// No description provided for @indexRetrievalSub.
  ///
  /// In en, this message translates to:
  /// **'Define how your knowledge will be indexed and retrieved for the best accuracy.'**
  String get indexRetrievalSub;

  /// No description provided for @indexMethod.
  ///
  /// In en, this message translates to:
  /// **'INDEX METHOD'**
  String get indexMethod;

  /// No description provided for @highQuality.
  ///
  /// In en, this message translates to:
  /// **'High Quality'**
  String get highQuality;

  /// No description provided for @highQualitySub.
  ///
  /// In en, this message translates to:
  /// **'Embedding model & Hybrid search support.'**
  String get highQualitySub;

  /// No description provided for @economical.
  ///
  /// In en, this message translates to:
  /// **'Economical'**
  String get economical;

  /// No description provided for @economicalSub.
  ///
  /// In en, this message translates to:
  /// **'No tokens consumed, keyword-only.'**
  String get economicalSub;

  /// No description provided for @embeddingModel.
  ///
  /// In en, this message translates to:
  /// **'EMBEDDING MODEL'**
  String get embeddingModel;

  /// No description provided for @retrievalSettings.
  ///
  /// In en, this message translates to:
  /// **'RETRIEVAL SETTINGS'**
  String get retrievalSettings;

  /// No description provided for @rerankSettings.
  ///
  /// In en, this message translates to:
  /// **'RERANK SETTINGS'**
  String get rerankSettings;

  /// No description provided for @rerankModel.
  ///
  /// In en, this message translates to:
  /// **'Rerank Model'**
  String get rerankModel;

  /// No description provided for @topK.
  ///
  /// In en, this message translates to:
  /// **'Top K'**
  String get topK;

  /// No description provided for @scoreThreshold.
  ///
  /// In en, this message translates to:
  /// **'Score Threshold'**
  String get scoreThreshold;

  /// No description provided for @finishLabel.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishLabel;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @knowledgeBases.
  ///
  /// In en, this message translates to:
  /// **'KNOWLEDGE BASES'**
  String get knowledgeBases;

  /// No description provided for @noKnowledgeBases.
  ///
  /// In en, this message translates to:
  /// **'No Knowledge Bases'**
  String get noKnowledgeBases;

  /// No description provided for @createDatasetMsg.
  ///
  /// In en, this message translates to:
  /// **'Create a new dataset to get started.'**
  String get createDatasetMsg;

  /// No description provided for @documentsLabel.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENTS'**
  String get documentsLabel;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No Documents'**
  String get noDocuments;

  /// No description provided for @uploadFilesMsg.
  ///
  /// In en, this message translates to:
  /// **'Upload files or add text to this knowledge base.'**
  String get uploadFilesMsg;

  /// No description provided for @itemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} items selected'**
  String itemsSelected(int count);

  /// No description provided for @deleteDocuments.
  ///
  /// In en, this message translates to:
  /// **'Delete Documents'**
  String get deleteDocuments;

  /// No description provided for @deleteDocumentsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} documents?'**
  String deleteDocumentsConfirm(int count);

  /// No description provided for @documentsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Documents deleted'**
  String get documentsDeleted;

  /// No description provided for @pasteUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Paste URL...'**
  String get pasteUrlHint;

  /// No description provided for @addLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLinkLabel;

  /// No description provided for @uploadLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadLabel;

  /// No description provided for @imageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageLabel;

  /// No description provided for @driveLabel.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get driveLabel;

  /// No description provided for @googleDriveIntegration.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Integration'**
  String get googleDriveIntegration;

  /// No description provided for @driveIntegrationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Direct Google Drive integration is coming soon. Please download your files and upload them manually for now.'**
  String get driveIntegrationComingSoon;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @kbStats.
  ///
  /// In en, this message translates to:
  /// **'{docCount} Documents • {wordCount} Words'**
  String kbStats(int docCount, int wordCount);

  /// No description provided for @tokensWords.
  ///
  /// In en, this message translates to:
  /// **'{tokens} Tokens • {wordCount} Words'**
  String tokensWords(int tokens, int wordCount);

  /// No description provided for @analyzeVisionAgent.
  ///
  /// In en, this message translates to:
  /// **'Analyze with Vision Agent'**
  String get analyzeVisionAgent;

  /// No description provided for @analyzeVisualAsset.
  ///
  /// In en, this message translates to:
  /// **'Analyze this visual asset: {title}'**
  String analyzeVisualAsset(String title);
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
