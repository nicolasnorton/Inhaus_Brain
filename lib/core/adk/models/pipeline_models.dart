
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

  Pipeline copyWith({
    String? id,
    String? name,
    String? description,
    List<PipelineStep>? steps,
  }) {
    return Pipeline(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
    );
  }

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

enum WorkflowNodeType {
  start,
  userInput,
  trigger,
  llm,
  knowledgeRetrieval,
  answer,
  output,
  agent,
  tool,
  questionClassifier,
  ifElse,
  iteration,
  loop,
  code,
  template,
  variableAggregator,
  documentExtractor,
  variableAssigner,
  parameterExtractor,
  httpRequest,
  listOperator,
  note
}

enum PipelineStepType { sequential, parallel, loop }

class PipelineStep {
  final String id;
  final WorkflowNodeType nodeType;
  final MessageSender? agentType; // Keep for legacy/agent nodes
  final String instruction; 
  final bool requiresApproval; 
  final PipelineStepType type;
  final List<PipelineStep>? parallelSteps; 
  final String? loopCondition; 
  final List<String> dependencies; 
  final Map<String, double>? uiPosition; 
  
  // New Dify-style fields
  final Map<String, dynamic> config;
  final Map<String, String> inputMappings; // node_id.output_name -> input_name

  PipelineStep({
    required this.id,
    this.nodeType = WorkflowNodeType.agent,
    this.agentType,
    this.instruction = '',
    this.requiresApproval = false,
    this.type = PipelineStepType.sequential,
    this.parallelSteps,
    this.loopCondition,
    this.dependencies = const [],
    this.uiPosition,
    this.config = const {},
    this.inputMappings = const {},
  });

  String get label => instruction.isNotEmpty ? instruction : nodeType.name.toUpperCase();

  PipelineStep copyWith({
    String? id,
    WorkflowNodeType? nodeType,
    MessageSender? agentType,
    String? instruction,
    bool? requiresApproval,
    PipelineStepType? type,
    List<PipelineStep>? parallelSteps,
    String? loopCondition,
    List<String>? dependencies,
    Map<String, double>? uiPosition,
    Map<String, dynamic>? config,
    Map<String, String>? inputMappings,
  }) {
    return PipelineStep(
      id: id ?? this.id,
      nodeType: nodeType ?? this.nodeType,
      agentType: agentType ?? this.agentType,
      instruction: instruction ?? this.instruction,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      type: type ?? this.type,
      parallelSteps: parallelSteps ?? this.parallelSteps,
      loopCondition: loopCondition ?? this.loopCondition,
      dependencies: dependencies ?? this.dependencies,
      uiPosition: uiPosition ?? this.uiPosition,
      config: config ?? this.config,
      inputMappings: inputMappings ?? this.inputMappings,
    );
  }

  factory PipelineStep.fromJson(Map<String, dynamic> json) {
    return PipelineStep(
      id: json['id'] as String,
      nodeType: WorkflowNodeType.values.firstWhere(
        (e) => e.name == (json['nodeType'] ?? 'agent'),
        orElse: () => WorkflowNodeType.agent,
      ),
      agentType: json['agentType'] != null 
          ? MessageSender.values.firstWhere((e) => e.name == json['agentType'])
          : null,
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
      config: Map<String, dynamic>.from(json['config'] ?? {}),
      inputMappings: Map<String, String>.from(json['inputMappings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nodeType': nodeType.name,
    if (agentType != null) 'agentType': agentType!.name,
    'instruction': instruction,
    'requiresApproval': requiresApproval,
    'type': type.name,
    if (parallelSteps != null) 'parallelSteps': parallelSteps!.map((e) => e.toJson()).toList(),
    if (loopCondition != null) 'loopCondition': loopCondition,
    'dependencies': dependencies,
    if (uiPosition != null) 'uiPosition': uiPosition,
    'config': config,
    'inputMappings': inputMappings,
  };
}
