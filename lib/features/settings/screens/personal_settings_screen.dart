import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/user_models.dart';
import '../providers/user_provider.dart';
import 'package:inhaus_brain/core/services/edge_ai_service.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
                            'Personal Settings',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your profile and preferences across all workspaces',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
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
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: theme.primaryColor,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Preferences'),
                    Tab(text: 'Security'),
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
                // Profile Tab
                _buildProfileTab(user),
                // Preferences Tab
                _buildPreferencesTab(preferences),
                // Security Tab
                _buildSecurityTab(user),
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
            'Profile Picture',
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
                onPressed: () => _showSnackBar('Avatar upload coming soon'),
                icon: const Icon(FontAwesomeIcons.upload),
                label: const Text('Upload New Picture'),
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
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Name cannot be empty';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Email
                Text(
                  'Email Address',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) return 'Invalid email';
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
                    'Changing your email affects all workspaces',
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
                  _showSnackBar('Profile updated successfully');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Changes'),
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
            'Display Language',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Language>(
            value: preferences.language,
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
                _showSnackBar('Language updated to ${value.displayName}');
              }
            },
          ),
          const SizedBox(height: 24),
          // Email Notifications
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive updates and alerts via email'),
            value: preferences.emailNotifications,
            onChanged: (value) {
              ref.read(userPreferencesProvider.notifier).toggleEmailNotifications();
            },
          ),
          const SizedBox(height: 12),
          // Dark Mode Toggle
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use a high-contrast dark theme'),
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
            'Developer Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Mock AI Models'),
            subtitle: const Text('Force all generative AI to use simulated edge mock for testing'),
            secondary: Icon(
              Icons.bug_report,
              color: theme.primaryColor,
            ),
            value: EdgeAIService.forceMock,
            onChanged: (value) {
              setState(() {
                EdgeAIService.forceMock = value;
              });
              _showSnackBar('AI Mock Mode: ${value ? 'ON' : 'OFF'}');
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
            'Connected Accounts',
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
                  isLinked ? 'Connected' : 'Not connected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isLinked ? Colors.green : Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          if (isLinked)
            TextButton(
              onPressed: () {
                ref.read(currentUserProvider.notifier).unlinkAccount(method);
                _showSnackBar('${method.displayName} disconnected');
              },
              child: const Text('Disconnect'),
            )
          else
            ElevatedButton(
              onPressed: () {
                ref.read(currentUserProvider.notifier).linkAccount(method);
                _showSnackBar('${method.displayName} connected');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Connect'),
            ),
        ],
      ),
    );
  }
}
