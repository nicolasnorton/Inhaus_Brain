import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/assistant_service.dart';
import '../../chat/models/chat_models.dart';
import '../../../core/tokens/llm_provider.dart';

// State for the open/close status of the assistant overlay
final isAssistantOpenProvider = StateProvider<bool>((ref) => false);

// Current status of the assistant (e.g. "Searching...", "Thinking...")
final assistantStatusProvider = StateProvider<String?>((ref) => null);

// Selected AI Model Provider
final selectedAIModelProvider = StateProvider<AIModelConfig>((ref) => AIModelConfig.geminiPro);

// Trigger for sending message from FAB
final assistantSendTriggerProvider = StateProvider<int>((ref) => 0);

// Command for real-time dialogue scene updates (passed to WebView)
final dialogueSceneCommandProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Chat history state
class AssistantChatState extends StateNotifier<List<AssistantMessage>> {
  final AssistantService _service;

  AssistantChatState(this._service) : super([]);

  Future<void> sendMessage(String text, {List<int>? attachment, List<int>? audioAttachment, ToolMode toolMode = ToolMode.chat}) async {
    // Optimistic update: show the user message bubble IMMEDIATELY
    final optimisticUserMsg = AssistantMessage(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      attachment: attachment,
      audioAttachment: audioAttachment,
    );
    state = [...state, optimisticUserMsg];

    // Now await the full service call (which adds both user + AI response to its history)
    await _service.sendMessage(text, attachment: attachment, audioAttachment: audioAttachment, toolMode: toolMode);
    // Re-sync with the authoritative history from the service (replaces optimistic msg)
    state = [..._service.history];
  }
  
  void clearChat() {
    _service.clearHistory();
    state = [];
  }
}

final assistantChatProvider = StateNotifierProvider<AssistantChatState, List<AssistantMessage>>((ref) {
  final service = ref.watch(assistantServiceProvider);
  return AssistantChatState(service);
});
