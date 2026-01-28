import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:inhaus_brain/features/clients/models/project_model.dart';
import 'package:inhaus_brain/core/services/local_persistence_service.dart';

class ProjectNotifier extends StateNotifier<List<Project>> {
  final LocalPersistenceService _persistenceService;

  ProjectNotifier(this._persistenceService) : super([]) {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await _persistenceService.getProjects();
    if (projects.isEmpty) {
      _loadMockProjects();
    } else {
      state = projects;
    }
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
    _persistenceService.saveProjects(state);
  }

  Future<void> addProject(String clientId, String name, String description, {
    List<String>? sections,
    String? priorityStr,
  }) async {
    final priority = ProjectPriority.values.firstWhere(
      (e) => e.toString() == 'ProjectPriority.${priorityStr?.toLowerCase() ?? 'medium'}',
      orElse: () => ProjectPriority.medium,
    );

    final newProject = Project(
      id: const Uuid().v4(),
      clientId: clientId,
      name: name,
      description: description,
      status: ProjectStatus.planning,
      priority: priority,
      startDate: DateTime.now(),
      sections: sections ?? ['To Do', 'In Progress', 'Done'],
    );
    state = [...state, newProject];
    await _persistenceService.saveProjects(state);
  }

  Future<void> updateProject(Project updatedProject) async {
    state = [
      for (final project in state)
        if (project.id == updatedProject.id) updatedProject else project
    ];
    await _persistenceService.saveProjects(state);
  }

  Future<void> deleteProject(String projectId) async {
    state = state.where((p) => p.id != projectId).toList();
    await _persistenceService.saveProjects(state);
  }

  Future<void> addSection(String projectId, String sectionName) async {
    state = [
      for (final p in state)
        if (p.id == projectId) p.copyWith(sections: [...p.sections, sectionName]) else p
    ];
    await _persistenceService.saveProjects(state);
  }

  Future<void> removeSection(String projectId, String sectionName) async {
    state = [
      for (final p in state)
        if (p.id == projectId) p.copyWith(sections: p.sections.where((s) => s != sectionName).toList()) else p
    ];
    await _persistenceService.saveProjects(state);
  }

  Future<void> renameSection(String projectId, String oldName, String newName) async {
    state = [
      for (final p in state)
        if (p.id == projectId) p.copyWith(sections: p.sections.map((s) => s == oldName ? newName : s).toList()) else p
    ];
    await _persistenceService.saveProjects(state);
  }

  List<Project> getProjectsForClient(String clientId) {
    return state.where((p) => p.clientId == clientId).toList();
  }
}

final projectProvider = StateNotifierProvider<ProjectNotifier, List<Project>>((ref) {
  final persistence = ref.watch(persistenceServiceProvider);
  return ProjectNotifier(persistence);
});
