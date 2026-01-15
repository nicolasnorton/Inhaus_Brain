import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/assistant_service.dart';

// State for the open/close status of the assistant overlay
final isAssistantOpenProvider = StateProvider<bool>((ref) => false);

// Trigger for sending message from FAB
final assistantSendTriggerProvider = StateProvider<int>((ref) => 0);

// Chat history state
class AssistantChatState extends StateNotifier<List<AssistantMessage>> {
  final AssistantService _service;

  AssistantChatState(this._service) : super([]);

  Future<void> sendMessage(String text, {List<int>? attachment, List<int>? audioAttachment}) async {
    // Service now uses Riverpod Ref for tools, no context needed
    
    // Optimistic update for user message (controlled by service actually, but triggered here)
    // The service manages the authoritative history list, we just sync the state
    await _service.sendMessage(text, attachment: attachment, audioAttachment: audioAttachment);
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
