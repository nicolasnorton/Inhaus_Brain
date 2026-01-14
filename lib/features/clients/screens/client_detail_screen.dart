import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/client_provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/client_integrations_provider.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientProvider);
    final client = clients.firstWhere(
      (c) => c.id == widget.clientId,
      orElse: () => Client(id: 'unknown', name: 'Unknown Client', industry: 'Unknown'),
    );

    if (client.id == 'unknown') {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Client Not Found')),
        body: const Center(child: Text('The requested client could not be found.', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Projects'),
            Tab(text: 'Tasks'),
            Tab(text: 'Integrations'),
            Tab(text: 'UCP Commerce'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(client),
          _buildProjectsTab(client),
          _buildTasksTab(client),
          _buildIntegrationsTab(client),
          _buildUCPTab(client),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Client client) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Industry: ${client.industry}', style: const TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 16),
          Text('Primary Contact: ${client.primaryContactEmail ?? "Not set"}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 32),
          const Text('Performance Summary', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Add some mock stats here
          Row(
            children: [
              _buildStatCard('Active Campaigns', '${client.campaignIds.length}'),
              const SizedBox(width: 16),
              _buildStatCard('Total Projects', '${ref.watch(projectProvider).where((p) => p.clientId == client.id).length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProjectsTab(Client client) {
    final projects = ref.watch(projectProvider).where((p) => p.clientId == client.id).toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Client Projects', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showAddProjectDialog(client),
                icon: const Icon(Icons.add),
                label: const Text('New Project'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _buildProjectTile(project);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectTile(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(project.status.name.toUpperCase(), style: TextStyle(color: _getStatusColor(project.status), fontSize: 10)),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.edit, color: Colors.white24), onPressed: () {}),
        ],
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    return switch (status) {
      ProjectStatus.planning => Colors.blueAccent,
      ProjectStatus.inProgress => Colors.orangeAccent,
      ProjectStatus.completed => Colors.greenAccent,
      ProjectStatus.archived => Colors.white24,
    };
  }

  Widget _buildTasksTab(Client client) {
    final projects = ref.watch(projectProvider).where((p) => p.clientId == client.id).toList();
    final allTasks = ref.watch(taskProvider);
    final projectIds = projects.map((p) => p.id).toSet();
    final tasks = allTasks.where((t) => projectIds.contains(t.projectId)).toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Tasks', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              if (projects.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _showAddTaskDialog(projects),
                  icon: const Icon(Icons.add),
                  label: const Text('New Task'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskTile(task);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(ProjectTask task) {
    final projects = ref.watch(projectProvider);
    final project = projects.firstWhere((p) => p.id == task.projectId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.status == TaskStatus.done,
            onChanged: (val) {
              ref.read(taskProvider.notifier).updateTask(
                task.copyWith(status: val! ? TaskStatus.done : TaskStatus.todo),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: TextStyle(
                  color: Colors.white,
                  decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                )),
                Text(project.name, style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ),
          if (task.dueDate != null)
            Text('${task.dueDate!.day}/${task.dueDate!.month}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildIntegrationsTab(Client client) {
    final integrationState = ref.watch(clientIntegrationsProvider)[client.id] ?? ClientIntegrationState();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Connect Third-Party Tools', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Authorize Inhaus Brain to access data from these platforms.', style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildIntegrationCard('Gmail', FontAwesomeIcons.envelope, integrationState.isGmailConnected, Colors.redAccent, client.id),
              _buildIntegrationCard('Slack', FontAwesomeIcons.slack, integrationState.isSlackConnected, Colors.purpleAccent, client.id),
              _buildIntegrationCard('Notion', FontAwesomeIcons.noteSticky, integrationState.isNotionConnected, Colors.white, client.id),
              _buildIntegrationCard('GoHighLevel', FontAwesomeIcons.rocket, integrationState.isGHLConnected, Colors.blueAccent, client.id),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationCard(String name, IconData icon, bool isConnected, Color color, String clientId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isConnected ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: color, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(isConnected ? 'Connected' : 'Not Connected', style: TextStyle(color: isConnected ? Colors.greenAccent : Colors.white24, fontSize: 10)),
              ],
            ),
          ),
          Switch(
            value: isConnected,
            onChanged: (val) {
              ref.read(clientIntegrationsProvider.notifier).toggleIntegration(clientId, name, val);
            },
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildUCPTab(Client client) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Universal Commerce Protocol (UCP)', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Seamless agentic commerce integration.', style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.globe, color: Colors.blueAccent, size: 32),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('UCP Status: Active', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Discovery Service: Online', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Trigger discovery mock
                  },
                  child: const Text('Discover Businesses'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Connected Commerce Agents', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Mock list
          _buildUCPParticipantCard('Shoaming Assistant', 'Platform Agent', FontAwesomeIcons.robot),
          const SizedBox(height: 16),
          _buildUCPParticipantCard('TechStore Global', 'Business', FontAwesomeIcons.store),
        ],
      ),
    );
  }

  Widget _buildUCPParticipantCard(String name, String role, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(role, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Text('Connected', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddProjectDialog(Client client) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Add Project', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Project Name'), style: const TextStyle(color: Colors.white)),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(projectProvider.notifier).addProject(client.id, nameController.text, descController.text);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(List<Project> projects) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedProjectId = projects.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text('Add Task', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedProjectId,
                dropdownColor: const Color(0xFF111111),
                isExpanded: true,
                items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setDialogState(() => selectedProjectId = val!),
              ),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Task Title'), style: const TextStyle(color: Colors.white)),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), style: const TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                ref.read(taskProvider.notifier).addTask(selectedProjectId, titleController.text, descController.text);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
