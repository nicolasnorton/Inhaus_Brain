import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';

class TaskNotifier extends StateNotifier<List<ProjectTask>> {
  TaskNotifier() : super([]) {
    _loadMockTasks();
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
  }

  void addTask(String projectId, String title, String description, {DateTime? dueDate, String? assigneeId}) {
    final newTask = ProjectTask(
      id: const Uuid().v4(),
      projectId: projectId,
      title: title,
      description: description,
      dueDate: dueDate,
      assigneeId: assigneeId,
    );
    state = [...state, newTask];
  }

  void updateTask(ProjectTask updatedTask) {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task
    ];
  }

  void deleteTask(String taskId) {
    state = state.where((t) => t.id != taskId).toList();
  }

  List<ProjectTask> getTasksForProject(String projectId) {
    return state.where((t) => t.projectId == projectId).toList();
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, List<ProjectTask>>((ref) => TaskNotifier());
