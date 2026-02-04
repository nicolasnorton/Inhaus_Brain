import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inhaus_brain/features/clients/models/project_model.dart';
import 'package:inhaus_brain/features/clients/providers/project_provider.dart';
import 'package:inhaus_brain/features/clients/screens/project_detail_screen.dart';

class ClientProjectsScreen extends ConsumerWidget {
  final String clientId;

  const ClientProjectsScreen({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectProvider).where((p) => p.clientId == clientId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProjectDialog(context, ref),
        label: const Text('New Project'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
      body: projects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Client Projects', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  const Text('No projects yet.', style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _ProjectCard(
                  project: project,
                  onEdit: () => _showAddProjectDialog(context, ref, projectToEdit: project),
                );
              },
            ),
    );
  }

  void _showAddProjectDialog(BuildContext context, WidgetRef ref, {Project? projectToEdit}) {
    final nameController = TextEditingController(text: projectToEdit?.name ?? '');
    final descController = TextEditingController(text: projectToEdit?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2128),
        title: Text(projectToEdit == null ? 'New Project' : 'Edit Project', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Project Name',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                if (projectToEdit == null) {
                  ref.read(projectProvider.notifier).addProject(
                        clientId,
                        nameController.text.trim(),
                        descController.text.trim(),
                      );
                } else {
                   ref.read(projectProvider.notifier).updateProject(
                     projectToEdit.copyWith(
                       name: nameController.text.trim(),
                       description: descController.text.trim(),
                     )
                   );
                }
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text(projectToEdit == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final Project project;
  final VoidCallback onEdit;

  const _ProjectCard({required this.project, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(projectId: project.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _StatusBadge(status: project.status),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    color: const Color(0xFF1E2128),
                    onSelected: (value) {
                      if (value == 'edit') {
                         onEdit();
                      } else if (value == 'delete') {
                         ref.read(projectProvider.notifier).deleteProject(project.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit', style: TextStyle(color: Colors.white)),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ],
              ),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.white38),
                  const SizedBox(width: 8),
                  Text(
                    'Started ${DateFormat.yMMMd().format(project.startDate)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const Spacer(),
                   IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                      onPressed: onEdit, 
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ProjectStatus.planning:
        color = Colors.blue;
        break;
      case ProjectStatus.inProgress:
        color = Colors.orange;
        break;
      case ProjectStatus.completed:
        color = Colors.green;
        break;
      case ProjectStatus.archived:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
