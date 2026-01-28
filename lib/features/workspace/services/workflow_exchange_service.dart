import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../../core/utils/downloader/downloader.dart';

import '../models/app_models.dart';
import '../providers/apps_provider.dart';
import '../../adk/providers/pipeline_provider.dart';
import '../../../core/adk/models/pipeline_models.dart';

class WorkflowExchangeService {
  final WidgetRef ref;

  WorkflowExchangeService(this.ref);

  Future<void> exportApp(String appId) async {
    // 1. Get App
    final apps = ref.read(appsProvider);
    final app = apps.firstWhere((a) => a.id == appId);

    // 2. Get Pipeline (if applicable)
    final pipelines = ref.read(pipelineProvider);
    final pipeline = pipelines.firstWhere(
      (p) => p.id == appId,
      orElse: () => Pipeline(id: appId, name: app.name, description: app.description, steps: []),
    );

    // 3. Create DSL
    final dsl = AppDSL(
      version: '1.0.0',
      kind: 'app',
      app: app,
      workflow: pipeline.toJson(),
    );

    // 4. Export
    await _downloadJson(dsl.toJsonString(), "${app.name.replaceAll(' ', '_')}.json");
  }

  Future<void> exportPipeline(Pipeline pipeline, {String? fileName}) async {
    final actualFileName = fileName ?? "${pipeline.name.replaceAll(' ', '_')}.json";
    await _downloadJson(jsonEncode(pipeline.toJson()), actualFileName);
  }

  Future<void> _downloadJson(String jsonString, String fileName) async {
    downloadJson(jsonString, fileName);
  }

  Future<bool> importApp() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        String? fileContent;

        if (kIsWeb) {
          final bytes = result.files.first.bytes;
          if (bytes != null) fileContent = utf8.decode(bytes);
        } else {
          final bytes = result.files.first.bytes;
          if (bytes != null) fileContent = utf8.decode(bytes);
        }

        if (fileContent != null) {
          final Map<String, dynamic> json = jsonDecode(fileContent);

          // Detect format: AppDSL vs Raw Pipeline
          if (json.containsKey('kind') && json['kind'] == 'app') {
            return await _importFromDSL(AppDSL.fromJsonString(fileContent)!);
          } else if (json.containsKey('steps') || json.containsKey('nodes')) {
            // It's a raw pipeline
            final pipeline = Pipeline.fromJson(json);
            return await _importFromPipeline(pipeline);
          }
        }
      }
    } catch (e) {
      debugPrint("Import failed: $e");
    }
    return false;
  }

  Future<bool> _importFromDSL(AppDSL dsl) async {
    final newAppId = '${dsl.app.id}_imported_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create App
    final newApp = dsl.app.copyWith(
      id: newAppId,
      name: '${dsl.app.name} (Imported)',
      status: AppStatus.draft,
    );
    ref.read(appsProvider.notifier).createApp(newApp);

    // Create Pipeline
    if (dsl.workflow.isNotEmpty) {
       final pipelineJson = Map<String, dynamic>.from(dsl.workflow);
       pipelineJson['id'] = newAppId; // Sync IDs
       pipelineJson['name'] = newApp.name;
       final newPipeline = Pipeline.fromJson(pipelineJson);
       ref.read(pipelineProvider.notifier).savePipeline(newPipeline);
    }
    return true;
  }

  Future<bool> _importFromPipeline(Pipeline pipeline) async {
    final newAppId = 'pipeline_imported_${DateTime.now().millisecondsSinceEpoch}';
    final name = '${pipeline.name} (Imported)';
    
    // Create App as generic workflow
    final newApp = App(
      id: newAppId,
      name: name,
      type: AppType.workflow,
      description: pipeline.description,
      icon: '🔄',
      status: AppStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    ref.read(appsProvider.notifier).createApp(newApp);

    // Create Pipeline
    final newPipeline = pipeline.copyWith(
      id: newAppId,
      name: name,
    );
    ref.read(pipelineProvider.notifier).savePipeline(newPipeline);
    
    return true;
  }
}
