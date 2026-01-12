import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/user_settings_models.dart';
import '../providers/user_settings_provider.dart';

class PersonalSettingsScreen extends ConsumerStatefulWidget {
  const PersonalSettingsScreen({super.key});

  @override
  ConsumerState<PersonalSettingsScreen> createState() => _PersonalSettingsScreenState();
}

class _PersonalSettingsScreenState extends ConsumerState<PersonalSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _orgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final profile = ref.read(userSettingsProvider).profile;
    _nameController.text = profile.name;
    _orgController.text = profile.organization ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(userSettingsProvider);

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
              border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FontAwesomeIcons.userGear, color: theme.primaryColor, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      'Personal Settings',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: theme.primaryColor,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Preferences'),
                    Tab(text: 'API Keys'),
                    Tab(text: 'Notifications'),
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
                _buildProfileTab(theme, settings),
                _buildPreferencesTab(theme, settings),
                _buildApiKeysTab(theme, settings),
                _buildNotificationsTab(theme, settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(ThemeData theme, UserSettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                child: Icon(Icons.person, size: 40, color: theme.primaryColor),
              ),
              const SizedBox(width: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                child: const Text('Change Avatar'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildTextField('Full Name', _nameController),
          const SizedBox(height: 24),
          _buildTextField('Email Address', TextEditingController(text: settings.profile.email), readOnly: true),
          const SizedBox(height: 24),
          _buildTextField('Organization', _orgController),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.read(userSettingsProvider.notifier).updateProfile(
                settings.profile.copyWith(
                  name: _nameController.text,
                  organization: _orgController.text,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab(ThemeData theme, UserSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Text('Theme Preference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ...ThemePreference.values.map((t) => RadioListTile<ThemePreference>(
              title: Text(t.displayName),
              value: t,
              groupValue: settings.theme,
              onChanged: (val) => ref.read(userSettingsProvider.notifier).updateTheme(val!),
            )),
        const SizedBox(height: 32),
        const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: 'English',
          items: ['English', 'Spanish', 'French', 'Chinese'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: (val) {},
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeysTab(ThemeData theme, UserSettings settings) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Workspace API Keys', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ElevatedButton.icon(
                onPressed: () => _showCreateApiKeyDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create New Key'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Use these keys to access Inhaus Brain via API.', style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: settings.apiKeys.length,
              itemBuilder: (context, index) {
                final key = settings.apiKeys[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(key.name),
                    subtitle: Text(key.key, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => ref.read(userSettingsProvider.notifier).deleteApiKey(key.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(ThemeData theme, UserSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        SwitchListTile(
          title: const Text('Email Notifications'),
          subtitle: const Text('Receive updates and alerts via email'),
          value: settings.notifications.emailNotifications,
          onChanged: (val) => ref.read(userSettingsProvider.notifier).updateNotifications(
                settings.notifications.copyWith(emailNotifications: val),
              ),
        ),
        SwitchListTile(
          title: const Text('Usage Alerts'),
          subtitle: const Text('Notify when reaching 80% and 100% of limits'),
          value: settings.notifications.usageAlerts,
          onChanged: (val) => ref.read(userSettingsProvider.notifier).updateNotifications(
                settings.notifications.copyWith(usageAlerts: val),
              ),
        ),
        SwitchListTile(
          title: const Text('Security Alerts'),
          subtitle: const Text('Notify about new sign-ins and password changes'),
          value: settings.notifications.securityAlerts,
          onChanged: (val) => ref.read(userSettingsProvider.notifier).updateNotifications(
                settings.notifications.copyWith(securityAlerts: val),
              ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  void _showCreateApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Key Name', hintText: 'e.g., Development Server'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(userSettingsProvider.notifier).addApiKey(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
