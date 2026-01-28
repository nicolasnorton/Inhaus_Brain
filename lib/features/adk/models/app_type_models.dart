/// Models for INHAUS BRAIN app types and configurations
library;

import '../../workspace/models/app_models.dart' show AppType;
export '../../workspace/models/app_models.dart' show AppType;

/// Extension on AppType for INHAUS BRAIN-specific logic
extension AppTypeExtensions on AppType {
  String get apiValue {
    switch (this) {
      case AppType.workflow:
        return 'workflow';
      case AppType.chatflow:
        return 'chatflow';
      case AppType.chatbot:
        return 'chatbot';
      case AppType.agent:
        return 'agent';
      case AppType.textGenerator:
        return 'completion';
    }
  }

  String get description {
    switch (this) {
      case AppType.workflow:
        return 'Agentic flow for intelligent automations';
      case AppType.chatflow:
        return 'Workflow enhanced for multi-turn chats';
      case AppType.chatbot:
        return 'LLM-based chatbot with simple setup';
      case AppType.agent:
        return 'Intelligent agent with reasoning and autonomous tool use';
      case AppType.textGenerator:
        return 'AI assistant for text generation tasks';
    }
  }

  bool get isRecommended {
    return this == AppType.workflow || this == AppType.chatflow;
  }

  bool get isLegacy {
    return this == AppType.chatbot || 
           this == AppType.agent || 
           this == AppType.textGenerator;
  }

  bool get supportsConversation {
    return this == AppType.chatflow || this == AppType.chatbot || this == AppType.agent;
  }

  bool get supportsTrigger {
    return this == AppType.workflow;
  }
}

/// Start node type for workflows
enum StartNodeType {
  userInput,
  trigger;

  String get displayName {
    switch (this) {
      case StartNodeType.userInput:
        return 'User Input';
      case StartNodeType.trigger:
        return 'Trigger';
    }
  }

  String get description {
    switch (this) {
      case StartNodeType.userInput:
        return 'Direct user interaction or API call invokes the app';
      case StartNodeType.trigger:
        return 'The application runs automatically on a schedule or in response to a specific third-party event';
    }
  }
}

/// System variables for workflows
class WorkflowSystemVariables {
  final String userId;
  final String appId;
  final String workflowId;
  final String workflowRunId;
  final int timestamp;

  const WorkflowSystemVariables({
    required this.userId,
    required this.appId,
    required this.workflowId,
    required this.workflowRunId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'sys.user_id': userId,
        'sys.app_id': appId,
        'sys.workflow_id': workflowId,
        'sys.workflow_run_id': workflowRunId,
        'sys.timestamp': timestamp,
      };
}

/// System variables for chatflows
class ChatflowSystemVariables extends WorkflowSystemVariables {
  final String conversationId;
  final int dialogueCount;

  const ChatflowSystemVariables({
    required this.conversationId,
    required this.dialogueCount,
    required super.userId,
    required super.appId,
    required super.workflowId,
    required super.workflowRunId,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'sys.conversation_id': conversationId,
        'sys.dialogue_count': dialogueCount,
      };
}

/// Variable data type
enum VariableDataType {
  string,
  number,
  object,
  arrayString,
  arrayNumber,
  arrayObject;

  String get displayName {
    switch (this) {
      case VariableDataType.string:
        return 'String';
      case VariableDataType.number:
        return 'Number';
      case VariableDataType.object:
        return 'Object';
      case VariableDataType.arrayString:
        return 'Array[String]';
      case VariableDataType.arrayNumber:
        return 'Array[Number]';
      case VariableDataType.arrayObject:
        return 'Array[Object]';
    }
  }
}

/// Input variable configuration
class InputVariable {
  final String name;
  final VariableDataType type;
  final String? description;
  final bool required;
  final dynamic defaultValue;
  final int? maxLength;
  final List<String>? options; // For select/radio inputs

  const InputVariable({
    required this.name,
    required this.type,
    this.description,
    this.required = false,
    this.defaultValue,
    this.maxLength,
    this.options,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        if (description != null) 'description': description,
        'required': required,
        if (defaultValue != null) 'default_value': defaultValue,
        if (maxLength != null) 'max_length': maxLength,
        if (options != null) 'options': options,
      };

  factory InputVariable.fromJson(Map<String, dynamic> json) {
    return InputVariable(
      name: json['name'] as String,
      type: VariableDataType.values.byName(json['type'] as String),
      description: json['description'] as String?,
      required: json['required'] as bool? ?? false,
      defaultValue: json['default_value'],
      maxLength: json['max_length'] as int?,
      options: (json['options'] as List?)?.cast<String>(),
    );
  }
}

/// Conversation variable (chatflow only)
class ConversationVariable {
  final String name;
  final VariableDataType type;
  final String? description;
  final dynamic defaultValue;

  const ConversationVariable({
    required this.name,
    required this.type,
    this.description,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        if (description != null) 'description': description,
        if (defaultValue != null) 'default_value': defaultValue,
      };

  factory ConversationVariable.fromJson(Map<String, dynamic> json) {
    return ConversationVariable(
      name: json['name'] as String,
      type: VariableDataType.values.byName(json['type'] as String),
      description: json['description'] as String?,
      defaultValue: json['default_value'],
    );
  }
}

/// Environment variable
class EnvironmentVariable {
  final String name;
  final String value;
  final String? description;

  const EnvironmentVariable({
    required this.name,
    required this.value,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        if (description != null) 'description': description,
      };

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariable(
      name: json['name'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
    );
  }
}

/// App configuration
class AppConfig {
  final String id;
  final String name;
  final AppType type;
  final String? description;
  final String? icon;
  final List<InputVariable> inputVariables;
  final List<ConversationVariable>? conversationVariables; // Chatflow only
  final List<EnvironmentVariable> environmentVariables;
  final StartNodeType? startNodeType; // Workflow only
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppConfig({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.icon,
    this.inputVariables = const [],
    this.conversationVariables,
    this.environmentVariables = const [],
    this.startNodeType,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.apiValue,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        'input_variables': inputVariables.map((v) => v.toJson()).toList(),
        if (conversationVariables != null)
          'conversation_variables': conversationVariables!.map((v) => v.toJson()).toList(),
        'environment_variables': environmentVariables.map((v) => v.toJson()).toList(),
        if (startNodeType != null) 'start_node_type': startNodeType!.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AppType.values.firstWhere((e) => e.apiValue == json['type']),
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      inputVariables: (json['input_variables'] as List?)
              ?.map((v) => InputVariable.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      conversationVariables: (json['conversation_variables'] as List?)
          ?.map((v) => ConversationVariable.fromJson(v as Map<String, dynamic>))
          .toList(),
      environmentVariables: (json['environment_variables'] as List?)
              ?.map((v) => EnvironmentVariable.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      startNodeType: json['start_node_type'] != null
          ? StartNodeType.values.byName(json['start_node_type'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// INHAUS BRAIN DSL export/import
class DifyDSL {
  final String version;
  final AppConfig app;
  final Map<String, dynamic> workflow;

  const DifyDSL({
    required this.version,
    required this.app,
    required this.workflow,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'app': app.toJson(),
        'workflow': workflow,
      };

  factory DifyDSL.fromJson(Map<String, dynamic> json) {
    return DifyDSL(
      version: json['version'] as String,
      app: AppConfig.fromJson(json['app'] as Map<String, dynamic>),
      workflow: json['workflow'] as Map<String, dynamic>,
    );
  }

  /// Export to YAML string
  String toYaml() {
    // This would use a YAML package to convert toJson() to YAML
    // For now, returning JSON string as placeholder
    return toJson().toString();
  }

  /// Import from YAML string
  static DifyDSL fromYaml(String yaml) {
    // This would use a YAML package to parse YAML to Map
    // For now, placeholder implementation
    throw UnimplementedError('YAML parsing not yet implemented');
  }
}
