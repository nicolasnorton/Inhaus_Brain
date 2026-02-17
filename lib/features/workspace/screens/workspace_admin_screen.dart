import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/agent_registry_service.dart';
import '../services/skills_firestore_service.dart';

/// Workspace admin screen — edit identity, manage agents, manage skills.
class WorkspaceAdminScreen extends ConsumerStatefulWidget {
  const WorkspaceAdminScreen({super.key});

  @override
  ConsumerState<WorkspaceAdminScreen> createState() => _WorkspaceAdminScreenState();
}

class _WorkspaceAdminScreenState extends ConsumerState<WorkspaceAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    Icon(FontAwesomeIcons.brain, color: theme.primaryColor, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      'Workspace Admin',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: theme.brightness == Brightness.light ? Colors.black54 : Colors.white60,
                  indicatorColor: theme.primaryColor,
                  tabs: const [
                    Tab(icon: Icon(Icons.fingerprint, size: 18), text: 'Identity'),
                    Tab(icon: Icon(Icons.smart_toy_outlined, size: 18), text: 'Agents'),
                    Tab(icon: Icon(Icons.auto_fix_high, size: 18), text: 'Skills'),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _IdentityTab(),
                _AgentsTab(),
                _SkillsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Identity Tab ────────────────────────────────────────────

class _IdentityTab extends ConsumerStatefulWidget {
  const _IdentityTab();

  @override
  ConsumerState<_IdentityTab> createState() => _IdentityTabState();
}

class _IdentityTabState extends ConsumerState<_IdentityTab> {
  final _identityController = TextEditingController();
  final _soulController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final db = FirebaseFirestore.instance;
    final identitySnap = await db.collection('workspaces').doc(uid).collection('docs').doc('identity').get();
    final soulSnap = await db.collection('workspaces').doc(uid).collection('docs').doc('soul').get();

    if (mounted) {
      setState(() {
        _identityController.text = identitySnap.data()?['content'] as String? ?? '';
        _soulController.text = soulSnap.data()?['content'] as String? ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);

    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.set(
      db.collection('workspaces').doc(uid).collection('docs').doc('identity'),
      {'content': _identityController.text, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    batch.set(
      db.collection('workspaces').doc(uid).collection('docs').doc('soul'),
      {'content': _soulController.text, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await batch.commit();

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identity & Soul saved'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  void dispose() {
    _identityController.dispose();
    _soulController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Identity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Defines who Brian is — personality, capabilities, role.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          _buildMarkdownEditor(_identityController, 'Brian\'s identity prompt...', 12),
          const SizedBox(height: 32),
          Text('Soul', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Communication style, values, and behavioral guidelines.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          _buildMarkdownEditor(_soulController, 'Brian\'s soul prompt...', 8),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownEditor(TextEditingController controller, String hint, int minLines) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      maxLines: null,
      minLines: minLines,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: theme.brightness == Brightness.light
            ? Colors.black.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─── Agents Tab ──────────────────────────────────────────────

class _AgentsTab extends ConsumerStatefulWidget {
  const _AgentsTab();

  @override
  ConsumerState<_AgentsTab> createState() => _AgentsTabState();
}

class _AgentsTabState extends ConsumerState<_AgentsTab> {
  List<AgentRegistryEntry> _agents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    final service = ref.read(agentRegistryServiceProvider);
    final agents = await service.getAgentRegistry();
    if (mounted) {
      setState(() {
        _agents = agents;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_agents.length} Agents Registered', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _reseed,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Re-seed Missing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _agents.length,
            itemBuilder: (context, index) {
              final agent = _agents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: agent.modelTier == 'pro'
                        ? Colors.deepPurple.withValues(alpha: 0.15)
                        : Colors.teal.withValues(alpha: 0.15),
                    child: Icon(
                      agent.modelTier == 'pro' ? Icons.star : Icons.bolt,
                      color: agent.modelTier == 'pro' ? Colors.deepPurple : Colors.teal,
                      size: 20,
                    ),
                  ),
                  title: Text(agent.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(agent.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (agent.tools.isNotEmpty)
                        Chip(
                          label: Text('${agent.tools.length} tools', style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        agent.modelTier.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: agent.modelTier == 'pro' ? Colors.deepPurple : Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showAgentDetail(agent),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _reseed() async {
    setState(() => _loading = true);
    final service = ref.read(agentRegistryServiceProvider);
    await service.seedRegistryFromAssets();
    await _loadAgents();
  }

  void _showAgentDetail(AgentRegistryEntry agent) {
    showDialog(
      context: context,
      builder: (context) => _AgentDetailDialog(agent: agent),
    );
  }
}

class _AgentDetailDialog extends StatelessWidget {
  final AgentRegistryEntry agent;
  const _AgentDetailDialog({required this.agent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.smart_toy, color: theme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Text(agent.name),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(agent.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(label: Text('Tier: ${agent.modelTier}'), backgroundColor: agent.modelTier == 'pro' ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.teal.withValues(alpha: 0.1)),
                  const SizedBox(width: 8),
                  if (agent.tools.isNotEmpty)
                    Chip(label: Text('Tools: ${agent.tools.join(", ")}'), backgroundColor: Colors.blue.withValues(alpha: 0.1)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Prompt Content', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? Colors.black.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  agent.promptContent ?? '(No prompt loaded — will be loaded from assets on demand)',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

// ─── Skills Tab ──────────────────────────────────────────────

class _SkillsTab extends ConsumerStatefulWidget {
  const _SkillsTab();

  @override
  ConsumerState<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends ConsumerState<_SkillsTab> {
  List<FirestoreSkill> _skills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    final service = ref.read(skillsFirestoreServiceProvider);
    final skills = await service.listSkills();
    if (mounted) {
      setState(() {
        _skills = skills;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_skills.length} Skills', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showCreateSkillDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Skill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_skills.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_fix_high, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text('No skills yet', style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor)),
                  const SizedBox(height: 8),
                  Text('Skills are created when Brian learns reusable processes from you.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _skills.length,
              itemBuilder: (context, index) {
                final skill = _skills[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                      child: const Icon(Icons.auto_fix_high, color: Colors.amber, size: 20),
                    ),
                    title: Text(skill.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(skill.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteSkill(skill.name),
                    ),
                    onTap: () => _showSkillDetail(skill),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _deleteSkill(String skillName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$skillName"?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(skillsFirestoreServiceProvider);
      await service.deleteSkill(skillName);
      await _loadSkills();
    }
  }

  void _showSkillDetail(FirestoreSkill skill) async {
    final service = ref.read(skillsFirestoreServiceProvider);
    final fullSkill = await service.getSkillContent(skill.name);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skill.name),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(skill.description, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black.withValues(alpha: 0.03)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    fullSkill?.content ?? '(No content)',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showCreateSkillDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Skill'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Skill Name', hintText: 'e.g. seo_audit_checklist')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', hintText: 'One-line summary')),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Content (Markdown)', hintText: 'Step-by-step instructions...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final service = ref.read(skillsFirestoreServiceProvider);
              await service.createSkill(FirestoreSkill(
                name: nameCtrl.text,
                description: descCtrl.text,
                content: contentCtrl.text,
              ));
              if (context.mounted) Navigator.pop(context);
              await _loadSkills();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
