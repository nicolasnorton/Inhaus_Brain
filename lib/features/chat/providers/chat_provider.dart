import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import '../../campaigns/models/campaign.dart';
import '../../../core/services/web_research_service.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../knowledge/providers/knowledge_provider.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/auth/secret_vault_service.dart';

class ChatNotifier extends StateNotifier<ChatSession?> {
  final Ref ref;

  ChatNotifier(this.ref) : super(null);

  void startSession(String campaignId) {
    state = ChatSession(
      id: const Uuid().v4(),
      campaignId: campaignId,
      messages: [],
      updatedAt: DateTime.now(),
    );
  }

  Future<void> sendMessage(String text, {List<Attachment> attachments = const []}) async {
    if (state == null) return;

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      sender: MessageSender.user,
      createdAt: DateTime.now(),
      attachments: attachments,
    );

    state = state!.copyWith(
      messages: [...state!.messages, userMessage],
      updatedAt: DateTime.now(),
    );

    // Get current Knowledge Context
    final knowledgeContext = ref.read(knowledgeProvider);
    
    // Get API Key (Gemini)
    final apiKey = await ref.read(secretVaultProvider).getGeminiKey();

    // A2A Handoff Logic: Trigger Creative Agent on Strategy Approval
    if (text.toLowerCase().contains('looks great. approved') && text.toLowerCase().contains('strategy')) {
       await _handleHumanHandoffToCreative("The user approved the strategy. Please generate visual concepts.", apiKey: apiKey);
       return;
    }

    // Auto-reply logic
    if (text.toLowerCase().contains('research') || text.toLowerCase().contains('market')) {
      await _handleResearchAgentResponse(text, context: knowledgeContext, apiKey: apiKey);
    } else if (text.toLowerCase().contains('design') || text.toLowerCase().contains('visual')) {
      await _handleCreativeAgentResponse(text, context: knowledgeContext, apiKey: apiKey);
    } else {
      await _handleGeneralResponse(text, context: knowledgeContext, apiKey: apiKey);
    }
  }

  Future<void> _handleHumanHandoffToCreative(String instruction, {String? apiKey}) async {
    // System message indicating handoff
    final handoffMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Strategy Approved. Activating Creative Agent...',
      sender: MessageSender.system,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'agent_handoff'},
    );
    state = state!.copyWith(messages: [...state!.messages, handoffMsg]);

    await Future.delayed(const Duration(seconds: 1));
    await _handleCreativeAgentResponse(instruction, context: ref.read(knowledgeProvider), apiKey: apiKey);
  }

  Future<void> _handleResearchAgentResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? apiKey}) async {
    // 1. Tool Usage Indicator
    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Scanning market trends and knowledge base...',
      sender: MessageSender.researchAgent,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'web_search_mcp'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    // 2. Perform Research (Simulated MCP Tool Call)
    // In a real scenario, we'd use the WebSearchTool class here.
    final researchResult = await WebResearchService.performSearch(userPrompt);
    
    // 3. AI Generation Grounded in Research & Context
    final aiRes = await EdgeAIService.generateText(
      "You are a Research Agent. User Request: '$userPrompt'. Research: ${researchResult.result}. Provide a strategic recommendation.",
      context: context,
      apiKey: apiKey,
    );

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: aiRes.text,
      sender: MessageSender.researchAgent,
      createdAt: DateTime.now(),
    );

    // 4. Propose Approval Widget
    final approvalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'I have synthesized a market strategy. Would you like me to formalize this into a Campaign Brief?',
      sender: MessageSender.researchAgent,
      type: MessageType.approvalWidget,
      createdAt: DateTime.now(),
      metadata: {'title': 'Strategy Draft Proposal', 'type': 'strategy'},
    );

    state = state!.copyWith(
      messages: [...state!.messages.where((m) => m.id != toolMsg.id), finalMsg, approvalMsg],
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handleCreativeAgentResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? apiKey}) async {
    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Synthesizing visual directions...',
      sender: MessageSender.creativeAgent,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'visual_analysis'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    final aiRes = await EdgeAIService.generateText(
      "You are a Creative Agent. Suggest a visual direction for: $userPrompt.",
      context: context,
      apiKey: apiKey,
    );

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: aiRes.text,
      sender: MessageSender.creativeAgent,
      createdAt: DateTime.now(),
    );

    // 4. Propose Approval Widget
    final approvalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'I have drafted a visual style. Shall we proceed with generating the production concepts?',
      sender: MessageSender.creativeAgent,
      type: MessageType.approvalWidget,
      createdAt: DateTime.now(),
      metadata: {'title': 'Design Plan Proposal', 'type': 'design plan'},
    );

    state = state!.copyWith(
      messages: [...state!.messages.where((m) => m.id != toolMsg.id), finalMsg, approvalMsg],
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handleGeneralResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? apiKey}) async {
    final aiRes = await EdgeAIService.generateText(
      "You are the Inhaus Brain assistant. Help the user with their campaign: $userPrompt",
      context: context,
      apiKey: apiKey,
    );

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: aiRes.text,
      sender: MessageSender.system,
      createdAt: DateTime.now(),
    );

    state = state!.copyWith(
      messages: [...state!.messages, finalMsg],
      updatedAt: DateTime.now(),
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatSession?>((ref) => ChatNotifier(ref));
