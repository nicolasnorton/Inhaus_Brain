import 'package:flutter/foundation.dart';
import '../../clients/models/client_model.dart';
import '../../clients/models/project_model.dart';
import '../../clients/models/task_model.dart';
import 'knowledge_api_service.dart';

class KnowledgeIngestionService {
  final KnowledgeApiService _knowledgeApi;

  KnowledgeIngestionService(this._knowledgeApi);

  Future<void> ingestClient(Client client) async {
    debugPrint('Autonomous Ingestion: Processing Client ${client.name}...');
    final content = """
Client: ${client.name}
Industry: ${client.industry}
Contact: ${client.primaryContactEmail}
Summary: ${client.description}
Custom Fields: ${client.customFields}
""";
    
    await _knowledgeApi.createDocumentFromText(
      datasetId: 'clients-intelligence', // Assuming a default intelligence dataset
      name: 'Client: ${client.name}',
      text: content,
    );
  }

  Future<void> ingestProject(Project project, List<ProjectTask> tasks) async {
    debugPrint('Autonomous Ingestion: Processing Project ${project.name}...');
    final taskSummary = tasks.map((t) => "- ${t.title} (${t.status.name})").join('\n');
    final content = """
Project: ${project.name}
Description: ${project.description}
Status: ${project.status.name}
Timeline: ${project.startDate} to ${project.endDate}
Tasks:
$taskSummary
""";

    await _knowledgeApi.createDocumentFromText(
      datasetId: 'project-intelligence',
      name: 'Project: ${project.name}',
      text: content,
    );
  }

  Future<void> ingestCopilotScreencap(String historySnippet, {List<int>? attachment}) async {
    // Create the future but don't await it yet
    final ingestionFuture = _knowledgeApi.createDocumentFromText(
      datasetId: 'agent-learnings',
      name: 'Copilot Learning ${DateTime.now().toIso8601String()}',
      text: historySnippet,
    );

    // CRITICAL: Attach a catchError to the ORIGINAL future to prevent uncaught exceptions
    // if the timeout fires first and the original future subsequently fails.
    ingestionFuture.catchError((e) {
      debugPrint('Background Ingestion Failed (Silently Caught): ${_safeError(e)}');
      return null; // Return value doesn't matter, just need to handle the error
    });

    try {
      // Now await with timeout
      await ingestionFuture.timeout(const Duration(seconds: 10));
    } catch (e) {
      // Swallowed to prevent dangling future crashes after timeout
      debugPrint('Ingestion Timeout/Error (Handled): ${_safeError(e)}');
    }
  }

  static String _safeError(dynamic e) {
    if (e == null) return "Unknown Error (null)";
    try {
      final dynamic err = e;
      return err.toString();
    } catch (_) {
      return "Error parsing exception";
    }
  }
}
