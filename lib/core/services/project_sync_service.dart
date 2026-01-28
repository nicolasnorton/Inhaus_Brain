import 'package:flutter/foundation.dart';
import '../../features/clients/models/project_model.dart';
import '../../features/clients/models/task_model.dart';
import '../../features/clients/services/integration_services.dart';

class ProjectSyncService {
  final NotionService _notion = NotionService();
  final SlackService _slack = SlackService();
  final GmailService _gmail = GmailService();
  // ... other services

  Future<void> syncProject(Project project, List<ProjectTask> tasks) async {
    debugPrint('Syncing Project: ${project.name} to all connected services...');
    
    // 1. Sync to Notion (create database or update pages)
    await _notion.createPage(project.id, {
      'Project': project.name,
      'Tasks': tasks.length,
    });

    // 2. Notify Slack
    await _slack.sendMessage('#projects', 'Project ${project.name} has been synced. Total tasks: ${tasks.length}');

    // 3. Calendar Sync (Mock)
    debugPrint('Syncing to Google Calendar...');
    
    // 4. Drive Sync (Mock)
    debugPrint('Syncing to Google Drive and Dropbox...');

    // 5. Otter.ai (Mock)
    debugPrint('Syncing meeting notes from Otter.ai...');

    await Future.delayed(const Duration(seconds: 2));
    debugPrint('Sync Complete.');
  }
}
