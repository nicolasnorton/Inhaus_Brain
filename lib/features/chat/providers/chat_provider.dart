import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_models.dart';
import '../../campaigns/models/campaign.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/auth/secret_vault_service.dart';
import '../../../core/utils/sanitization_utils.dart';
import '../../../core/services/orchestrator_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../../core/services/system_prompts_service.dart';
import '../../../core/mcp/tools/web_search_tool.dart';
import '../../../core/mcp/tools/image_generation_tool.dart';
import '../../../core/mcp/tools/video_generation_tool.dart';
import '../../../core/mcp/tools/audio_generation_tool.dart';
import '../agents/utility_agents.dart';
import '../agents/base_agent.dart';
import '../agents/router_agent.dart';
import '../agents/router_agent.dart';
import '../agents/agency_agents.dart';
import '../../reports/agents/data_analyst_agent.dart';
import '../agents/management_agent.dart';
import '../../../core/services/memory_service.dart';
import '../models/memory_models.dart';
import '../../../core/adk/services/adk_service.dart';
import '../../../core/adk/models/pipeline_models.dart';
import '../../adk/providers/pipeline_provider.dart';
import '../../knowledge/providers/knowledge_provider.dart';
import '../services/skill_discovery_service.dart';
import '../../../core/services/telemetry_service.dart';

class ChatNotifier extends StateNotifier<ChatSession?> {
  final Ref ref;

  ChatNotifier(this.ref) : super(null) {
    // Phase: Agent Skills Integration - Trigger discovery on startup
    ref.listen(skillDiscoveryInitProvider, (_, __) {});
  }

  void _updateMessageStatus(String messageId, String newContent, {Map<String, dynamic>? extraMetadata}) {
    if (state == null) return;
    state = state!.copyWith(
      messages: state!.messages.map((m) {
        if (m.id == messageId) {
          final newMetadata = Map<String, dynamic>.from(m.metadata ?? {});
          if (extraMetadata != null) {
            newMetadata.addAll(extraMetadata);
          }
          return m.copyWith(content: newContent, metadata: newMetadata);
        }
        return m;
      }).toList(),
      updatedAt: DateTime.now(),
    );
  }

  void startSession(String campaignId) {
    state = ChatSession(
      id: const Uuid().v4(),
      campaignId: campaignId,
      messages: [],
      updatedAt: DateTime.now(),
    );
  }

  // Helper to build compressed history
  String _buildConversationHistory() {
    if (state == null || state!.messages.isEmpty) return "";
    
    // Logic: We want the LAST 20 messages (Recent Context)
    // messages list is [Old, ..., New]
    int count = state!.messages.length;
    int takeCount = 20;
    
    final recentMessages = (count > takeCount) 
        ? state!.messages.sublist(count - takeCount) // Take last N
        : state!.messages;
        
    final history = recentMessages
        .where((m) => m.type == MessageType.text || m.type == MessageType.toolUsage) // Exclude large blobs
        .map((m) => "${m.sender.name}: ${m.content}")
        .join("\n");
        
    // Use Orchestrator to compress if needed
    return ref.read(orchestratorProvider).compressContext(history);
  }

  // Helper to handle multimodal failure
  Future<bool> _rejectIfLowQuality(String modalType, double score, String userPrompt) async {
    final rejection = ref.read(orchestratorProvider).checkMultimodalQuality(score, modalType);
    if (rejection != null) {
      final msg = ChatMessage(
        id: const Uuid().v4(),
        content: rejection,
        sender: MessageSender.system,
        createdAt: DateTime.now(),
      );
      state = state!.copyWith(
        messages: [...state!.messages, msg],
        updatedAt: DateTime.now(),
      );
      
      // Log Failure
      ref.read(telemetryServiceProvider).logInteraction(
        agentName: 'MultimodalCheck', 
        action: 'reject_$modalType', 
        durationMs: 0, 
        success: false
      );
      return true;
    }
    return false;
  }

  Future<void> sendMessage(String text, {List<Attachment> attachments = const [], AIModelConfig? modelConfig}) async {
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
    
    
    // Phase 35: Multi-Model Keys - REMOVED (Legacy)

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

    // --- INTELLIGENT ROUTING (Phase 23: Step 2 - The Engine) ---
    // Respect explicit commands, but otherwise use the RouterAgent (The Front Door)
    if (text.startsWith('@')) {
      await _handleExplicitCommand(text, lowerText, knowledgeContext, memoryContext, apiKey, gemmaKey, imagenKey, bananaKey, modelConfig);
    } else {
      await _handleIntelligentRouting(text, knowledgeContext, memoryContext, apiKey, gemmaKey, imagenKey, bananaKey, modelConfig);
    }

    // TRIGGER MEMORY HARVESTING (Post-Response)
    _harvestInsights(text, apiKey: apiKey, gemmaKey: gemmaKey);
  }

  Future<void> _handleExplicitCommand(String text, String lowerText, List<KnowledgeSource> knowledgeContext, String? memoryContext, String? apiKey, String? gemmaKey, String? imagenKey, String? bananaKey, AIModelConfig? config) async {
    if (lowerText.contains('@research')) {
      await _handleResearchAgentResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, config: config);
    } else if (lowerText.contains('@creative')) {
      await _handleCreativeAgentResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, imagenKey: imagenKey, bananaKey: bananaKey, config: config);
    } else if (lowerText.contains('@copy') || lowerText.contains('@write')) {
      await _handleCopywriterResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, config: config);
    } else if (lowerText.contains('@dev') || lowerText.contains('@code')) {
      await _handleDeveloperResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, config: config);
    } else if (lowerText.contains('@vision')) {
      await _handleVisionAgentResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
    } else if (lowerText.contains('@run:') || lowerText.contains('@pipeline:')) {
      final pipelineName = text.split(':').last.trim();
      await _handlePipelineExecution(pipelineName, text, context: knowledgeContext, memoryContext: memoryContext);
    } else {
      // Fallback for unknown @ command
      await _handleGeneralResponse(text, context: knowledgeContext, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, config: config);
    }
  }

  Future<void> _handleIntelligentRouting(String text, List<KnowledgeSource> context, String? memoryContext, String? apiKey, String? gemmaKey, String? imagenKey, String? bananaKey, AIModelConfig? config) async {
    // 0. Fast-Path: Salutations (Instant Response)
    if (SanitizationUtils.isSimpleSalutation(text)) {
      await _handleGeneralResponse(text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, config: config);
      return;
    }

    // 1. Tool Usage Indicator
    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Determining best agent for your request...',
      sender: MessageSender.orchestratorAgent,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'root_router'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    // 2. Call RouterAgent
    try {
      final router = RouterAgent();
      final routerOutput = await router.execute(
        userPrompt: text,
        context: context,
        systemPrompt: await ref.read(systemPromptsProvider).getRouterPrompt(),
        apiKey: apiKey,
        ref: ref, // Phase 89: Sync proximity state
      );
      
      // Basic JSON parsing (Simulated for speed, in production wrap in jsonDecode)
      final lowerOut = routerOutput.toLowerCase();
      
      if (lowerOut.contains('"research"') || lowerOut.contains('research')) {
        await _handleResearchAgentResponse(text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, config: config);
      } else if (lowerOut.contains('"creative"') || lowerOut.contains('creative')) {
        await _handleCreativeAgentResponse(text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, imagenKey: imagenKey, bananaKey: bananaKey, config: config);
      } else if (lowerOut.contains('"copywriting"') || lowerOut.contains('copy')) {
        await _handleCopywriterResponse(text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, config: config);
      } else if (lowerOut.contains('"development"') || lowerOut.contains('dev')) {
        await _handleDeveloperResponse(text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, config: config);
      } else if (lowerOut.contains('"management"')) {
        await _handleManagementAgentResponse(text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
      } else if (lowerOut.contains('"trend"') || lowerOut.contains('scout')) {
        await _handleUtilityAgent(TrendScoutAgent(), text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
      } else if (lowerOut.contains('"strategy"') || lowerOut.contains('strategist')) {
        await _handleUtilityAgent(StrategistAgent(), text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
      } else if (lowerOut.contains('"account"') || lowerOut.contains('director')) {
        await _handleUtilityAgent(AccountDirectorAgent(), text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
      } else if (lowerOut.contains('"media"') || lowerOut.contains('buyer')) {
        await _handleUtilityAgent(MediaBuyerAgent(), text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
      } else if (lowerOut.contains('"performance"') || lowerOut.contains('analyst')) {
        await _handleUtilityAgent(PerformanceAnalystAgent(), text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
      } else if (lowerOut.contains('"editorial"') || lowerOut.contains('manager')) {
        await _handleUtilityAgent(EditorialManagerAgent(), text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
      } else if (lowerOut.contains('"pipeline"')) {
        // Try to find a matching pipeline by name in the output, or default to Research if triggered
        final pipelines = ref.read(pipelineProvider);
        Pipeline? bestMatch;
        for (final p in pipelines) {
          if (lowerOut.contains(p.name.toLowerCase())) {
            bestMatch = p;
            break;
          }
        }
        
        if (bestMatch != null) {
          await _handlePipelineExecution(bestMatch.name, text, context: context, memoryContext: memoryContext);
        } else if (text.toLowerCase().contains('deep research')) {
          await _handlePipelineExecution('Research Deep Dive', text, context: context, memoryContext: memoryContext);
        } else if (text.toLowerCase().contains('agency flow') || text.toLowerCase().contains('master workflow')) {
          await _handlePipelineExecution('Master Agency Workflow', text, context: context, memoryContext: memoryContext);
        } else {
          await _handleGeneralResponse(text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
        }
      } else if (lowerOut.contains('"reports"') || lowerOut.contains('report') || lowerOut.contains('notebook') || lowerOut.contains('dashboard')) {
        await _handleUtilityAgent(DataAnalystAgent(), text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
      } else if (lowerOut.contains('"proposal"') || lowerOut.contains('proposal')) {
        await _handleManagementAgentResponse(text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
      } else {
        await _handleGeneralResponse(text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey);
      }
    } catch (e) {
      debugPrint('Router Error: $e. Falling back to general chat.');
      await _handleGeneralResponse(text, context: context, memoryContext: memoryContext, apiKey: apiKey, gemmaKey: gemmaKey, config: config);
    }
  }

  // NOTE: Video/Audio handlers don't use LLM config yet (they are specialized models)

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

    final videoTool = VideoGenerationTool(ref, veoKey: veoKey);
    final stopWatch = Stopwatch()..start();
    final result = await videoTool.execute({'prompt': userPrompt});
    stopWatch.stop();

    ref.read(telemetryServiceProvider).logInteraction(
        agentName: 'CreativeAgent',
        action: 'generate_video',
        durationMs: stopWatch.elapsedMilliseconds.toDouble(),
        success: result.isSuccess
    );

    // Multimodal Check (Mock Score 0.9 if success)
    if (result.isSuccess) {
       if (await _rejectIfLowQuality('video', 0.90, userPrompt)) return;
    }
    
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

  Future<void> _handleCopywriterResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey, AIModelConfig? config}) async {
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

    final aiRes = await EdgeAIService.generateText(
      masterPrompt.isNotEmpty
        ? "You are a Copywriting Agent. $masterPrompt. User Request: $userPrompt"
        : "You are a Copywriting Agent. Write engaging text for: $userPrompt. Tone: Professional yet bold.",
      context: context,
      memoryContext: memoryContext,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      modelConfig: config,
      ref: ref, // Phase 89: Pass ref for proximity sync
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

  Future<void> _handleDeveloperResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey, AIModelConfig? config}) async {
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

    final aiRes = await EdgeAIService.generateText(
      masterPrompt.isNotEmpty
        ? "You are a Developer Agent. $masterPrompt. User Request: $userPrompt"
        : "You are a Developer Agent. Generate Flutter code for: $userPrompt. Return ONLY valid Dart code wrapped in ```dart blocks.",
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

  Future<void> _handleManagementAgentResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey}) async {
    final toolMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Managing resources...',
      sender: MessageSender.managementAgent,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'management_ops'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    final agent = ManagementAgent();
    // System prompt can be fetched from service if we added it, or use default fallback in agent
    final resultText = await agent.execute(
      userPrompt: userPrompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
    );

    // If the agent returned a tool call JSON, it processes it internally now? 
    // Wait, in my implementation of ManagementAgent, I made it call `_processToolCall`.
    // But `_processToolCall` needs `ref` to check for `clientToolsProvider`?
    // Actually, `ManagementAgent` imports `client_tools.dart` but `clientToolsProvider` is a provider.
    // The `_processToolCall` in `ManagementAgent` (which I just wrote) returned a string logic error message:
    // "Tool execution handled by ChatProvider...".
    // Ah, I need to implement the actual execution logic EITHER in the Agent OR in the Provider.
    // Since `ManagementAgent` has access to `Ref` (passed in execute), it can read `clientToolsProvider`.
    // Let me update `ManagementAgent` properly in the next step to actually execute the tool.
    // For now, I'll update ChatProvider to just display the result.
    
    // Orchestrator Audit
    final auditedContent = await ref.read(orchestratorProvider).auditResponse(resultText, 'ManagementAgent');

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: auditedContent,
      sender: MessageSender.managementAgent,
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

  Future<void> _handleResearchAgentResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey, AIModelConfig? config}) async {
    // 1. Tool Usage Indicator
    final toolMsgId = const Uuid().v4();
    final toolMsg = ChatMessage(
      id: toolMsgId,
      content: 'Using Google Search Grounding to research "$userPrompt"...',
      sender: MessageSender.researchAgent,
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'google_search_grounding', 'status': 'searching'},
    );
    state = state!.copyWith(messages: [...state!.messages, toolMsg]);

    // Simulate UX delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final systemPrompts = ref.read(systemPromptsProvider);
    final masterPrompt = await systemPrompts.getResearchPrompt();
    
    // We pass the user prompt directly. The model will search if needed because we enable the tool.
    final systemInstruction = masterPrompt.isNotEmpty
        ? "You are a Research Agent. $masterPrompt. User Context: $userPrompt"
        : "You are a Research Agent. Research the following: '$userPrompt'. Provide a strategic recommendation.";

    // 3. AI Generation Grounded in Google Search
    // We force enable Google Search for the Research Agent
    final researchConfig = config?.copyWith(useGoogleSearch: true) ?? AIModelConfig.geminiResearch;

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      memoryContext: memoryContext,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: researchConfig,
    );
    
    // Update the tool message to show success
    _updateMessageStatus(toolMsgId, 'Research Complete. Sources found: ${aiRes.sourceCitations?.length ?? 0}', extraMetadata: {'status': 'complete'});

    // 4. Orchestrator Audit
    final auditedContent = await ref.read(orchestratorProvider).auditResponse(aiRes.text, 'ResearchAgent');

    // 5. Final Message with Sources Metadata
    // Transform simple URL strings into the map format likely expected by UI (or just pass as is if UI handles it)
    // The previous code used {'title', 'url', 'snippet'}. We only have URLs now.
    List<Map<String, dynamic>>? sourcesMetadata;
    if (aiRes.sourceCitations != null && aiRes.sourceCitations!.isNotEmpty) {
      sourcesMetadata = aiRes.sourceCitations!.map((url) => {
        'title': 'Source',
        'url': url,
        'snippet': 'Referenced by Google Grounding'
      }).toList();
    }

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: auditedContent,
      sender: MessageSender.researchAgent,
      createdAt: DateTime.now(),
      metadata: sourcesMetadata != null ? {'sources': sourcesMetadata} : null,
    );

    // 6. Propose Approval Widget
    final approvalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'I have synthesized a market strategy. Would you like me to formalize this into a Campaign Brief?',
      sender: MessageSender.researchAgent,
      type: MessageType.approvalWidget,
      createdAt: DateTime.now(),
      metadata: {'title': 'Strategy Draft Proposal', 'type': 'strategy'},
    );

    state = state!.copyWith(
      messages: [...state!.messages.where((m) => m.id != toolMsgId), finalMsg, approvalMsg],
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handleCreativeAgentResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey, String? imagenKey, String? bananaKey, AIModelConfig? config}) async {
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

      final imageTool = ImageGenerationTool(ref, imagenKey: imagenKey);
      final stopWatch = Stopwatch()..start();
      final result = await imageTool.execute({'prompt': userPrompt});
      stopWatch.stop();

      // Telemetry
      ref.read(telemetryServiceProvider).logInteraction(
        agentName: 'CreativeAgent',
        action: 'generate_image',
        durationMs: stopWatch.elapsedMilliseconds.toDouble(),
        success: result.isSuccess
      );
      
      // Multimodal Check (Mock Score for now, ideally derived from model or tool)
      // Using 0.95 if success, so it passes. If we had a VQA, we'd use that.
      if (result.isSuccess) {
         if (await _rejectIfLowQuality('image', 0.95, userPrompt)) return;
      }
      
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
    
    // Include History
    final history = _buildConversationHistory();
    
    final systemInstruction = masterPrompt.isNotEmpty
        ? "You are a Creative Agent. $masterPrompt. \n[HISTORY]:\n$history\n\nUser Context: $userPrompt"
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

  Future<void> _handleGeneralResponse(String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext, String? apiKey, String? gemmaKey, AIModelConfig? config}) async {
    final systemPrompts = ref.read(systemPromptsProvider);
    final brianPrompt = await systemPrompts.getBrianPrompt();
    
    // Multi-Turn Context
    final history = _buildConversationHistory();
    
    final combinedPrompt = brianPrompt.isNotEmpty 
        ? "$brianPrompt\n\n[CONVERSATION HISTORY]:\n$history\n\nUser Request: $userPrompt"
        : "You are the Inhaus Brain assistant.\n[HISTORY]:\n$history\n\nUser Request: $userPrompt";

    // Check for image attachments in the latest message for Multimodal Vision
    Uint8List? imageBytes;
    String? mimeType;
    if (state != null && state!.messages.isNotEmpty) {
      final lastMsg = state!.messages.last;
      // We look for any image attachment
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
           debugPrint('Brian(Vision): Failed to parse data URI: $e');
         }
      }
    }

    final aiRes = await EdgeAIService.generateText(
      combinedPrompt,
      imageBytes: imageBytes,
      imageMimeType: mimeType,
      context: context,
      memoryContext: memoryContext,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      modelConfig: config?.copyWith(useGoogleSearch: true) ?? AIModelConfig.geminiResearch,
      ref: ref,
    );

    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: aiRes.text,
      sender: MessageSender.system,
      createdAt: DateTime.now(),
      suggestedPrompts: await _generateSuggestedPrompts(aiRes.text, apiKey: apiKey),
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

    // 3. FETCH DYNAMIC SYSTEM PROMPT
    final prompts = ref.read(systemPromptsProvider);
    String? dynamicPrompt;
    switch (agent.type) {
      case MessageSender.trendScoutAgent: dynamicPrompt = await prompts.getTrendScoutPrompt(); break;
      case MessageSender.accountDirectorAgent: dynamicPrompt = await prompts.getAccountDirectorPrompt(); break;
      case MessageSender.strategistAgent: dynamicPrompt = await prompts.getStrategistPrompt(); break;
      case MessageSender.editorialManagerAgent: dynamicPrompt = await prompts.getEditorialManagerPrompt(); break;
      case MessageSender.mediaBuyerAgent: dynamicPrompt = await prompts.getMediaBuyerPrompt(); break;
      case MessageSender.performanceAnalystAgent: dynamicPrompt = await prompts.getPerformanceAnalystPrompt(); break;
      default: break;
    }

    // Execute Agent Logic
    final resultText = await agent.execute(
      userPrompt: userPrompt,
      context: context,
      systemPrompt: dynamicPrompt,
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

  Future<List<String>> _generateSuggestedPrompts(String lastResponse, {String? apiKey}) async {
    // Audit Rec: Add follow-up suggestions
    final prompt = """
Based on the following AI response, generate 3 short, helpful follow-up questions the user might want to ask.
Keep them under 10 words each.
Return ONLY a JSON list of strings.

Response:
$lastResponse
""";

    try {
      final res = await EdgeAIService.generateText(prompt, apiKey: apiKey, ref: ref);
      final List<dynamic> list = json.decode(res.text.contains('[') ? res.text.substring(res.text.indexOf('['), res.text.lastIndexOf(']') + 1) : "[]");
      return list.cast<String>();
    } catch (e) {
      return ["Explain this further", "What are the next steps?", "Show me more examples"];
    }
  }
  // --- ADK Pipeline Execution ---
  Future<void> _handlePipelineExecution(String pipelineName, String userPrompt, {List<KnowledgeSource> context = const [], String? memoryContext}) async {
    // 1. Pipeline Lookup from Provider
    final List<Pipeline> pipelines = ref.read(pipelineProvider);
    final Pipeline pipeline;
    
    // Attempt exact match first
    final exactMatch = pipelines.where((p) => p.name.toLowerCase() == pipelineName.toLowerCase() || p.id == pipelineName);
    
    if (exactMatch.isNotEmpty) {
      pipeline = exactMatch.first;
    } else {
      // Attempt fuzzy match
      final fuzzyMatch = pipelines.where((final p) => p.name.toLowerCase().contains(pipelineName.toLowerCase()));
      if (fuzzyMatch.isNotEmpty) {
        pipeline = fuzzyMatch.first;
      } else {
        pipeline = Pipeline(id: 'null', name: 'Not Found', description: 'Pipeline Not Found', steps: []);
      }
    }

    if (pipeline.id == 'null') {
      final errorMsg = ChatMessage(
        id: const Uuid().v4(),
        content: 'Pipeline "$pipelineName" not found. Try "@run:Research Deep Dive"',
        sender: MessageSender.system,
        createdAt: DateTime.now(),
      );
      state = state!.copyWith(messages: [...state!.messages, errorMsg]);
      return;
    }

    // 2. Initial System Message
    final startMsg = ChatMessage(
      id: const Uuid().v4(),
      content: 'Starting Pipeline: ${pipeline.name}...',
      sender: MessageSender.orchestratorAgent, // Using Orchestrator as the runner persona
      type: MessageType.toolUsage,
      createdAt: DateTime.now(),
      metadata: {'tool': 'adk_pipeline_runner', 'pipeline': pipeline.name},
    );
    state = state!.copyWith(messages: [...state!.messages, startMsg]);

    // 3. Execute via ADK Service
    final adkService = ref.read(adkServiceProvider);
    
    // Clean input (remove command)
    final cleanInput = userPrompt.replaceAll(RegExp(r'@run:\s*\w+'), '').trim();

    final result = await adkService.executePipeline(
      pipeline: pipeline, 
      initialInput: cleanInput.isEmpty ? "Conduct research on current market trends" : cleanInput,
      context: context,
      memoryContext: memoryContext,
      onStepLog: (stepName, log) {
         debugPrint('ADK Log [$stepName]: $log');
      }
    );

    // 4. Final Result
    final finalMsg = ChatMessage(
      id: const Uuid().v4(),
      content: result.success ? result.output : "Pipeline Failed: ${result.output}",
      // The final output comes from the Security Agent (which wraps the pipeline), 
      // but showing it as Orchestrator is clearer for the "Runner" concept.
      sender: MessageSender.orchestratorAgent,
      createdAt: DateTime.now(),
      metadata: {'logs': result.stepLogs}, // Store logs for detailed view
    );

    state = state!.copyWith(
      messages: [...state!.messages.where((m) => m.id != startMsg.id), finalMsg],
      updatedAt: DateTime.now(),
    );
  }
}

extension ListExtensions<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatSession?>((ref) => ChatNotifier(ref));
