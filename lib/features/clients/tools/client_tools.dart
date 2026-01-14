import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import 'package:inhaus_brain/features/clients/models/project_model.dart';
import 'package:inhaus_brain/features/clients/models/task_model.dart';
import 'package:inhaus_brain/features/clients/models/client_model.dart';
import 'package:inhaus_brain/features/clients/providers/project_provider.dart';
import 'package:inhaus_brain/features/clients/providers/task_provider.dart';
import 'package:inhaus_brain/features/clients/providers/client_provider.dart';

class CreateProjectTool extends AgentTool {
  final ProjectNotifier _notifier;

  CreateProjectTool(this._notifier)
      : super(
          name: 'create_project',
          description: 'Create a new project for a client.',
          inputSchema: {
            'clientId': {
              'type': 'string',
              'description': 'The ID of the client.',
            },
            'name': {
              'type': 'string',
              'description': 'Name of the project.',
            },
            'description': {
              'type': 'string',
              'description': 'Description of the project.',
            },
            'startDate': {
              'type': 'string',
              'description': 'Start date (YYYY-MM-DD).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final clientId = (parameters['clientId'] ?? parameters['client_id']) as String?;
    final name = (parameters['name'] ?? parameters['project_name']) as String?;
    final description = parameters['description'] as String? ?? 'No description provided.';
    final startDateStr = parameters['startDate'] as String? ?? DateTime.now().toIso8601String().split('T')[0];

    if (clientId == null || name == null) {
      return ToolResult.failure('Missing required parameters: clientId and name are required.');
    }

    try {
      final startDate = DateTime.parse(startDateStr);
      // ProjectNotifier takes raw args, not a Project object
      _notifier.addProject(clientId, name, description);
      
      return ToolResult.success({'message': 'Project created successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to create project: $e');
    }
  }
}

class CreateTaskTool extends AgentTool {
  final TaskNotifier _notifier;

  CreateTaskTool(this._notifier)
      : super(
          name: 'create_task',
          description: 'Create a new task in a project.',
          inputSchema: {
            'projectId': {
              'type': 'string',
              'description': 'The ID of the project.',
            },
            'title': {
              'type': 'string',
              'description': 'Title of the task.',
            },
            'description': {
              'type': 'string',
              'description': 'Description of the task.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final projectId = parameters['projectId'] as String?;
    final title = parameters['title'] as String?;
    final description = parameters['description'] as String?;

    if (projectId == null || title == null) {
      return ToolResult.failure('Missing required parameters.');
    }

    try {
       // TaskNotifier takes raw args
       _notifier.addTask(projectId, title, description ?? '');
      return ToolResult.success({'message': 'Task created successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to create task: $e');
    }
  }
}

class UpdateTaskTool extends AgentTool {
  final TaskNotifier _notifier;
  final List<ProjectTask> _tasks;

  UpdateTaskTool(this._notifier, this._tasks)
      : super(
          name: 'update_task',
          description: 'Update the title or description of a task.',
          inputSchema: {
            'taskId': {
              'type': 'string',
              'description': 'The ID of the task to update.',
            },
            'title': {
              'type': 'string',
              'description': 'New title for the task (optional).',
            },
            'description': {
              'type': 'string',
              'description': 'New description for the task (optional).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final taskId = (parameters['taskId'] ?? parameters['id']) as String?;
    final newTitle = (parameters['title'] ?? parameters['task_title']) as String?;
    final newDescription = parameters['description'] as String?;

    if (taskId == null) {
      return ToolResult.failure('Missing required parameter: "taskId" is required.');
    }

    try {
      final task = _tasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw Exception('Task with ID $taskId not found.'),
      );

      final updatedTask = task.copyWith(
        title: newTitle,
        description: newDescription,
      );

      await _notifier.updateTask(updatedTask);
      return ToolResult.success({'message': 'Task updated successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to update task: $e');
    }
  }
}

class DeleteTaskTool extends AgentTool {
  final TaskNotifier _notifier;

  DeleteTaskTool(this._notifier)
      : super(
          name: 'delete_task',
          description: 'Delete a task.',
          inputSchema: {
            'taskId': {
              'type': 'string',
              'description': 'The ID of the task to delete.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final taskId = (parameters['taskId'] ?? parameters['id']) as String?;

    if (taskId == null) {
      return ToolResult.failure('Missing required parameter: "taskId" is required.');
    }

    try {
      await _notifier.deleteTask(taskId);
      return ToolResult.success({'message': 'Task deleted successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to delete task: $e');
    }
  }
}

final clientToolsProvider = Provider<List<AgentTool>>((ref) {
  final projectNotifier = ref.read(projectProvider.notifier);
  final taskNotifier = ref.read(taskProvider.notifier);
  final clientNotifier = ref.read(clientProvider.notifier);
  final clients = ref.watch(clientProvider);
  final projects = ref.watch(projectProvider);
  final tasks = ref.watch(taskProvider);
  
  return [
    CreateClientTool(clientNotifier),
    UpdateClientTool(clientNotifier, clients),
    DeleteClientTool(clientNotifier),
    ListClientsTool(clients),
    CreateProjectTool(projectNotifier),
    UpdateProjectTool(projectNotifier, projects),
    DeleteProjectTool(projectNotifier),
    CreateTaskTool(taskNotifier),
    UpdateTaskTool(taskNotifier, tasks),
    DeleteTaskTool(taskNotifier),
  ];
});

class UpdateProjectTool extends AgentTool {
  final ProjectNotifier _notifier;
  final List<Project> _projects;

  UpdateProjectTool(this._notifier, this._projects)
      : super(
          name: 'update_project',
          description: 'Update the name or description of an existing project.',
          inputSchema: {
            'projectId': {
              'type': 'string',
              'description': 'The ID of the project to update.',
            },
            'name': {
              'type': 'string',
              'description': 'New name for the project (optional).',
            },
            'description': {
              'type': 'string',
              'description': 'New description for the project (optional).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final projectId = (parameters['projectId'] ?? parameters['id']) as String?;
    final newName = (parameters['name'] ?? parameters['project_name']) as String?;
    final newDescription = parameters['description'] as String?;

    if (projectId == null) {
      return ToolResult.failure('Missing required parameter: "projectId" is required.');
    }

    try {
      final project = _projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => throw Exception('Project with ID $projectId not found.'),
      );

      final updatedProject = project.copyWith(
        name: newName,
        description: newDescription,
      );

      await _notifier.updateProject(updatedProject);
      return ToolResult.success({'message': 'Project updated successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to update project: $e');
    }
  }
}

class DeleteProjectTool extends AgentTool {
  final ProjectNotifier _notifier;

  DeleteProjectTool(this._notifier)
      : super(
          name: 'delete_project',
          description: 'Delete a project.',
          inputSchema: {
            'projectId': {
              'type': 'string',
              'description': 'The ID of the project to delete.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final projectId = (parameters['projectId'] ?? parameters['id']) as String?;

    if (projectId == null) {
      return ToolResult.failure('Missing required parameter: "projectId" is required.');
    }

    try {
      await _notifier.deleteProject(projectId);
      return ToolResult.success({'message': 'Project deleted successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to delete project: $e');
    }
  }
}

class UpdateClientTool extends AgentTool {
  final ClientNotifier _notifier;
  final List<Client> _clients;

  UpdateClientTool(this._notifier, this._clients)
      : super(
          name: 'update_client',
          description: 'Update the name or industry of an existing client.',
          inputSchema: {
            'clientId': {
              'type': 'string',
              'description': 'The ID (not name) of the client to update.',
            },
            'name': {
              'type': 'string',
              'description': 'New name for the client (optional).',
            },
            'industry': {
              'type': 'string',
              'description': 'New industry for the client (optional).',
            },
            'email': {
              'type': 'string',
              'description': 'New contact email for the client (optional).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final clientId = (parameters['clientId'] ?? parameters['id']) as String?;
    final newName = (parameters['name'] ?? parameters['client_name']) as String?;
    final newIndustry = (parameters['industry'] ?? parameters['sector']) as String?;
    final newEmail = (parameters['email'] ?? parameters['contact']) as String?;

    if (clientId == null) {
      return ToolResult.failure('Missing required parameter: "clientId" is required.');
    }

    try {
      final client = _clients.firstWhere(
        (c) => c.id == clientId,
        orElse: () => throw Exception('Client with ID $clientId not found.'),
      );

      final updatedClient = client.copyWith(
        name: newName,
        industry: newIndustry,
        primaryContactEmail: newEmail,
      );

      await _notifier.updateClient(updatedClient);
      return ToolResult.success({'message': 'Client updated successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to update client: $e');
    }
  }
}

class DeleteClientTool extends AgentTool {
  final ClientNotifier _notifier;

  DeleteClientTool(this._notifier)
      : super(
          name: 'delete_client',
          description: 'Delete a client from the system permanently.',
          inputSchema: {
            'clientId': {
              'type': 'string',
              'description': 'The ID of the client to delete.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final clientId = (parameters['clientId'] ?? parameters['id']) as String?;

    if (clientId == null) {
      return ToolResult.failure('Missing required parameter: "clientId" is required.');
    }

    try {
      await _notifier.deleteClient(clientId);
      return ToolResult.success({'message': 'Client deleted successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to delete client: $e');
    }
  }
}

class CreateClientTool extends AgentTool {
  final ClientNotifier _notifier;

  CreateClientTool(this._notifier)
      : super(
          name: 'create_client',
          description: 'Add a new client to the system.',
          inputSchema: {
            'name': {
              'type': 'string',
              'description': 'Name of the client.',
            },
            'industry': {
              'type': 'string',
              'description': 'Industry of the client.',
            },
            'email': {
              'type': 'string',
              'description': 'Contact email of the client (optional).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final name = (parameters['name'] ?? parameters['client_name']) as String?;
    final industry = (parameters['industry'] ?? parameters['sector']) as String? ?? 'General';
    final email = (parameters['email'] ?? parameters['contact']) as String?;

    if (name == null) {
      return ToolResult.failure('Missing required parameter: "name" (or "client_name") is required.');
    }

    try {
      await _notifier.addClient(name, industry, email: email);
      return ToolResult.success({'message': 'Client "$name" added successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to add client: $e');
    }
  }
}

class ListClientsTool extends AgentTool {
  final List<Client> _clients;

  ListClientsTool(this._clients)
      : super(
          name: 'list_clients',
          description: 'List all clients in the system.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    return ToolResult.success({
      'clients': _clients.map((c) => {
        'id': c.id,
        'name': c.name,
        'industry': c.industry,
      }).toList(),
    });
  }
}
