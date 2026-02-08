
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agency_models.dart';
import '../../chat/agents/core_agents.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/services/system_prompts_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../knowledge/models/knowledge_source.dart';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class SalesChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  SalesChatState({this.messages = const [], this.isLoading = false, this.error});

  SalesChatState copyWith({List<ChatMessage>? messages, bool? isLoading, String? error}) {
    return SalesChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Provider family to create a unique chat session per Lead ID
final salesChatProvider = StateNotifierProvider.family<SalesChatNotifier, SalesChatState, String>((ref, leadId) {
  return SalesChatNotifier(ref, leadId);
});

class SalesChatNotifier extends StateNotifier<SalesChatState> {
  final Ref _ref;
  final String _leadId;

  SalesChatNotifier(this._ref, this._leadId) : super(SalesChatState());

  Future<void> sendMessage(String text, SalesLead lead) async {
    // 1. Add User Message
    final userMsg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      // 2. Prepare Context & Agent
      final crmAgent = CRMAgent(); // Defined in core_agents.dart
      
      // Inject Lead Data into the prompt context
      final leadContext = """
      CURRENT LEAD CONTEXT:
      Name: ${lead.name}
      Company: ${lead.company}
      Status: ${lead.status}
      Notes: ${lead.notes}
      Data: ${lead.estimatedValue}
      """;

      final fullPrompt = "$leadContext\n\nUser Query: $text";

      // 3. Execute Agent
      // Note: We use the existing agent execution flow
      final responseText = await crmAgent.execute(
        userPrompt: fullPrompt,
        context: [], // Add knowledge sources if needed
        ref: _ref,
      );

      // 4. Add Agent Response
      final agentMsg = ChatMessage(text: responseText, isUser: false, timestamp: DateTime.now());
      state = state.copyWith(
        messages: [...state.messages, agentMsg],
        isLoading: false,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to get response: $e",
      );
    }
  }
}
