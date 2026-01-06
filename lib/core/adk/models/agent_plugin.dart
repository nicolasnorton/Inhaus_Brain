/// Abstract base for all Agent Plugins.
/// Plugins can intercept agent execution, modify prompts, or inject extra tools.
abstract class AgentPlugin {
  String get name;
  String get version;

  /// Hook called before agent execution
  Future<String> beforeExecute(String prompt) async => prompt;

  /// Hook called after agent execution
  Future<String> afterExecute(String result) async => result;
}

/// A specialized plugin for external notifications (Slack, Discord, etc.)
class NotificationPlugin extends AgentPlugin {
  @override
  String get name => "Notifier";
  @override
  String get version => "1.0.0";

  final String channel;
  NotificationPlugin(this.channel);

  @override
  Future<String> afterExecute(String result) async {
    // Logic to send notification would go here
    return result;
  }
}
