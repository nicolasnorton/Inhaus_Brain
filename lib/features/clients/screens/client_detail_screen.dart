import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import '../providers/client_provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/client_integrations_provider.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import 'project_detail_screen.dart';

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
    _tabController = TabController(length: 6, vsync: this);
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, title: Text(AppLocalizations.of(context)!.clientNotFound)),
        body: Center(child: Text(AppLocalizations.of(context)!.clientNotFoundMsg)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
            tooltip: 'Edit Business Profile',
            onPressed: () => context.push('/clients/${client.id}/edit'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.tabOverview),
            Tab(text: AppLocalizations.of(context)!.tabContacts),
            Tab(text: AppLocalizations.of(context)!.tabProjects),
            Tab(text: AppLocalizations.of(context)!.tabTasks),
            Tab(text: AppLocalizations.of(context)!.tabIntegrations),
            Tab(text: AppLocalizations.of(context)!.tabUCP),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(client),
          _buildContactsTab(client),
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
          Row(
            children: [
              if (client.website != null) ...[
                const Icon(Icons.language, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 8),
                Text(client.website!, style: const TextStyle(color: Colors.blueAccent)),
                const SizedBox(width: 24),
              ],
               if (client.address != null) ...[
                Icon(Icons.location_on, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), size: 16),
                const SizedBox(width: 8),
                Text(client.address!, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(client.description ?? AppLocalizations.of(context)!.noDescriptionAvailable, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),),
          const SizedBox(height: 24),
          Text('${AppLocalizations.of(context)!.industryLabelShort}: ${client.industry}  •  ${AppLocalizations.of(context)!.sizeLabel}: ${client.size ?? AppLocalizations.of(context)!.notAvailable}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 16),
          Text('${AppLocalizations.of(context)!.primaryContactLabel}: ${client.primaryContactEmail ?? AppLocalizations.of(context)!.notAvailable}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),),
          if (client.customFields.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text('ADDITIONAL INFORMATION', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: client.customFields.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(entry.key.toUpperCase(), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 4),
                   Text(entry.value.toString(), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14)),
                ],
              )).toList(),
            ),
          ],
          const SizedBox(height: 32),
          Text(AppLocalizations.of(context)!.performanceSummary, style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold),),
          const SizedBox(height: 16),
          // Add some mock stats here
          Row(
            children: [
              _buildStatCard(AppLocalizations.of(context)!.activeCampaigns, '${client.campaignIds.length}'),
              const SizedBox(width: 16),
              _buildStatCard(AppLocalizations.of(context)!.totalProjects, '${ref.watch(projectProvider).where((p) => p.clientId == client.id).length}'),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContactsTab(Client client) {
     return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.clientContacts, style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold),),
              ElevatedButton.icon(
                onPressed: () => _showAddContactDialog(client),
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addContact),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (client.contacts.isEmpty)
            Center(child: Text(AppLocalizations.of(context)!.noContactsAdded, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),))
          else
            Expanded(
              child: ListView.builder(
                itemCount: client.contacts.length,
                itemBuilder: (context, index) {
                  final contact = client.contacts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(contact.firstName.characters.first, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.fullName, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${contact.role}  •  ${contact.email}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.light ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(contact.accessLevel, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7), fontSize: 10)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
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
              Text(AppLocalizations.of(context)!.clientProjects, style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold),),
              ElevatedButton.icon(
                onPressed: () => _showAddProjectDialog(client),
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.newProject),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProjectDetailScreen(projectId: project.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_getStatusText(context, project.status).toUpperCase(), style: TextStyle(color: _getStatusColor(project.status), fontSize: 10)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4), size: 16),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    return switch (status) {
      ProjectStatus.planning => Colors.blueAccent,
      ProjectStatus.inProgress => Colors.orangeAccent,
      ProjectStatus.completed => Colors.greenAccent,
      ProjectStatus.archived => Theme.of(context).disabledColor,
    };
  }

  String _getStatusText(BuildContext context, ProjectStatus status) {
    return switch (status) {
      ProjectStatus.planning => AppLocalizations.of(context)!.statusPlanning,
      ProjectStatus.inProgress => AppLocalizations.of(context)!.statusInProgress,
      ProjectStatus.completed => AppLocalizations.of(context)!.statusCompleted,
      ProjectStatus.archived => AppLocalizations.of(context)!.statusArchived,
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
              Text(AppLocalizations.of(context)!.activeTasksLabel, style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold),),
              if (projects.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _showAddTaskDialog(projects),
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.newTask),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                )),
                Text(project.name, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4), fontSize: 10)),
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
          Text(AppLocalizations.of(context)!.connectThirdPartyTools, style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold),),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.authorizeInhausBrainMsg, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),),
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
              _buildIntegrationCard('Notion', FontAwesomeIcons.noteSticky, integrationState.isNotionConnected, Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white, client.id),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isConnected ? color.withValues(alpha: 0.3) : Theme.of(context).dividerColor),
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
                Text(name, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),),
                Text(isConnected ? AppLocalizations.of(context)!.connected : AppLocalizations.of(context)!.notConnected, style: TextStyle(color: isConnected ? Colors.greenAccent : (Theme.of(context).brightness == Brightness.light ? Colors.black26 : Colors.white24), fontSize: 10)),
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
          Text(AppLocalizations.of(context)!.ucpTitle, style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold),),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.ucpSubTitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),),
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
                      Text(AppLocalizations.of(context)!.ucpStatusActive, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(AppLocalizations.of(context)!.discoveryServiceOnline, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Trigger discovery mock
                  },
                  child: Text(AppLocalizations.of(context)!.discoverBusinesses),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(AppLocalizations.of(context)!.connectedCommerceAgents, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),),
              Text(role, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5), fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text(AppLocalizations.of(context)!.connected, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
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
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.addProject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.projectName)),
            TextField(controller: descController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.descriptionLabel)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              ref.read(projectProvider.notifier).addProject(client.id, nameController.text, descController.text);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.createLabel),
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
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppLocalizations.of(context)!.addTask),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedProjectId,
                dropdownColor: Theme.of(context).cardColor,
                isExpanded: true,
                items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (val) => setDialogState(() => selectedProjectId = val!),
              ),
              TextField(controller: titleController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.taskTitle)),
              TextField(controller: descController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.descriptionLabel)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
            ElevatedButton(
              onPressed: () {
                ref.read(taskProvider.notifier).addTask(selectedProjectId, titleController.text, descController.text);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.addLabel),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(Client client) {
    final firstController = TextEditingController();
    final lastController = TextEditingController();
    final emailController = TextEditingController();
    final roleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.addContact),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: firstController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.firstName)),
            TextField(controller: lastController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.lastName)),
            TextField(controller: emailController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.emailLabel)),
            TextField(controller: roleController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.roleLabel)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              ref.read(clientProvider.notifier).addClientContact(
                client.id,
                firstController.text,
                lastController.text,
                emailController.text,
                roleController.text,
              );
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.addLabel),
          ),
        ],
      ),
    );
  }
}
