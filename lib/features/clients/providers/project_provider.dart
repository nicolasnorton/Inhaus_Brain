import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';

class ProjectNotifier extends StateNotifier<List<Project>> {
  ProjectNotifier() : super([]) {
    _loadMockProjects();
  }

  void _loadMockProjects() {
    state = [
      Project(
        id: 'proj-1',
        clientId: 'client-1',
        name: 'Website Redesign',
        description: 'Overhaul the main agency website for better conversion.',
        status: ProjectStatus.inProgress,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Project(
        id: 'proj-2',
        clientId: 'client-1',
        name: 'Brand Refresh',
        description: 'New visual identity and style guide.',
        status: ProjectStatus.planning,
        startDate: DateTime.now(),
      ),
    ];
  }

  void addProject(String clientId, String name, String description) {
    final newProject = Project(
      id: const Uuid().v4(),
      clientId: clientId,
      name: name,
      description: description,
      startDate: DateTime.now(),
    );
    state = [...state, newProject];
  }

  void updateProject(Project updatedProject) {
    state = [
      for (final project in state)
        if (project.id == updatedProject.id) updatedProject else project
    ];
  }

  void deleteProject(String projectId) {
    state = state.where((p) => p.id != projectId).toList();
  }

  List<Project> getProjectsForClient(String clientId) {
    return state.where((p) => p.clientId == clientId).toList();
  }
}

final projectProvider = StateNotifierProvider<ProjectNotifier, List<Project>>((ref) => ProjectNotifier());
