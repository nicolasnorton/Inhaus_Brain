import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_type_models.dart';

/// Provider for current app configuration
final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig?>((ref) {
  return AppConfigNotifier();
});

/// Provider for selected app type
final selectedAppTypeProvider = StateProvider<AppType?>((ref) => null);

/// Provider for input variables
final inputVariablesProvider = StateProvider<List<InputVariable>>((ref) => []);

/// Provider for conversation variables (chatflow only)
final conversationVariablesProvider = StateProvider<List<ConversationVariable>>((ref) => []);

/// Provider for environment variables
final environmentVariablesProvider = StateProvider<List<EnvironmentVariable>>((ref) => []);

/// Provider for start node type (workflow only)
final startNodeTypeProvider = StateProvider<StartNodeType?>((ref) => null);

/// State notifier for app configuration
class AppConfigNotifier extends StateNotifier<AppConfig?> {
  AppConfigNotifier() : super(null);

  /// Create new app configuration
  void createApp({
    required String name,
    required AppType type,
    String? description,
    String? icon,
  }) {
    final now = DateTime.now();
    state = AppConfig(
      id: _generateId(),
      name: name,
      type: type,
      description: description,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update app configuration
  void updateApp(AppConfig config) {
    state = config;
  }

  /// Update app name
  void updateName(String name) {
    if (state == null) return;
    state = AppConfig(
      id: state!.id,
      name: name,
      type: state!.type,
      description: state!.description,
      icon: state!.icon,
      inputVariables: state!.inputVariables,
      conversationVariables: state!.conversationVariables,
      environmentVariables: state!.environmentVariables,
      startNodeType: state!.startNodeType,
      createdAt: state!.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Update input variables
  void updateInputVariables(List<InputVariable> variables) {
    if (state == null) return;
    state = AppConfig(
      id: state!.id,
      name: state!.name,
      type: state!.type,
      description: state!.description,
      icon: state!.icon,
      inputVariables: variables,
      conversationVariables: state!.conversationVariables,
      environmentVariables: state!.environmentVariables,
      startNodeType: state!.startNodeType,
      createdAt: state!.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Update conversation variables (chatflow only)
  void updateConversationVariables(List<ConversationVariable> variables) {
    if (state == null || state!.type != AppType.chatflow) return;
    state = AppConfig(
      id: state!.id,
      name: state!.name,
      type: state!.type,
      description: state!.description,
      icon: state!.icon,
      inputVariables: state!.inputVariables,
      conversationVariables: variables,
      environmentVariables: state!.environmentVariables,
      startNodeType: state!.startNodeType,
      createdAt: state!.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Update environment variables
  void updateEnvironmentVariables(List<EnvironmentVariable> variables) {
    if (state == null) return;
    state = AppConfig(
      id: state!.id,
      name: state!.name,
      type: state!.type,
      description: state!.description,
      icon: state!.icon,
      inputVariables: state!.inputVariables,
      conversationVariables: state!.conversationVariables,
      environmentVariables: variables,
      startNodeType: state!.startNodeType,
      createdAt: state!.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Update start node type (workflow only)
  void updateStartNodeType(StartNodeType type) {
    if (state == null || state!.type != AppType.workflow) return;
    state = AppConfig(
      id: state!.id,
      name: state!.name,
      type: state!.type,
      description: state!.description,
      icon: state!.icon,
      inputVariables: state!.inputVariables,
      conversationVariables: state!.conversationVariables,
      environmentVariables: state!.environmentVariables,
      startNodeType: type,
      createdAt: state!.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Clear app configuration
  void clear() {
    state = null;
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
