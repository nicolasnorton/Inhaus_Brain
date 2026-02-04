import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inhaus_brain/features/clients/models/task_model.dart';
import 'package:inhaus_brain/features/clients/providers/task_provider.dart';
import 'package:inhaus_brain/features/clients/providers/project_provider.dart';
import 'package:inhaus_brain/features/clients/models/project_model.dart'; // Import Project model
import 'package:inhaus_brain/features/clients/screens/client_task_detail_pane.dart';

final selectedTaskProvider = StateProvider<String?>((ref) => null);

class ClientTasksScreen extends ConsumerWidget {
  final String clientId;

  const ClientTasksScreen({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get all projects for this client
    final clientProjects = ref.watch(projectProvider).where((p) => p.clientId == clientId).toList();
    final clientProjectIds = clientProjects.map((p) => p.id).toSet();

    // 2. Get all LOCAL tasks (tasks currently in memory)
    // In a real app we might need to filter by parentId == null to only show headers, 
    // but Asana shows everything flattened or by section. Let's filter top-level only for the main list?
    // Actually Asana lists usually show parent tasks. Subtasks are hidden unless expanded.
    // So let's filter: where parentId is NULL.
    final allTasks = ref.watch(taskProvider);
    final clientTasks = allTasks.where((t) => clientProjectIds.contains(t.projectId) && t.parentId == null).toList();
    
    // 3. Selection State override (local state for now, could be provider)
    final selectedTaskId = ref.watch(selectedTaskProvider);
    final selectedTask = allTasks.firstWhere((t) => t.id == selectedTaskId, orElse: () => clientTasks.isNotEmpty ? clientTasks.first : ProjectTask(id: 'dummy', projectId: '', title: '', description: '', createdAt: DateTime.now(), updatedAt: DateTime.now())); 

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      floatingActionButton: clientProjects.isNotEmpty 
          ? FloatingActionButton.extended(
              onPressed: () => _showTaskDialog(context, ref, clientProjects),
              label: const Text('New Task'),
              icon: const Icon(Icons.add),
              backgroundColor: Colors.blueAccent,
            )
          : null,
      body: Row(
        children: [
          // Main List
          Expanded(
            flex: 2,
            child: clientTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Client Tasks', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      if (clientProjects.isEmpty)
                         const Text('Create a project first to add tasks.', style: TextStyle(color: Colors.white54))
                      else
                         const Text('No tasks found. Create one!', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: clientTasks.length,
                  itemBuilder: (context, index) {
                    final task = clientTasks[index];
                    final project = clientProjects.firstWhere((p) => p.id == task.projectId, orElse: () => clientProjects.first);
                    
                    return _TaskCard(
                      task: task, 
                      projectName: project.name,
                      isSelected: task.id == selectedTaskId,
                      onTap: () => ref.read(selectedTaskProvider.notifier).state = task.id,
                      onEdit: () => ref.read(selectedTaskProvider.notifier).state = task.id, // Editing opens pane now
                      onDelete: () => ref.read(taskProvider.notifier).deleteTask(task.id),
                      onToggleStatus: (done) {
                         ref.read(taskProvider.notifier).updateTask(task.copyWith(status: done ? TaskStatus.done : TaskStatus.todo));
                      },
                    );
                  },
                ),
          ),
          
          // Right Pane (Split View)
          if (selectedTaskId != null && allTasks.any((t) => t.id == selectedTaskId))
             ClientTaskDetailPane(
               task: allTasks.firstWhere((t) => t.id == selectedTaskId),
               onClose: () => ref.read(selectedTaskProvider.notifier).state = null,
               onTaskSelected: (id) => ref.read(selectedTaskProvider.notifier).state = id,
             ),
        ],
      ),
    );
  }

  void _showTaskDialog(BuildContext context, WidgetRef ref, List<Project> projects, {ProjectTask? taskToEdit}) {
    final titleController = TextEditingController(text: taskToEdit?.title ?? '');
    final descController = TextEditingController(text: taskToEdit?.description ?? '');
    
    // Default to first project if creating, or the task's project if editing
    String selectedProjectId = taskToEdit?.projectId ?? (projects.isNotEmpty ? projects.first.id : '');
    TaskPriority selectedPriority = taskToEdit?.priority ?? TaskPriority.medium;
    DateTime? selectedDate = taskToEdit?.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E2128),
            title: Text(taskToEdit == null ? 'New Task' : 'Edit Task', style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Project Selector
                   DropdownButtonFormField<String>(
                     value: selectedProjectId,
                     decoration: const InputDecoration(
                       labelText: 'Project',
                       labelStyle: TextStyle(color: Colors.white54),
                       enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                     ),
                     dropdownColor: const Color(0xFF1E2128), // Matches dialog bg
                     style: const TextStyle(color: Colors.white),
                     items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                     onChanged: (val) => setState(() => selectedProjectId = val!),
                   ),
                   const SizedBox(height: 16),
                   TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TaskPriority>(
                           value: selectedPriority,
                           decoration: const InputDecoration(
                             labelText: 'Priority',
                             labelStyle: TextStyle(color: Colors.white54),
                             enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                           ),
                           dropdownColor: const Color(0xFF1E2128),
                           style: const TextStyle(color: Colors.white),
                           items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                           onChanged: (val) => setState(() => selectedPriority = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.calendar_today, color: selectedDate != null ? Colors.blueAccent : Colors.white54),
                        onPressed: () async {
                           final picked = await showDatePicker(
                             context: context, 
                             initialDate: selectedDate ?? DateTime.now(), 
                             firstDate: DateTime.now().subtract(const Duration(days: 365)), 
                             lastDate: DateTime.now().add(const Duration(days: 365))
                           );
                           if (picked != null) {
                             setState(() => selectedDate = picked);
                           }
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty && selectedProjectId.isNotEmpty) {
                    if (taskToEdit == null) {
                      ref.read(taskProvider.notifier).addTask(
                            selectedProjectId,
                            titleController.text.trim(),
                            descController.text.trim(),
                            priorityStr: selectedPriority.name,
                            dueDate: selectedDate,
                          );
                    } else {
                      ref.read(taskProvider.notifier).updateTask(
                        taskToEdit.copyWith(
                          projectId: selectedProjectId,
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          priority: selectedPriority,
                          dueDate: selectedDate,
                        )
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: Text(taskToEdit == null ? 'Create' : 'Save'),
              ),
            ],
          );
        }
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final ProjectTask task;
  final String projectName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleStatus;
  final bool isSelected;
  final VoidCallback onTap;


  const _TaskCard({
    required this.task, 
    required this.projectName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12),
           side: isSelected ? const BorderSide(color: Colors.blueAccent) : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
             // Checkbox or Status Indicator
             InkWell(
               onTap: () => onToggleStatus(task.status != TaskStatus.done),
               child: Container(
                 width: 24,
                 height: 24,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   border: Border.all(color: task.status == TaskStatus.done ? Colors.green : Colors.white38, width: 2),
                   color: task.status == TaskStatus.done ? Colors.green.withOpacity(0.2) : null,
                 ),
                 child: task.status == TaskStatus.done 
                    ? const Icon(Icons.check, size: 16, color: Colors.green) 
                    : null,
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     task.title,
                     style: TextStyle(
                       color: Colors.white, 
                       fontSize: 16, 
                       fontWeight: FontWeight.w600,
                       decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                       decorationColor: Colors.white38,
                     ),
                   ),
                   const SizedBox(height: 4),
                   Row(
                     children: [
                       Text(projectName, style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                       if (task.dueDate != null) ...[
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: Colors.white38)),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat.MMMd().format(task.dueDate!),
                            style: TextStyle(
                              color: task.dueDate!.isBefore(DateTime.now()) && task.status != TaskStatus.done 
                                ? Colors.redAccent 
                                : Colors.white38, 
                              fontSize: 12
                            ),
                          ),
                       ]
                     ],
                   ),
                 ],
               ),
             ),
             _PriorityBadge(priority: task.priority),
             const SizedBox(width: 8),
             PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.white38),
                  color: const Color(0xFF1E2128),
                  onSelected: (value) {
                    if (value == 'edit') {
                       onEdit();
                    } else if (value == 'delete') {
                       onDelete();
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
      ),
    ),
  );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case TaskPriority.urgent:
        color = Colors.red;
        break;
      case TaskPriority.high:
        color = Colors.orange;
        break;
      case TaskPriority.medium:
        color = Colors.yellow;
        break;
      case TaskPriority.low:
        color = Colors.green;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
