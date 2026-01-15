import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/user_models.dart';
import '../providers/user_provider.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'package:inhaus_brain/core/services/edge_ai_service.dart';
import 'package:go_router/go_router.dart';

/// Personal settings screen with tabs
class PersonalSettingsScreen extends ConsumerStatefulWidget {
  const PersonalSettingsScreen({super.key});

  @override
  ConsumerState<PersonalSettingsScreen> createState() =>
      _PersonalSettingsScreenState();
}

class _PersonalSettingsScreenState
    extends ConsumerState<PersonalSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final preferences = ref.watch(userPreferencesProvider);
    final workspaces = ref.watch(userWorkspacesProvider);

    _nameController.text = user.name;
    _emailController.text = user.email;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.userGear,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.settingsTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.settingsSubtitle,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: theme.brightness == Brightness.light ? Colors.black54 : Colors.white60,
                  indicatorColor: theme.primaryColor,
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.tabProfile),
                    Tab(text: AppLocalizations.of(context)!.tabPreferences),
                    Tab(text: AppLocalizations.of(context)!.tabSecurity),
                    Tab(text: AppLocalizations.of(context)!.navWorkflows), // Or a specific 'Workspace' key if needed
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(user),
                // Preferences Tab
                _buildPreferencesTab(preferences),
                // Security Tab
                _buildSecurityTab(user),
                // Workspace Tab
                _buildWorkspaceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(UserProfile user) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Section
          Text(
            AppLocalizations.of(context)!.profilePicture,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Avatar
              Semantics(
                label: 'Profile picture for ${user.name}',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor,
                  ),
                  child: Center(
                    child: user.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user.avatarUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            user.initials,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                onPressed: () => _showSnackBar(AppLocalizations.of(context)!.uploadComingSoon),
                icon: const Icon(FontAwesomeIcons.upload),
                label: Text(AppLocalizations.of(context)!.uploadNewPicture),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.nameHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return AppLocalizations.of(context)!.nameEmptyError;
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Email
                Text(
                  AppLocalizations.of(context)!.emailLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.emailHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) return AppLocalizations.of(context)!.emailInvalidError;
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(FontAwesomeIcons.triangleExclamation,
                    color: Colors.orange, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.emailChangeWarning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ref.read(currentUserProvider.notifier).updateName(_nameController.text);
                  ref.read(currentUserProvider.notifier).updateEmail(_emailController.text);
                  _showSnackBar(AppLocalizations.of(context)!.profileUpdated);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(AppLocalizations.of(context)!.saveChanges),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab(UserPreferences preferences) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language
          Text(
            AppLocalizations.of(context)!.displayLanguage,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Language>(
            initialValue: preferences.language,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: Language.values.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Text(lang.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(userPreferencesProvider.notifier).updateLanguage(value);
                _showSnackBar(AppLocalizations.of(context)!.languageUpdated(value.displayName));
              }
            },
          ),
          const SizedBox(height: 24),
          // Email Notifications
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.emailNotifications),
            subtitle: Text(AppLocalizations.of(context)!.emailNotificationsSubtitle),
            value: preferences.emailNotifications,
            onChanged: (value) {
              ref.read(userPreferencesProvider.notifier).toggleEmailNotifications();
            },
          ),
          const SizedBox(height: 12),
          // Dark Mode Toggle
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.darkMode),
            subtitle: Text(AppLocalizations.of(context)!.darkModeSubtitle),
            secondary: Icon(
              preferences.darkMode ? Icons.dark_mode : Icons.light_mode,
              color: theme.primaryColor,
            ),
            value: preferences.darkMode,
            onChanged: (value) {
              ref.read(userPreferencesProvider.notifier).toggleDarkMode();
            },
          ),
          const Divider(height: 48),
          // Developer Settings
          Text(
            AppLocalizations.of(context)!.developerSettings,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.mockAIModels),
            subtitle: Text(AppLocalizations.of(context)!.mockAIModelsSubtitle),
            secondary: Icon(
              Icons.bug_report,
              color: theme.primaryColor,
            ),
            value: EdgeAIService.forceMock,
            onChanged: (value) {
              setState(() {
                EdgeAIService.forceMock = value;
              });
              
              final status = value ? 'ON' : 'OFF';
              _showSnackBar(AppLocalizations.of(context)!.aiMockMode(status));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(UserProfile user) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connected Accounts
          Text(
            AppLocalizations.of(context)!.connectedAccounts,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // GitHub
          _buildAccountTile(
            theme,
            LoginMethod.github,
            user.linkedAccounts.contains(LoginMethod.github),
          ),
          const SizedBox(height: 12),
          // Google
          _buildAccountTile(
            theme,
            LoginMethod.google,
            user.linkedAccounts.contains(LoginMethod.google),
          ),
          const SizedBox(height: 12),
          // Email
          _buildAccountTile(
            theme,
            LoginMethod.email,
            user.linkedAccounts.contains(LoginMethod.email),
          ),
          
          const Divider(height: 48),
          
          // Secrets Management
          Text(
            'Secrets & API Keys',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildWorkspaceItem(
            theme,
            icon: FontAwesomeIcons.key,
            title: 'My Secrets (secrets.md)',
            subtitle: 'Manage your API keys and environment variables securely',
            onTap: () => context.push('/settings/secrets'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(ThemeData theme, LoginMethod method, bool isLinked) {
    IconData icon;
    Color color;

    switch (method) {
      case LoginMethod.github:
        icon = FontAwesomeIcons.github;
        color = Colors.white;
        break;
      case LoginMethod.google:
        icon = FontAwesomeIcons.google;
        color = Colors.red;
        break;
      case LoginMethod.email:
        icon = FontAwesomeIcons.envelope;
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isLinked ? AppLocalizations.of(context)!.connected : AppLocalizations.of(context)!.notConnected,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isLinked ? Colors.green : (theme.brightness == Brightness.light ? Colors.black54 : Colors.white60),
                  ),
                ),
              ],
            ),
          ),
          if (isLinked)
            TextButton(
              onPressed: () {
                ref.read(currentUserProvider.notifier).unlinkAccount(method);
                _showSnackBar(AppLocalizations.of(context)!.accountDisconnected(method.displayName));
              },
              child: Text(AppLocalizations.of(context)!.disconnect),
            )
          else
            ElevatedButton(
              onPressed: () {
                ref.read(currentUserProvider.notifier).linkAccount(method);
                _showSnackBar(AppLocalizations.of(context)!.accountConnected(method.displayName));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.connect),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.workspaceInfrastructure,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildWorkspaceItem(
            theme,
            icon: FontAwesomeIcons.microchip,
            title: AppLocalizations.of(context)!.modelProviders,
            subtitle: AppLocalizations.of(context)!.modelProvidersSub,
            onTap: () => context.go('/workspace/model-providers'),
          ),
          const SizedBox(height: 12),
          _buildWorkspaceItem(
            theme,
            icon: FontAwesomeIcons.plug,
            title: AppLocalizations.of(context)!.pluginsTools,
            subtitle: AppLocalizations.of(context)!.pluginsToolsSub,
            onTap: () => context.go('/workspace/plugins'),
          ),
          const SizedBox(height: 12),
           _buildWorkspaceItem(
            theme,
            icon: FontAwesomeIcons.layerGroup,
            title: AppLocalizations.of(context)!.manageApps,
            subtitle: AppLocalizations.of(context)!.manageAppsSub,
            onTap: () => context.go('/workspace/apps'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceItem(ThemeData theme, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor.withValues(alpha: 0.1),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.primaryColor, size: 20),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white54)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
