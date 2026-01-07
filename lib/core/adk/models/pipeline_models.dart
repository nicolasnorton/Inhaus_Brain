import 'package:uuid/uuid.dart';
import '../../../features/chat/models/chat_models.dart';

class Pipeline {
  final String id;
  final String name;
  final String description;
  final List<PipelineStep> steps;

  Pipeline({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
  });

  factory Pipeline.fromJson(Map<String, dynamic> json) {
    return Pipeline(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List)
          .map((e) => PipelineStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'steps': steps.map((e) => e.toJson()).toList(),
  };
}

enum PipelineStepType { sequential, parallel, loop }

class PipelineStep {
  final String id;
  final MessageSender agentType;
  final String instruction; // Override or specific instruction for this step
  final bool requiresApproval; // If true, pauses pipeline for user action
  final PipelineStepType type;
  final List<PipelineStep>? parallelSteps; // Steps to run in parallel
  final String? loopCondition; // Descriptive condition for looping
  final List<String> dependencies; // DAG: IDs of steps that must finish first
  final Map<String, double>? uiPosition; // Canvas: {x: 100.0, y: 200.0}

  PipelineStep({
    required this.id,
    required this.agentType,
    this.instruction = '',
    this.requiresApproval = false,
    this.type = PipelineStepType.sequential,
    this.parallelSteps,
    this.loopCondition,
    this.dependencies = const [],
    this.uiPosition,
  });

  factory PipelineStep.fromJson(Map<String, dynamic> json) {
    return PipelineStep(
      id: json['id'] as String,
      agentType: MessageSender.values.firstWhere((e) => e.name == json['agentType']),
      instruction: json['instruction'] as String? ?? '',
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      type: PipelineStepType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'sequential'),
        orElse: () => PipelineStepType.sequential,
      ),
      parallelSteps: json['parallelSteps'] != null
          ? (json['parallelSteps'] as List)
              .map((e) => PipelineStep.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      loopCondition: json['loopCondition'] as String?,
      dependencies: (json['dependencies'] as List?)?.map((e) => e as String).toList() ?? [],
      uiPosition: json['uiPosition'] != null ? Map<String, double>.from(json['uiPosition']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'agentType': agentType.name,
    'instruction': instruction,
    'requiresApproval': requiresApproval,
    'type': type.name,
    if (parallelSteps != null) 'parallelSteps': parallelSteps!.map((e) => e.toJson()).toList(),
    if (loopCondition != null) 'loopCondition': loopCondition,
    'dependencies': dependencies,
    if (uiPosition != null) 'uiPosition': uiPosition,
  };
}
