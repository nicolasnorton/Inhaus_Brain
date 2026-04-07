import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/budget_governor.dart';
import '../models/chat_models.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../../core/architecture/reflection_loop.dart';
import 'agent_config.dart';
import 'agent_executor.dart';

abstract class BaseAgent {
  MessageSender get type;
  String get name;
  String get systemPromptKey;
  
  /// Configuration for this agent (model, temp, etc.)
  AgentConfig get config => const AgentConfig();

  /// Tools available to this agent
  List<AgentTool> get tools => []; 

  /// Model configuration for this agent's LLM calls.
  AIModelConfig get modelConfig => AIModelConfig.geminiResearch;

  /// Maximum tool-calling iterations for the ReAct loop.
  int get maxIterations => 8;

  /// Whether this agent should use thinking/reasoning mode.
  bool get enableThinking => false;

  /// Legacy single-shot execution. Preserved for backward compatibility.
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
    Function(AdkEvent)? onEvent,
    dynamic ref,
  });

  /// Execute with the ReAct tool-calling loop via [AgentExecutor].
  ///
  /// March 2026 agentic standard: agents iteratively call tools when
  /// the LLM requests them, building on each result until producing
  /// a final answer. Includes conditional ReflectionLoop quality gate.
  Future<ExecutorResult> executeWithTools({
    required String userPrompt,
    required List<KnowledgeSource> context,
    required String systemPrompt,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
    Function(AdkEvent)? onEvent,
    dynamic ref,
    ExecutorConfig? config,
  }) async {
    final executor = AgentExecutor(
      agentName: name,
      systemPrompt: systemPrompt,
      tools: tools,
    );

    var executorConfig = config ?? ExecutorConfig(
      maxIterations: maxIterations,
      modelConfig: modelConfig,
      enableThinking: enableThinking,
    );

    // Dynamic Model Selection via BudgetGovernor (Phase 5)
    if (ref != null && config == null) {
      try {
        final governor = ref.read(budgetGovernorProvider);
        final recommendedModelId = governor.recommendModel();
        if (recommendedModelId.contains('lite') && !enableThinking) {
           executorConfig = ExecutorConfig(
             maxIterations: maxIterations,
             modelConfig: AIModelConfig.geminiFlashLite,
             enableThinking: enableThinking,
           );
        }
      } catch (e) {
        debugPrint('BaseAgent: BudgetGovernor model check failed: $e');
      }
    }

    final result = await executor.run(
      userPrompt: userPrompt,
      context: context,
      config: executorConfig,
      onEvent: onEvent,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    );

    // ── Conditional Quality Gate ──
    // Only run ReflectionLoop for tasks explicitly tagged as high-stakes
    final triggerKeywords = ['highimpact', 'be exact', 'audit', 'verify', 'critical', 'double check'];
    final needsReflection = triggerKeywords.any((kw) => userPrompt.toLowerCase().contains(kw));

    if (needsReflection && ref != null && result.text.isNotEmpty) {
      debugPrint('BaseAgent ($name): HighImpact task detected — running ReflectionLoop.');
      onEvent?.call(AdkEvent(
        type: AdkEventType.agentThinking,
        source: name,
        message: 'Running quality assurance checks...',
      ));

      try {
        final reflection = await ReflectionLoop.evaluate(
          originalPrompt: userPrompt,
          agentOutput: result.text,
          agentName: name,
          ref: ref,
        );

        if (!reflection.passesThreshold || reflection.score < 0.8) {
           debugPrint('BaseAgent: Output failed reflection (score=${reflection.score}). Critique: ${reflection.critique}');
           onEvent?.call(AdkEvent(
             type: AdkEventType.agentThinking,
             source: name,
             message: 'Revising output based on self-critique...',
           ));

           // Rerun with critique injected
           final critiquePrompt =
               'Revise your previous answer based on this critique: ${reflection.critique}\n'
               'Issues: ${reflection.issues.join(', ')}\n'
               'Original Prompt: $userPrompt';

           return await executor.run(
             userPrompt: critiquePrompt,
             context: context,
             onEvent: onEvent,
             ref: ref,
             apiKey: apiKey,
             gemmaKey: gemmaKey,
           );
        }
      } catch (e) {
        debugPrint('BaseAgent: Reflection check failed: $e');
      }
    }

    return result;
  }
}
