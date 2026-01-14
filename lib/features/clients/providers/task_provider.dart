import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:inhaus_brain/features/clients/models/task_model.dart';
import 'package:inhaus_brain/core/services/local_persistence_service.dart';

class TaskNotifier extends StateNotifier<List<ProjectTask>> {
  final LocalPersistenceService _persistenceService;

  TaskNotifier(this._persistenceService) : super([]) {
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

  Future<void> addTask(String projectId, String title, String description, {DateTime? dueDate, String? assigneeId}) async {
    final newTask = ProjectTask(
      id: const Uuid().v4(),
      projectId: projectId,
      title: title,
      description: description,
      dueDate: dueDate,
      assigneeId: assigneeId,
    );
    state = [...state, newTask];
    await _persistenceService.saveTasks(state);
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

  List<ProjectTask> getTasksForProject(String projectId) {
    return state.where((t) => t.projectId == projectId).toList();
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, List<ProjectTask>>((ref) {
  final persistence = ref.watch(persistenceServiceProvider);
  return TaskNotifier(persistence);
});
