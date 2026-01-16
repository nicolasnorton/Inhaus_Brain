import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/services/project_sync_service.dart';
import 'package:table_calendar/table_calendar.dart';
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
  bool _isCalendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Dialog State
  DateTime? _selectedDueDate;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _selectedDoneDate;

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
            icon: Icon(_isCalendarView ? Icons.view_kanban : Icons.calendar_month, color: Colors.white),
            onPressed: () => setState(() {
              if (_isCalendarView) {
                _isCalendarView = false;
                _isBoardView = true;
              } else {
                _isCalendarView = true;
                _isBoardView = false;
              }
            }),
            tooltip: 'Switch to Calendar',
          ),
          IconButton(
            icon: Icon(_isBoardView ? Icons.list : Icons.view_kanban, color: Colors.white),
            onPressed: () => setState(() {
              _isBoardView = !_isBoardView;
              _isCalendarView = false;
            }),
            tooltip: _isBoardView ? AppLocalizations.of(context)!.switchToListView : AppLocalizations.of(context)!.switchToBoardView,
          ),
          IconButton(
             icon: const Icon(Icons.add, color: Colors.blueAccent),
             onPressed: () => _showAddTaskDialog(project),
          ),
        ],
      ),
      body: _isCalendarView 
          ? _buildCalendarView(project)
          : (_isBoardView ? _buildKanbanView(project) : _buildListView(project)),
    );
  }

  Widget _buildKanbanView(Project project) {
    final allTasks = ref.watch(taskProvider);
    final tasks = allTasks.where((t) => t.projectId == project.id).toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: project.sections.length + 1,
      itemBuilder: (context, index) {
        if (index == project.sections.length) {
          return _buildAddSectionButton(project);
        }

        final section = project.sections[index];
        final sectionTasks = tasks.where((t) => t.sectionId == section || (t.sectionId == null && section == 'To Do'))
            .toList();
        sectionTasks.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        
        return DragTarget<ProjectTask>(
          onWillAccept: (data) => true,
          onAccept: (task) {
            ref.read(taskProvider.notifier).moveTaskToSection(task.id, section);
          },
          builder: (context, candidateData, rejectedData) => Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? Colors.blueAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: candidateData.isNotEmpty ? Border.all(color: Colors.blueAccent) : null,
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
                      _buildSectionMenu(project, section),
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
          ),
        );
      },
    );
  }

  Widget _buildAddSectionButton(Project project) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: TextButton.icon(
          onPressed: () => _showAddSectionDialog(project),
          icon: const Icon(Icons.add),
          label: const Text('Add Stage'),
          style: TextButton.styleFrom(foregroundColor: Colors.white24),
        ),
      ),
    );
  }

  void _showAddSectionDialog(Project project) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Add New Stage', style: TextStyle(color: Colors.white)),
        content: TextField(controller: controller, autofocus: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'e.g. Quality Assurance')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(projectProvider.notifier).addSection(project.id, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionMenu(Project project, String section) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white24, size: 16),
      onSelected: (val) {
        if (val == 'rename') _showRenameSectionDialog(project, section);
        if (val == 'delete') _showDeleteSectionDialog(project, section);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'rename', child: Text('Rename Stage')),
        const PopupMenuItem(value: 'delete', child: Text('Remove Stage', style: TextStyle(color: Colors.redAccent))),
      ],
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
        sectionTasks.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

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
     final card = Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                     decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                     child: Text(t, style: const TextStyle(color: Colors.blueAccent, fontSize: 10)),
                   )).toList(),
                 ),
               ),
          ],
        ),
      );

     return LongPressDraggable<ProjectTask>(
        data: task,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 280,
            child: card,
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: card),
        child: GestureDetector(
          onTap: () => _showEditTaskDialog(task, project),
          child: card,
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

  Future<void> _handleSync(Project project) async {
     final tasks = ref.read(taskProvider).where((t) => t.projectId == project.id).toList();
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting synchronization...')));
     await ProjectSyncService().syncProject(project, tasks);
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synchronization complete! Check Notion/Slack.'), backgroundColor: Colors.green));
     }
  }

  Widget _buildCalendarView(Project project) {
    final allTasks = ref.watch(taskProvider);
    final tasks = allTasks.where((t) => t.projectId == project.id).toList();

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: const CalendarStyle(
            defaultTextStyle: TextStyle(color: Colors.white),
            weekendTextStyle: TextStyle(color: Colors.white70),
            todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
          ),
          headerStyle: HeaderStyle(
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
            formatButtonTextStyle: const TextStyle(color: Colors.white54),
            formatButtonVisible: false,
            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
            rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
            titleCentered: true,
          ),
        ),
        const Divider(color: Colors.white12),
        Expanded(
          child: _selectedDay == null 
              ? const Center(child: Text('Select a day to see tasks', style: TextStyle(color: Colors.white24)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                     ...tasks.where((t) => t.dueDate != null && isSameDay(t.dueDate, _selectedDay)).map((t) => _buildTaskCard(t, project)),
                     if (tasks.where((t) => t.dueDate != null && isSameDay(t.dueDate, _selectedDay)).isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text('No tasks due on this day', style: TextStyle(color: Colors.white12)),
                        )),
                  ],
                ),
        ),
      ],
    );
  }

  void _showRenameSectionDialog(Project project, String section) {
    final controller = TextEditingController(text: section);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Rename Stage', style: TextStyle(color: Colors.white)),
        content: TextField(controller: controller, autofocus: true, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(projectProvider.notifier).renameSection(project.id, section, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSectionDialog(Project project, String section) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Remove Stage?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to remove "$section"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(projectProvider.notifier).removeSection(project.id, section);
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(Project project, {String? initialSection}) {
    final titleController = TextEditingController();
    String selectedSection = initialSection ?? project.sections.first;
    TaskPriority selectedPriority = TaskPriority.medium;
    _selectedDueDate = null; // Reset for new task

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
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_selectedDueDate == null ? 'Set Due Date' : 'Due: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.calendar_today, color: Colors.white38, size: 18),
                onTap: () async {
                   final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setDialogState(() => _selectedDueDate = picked);
                },
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
                  dueDate: _selectedDueDate,
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
    _selectedStartDate = task.startDate;
    _selectedDueDate = task.dueDate;
    _selectedEndDate = task.endDate;
    _selectedDoneDate = task.doneDate;
    final Map<String, dynamic> customFields = Map.from(task.customFields);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: Text(AppLocalizations.of(context)!.editTask, style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 16),
                _buildDatePickerTile('Start Date', _selectedStartDate, (d) => setDialogState(() => _selectedStartDate = d)),
                _buildDatePickerTile('Due Date', _selectedDueDate, (d) => setDialogState(() => _selectedDueDate = d)),
                _buildDatePickerTile('End Date', _selectedEndDate, (d) => setDialogState(() => _selectedEndDate = d)),
                _buildDatePickerTile('Done Date', _selectedDoneDate, (d) => setDialogState(() => _selectedDoneDate = d)),
                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const Text('MULTIMODAL FIELDS', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                ...customFields.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: Text('${e.key}: ${e.value}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      IconButton(icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent), onPressed: () => setDialogState(() => customFields.remove(e.key))),
                    ],
                  ),
                )),
                TextButton.icon(
                  onPressed: () => _showAddCustomFieldDialog(context, customFields, setDialogState),
                  icon: const Icon(Icons.add_link, size: 16),
                  label: const Text('Add Media/Field'),
                ),
              ],
            ),
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
                  dueDate: _selectedDueDate,
                  startDate: _selectedStartDate,
                  endDate: _selectedEndDate,
                  doneDate: _selectedDoneDate,
                  customFields: customFields,
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

  Widget _buildDatePickerTile(String label, DateTime? date, Function(DateTime) onPicked) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(date == null ? 'Set $label' : '$label: ${date.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
      trailing: const Icon(Icons.calendar_today, color: Colors.white12, size: 16),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  void _showAddCustomFieldDialog(BuildContext context, Map<String, dynamic> fields, StateSetter setDialogState) {
    final keyController = TextEditingController();
    final valController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Add Field (URL, Note, etc.)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: keyController, decoration: const InputDecoration(labelText: 'Field Type (e.g. Dropbox URL)')),
            TextField(controller: valController, decoration: const InputDecoration(labelText: 'Value (e.g. link or text)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (keyController.text.isNotEmpty) {
                setDialogState(() => fields[keyController.text] = valController.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
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
