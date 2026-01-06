import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import '../../campaigns/models/campaign.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../knowledge/providers/knowledge_provider.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/auth/secret_vault_service.dart';
import '../../../core/services/orchestrator_service.dart';
import '../../../core/services/system_prompts_service.dart';
import '../../../core/mcp/tools/web_search_tool.dart';
import '../../../core/mcp/tools/image_generation_tool.dart';
import '../../../core/mcp/tools/video_generation_tool.dart';
import '../../../core/mcp/tools/audio_generation_tool.dart';
import '../agents/utility_agents.dart';
import '../agents/base_agent.dart';
import '../../../core/services/memory_service.dart';
import '../models/memory_models.dart';

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
    
    // Get API Keys
    final vault = ref.read(secretVaultProvider);
    final apiKey = await vault.getGeminiKey();
    final gemmaKey = await vault.getGemmaKey();
    final imagenKey = await vault.getImagenKey();
    final bananaKey = await vault.getBananaKey();
    final veoKey = await vault.getVeoKey();
    final lyriaKey = await vault.getLyriaKey();

    // A2A Handoff Logic: Trigger Creative Agent on Strategy Approval
    if (text.toLowerCase().contains('looks great. approved') && text.toLowerCase().contains('strategy')) {
       await _handleHumanHandoffToCreative("The user approved the strategy. Please generate visual concepts.", apiKey: apiKey, gemmaKey: gemmaKey);
       return;
    }

    // Auto-reply logic
    final lowerText = text.toLowerCase();
    
    // Multimedia Triggers
    if (lowerText.contains('generate video') || lowerText.contains('create video')) {
       await _handleVideoGeneration(text, veoKey: veoKey);
       return;
    }
    if (lowerText.contains('generate music') || lowerText.contains('create audio') || lowerText.contains('compose')) {
       await _handleAudioGeneration(text, lyriaKey: lyriaKey);
       return;
    }

    // Get Memory Context
    final memoryService = ref.read(memoryServiceProvider);
    final memoryContext = memoryService.getContextString(campaignId: state!.campaignId);

    // Explicit Agent Calls (Strongest signal)
    if (lowerText.contains('@research') || lowerText.contains('research analysis')) {
      await _handleResearchAgentResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('@creative') || lowerText.contains('visual concept')) {
      await _handleCreativeAgentResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, imagenKey: imagenKey, bananaKey: bananaKey);
    } else if (lowerText.contains('@copy') || lowerText.contains('write copy') || lowerText.contains('draft blog')) {
      await _handleCopywriterResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('@dev') || lowerText.contains('generate code') || lowerText.contains('flutter widget')) {
      await _handleDeveloperResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('@client') || lowerText.contains('onboarding')) {
      await _handleUtilityAgent(ClientOnboardingAgent(), text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('@extract')) {
      await _handleUtilityAgent(ExtractorAgent(), text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('@parse')) {
      await _handleUtilityAgent(ParserAgent(), text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('@summarize')) {
      await _handleUtilityAgent(SummarizerAgent(), text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('@security') || lowerText.contains('audit')) {
      await _handleUtilityAgent(SecurityAgent(), text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('@data') || lowerText.contains('schema')) {
      await _handleUtilityAgent(DataEngineerAgent(), text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('@vision') || attachments.any((a) => a.type == AttachmentType.image)) {
      await _handleVisionAgentResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    }

    // Implicit Intent Detection (Contextual)
    } else if (lowerText.contains('market') || lowerText.contains('competitor') || lowerText.contains('trend')) {
      await _handleResearchAgentResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('design') || lowerText.contains('style') || lowerText.contains('moodboard')) {
      await _handleCreativeAgentResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, imagenKey: imagenKey, bananaKey: bananaKey);
    } else if (lowerText.contains('write') || lowerText.contains('script')) {
      // "Write" is ambiguous. Check context. Default to Copywriter if it looks like content.
      await _handleCopywriterResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else {
      // Default to System/Orchestrator for general help
      await _handleGeneralResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    }

    // TRIGGER MEMORY HARVESTING (Post-Response)
    // Run asynchronously to not block UI/Chat
    _harvestInsights(text, apiKey: apiKey, gemmaKey: gemmaKey);
  }

  Future<void> _handleVideoGeneration(String userPrompt, {String? veoKey}) async {
    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Rendering video asset via Veo...',
      sender: MessageSender.creativeAgent, // Creative Agent handles video too
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'veo_video_gen'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    final videoTool = VideoGenerationTool(veoKey: veoKey);
    final result = await videoTool.execute({'prompt': userPrompt});
    
    final videoUrl = result.isSuccess ? result.data['url'] : "assets/videos/mock_render.mp4";
    
    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Video generated successfully.',
      sender: MessageSender.creativeAgent,
      createdAt: DateTime.now(),
      attachments: [Attachment(id: const Uuid().v4(), type: AttachmentType.video, url: videoUrl, name: 'veo_gen.mp4', createdAt: DateTime.now())],
    );

    state = state!.copyWith(
      messages: [...state!.messages.where((m) => m.id != toolMsg.id), finalMsg],
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handleAudioGeneration(String userPrompt, {String? lyriaKey}) async {
    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Composing audio via Lyria...',
      sender: MessageSender.creativeAgent, 
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'lyria_music_gen'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    final audioTool = AudioGenerationTool(lyriaKey: lyriaKey);
    final result = await audioTool.execute({'prompt': userPrompt});
    
    final audioUrl = result.isSuccess ? result.data['url'] : "assets/audio/mock_soundtrack.mp3";
    
    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Audio track composed.',
      sender: MessageSender.creativeAgent,
      createdAt: DateTime.now(),
      // Assuming AttachmentType.audio exits or using file/other
      attachments: [Attachment(id: const Uuid().v4(), type: AttachmentType.file, url: audioUrl, name: 'lyria_track.mp3', createdAt: DateTime.now())],
    );

    state = state!.copyWith(
      messages: [...state!.messages.where((m) => m.id != toolMsg.id), finalMsg],
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handleCopywriterResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey}) async {
    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Drafting high-conversion copy...',
      sender: MessageSender.copywriterAgent,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'text_generation'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    final systemPrompts = ref.read(systemPromptsProvider);
    final masterPrompt = await systemPrompts.getCopywriterPrompt();
    final systemInstruction = masterPrompt.isNotEmpty
        ? "You are a Copywriting Agent. $masterPrompt. User Request: $userPrompt"
        : "You are a Copywriting Agent. Write engaging text for: $userPrompt. Tone: Professional yet bold.";

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      memoryContext: memoryContext,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    );

    // Orchestrator Audit
    final auditedContent = await ref.read(orchestratorProvider).auditResponse(aiRes.text, 'CopywriterAgent');

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: auditedContent,
      sender: MessageSender.copywriterAgent,
      createdAt: DateTime.now(),
    );

    state = state!.copyWith(
      messages: [...state!.messages.where((m) => m.id != toolMsg.id), finalMsg],
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handleDeveloperResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey}) async {
    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Generating Flutter code...',
      sender: MessageSender.developerAgent,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'code_gen'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    final systemPrompts = ref.read(systemPromptsProvider);
    final masterPrompt = await systemPrompts.getDeveloperPrompt();
    final systemInstruction = masterPrompt.isNotEmpty
        ? "You are a Developer Agent. $masterPrompt. User Request: $userPrompt"
        : "You are a Developer Agent. Generate Flutter code for: $userPrompt. Return ONLY valid Dart code wrapped in ```dart blocks.";

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      memoryContext: memoryContext,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    );

    // Orchestrator Audit
    final auditedContent = await ref.read(orchestratorProvider).auditResponse(aiRes.text, 'DeveloperAgent');

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: auditedContent,
      sender: MessageSender.developerAgent,
      createdAt: DateTime.now(),
    );

    state = state!.copyWith(
      messages: [...state!.messages.where((m) => m.id != toolMsg.id), finalMsg],
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handleHumanHandoffToCreative(String instruction, {String? apiKey, String? gemmaKey}) async {
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
    // Pass keys retrieved from the calling scope (need to re-fetch if not passed, but passing is cleaner)
    final vault = ref.read(secretVaultProvider);
    final imagenKey = await vault.getImagenKey();
    final bananaKey = await vault.getBananaKey();
    
    // FETCH MEMORY FOR HANDOFF
    final memoryContext = ref.read(memoryServiceProvider).getContextString(campaignId: state!.campaignId);
    
    await _handleCreativeAgentResponse(instruction, context: ref.read(knowledgeProvider), memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, imagenKey: imagenKey, bananaKey: bananaKey);
  }

  Future<void> _handleResearchAgentResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey}) async {
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

    // 2. Perform Research (MCP Tool Call)
    final searchTool = WebSearchTool();
    final result = await searchTool.execute({'query': userPrompt});
    
    String researchSummaray = "";
    if (result.isSuccess) {
      final results = result.data['results'] as List;
      researchSummaray = results.map((r) => "- ${r['title']}: ${r['snippet']}").join("\n");
    } else {
      researchSummaray = "Search failed: ${result.errorMessage}";
    }
    
    final systemPrompts = ref.read(systemPromptsProvider);
    final masterPrompt = await systemPrompts.getResearchPrompt();
    final systemInstruction = masterPrompt.isNotEmpty
        ? "You are a Research Agent. Research Results: $researchSummaray. $masterPrompt. User Context: $userPrompt"
        : "You are a Research Agent. User Request: '$userPrompt'. Research: $researchSummaray. Provide a strategic recommendation.";

    // 3. AI Generation Grounded in Research & Context
    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      memoryContext: memoryContext,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    );

    // 4. Orchestrator Audit
    final auditedContent = await ref.read(orchestratorProvider).auditResponse(aiRes.text, 'ResearchAgent');

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: auditedContent,
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

  Future<void> _handleCreativeAgentResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey, String? imagenKey, String? bananaKey}) async {
    // Visual Generation Check
    if (userPrompt.toLowerCase().contains('generate') || userPrompt.toLowerCase().contains('concept') || userPrompt.toLowerCase().contains('image')) {
       final toolMsg = ChatMessage(
        id: const Uuid().v4(),
        content: 'Generating production-grade visuals...',
        sender: MessageSender.creativeAgent,
        type: MessageType.toolUsage,
        createdAt: DateTime.now(),
        metadata: {'tool': 'imagen_3_gen'},
      );
      state = state!.copyWith(messages: [...state!.messages, toolMsg]);

      final imageTool = ImageGenerationTool(imagenKey: imagenKey, bananaKey: bananaKey);
      final result = await imageTool.execute({'prompt': userPrompt});
      
      final imageUrl = result.isSuccess ? result.data['url'] : "assets/images/mock_concept.png";
      
      final finalMsg = ChatMessage(
        id: const Uuid().v4(),
        content: 'Here is the visual concept generated based on your brief.',
        sender: MessageSender.creativeAgent,
        createdAt: DateTime.now(),
        attachments: [
          Attachment(id: const Uuid().v4(), type: AttachmentType.image, url: imageUrl, name: 'concept_art.png', createdAt: DateTime.now())
        ],
      );

      state = state!.copyWith(
        messages: [...state!.messages.where((m) => m.id != toolMsg.id), finalMsg],
        updatedAt: DateTime.now(),
      );
      return;
    }


    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Synthesizing visual directions...',
      sender: MessageSender.creativeAgent,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'visual_analysis'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    final systemPrompts = ref.read(systemPromptsProvider);
    final masterPrompt = await systemPrompts.getCreativePrompt();
    final systemInstruction = masterPrompt.isNotEmpty
        ? "You are a Creative Agent. $masterPrompt. User Context: $userPrompt"
        : "You are a Creative Agent. Suggest a visual direction for: $userPrompt.";

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      memoryContext: memoryContext,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    );

    // Orchestrator Audit
    final auditedContent = await ref.read(orchestratorProvider).auditResponse(aiRes.text, 'CreativeAgent');

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: auditedContent,
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

  Future<void> _handleVisionAgentResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey}) async {
    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Analyzing visual assets...',
      sender: MessageSender.visionAgent,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'vision_analysis'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    // Find the latest image attachment in the session context if none in current message
    Uint8List? imageBytes;
    String? mimeType;
    
    // Check current message attachments first
    if (state!.messages.isNotEmpty) {
      final lastMsg = state!.messages.last;
      final imageAttachment = lastMsg.attachments.firstWhere(
        (a) => a.type == AttachmentType.image, 
        orElse: () => Attachment(id: '', type: AttachmentType.file, url: '', name: '', createdAt: DateTime.now()),
      );
      
      if (imageAttachment.id.isNotEmpty && imageAttachment.url.startsWith('data:')) {
         try {
           final uri = Uri.parse(imageAttachment.url);
           imageBytes = uri.data?.contentAsBytes();
           mimeType = uri.data?.mimeType;
         } catch (e) {
           debugPrint('VisionAgent: Failed to parse data URI: $e');
         }
      }
    }

    final agent = VisionAgent();
    final resultText = await agent.execute(
      userPrompt: userPrompt,
      context: context,
      imageBytes: imageBytes,
      imageMimeType: mimeType,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    );

    // Orchestrator Audit
    final auditedContent = await ref.read(orchestratorProvider).auditResponse(resultText, 'VisionAgent');

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: auditedContent,
      sender: MessageSender.visionAgent,
      createdAt: DateTime.now(),
    );

    state = state!.copyWith(
      messages: [...state!.messages.where((m) => m.id != toolMsg.id), finalMsg],
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handleGeneralResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey}) async {
    final aiRes = await EdgeAIService.generateText(
      "You are the Inhaus Brain assistant. Help the user with their campaign: $userPrompt",
      context: context,
      memoryContext: memoryContext,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
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

  Future<void> _handleUtilityAgent(BaseAgent agent, String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey}) async {
    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: '${agent.name} is working...',
      sender: agent.type,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': agent.name.toLowerCase().replaceAll(' ', '_')},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    // Execute Agent Logic
    final resultText = await agent.execute(
      userPrompt: userPrompt,
      context: context,
      imageBytes: null, // Utilities don't handle vision yet
      imageMimeType: null,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    );

    // Orchestrator Audit (Generic)
    final auditedContent = await ref.read(orchestratorProvider).auditResponse(resultText, agent.name);

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: auditedContent,
      sender: agent.type,
      createdAt: DateTime.now(),
    );

    state = state!.copyWith(
      messages: [...state!.messages.where((m) => m.id != toolMsg.id), finalMsg],
      updatedAt: DateTime.now(),
    );
  }

  // --- Long Term Memory Harvesting ---
  Future<void> _harvestInsights(String lastUserMessage, {String? apiKey, String? gemmaKey}) async {
    if (state == null) return;
    
    debugPrint('MemoryService: Harvesting insights from session...');
    
    // Use the ExtractorAgent to pull facts
    final harvester = ExtractorAgent();
    final conversationHistory = state!.messages.takeLast(5).map((m) => "${m.sender.name}: ${m.content}").join("\n");
    
    final extractionPrompt = """
Extract useful long-term memory facts from this conversation. 
Look for: User preferences, brand constraints, specific campaign goals, and technical requirements.
Return ONLY a JSON list of objects with 'key', 'value', and 'category'.
Example: [{"key": "Brand Mood", "value": "Minimalist", "category": "preference"}]
Conversation:
$conversationHistory
""";

    try {
      final resText = await harvester.execute(userPrompt: extractionPrompt, context: [], apiKey: apiKey, gemmaKey: gemmaKey);
      
      // Smart Parse (Lean)
      final cleanJson = resText.contains('[') ? resText.substring(resText.indexOf('['), resText.lastIndexOf(']') + 1) : "[]";
      final List<dynamic> harvested = json.decode(cleanJson);
      
      final memoryService = ref.read(memoryServiceProvider);
      for (final item in harvested) {
        final memoryItem = MemoryItem(
          id: const Uuid().v4(),
          key: item['key'],
          value: item['value'],
          category: item['category'] ?? 'fact',
          createdAt: DateTime.now(),
          campaignId: state!.campaignId,
        );
        await memoryService.addMemory(memoryItem);
        debugPrint('MemoryService: Remembered ${memoryItem.key}');
      }
    } catch (e) {
      debugPrint('MemoryService: Extraction failed or no insights found: $e');
    }
  }
}

extension ListExtensions<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatSession?>((ref) => ChatNotifier(ref));
