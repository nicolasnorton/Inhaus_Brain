import 'dart:typed_data';
import '../../knowledge/models/knowledge_source.dart';
import '../models/chat_models.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/tokens/llm_provider.dart';
import 'agent_config.dart';
import 'agent_executor.dart';

abstract class BaseAgent {
  MessageSender get type;
  String get name;
  String get systemPromptKey; // Key to fetch from SystemPromptsService if needed, or hardcoded default
  
  /// Configuration for this agent (model, temp, etc.)
  AgentConfig get config => const AgentConfig();

  /// Tools available to this agent
  List<AgentTool> get tools => []; 

  /// Model configuration for this agent's LLM calls.
  /// Override in subclasses to customize model tier, temperature, etc.
  AIModelConfig get modelConfig => AIModelConfig.geminiResearch;

  /// Maximum tool-calling iterations for the ReAct loop.
  int get maxIterations => 8;

  /// Whether this agent should use thinking/reasoning mode.
  bool get enableThinking => false;

  /// Legacy single-shot execution. Preserved for backward compatibility.
  /// New agents should prefer [executeWithTools] which enables the ReAct loop.
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt, // Optional override from SystemPromptsService
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
    Function(AdkEvent)? onEvent,
    dynamic ref, // Phase 89
  });

  /// Execute with the ReAct tool-calling loop via [AgentExecutor].
  ///
  /// This is the March 2026 agentic standard: agents iteratively call
  /// tools when the LLM requests them, building on each result until
  /// producing a final answer.
  ///
  /// Falls back to legacy [execute] if no system prompt is provided and
  /// the agent hasn't been migrated to the new pattern.
  Future<ExecutorResult> executeWithTools({
    required String userPrompt,
    required List<KnowledgeSource> context,
    required String systemPrompt,
    Uint8List? imageBytes,
    String? imageMimeType,
    Function(AdkEvent)? onEvent,
    dynamic ref,
    ExecutorConfig? config,
  }) async {
    final executor = AgentExecutor(
      agentName: name,
      systemPrompt: systemPrompt,
      tools: tools,
    );

    final executorConfig = config ?? ExecutorConfig(
      maxIterations: maxIterations,
      modelConfig: modelConfig,
      enableThinking: enableThinking,
    );

    return executor.run(
      userPrompt: userPrompt,
      context: context,
      config: executorConfig,
      onEvent: onEvent,
      ref: ref,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
    );
  }
}
