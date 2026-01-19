// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get nodeStart => 'Start';

  @override
  String get nodeEnd => 'End';

  @override
  String get nodeFunction => 'Function';

  @override
  String get nodeParallel => 'Parallel';

  @override
  String get nodeCondition => 'Condition';

  @override
  String get moduleClient => 'Client';

  @override
  String get moduleCampaign => 'Campaign';

  @override
  String get mockAIModels => 'Mock AI Models';

  @override
  String get mockAIModelsSubtitle => 'Use simulated responses for testing';

  @override
  String aiMockMode(Object status) {
    return 'AI Mock Mode: $status';
  }

  @override
  String get connectedAccounts => 'Connected Accounts';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not Connected';

  @override
  String get disconnect => 'Disconnect';

  @override
  String accountDisconnected(Object account) {
    return 'Disconnected from $account';
  }

  @override
  String get connect => 'Connect';

  @override
  String accountConnected(Object account) {
    return 'Connected to $account';
  }

  @override
  String get nameHint => 'Enter your name';

  @override
  String get nameEmptyError => 'Name cannot be empty';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get emailInvalidError => 'Please enter a valid email';

  @override
  String get emailChangeWarning =>
      'Note: Changing email may require re-verification';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get displayLanguage => 'Display Language';

  @override
  String languageUpdated(Object language) {
    return 'Language changed to $language';
  }

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get emailNotificationsSubtitle =>
      'Receive updates and alerts via email';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Use dark theme for the application';

  @override
  String get developerSettings => 'Developer Settings';

  @override
  String get settingsTitle => 'Personal Settings';

  @override
  String get settingsSubtitle => 'Manage your profile and preferences';

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
  String get uploadComingSoon => 'Upload feature coming soon';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navClients => 'Clients';

  @override
  String get navCampaigns => 'Campaigns';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navWorkflows => 'Workflows';

  @override
  String get navPublish => 'Publish';

  @override
  String get navKnowledge => 'Knowledge';

  @override
  String get navSettings => 'Settings';

  @override
  String get navDebug => 'Debug';

  @override
  String welcomeBack(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get readyForCampaign =>
      'Inhaus Brain is ready for your next campaign.';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get logout => 'Logout';

  @override
  String loggedInAs(String role) {
    return 'Logged in as $role';
  }

  @override
  String get campaignsTitle => 'Campaigns';

  @override
  String get creativeStudio => 'Creative Studio';

  @override
  String get newCampaign => 'New Campaign';

  @override
  String get noActiveCampaigns => 'No Active Campaigns';

  @override
  String get createNewCampaign => 'Create New Campaign';

  @override
  String get noClient => 'No Client';

  @override
  String createdOn(String date) {
    return 'Created: $date';
  }

  @override
  String get statusResearching => 'Researching';

  @override
  String get statusDesigning => 'Designing';

  @override
  String get statusInProduction => 'In Production';

  @override
  String get statusPublished => 'Published';

  @override
  String get researchWorkshop => 'Research Workshop';

  @override
  String get campaignBrief => 'Campaign Brief';

  @override
  String get tellAgentGoals => 'Tell the AI Agent what you want to achieve.';

  @override
  String get campaignTitle => 'Campaign Title';

  @override
  String get campaignTitleHint => 'e.g. Summer Collection 2026';

  @override
  String get clientNameLabel => 'Client Name';

  @override
  String get clientNameHint => 'e.g. Acme Corp';

  @override
  String get detailedBrief => 'Detailed Brief';

  @override
  String get detailedBriefHint =>
      'Describe goals, target audience, and key messages...';

  @override
  String get requiredField => 'Required';

  @override
  String get startResearchChat => 'Start Research Chat';

  @override
  String get confirmStrategyCreate => 'Confirm Strategy & Create Campaign';

  @override
  String startNewCampaignMsg(String title, String description) {
    return 'I want to start a new campaign: $title. Brief: $description';
  }

  @override
  String get agentResearchInsights => 'Agent Research Insights';

  @override
  String get reviewApproveInsights =>
      'Review and approve insights gathered by the Research Agent.';

  @override
  String get proceedToDesignPlan => 'Proceed to Design Plan';

  @override
  String get campaignStrategyBrief => 'Campaign Strategy Brief';

  @override
  String get clientLabel => 'Client:';

  @override
  String get approve => 'Approve';

  @override
  String get designPhaseActive => 'Design Phase Active';

  @override
  String get creativeProposedDirections =>
      'The Creative Agent has proposed visual directions for this campaign.';

  @override
  String get openCreativeStudio => 'Open Creative Studio';

  @override
  String get notAvailable => 'N/A';

  @override
  String get proposeNewConcept => 'Propose New Concept';

  @override
  String get noCreativeConceptsYet => 'No creative concepts yet.';

  @override
  String get completeResearchApprovalMsg =>
      'Complete a campaign research approval to trigger the Design Agent.';

  @override
  String get designFeedback => 'DESIGN FEEDBACK';

  @override
  String campaignIdLabel(String id) {
    return 'Campaign ID: $id';
  }

  @override
  String get copyProposition => 'Copy Proposition';

  @override
  String get visualStrategyPrompt => 'Visual Strategy Prompt';

  @override
  String get finalProductionAssets => 'Final Production Assets';

  @override
  String get generateHighTierAssets => 'Generate High-Tier Assets';

  @override
  String get finalHighFidelityCopy => 'Final High-Fidelity Copy (Vertex AI)';

  @override
  String get finalVisualMock => 'Final Visual Mock (Imagen-3)';

  @override
  String get conceptApprovedReadyProduction =>
      'Concept approved. Ready for high-fidelity production.';

  @override
  String get styleBoards => 'Style Boards';

  @override
  String suggestedCount(int count) {
    return '$count Suggested';
  }

  @override
  String get clientModule => 'CLIENT MODULE';

  @override
  String get portfolioManagement => 'Portfolio Management';

  @override
  String get addClient => 'Add Client';

  @override
  String get noClientsConfigured => 'No clients configured yet.';

  @override
  String get approved => 'Approved';

  @override
  String get approveInsight => 'Approve Insight';

  @override
  String get designConcept => 'DESIGN CONCEPT';

  @override
  String get campaignsCountLabel => 'CAMPAIGNS';

  @override
  String get manageClient => 'Manage Client';

  @override
  String get addNewClient => 'Add New Client';

  @override
  String get industryLabel => 'Industry';

  @override
  String get contactEmail => 'Contact Email';

  @override
  String get cancel => 'Cancel';

  @override
  String get primaryContactEmail => 'Primary Contact Email';

  @override
  String get createClient => 'Create Client';

  @override
  String get clientNotFound => 'Client Not Found';

  @override
  String get clientNotFoundMsg => 'The requested client could not be found.';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabContacts => 'Contacts';

  @override
  String get tabProjects => 'Projects';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabIntegrations => 'Integrations';

  @override
  String get tabUCP => 'UCP Commerce';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get industryLabelShort => 'Industry';

  @override
  String get sizeLabel => 'Size';

  @override
  String get primaryContactLabel => 'Primary Contact';

  @override
  String get performanceSummary => 'Performance Summary';

  @override
  String get activeCampaigns => 'Active Campaigns';

  @override
  String get totalProjects => 'Total Projects';

  @override
  String get clientContacts => 'Client Contacts';

  @override
  String get addContact => 'Add Contact';

  @override
  String get noContactsAdded => 'No contacts added yet.';

  @override
  String get clientProjects => 'Client Projects';

  @override
  String get newProject => 'New Project';

  @override
  String get activeTasksLabel => 'Active Tasks';

  @override
  String get newTask => 'New Task';

  @override
  String get connectThirdPartyTools => 'Connect Third-Party Tools';

  @override
  String get authorizeInhausBrainMsg =>
      'Authorize Inhaus Brain to access data from these platforms.';

  @override
  String get ucpTitle => 'Universal Commerce Protocol (UCP)';

  @override
  String get ucpSubTitle => 'Seamless agentic commerce integration.';

  @override
  String get ucpStatusActive => 'UCP Status: Active';

  @override
  String get discoveryServiceOnline => 'Discovery Service: Online';

  @override
  String get discoverBusinesses => 'Discover Businesses';

  @override
  String get connectedCommerceAgents => 'Connected Commerce Agents';

  @override
  String get addProject => 'Add Project';

  @override
  String get projectName => 'Project Name';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get createLabel => 'Create';

  @override
  String get addTask => 'Add Task';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get roleLabel => 'Role';

  @override
  String get addLabel => 'Add';

  @override
  String get statusPlanning => 'Planning';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusArchived => 'Archived';

  @override
  String get statusTodo => 'Todo';

  @override
  String get statusDone => 'Done';

  @override
  String get projectNotFound => 'Project Not Found';

  @override
  String get projectNotFoundMsg => 'Project not found.';

  @override
  String get switchToListView => 'Switch to List View';

  @override
  String get switchToBoardView => 'Switch to Board View';

  @override
  String get editTask => 'Edit Task';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get saveLabel => 'Save';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get operationsCenter => 'Operations Center';

  @override
  String get secGeneral => 'General';

  @override
  String get secAgentBrain => 'Agent Brain';

  @override
  String get secAIModels => 'AI Models';

  @override
  String get secConnectors => 'Connectors';

  @override
  String get profileAccount => 'PROFILE & ACCOUNT';

  @override
  String get profileAccountSub => 'Manage your identity and access levels.';

  @override
  String get agentBrainTitle => 'AGENT BRAIN (MASTER PROMPTS)';

  @override
  String get agentBrainSub =>
      'Configure the behavior, persona, and workflows for your workforce.';

  @override
  String get agentStudioTitle => 'Agent Studio';

  @override
  String get agentStudioSub =>
      'Access the advanced configuration panel to tune System Prompts, manage Pipeline connections, and configure tools for Campaign & Creative agents.';

  @override
  String get launchAgentStudio => 'Launch Agent Studio';

  @override
  String get aiModelVaultTitle => 'AI MODEL VAULT';

  @override
  String get aiModelVaultSub =>
      'Securely store API keys for external providers. Keys never leave your device.';

  @override
  String get saveKeysLabel => 'Save Keys';

  @override
  String get toolConnectorsTitle => 'TOOL CONNECTORS';

  @override
  String get toolConnectorsSub =>
      'Integrate third-party services into your workflow.';

  @override
  String get teamAccessRoles => 'TEAM ACCESS & ROLES';

  @override
  String get systemRole => 'System Role';

  @override
  String get assignedClients => 'Assigned Clients';

  @override
  String get saveAccessLevels => 'Save Access Levels';

  @override
  String get keysSavedMsg => 'Keys securely saved to Vault.';

  @override
  String get promptsUpdatedMsg => 'Master Prompts updated.';

  @override
  String get profileUpdatedMsg => 'Profile updated successfully.';

  @override
  String get pleaseLoginManage => 'Please log in to manage settings.';

  @override
  String get enterAgentInstructions => 'Enter agent instructions...';

  @override
  String get enterApiKey => 'Enter API Key...';

  @override
  String get unnamedUser => 'Unnamed User';

  @override
  String get noClientsFound => 'No clients found.';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get workspaceInfrastructure => 'Workspace Infrastructure';

  @override
  String get modelProviders => 'Model Providers';

  @override
  String get modelProvidersSub => 'Configure LLM and image generation keys';

  @override
  String get pluginsTools => 'Plugins & Tools';

  @override
  String get pluginsToolsSub => 'Connect external tools and MCP servers';

  @override
  String get manageApps => 'Manage Apps';

  @override
  String get manageAppsSub => 'Deploy and organize your micro-apps';

  @override
  String get analyticsMonitor => 'Analytics & Monitor';

  @override
  String get tabBusinessAnalytics => 'Business Analytics';

  @override
  String get tabSystemMonitor => 'System Monitor';

  @override
  String get campaignPerformance => 'Campaign Performance';

  @override
  String get conversionOverTime => 'Conversion over Time';

  @override
  String get historicalDataAggregated => 'Historical data being aggregated...';

  @override
  String get statROI => 'ROI';

  @override
  String get statConversion => 'Conversion';

  @override
  String get statCPA => 'CPA';

  @override
  String get monitorDashboard => 'Monitor Dashboard';

  @override
  String get statStatistics => 'Statistics';

  @override
  String get quickLogs => 'Quick Logs';

  @override
  String get viewAllLogs => 'View All Logs';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get totalMessages => 'Total Messages';

  @override
  String get activeUsers => 'Active Users';

  @override
  String get avgInteractions => 'Avg. Interactions';

  @override
  String get tokenUsage => 'Token Usage';

  @override
  String get tracingAppPerformance => 'Tracing app performance';

  @override
  String get tracingIntegration => 'Tracing Integration';

  @override
  String get connectExternalTracingMsg =>
      'Connect external tracing providers to monitor agent performance.';

  @override
  String connectedToMsg(String name) {
    return 'Connected to $name (Mock)';
  }

  @override
  String get statConvVolume => 'Conversation volume';

  @override
  String get statMeaningfulExchange => '>1 meaningful exchange';

  @override
  String get statEngagementDepth => 'Engagement depth';

  @override
  String get statResourceConsumption => 'Resource consumption';

  @override
  String get knowledgeModule => 'KNOWLEDGE';

  @override
  String get createKnowledge => 'Create Knowledge';

  @override
  String get quickCreate => 'Quick Create';

  @override
  String get knowledgePipeline => 'Knowledge Pipeline';

  @override
  String get authorizeDataSource => 'Authorize Data Source';

  @override
  String get connectToExternal => 'Connect to External';

  @override
  String get externalBase => 'External Base';

  @override
  String get apiReference => 'API Reference';

  @override
  String get manageKnowledge => 'Manage Knowledge';

  @override
  String get contentLabel => 'Content';

  @override
  String get metadataLabel => 'Metadata';

  @override
  String get testRetrieval => 'Test Retrieval';

  @override
  String get integrateApps => 'Integrate within Apps';

  @override
  String get backLabel => 'Back';

  @override
  String get kbDocuments => 'Documents';

  @override
  String get kbRetrievalTest => 'Retrieval Test';

  @override
  String get knowledgeUsage => 'USAGE';

  @override
  String get kbCloud => 'CLOUD';

  @override
  String kbUsedMsg(String used, String total) {
    return '$used / $total used';
  }

  @override
  String get welcomeBackAuth => 'WELCOME BACK';

  @override
  String get createAccountAuth => 'CREATE ACCOUNT';

  @override
  String get signInAccessConsole => 'Sign in to access the agentic console';

  @override
  String get joinEcosystem => 'Join the INHAUS ecosystem';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInLabel => 'SIGN IN';

  @override
  String get registerLabel => 'REGISTER';

  @override
  String get newAccountLabel => 'NEW ACCOUNT';

  @override
  String get existingUserLogin => 'EXISTING USER? LOGIN';

  @override
  String get googleLogin => 'GOOGLE LOGIN';

  @override
  String get orLabel => 'OR';

  @override
  String get basicInfo => 'BASIC INFORMATION';

  @override
  String get knowledgeNameLabel => 'Knowledge Name';

  @override
  String get enableHybridSearch => 'Enable Hybrid Search';

  @override
  String get metadataConfig => 'METADATA CONFIGURATION';

  @override
  String get autoExtractAuthor => 'Auto-extract author';

  @override
  String get autoExtractDate => 'Auto-extract publish date';

  @override
  String get indexTablesAsText => 'Index tables as text';

  @override
  String get dangerZone => 'DANGER ZONE';

  @override
  String get deleteKnowledgeBase => 'Delete Knowledge Base';

  @override
  String get deleteKnowledgeBaseSub =>
      'Permanently delete this knowledge base and all associated data.';

  @override
  String get knowledgeSettings => 'Knowledge Settings';

  @override
  String get knowledgeSettingsSub =>
      'Manage your knowledge base configuration, indexing, and retrieval settings.';

  @override
  String get statusActive => 'Active';

  @override
  String get statusError => 'Error';

  @override
  String get externalKnowledgeTitle => 'Connect to External Knowledge Base';

  @override
  String get externalKnowledgeSub =>
      'Integrate with external knowledge bases through API services or official plugins.';

  @override
  String get apiConnections => 'API Connections';

  @override
  String get pluginMarketplace => 'Plugin Marketplace';

  @override
  String get apiConnectionsSub =>
      'Configure custom API endpoints to connect to your self-hosted or third-party knowledge bases.';

  @override
  String get addApiConnection => 'Add API Connection';

  @override
  String get noConnectionsConfigured => 'No connections configured';

  @override
  String get addFirstConnection => 'Add your first connection';

  @override
  String get retrievalSandbox => 'Retrieval Sandbox';

  @override
  String get retrievalSandboxSub =>
      'Test your retrieval settings and view raw chunks returned by the API.';

  @override
  String get selectConnection => 'Select Connection';

  @override
  String get chooseConnectionHint => 'Choose a connection';

  @override
  String get queryLabel => 'Query';

  @override
  String get searchQueryHint => 'Enter search query...';

  @override
  String get searchLabel => 'Search';

  @override
  String get retrievalResults => 'Retrieval Results';

  @override
  String scoreLabel(String score) {
    return 'Score: $score';
  }

  @override
  String lastSyncLabel(String time) {
    return 'Last sync: $time';
  }

  @override
  String get testingStatus => 'Testing...';

  @override
  String get disconnectedStatus => 'Disconnected';

  @override
  String get connectionSuccessful => 'Connection successful!';

  @override
  String get connectionFailed => 'Connection failed. Check your settings.';

  @override
  String get installedLabel => 'INSTALLED';

  @override
  String get configureLabel => 'Configure';

  @override
  String get installLabel => 'Install';

  @override
  String get connectionNameLabel => 'Connection Name';

  @override
  String get connectionNameHint => 'e.g. My Custom Vector Store';

  @override
  String get apiEndpointLabel => 'API Endpoint';

  @override
  String get knowledgeIdOptional => 'Knowledge ID (Optional)';

  @override
  String get internalRefId => 'Internal reference ID';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get apiRequirements => 'API Requirements';

  @override
  String get apiRequirementsSub =>
      'Your API must accept POST requests with a query parameter and return results in JSON format with text content.';

  @override
  String get testSave => 'Test & Save';

  @override
  String configurePlugin(String plugin) {
    return 'Configure $plugin';
  }

  @override
  String apiKeyOptionalHint(String label) {
    return 'Optional: Specify a $label';
  }

  @override
  String get needApiKey => 'Need an API key?';

  @override
  String visitPluginHub(String url) {
    return 'Visit $url to create one';
  }

  @override
  String get saveConfiguration => 'Save Configuration';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get dataSourceStep => 'DATA SOURCE';

  @override
  String get processingStep => 'DOCUMENT PROCESSING';

  @override
  String get executeFinishStep => 'EXECUTE & FINISH';

  @override
  String get selectDataSource => 'Select Data Source';

  @override
  String get dataSourceChangeWarning =>
      'Once a knowledge base is created, its data source cannot be changed later.';

  @override
  String get importFromFile => 'Import from file';

  @override
  String get syncFromNotion => 'Sync from Notion';

  @override
  String get syncFromWebsite => 'Sync from Website';

  @override
  String get chunkSettings => 'Chunk Settings';

  @override
  String get chunkSettingsSub =>
      'Configure how your data will be segmented and cleaned before indexing.';

  @override
  String get chunkingMode => 'CHUNKING MODE';

  @override
  String get automatic => 'Automatic';

  @override
  String get custom => 'Custom';

  @override
  String get chunkingRules => 'CHUNKING RULES';

  @override
  String get separator => 'Separator';

  @override
  String get maxChunkLength => 'Max chunk length';

  @override
  String get chunkOverlap => 'Chunk overlap';

  @override
  String get cleaningRules => 'CLEANING RULES';

  @override
  String get cleanSpacesRule => 'Replace consecutive spaces, newlines and tabs';

  @override
  String get cleanUrlsRule => 'Delete all URLs and email addresses';

  @override
  String get chunksPreview => 'CHUNKS PREVIEW';

  @override
  String chunksIdentified(int count) {
    return '$count chunks identified';
  }

  @override
  String get indexRetrievalTitle => 'Index & Retrieval';

  @override
  String get indexRetrievalSub =>
      'Define how your knowledge will be indexed and retrieved for the best accuracy.';

  @override
  String get indexMethod => 'INDEX METHOD';

  @override
  String get highQuality => 'High Quality';

  @override
  String get highQualitySub => 'Embedding model & Hybrid search support.';

  @override
  String get economical => 'Economical';

  @override
  String get economicalSub => 'No tokens consumed, keyword-only.';

  @override
  String get embeddingModel => 'EMBEDDING MODEL';

  @override
  String get retrievalSettings => 'RETRIEVAL SETTINGS';

  @override
  String get rerankSettings => 'RERANK SETTINGS';

  @override
  String get rerankModel => 'Rerank Model';

  @override
  String get topK => 'Top K';

  @override
  String get scoreThreshold => 'Score Threshold';

  @override
  String get finishLabel => 'Finish';

  @override
  String get nextLabel => 'Next';

  @override
  String get knowledgeBases => 'KNOWLEDGE BASES';

  @override
  String get noKnowledgeBases => 'No Knowledge Bases';

  @override
  String get createDatasetMsg => 'Create a new dataset to get started.';

  @override
  String get documentsLabel => 'DOCUMENTS';

  @override
  String get noDocuments => 'No Documents';

  @override
  String get uploadFilesMsg =>
      'Upload files or add text to this knowledge base.';

  @override
  String itemsSelected(int count) {
    return '$count items selected';
  }

  @override
  String get deleteDocuments => 'Delete Documents';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Are you sure you want to delete $count documents?';
  }

  @override
  String get documentsDeleted => 'Documents deleted';

  @override
  String get pasteUrlHint => 'Paste URL...';

  @override
  String get addLinkLabel => 'Add Link';

  @override
  String get uploadLabel => 'Upload';

  @override
  String get imageLabel => 'Image';

  @override
  String get driveLabel => 'Drive';

  @override
  String get googleDriveIntegration => 'Google Drive Integration';

  @override
  String get driveIntegrationComingSoon =>
      'Direct Google Drive integration is coming soon. Please download your files and upload them manually for now.';

  @override
  String get gotIt => 'Got it';

  @override
  String kbStats(int docCount, int wordCount) {
    return '$docCount Documents • $wordCount Words';
  }

  @override
  String tokensWords(int tokens, int wordCount) {
    return '$tokens Tokens • $wordCount Words';
  }

  @override
  String get analyzeVisionAgent => 'Analyze with Vision Agent';

  @override
  String analyzeVisualAsset(String title) {
    return 'Analyze this visual asset: $title';
  }
}
