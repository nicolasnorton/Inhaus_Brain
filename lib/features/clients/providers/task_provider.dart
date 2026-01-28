import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:inhaus_brain/features/knowledge/providers/knowledge_service_providers.dart';
import 'package:inhaus_brain/features/clients/providers/project_provider.dart';
import 'package:inhaus_brain/features/clients/models/task_model.dart';
import 'package:inhaus_brain/core/services/local_persistence_service.dart';

class TaskNotifier extends StateNotifier<List<ProjectTask>> {
  final LocalPersistenceService _persistenceService;
  final Ref _ref;
 
  TaskNotifier(this._persistenceService, this._ref) : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _persistenceService.getTasks();
    if (tasks.isEmpty) {
      _loadMockTasks();
    } else {
      state = tasks;
    }
  }

  void _loadMockTasks() {
    state = [
      ProjectTask(
        id: 'task-1',
        projectId: 'proj-1',
        title: 'Draft Wireframes',
        description: 'Create initial wireframes for the homepage.',
        status: TaskStatus.done,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ProjectTask(
        id: 'task-2',
        projectId: 'proj-1',
        title: 'Visual Design',
        description: 'Style the wireframes with new brand colors.',
        status: TaskStatus.inProgress,
        dueDate: DateTime.now().add(const Duration(days: 5)),
      ),
      ProjectTask(
        id: 'task-3',
        projectId: 'proj-2',
        title: 'Logo Concepting',
        description: 'Sketch 5 different logo directions.',
        status: TaskStatus.todo,
        dueDate: DateTime.now().add(const Duration(days: 7)),
      ),
    ];
    _persistenceService.saveTasks(state);
  }

  Future<void> addTask(String projectId, String title, String description, {
    DateTime? dueDate,
    String? assigneeId,
    String? priorityStr,
    String? sectionId,
    List<String>? tags,
  }) async {
    final priority = TaskPriority.values.firstWhere(
      (e) => e.toString() == 'TaskPriority.${priorityStr?.toLowerCase() ?? 'medium'}',
      orElse: () => TaskPriority.medium,
    );

    final newTask = ProjectTask(
      id: const Uuid().v4(),
      projectId: projectId,
      title: title,
      description: description,
      dueDate: dueDate,
      assigneeId: assigneeId,
      priority: priority,
      sectionId: sectionId,
      tags: tags ?? [],
    );
    state = [...state, newTask];
    await _persistenceService.saveTasks(state);
    _triggerIngestion(projectId);
  }

  Future<void> _triggerIngestion(String projectId) async {
    final project = _ref.read(projectProvider).firstWhere((p) => p.id == projectId);
    final tasks = state.where((t) => t.projectId == projectId).toList();
    _ref.read(knowledgeIngestionServiceProvider).ingestProject(project, tasks);
  }

  Future<void> updateTask(ProjectTask updatedTask) async {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task
    ];
    await _persistenceService.saveTasks(state);
  }

  Future<void> deleteTask(String taskId) async {
    state = state.where((t) => t.id != taskId).toList();
    await _persistenceService.saveTasks(state);
  }

  Future<void> moveTaskToSection(String taskId, String sectionId) async {
    state = [
      for (final task in state)
        if (task.id == taskId) task.copyWith(sectionId: sectionId) else task
    ];
    await _persistenceService.saveTasks(state);
  }

  Future<void> reorderTask(String taskId, int newIndex, {String? sectionId}) async {
    final tasksInTarget = state.where((t) => t.projectId == state.firstWhere((st) => st.id == taskId).projectId && (sectionId == null || t.sectionId == sectionId)).toList();
    tasksInTarget.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    
    // Logic to update orderIndex for elements
    // For simplicity, we just set the new index and push others
    final currentTask = state.firstWhere((t) => t.id == taskId);
    final updatedList = List<ProjectTask>.from(state);
    
    // This is a simplified reorder logic
    int idx = 0;
    state = [
      for (final t in state)
        if (t.id == taskId) t.copyWith(orderIndex: newIndex, sectionId: sectionId ?? t.sectionId)
        else t.copyWith(orderIndex: idx++)
    ];
    await _persistenceService.saveTasks(state);
  }

  List<ProjectTask> getTasksForProject(String projectId) {
    return state.where((t) => t.projectId == projectId).toList();
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, List<ProjectTask>>((ref) {
  final persistence = ref.watch(persistenceServiceProvider);
  return TaskNotifier(persistence, ref);
});
