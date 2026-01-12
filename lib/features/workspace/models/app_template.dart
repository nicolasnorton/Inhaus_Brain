import '../../../core/adk/models/pipeline_models.dart';
import 'app_models.dart';

class AppTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AppType appType;
  final Map<String, dynamic> defaultConfig;
  final List<PipelineStep>? pipelineSteps;

  const AppTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.appType,
    required this.defaultConfig,
    this.pipelineSteps,
  });
}
