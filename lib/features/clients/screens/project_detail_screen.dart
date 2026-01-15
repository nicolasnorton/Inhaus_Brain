import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  bool _isBoardView = true;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectProvider);
    final project = projects.firstWhere(
      (p) => p.id == widget.projectId,
      orElse: () => Project(id: 'unknown', clientId: '', name: 'Unknown Project', description: 'Unknown', startDate: DateTime.now()),
    );

    if (project.id == 'unknown') {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.projectNotFound), backgroundColor: Colors.transparent),
        body: Center(child: Text(AppLocalizations.of(context)!.projectNotFoundMsg, style: const TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(_getStatusText(context, project.status).toUpperCase(), style: TextStyle(color: _getStatusColor(project.status), fontSize: 10)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isBoardView ? Icons.list : Icons.view_kanban, color: Colors.white),
            onPressed: () => setState(() => _isBoardView = !_isBoardView),
            tooltip: _isBoardView ? AppLocalizations.of(context)!.switchToListView : AppLocalizations.of(context)!.switchToBoardView,
          ),
          IconButton(
             icon: const Icon(Icons.add, color: Colors.blueAccent),
             onPressed: () => _showAddTaskDialog(project),
          ),
        ],
      ),
      body: _isBoardView ? _buildKanbanView(project) : _buildListView(project),
    );
  }

  Widget _buildKanbanView(Project project) {
    final allTasks = ref.watch(taskProvider);
    final tasks = allTasks.where((t) => t.projectId == project.id).toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: project.sections.length,
      itemBuilder: (context, index) {
        final section = project.sections[index];
        final sectionTasks = tasks.where((t) => t.sectionId == section || (t.sectionId == null && section == 'To Do')).toList();
        
        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(section, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${sectionTasks.length}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: sectionTasks.length,
                  itemBuilder: (context, taskIndex) {
                    final task = sectionTasks[taskIndex];
                    return _buildTaskCard(task, project);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton.icon(
                  onPressed: () => _showAddTaskDialog(project, initialSection: section),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(AppLocalizations.of(context)!.addTask),
                  style: TextButton.styleFrom(foregroundColor: Colors.white54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildListView(Project project) {
    final allTasks = ref.watch(taskProvider);
    final tasks = allTasks.where((t) => t.projectId == project.id).toList();
    
    // Group by section for list view? Or just flat? Let's do grouped.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: project.sections.length,
      itemBuilder: (context, index) {
        final section = project.sections[index];
        final sectionTasks = tasks.where((t) => t.sectionId == section || (t.sectionId == null && section == 'To Do')).toList();
        
        if (sectionTasks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(section, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...sectionTasks.map((t) => _buildTaskCard(t, project, isList: true)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard(ProjectTask task, Project project, {bool isList = false}) {
     return GestureDetector(
       onTap: () => _showEditTaskDialog(task, project),
       child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               children: [
                 Expanded(child: Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                 if (task.priority != TaskPriority.medium)
                    _buildPriorityBadge(task.priority)
               ],
             ),
             if (task.tags.isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Wrap(
                   spacing: 4,
                   children: task.tags.map((t) => Container(
                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                     decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                     child: Text(t, style: const TextStyle(color: Colors.blueAccent, fontSize: 10)),
                   )).toList(),
                 ),
               ),
          ],
        ),
      ),
     );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color color;
    switch(priority) {
      case TaskPriority.low: color = Colors.green; break;
      case TaskPriority.medium: color = Colors.blue; break;
      case TaskPriority.high: color = Colors.orange; break;
      case TaskPriority.urgent: color = Colors.red; break;
    }
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  String _getStatusText(BuildContext context, ProjectStatus status) {
    return switch (status) {
      ProjectStatus.planning => AppLocalizations.of(context)!.statusPlanning,
      ProjectStatus.inProgress => AppLocalizations.of(context)!.statusInProgress,
      ProjectStatus.completed => AppLocalizations.of(context)!.statusCompleted,
      ProjectStatus.archived => AppLocalizations.of(context)!.statusArchived,
    };
  }

  void _showAddTaskDialog(Project project, {String? initialSection}) {
    final titleController = TextEditingController();
    String selectedSection = initialSection ?? project.sections.first;
    TaskPriority selectedPriority = TaskPriority.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: Text(AppLocalizations.of(context)!.addTask, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.taskTitle), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedSection,
                dropdownColor: const Color(0xFF111111),
                isExpanded: true,
                items: project.sections.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setDialogState(() => selectedSection = val!),
              ),
              const SizedBox(height: 16),
              DropdownButton<TaskPriority>(
                value: selectedPriority,
                dropdownColor: const Color(0xFF111111),
                isExpanded: true,
                items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(_getPriorityText(context, p).toUpperCase(), style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setDialogState(() => selectedPriority = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
            ElevatedButton(
              onPressed: () {
                ref.read(taskProvider.notifier).addTask(
                  project.id,
                  titleController.text,
                  '',
                  sectionId: selectedSection,
                  priorityStr: selectedPriority.name,
                );
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.addLabel),
            ),
          ],
        ),
      ),
    );
  }

    void _showEditTaskDialog(ProjectTask task, Project project) {
    final titleController = TextEditingController(text: task.title);
    String selectedSection = task.sectionId ?? project.sections.first;
    TaskPriority selectedPriority = task.priority;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: Text(AppLocalizations.of(context)!.editTask, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.taskTitle), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedSection,
                dropdownColor: const Color(0xFF111111),
                isExpanded: true,
                items: project.sections.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setDialogState(() => selectedSection = val!),
              ),
              const SizedBox(height: 16),
              DropdownButton<TaskPriority>(
                value: selectedPriority,
                dropdownColor: const Color(0xFF111111),
                isExpanded: true,
                items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(_getPriorityText(context, p).toUpperCase(), style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setDialogState(() => selectedPriority = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () {
               ref.read(taskProvider.notifier).deleteTask(task.id);
               Navigator.pop(context);
            }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: Text(AppLocalizations.of(context)!.deleteLabel)),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
            ElevatedButton(
              onPressed: () {
                final updatedTask = task.copyWith(
                  title: titleController.text,
                  sectionId: selectedSection,
                  priority: selectedPriority,
                );
                ref.read(taskProvider.notifier).updateTask(updatedTask);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.saveLabel),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriorityText(BuildContext context, TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => AppLocalizations.of(context)!.priorityLow,
      TaskPriority.medium => AppLocalizations.of(context)!.priorityMedium,
      TaskPriority.high => AppLocalizations.of(context)!.priorityHigh,
      TaskPriority.urgent => AppLocalizations.of(context)!.priorityUrgent,
    };
  }
}
