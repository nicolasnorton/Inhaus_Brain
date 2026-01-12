import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../workspace/models/app_models.dart';
import '../../workspace/providers/apps_provider.dart';
import '../widgets/variable_text_field.dart';

import '../providers/app_config_provider.dart';
import '../../chat/agentic_chat_view.dart';

class AppSetupScreen extends ConsumerStatefulWidget {
  final String appId;
  const AppSetupScreen({super.key, required this.appId});

  @override
  ConsumerState<AppSetupScreen> createState() => _AppSetupScreenState();
}

class _AppSetupScreenState extends ConsumerState<AppSetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize prompt from app config
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apps = ref.read(appsProvider);
      final app = apps.firstWhere((a) => a.id == widget.appId);
      _promptController.text = app.config['system_prompt'] ?? '';
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _saveConfig() {
    final apps = ref.read(appsProvider);
    final app = apps.firstWhere((a) => a.id == widget.appId);
    
    final newConfig = {
      ...app.config,
      'system_prompt': _promptController.text,
    };
    
    ref.read(appsProvider.notifier).updateApp(app.id, app.copyWith(
      config: newConfig,
      updatedAt: DateTime.now(),
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(appsProvider);
    final app = apps.cast<App?>().firstWhere((a) => a?.id == widget.appId, orElse: () => null);

    if (app == null) return const Scaffold(body: Center(child: Text('App not found')));

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2128),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(app.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(app.type.displayName, style: TextStyle(color: app.type.color, fontSize: 11)),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Setup'),
            Tab(text: 'Preview'),
          ],
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.white38,
        ),
        actions: [
          ElevatedButton(
            onPressed: _saveConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Save'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSetupTab(app),
          _buildPreviewTab(app),
        ],
      ),
    );
  }

  Widget _buildSetupTab(App app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Instruction', 'Describe how the ${app.type.displayName} should behave'),
          const SizedBox(height: 16),
          _buildPromptEditor(),
          const SizedBox(height: 32),
          _buildSectionHeader('Context', 'Provide knowledge bases for the ${app.type.displayName} to reference'),
          const SizedBox(height: 16),
          _buildKnowledgeSelection(),
          const SizedBox(height: 32),
          _buildSectionHeader('Capabilities', 'Enable tools and plugins'),
          const SizedBox(height: 16),
          _buildToolSelection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildPromptEditor() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             decoration: const BoxDecoration(
               border: Border(bottom: BorderSide(color: Colors.white10)),
             ),
             child: Row(
               children: [
                 const Icon(Icons.wb_incandescent_outlined, size: 16, color: Colors.blueAccent),
                 const SizedBox(width: 8),
                 const Text('System Prompt', style: TextStyle(color: Colors.white70, fontSize: 12)),
                 const Spacer(),
                 TextButton.icon(
                   onPressed: () {},
                   icon: const Icon(Icons.auto_awesome, size: 14),
                   label: const Text('Generate', style: TextStyle(fontSize: 12)),
                 ),
               ],
             ),
          ),
          TextField(
            controller: _promptController,
            maxLines: 15,
            decoration: const InputDecoration(
              hintText: 'Enter app instructions...',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(FontAwesomeIcons.bookOpen, size: 32, color: Colors.white10),
            const SizedBox(height: 16),
            const Text('No Knowledge Selected', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Knowledge'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildToolChip('Google Search', FontAwesomeIcons.google),
          _buildToolChip('Calculator', FontAwesomeIcons.calculator),
          _buildToolChip('Web Scraper', FontAwesomeIcons.globe),
          ActionChip(
            label: const Text('+ Add Tool'),
            onPressed: () {},
            backgroundColor: Colors.white.withValues(alpha: 0.05),
          ),
        ],
      ),
    );
  }

  Widget _buildToolChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 12, color: Colors.blueAccent),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
      onDeleted: () {},
    );
  }

  Widget _buildPreviewTab(App app) {
    return Container(
      color: const Color(0xFF0D1117),
      child: const AgenticChatView(),
    );
  }
}
