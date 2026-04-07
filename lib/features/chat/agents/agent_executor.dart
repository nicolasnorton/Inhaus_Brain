/// AgentExecutor — ReAct tool-calling loop engine.
///
/// This is the core execution engine that transforms InhausBrain agents
/// from single-shot LLM responders into iterative, tool-using reasoners.
///
/// The ReAct (Reason + Act) loop:
/// 1. Call LLM with system prompt + user prompt + tools
/// 2. If LLM returns functionCall → execute tool → append result → goto 1
/// 3. If LLM returns text → return as final answer
/// 4. If max iterations reached → return best available text
///
/// Competitive parity:
/// - Google ADK 2.0: Graph-based workflows with function calling
/// - Claude Workspace: Iterative tool-use + computer-use loops
/// - Grok 4.2 Heavy: Native tool-use loop with cross-verification
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/services/ai/ai_generation_request.dart';
import '../../../core/services/ai/ai_router.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../knowledge/models/knowledge_source.dart';

/// Configuration for the AgentExecutor.
class ExecutorConfig {
  /// Maximum number of LLM round-trips (tool calls + final answer).
  final int maxIterations;

  /// Timeout for the entire execution (all iterations combined).
  final Duration timeout;

  /// Whether to emit detailed ADK events for each step.
  final bool emitEvents;

  /// Model configuration to use for LLM calls.
  final AIModelConfig modelConfig;

  /// Whether to use thinking/reasoning mode.
  final bool enableThinking;

  const ExecutorConfig({
    this.maxIterations = 8,
    this.timeout = const Duration(seconds: 300),
    this.emitEvents = true,
    this.modelConfig = const AIModelConfig(
      provider: AIProvider.gemini,
      modelId: 'gemini-3-flash-preview',
      temperature: 1.0,
      useGoogleSearch: true,
    ),
    this.enableThinking = false,
  });

  /// Apply thinking mode to the model config.
  AIModelConfig get effectiveModelConfig {
    if (enableThinking) {
      return modelConfig.copyWith(thinkingLevel: 'medium');
    }
    return modelConfig;
  }
}

/// Record of a single tool execution within the ReAct loop.
class ToolExecutionRecord {
  final String toolName;
  final Map<String, dynamic> arguments;
  final ToolResult result;
  final Duration duration;

  const ToolExecutionRecord({
    required this.toolName,
    required this.arguments,
    required this.result,
    required this.duration,
  });

  /// Format for injection back into the LLM conversation.
  String toPromptFragment() {
    if (result.isSuccess) {
      return 'Tool "$toolName" returned: ${jsonEncode(result.data)}';
    }
    return 'Tool "$toolName" failed: ${result.errorMessage}';
  }
}

/// Result of a full AgentExecutor run (potentially multiple iterations).
class ExecutorResult {
  /// The final text response from the agent.
  final String text;

  /// All tool executions that occurred during the run.
  final List<ToolExecutionRecord> toolExecutions;

  /// Number of LLM round-trips taken.
  final int iterations;

  /// Total wall-clock time for all iterations.
  final Duration totalDuration;

  /// Model used for the final response.
  final String? modelUsed;

  /// Chain-of-thought content (if thinking was enabled).
  final String? thinkingContent;

  /// Source citations from grounded responses.
  final List<String> sourceCitations;

  /// The Interaction ID for stateful conversational continuity.
  final String? interactionId;
  
  /// Status of the background interaction, e.g., RUNNING.
  final String? status;

  const ExecutorResult({
    required this.text,
    this.toolExecutions = const [],
    this.iterations = 1,
    required this.totalDuration,
    this.modelUsed,
    this.thinkingContent,
    this.sourceCitations = const [],
    this.interactionId,
    this.status,
  });
}

/// The core ReAct execution engine.
///
/// Usage:
/// ```dart
/// final executor = AgentExecutor(
///   agentName: 'Research Agent',
///   systemPrompt: researchPrompt,
///   tools: [QueryBrainWeaveTool(), WebSearchTool()],
/// );
/// final result = await executor.run(
///   userPrompt: 'Find our competitor analysis from Q4',
///   context: knowledgeSources,
///   config: ExecutorConfig(maxIterations: 5),
///   ref: ref,
/// );
/// ```
class AgentExecutor {
  static final _logger = Logger();

  final String agentName;
  final String systemPrompt;
  final List<AgentTool> tools;

  AgentExecutor({
    required this.agentName,
    required this.systemPrompt,
    required this.tools,
  });

  /// Resolve a tool by name from the available tools list.
  AgentTool? _findTool(String name) {
    try {
      return tools.firstWhere((t) => t.name == name);
    } catch (_) {
      // Try case-insensitive match
      try {
        return tools.firstWhere(
          (t) => t.name.toLowerCase() == name.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Execute the ReAct loop.
  ///
  /// This is the primary entry point. It calls the LLM, checks for
  /// function calls, executes them, and loops until a final text answer
  /// is produced or the iteration limit is reached.
  Future<ExecutorResult> run({
    required String userPrompt,
    List<KnowledgeSource> context = const [],
    ExecutorConfig config = const ExecutorConfig(),
    Function(AdkEvent)? onEvent,
    dynamic ref,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? previousInteractionId,
    String? apiKey,
    String? gemmaKey,
  }) async {
    final stopwatch = Stopwatch()..start();
    final toolExecutions = <ToolExecutionRecord>[];
    final conversationParts = <String>[];
    int iteration = 0;

    // Build tool schemas for LLM
    final toolSchemas = tools.isNotEmpty
        ? tools.map((t) => t.toFunctionSchema()).toList()
        : null;

    if (config.emitEvents) {
      onEvent?.call(AdkEvent(
        type: AdkEventType.agentStarted,
        source: agentName,
        message: 'Starting execution with ${tools.length} tools available',
      ));
    }

    String? lastThinking;
    List<String> sourceCitations = [];
    String? modelUsed;
    String? currentInteractionId = previousInteractionId;

    while (iteration < config.maxIterations) {
      iteration++;

      // Build the effective prompt with tool results from previous iterations
      final effectivePrompt = _buildPrompt(
        userPrompt: userPrompt,
        previousToolResults: conversationParts,
        iteration: iteration,
      );

      if (config.emitEvents && iteration > 1) {
        onEvent?.call(AdkEvent(
          type: AdkEventType.agentThinking,
          source: agentName,
          message: 'Iteration $iteration — processing tool results',
        ));
      }

      // Call the LLM via strategy layer
      final request = AIGenerationRequest(
        prompt: effectivePrompt,
        config: config.effectiveModelConfig,
        systemInstruction: systemPrompt,
        context: context,
        tools: toolSchemas,
        imageBytes: iteration == 1 ? imageBytes : null,
        imageMimeType: iteration == 1 ? imageMimeType : null,
        previousInteractionId: currentInteractionId,
        apiKey: apiKey,
      );

      AIGenerationResult result;
      try {
        result = await AIRouter.generate(request, ref: ref)
            .timeout(config.timeout);
      } catch (e) {
        _logger.e('AgentExecutor: LLM call failed on iteration $iteration: $e');
        if (config.emitEvents) {
          onEvent?.call(AdkEvent(
            type: AdkEventType.agentError,
            source: agentName,
            message: 'LLM call failed: $e',
          ));
        }
        // Return best available result
        stopwatch.stop();
        return ExecutorResult(
          text: conversationParts.isNotEmpty
              ? 'Partial result after ${iteration - 1} iterations:\n${conversationParts.last}'
              : 'AI service temporarily unavailable. Please try again.',
          toolExecutions: toolExecutions,
          iterations: iteration,
          totalDuration: stopwatch.elapsed,
          sourceCitations: sourceCitations,
          interactionId: currentInteractionId,
        );
      }

      modelUsed = result.modelUsed;
      if (result.thinkingContent != null) {
        lastThinking = result.thinkingContent;
      }
      if (result.sourceCitations.isNotEmpty) {
        sourceCitations = result.sourceCitations;
      }
      if (result.interactionId != null) {
        currentInteractionId = result.interactionId;
      }

      // ── Check: Does the LLM want to call tools? ──
      if (result.hasFunctionCalls) {
        _logger.d('AgentExecutor: Iteration $iteration — ${result.functionCalls.length} tool call(s) requested');

        for (final fc in result.functionCalls) {
          final tool = _findTool(fc.name);

          if (tool == null) {
            _logger.w('AgentExecutor: Tool "${fc.name}" not found. Available: ${tools.map((t) => t.name).join(', ')}');
            conversationParts.add(
              'Tool "${fc.name}" is not available. Available tools: ${tools.map((t) => t.name).join(', ')}',
            );
            continue;
          }

          if (config.emitEvents) {
            onEvent?.call(AdkEvent(
              type: AdkEventType.toolStarted,
              source: agentName,
              message: 'Calling tool: ${fc.name}',
              metadata: {'args': fc.arguments},
            ));
          }

          // Execute the tool
          final toolStopwatch = Stopwatch()..start();
          ToolResult toolResult;
          try {
            toolResult = await tool.execute(fc.arguments, ref: ref);
          } catch (e) {
            _logger.e('AgentExecutor: Tool "${fc.name}" threw: $e');
            toolResult = ToolResult.failure('Tool execution error: $e');
          }
          toolStopwatch.stop();

          final record = ToolExecutionRecord(
            toolName: fc.name,
            arguments: fc.arguments,
            result: toolResult,
            duration: toolStopwatch.elapsed,
          );
          toolExecutions.add(record);

          // Add tool result to conversation for next iteration
          conversationParts.add(record.toPromptFragment());

          if (config.emitEvents) {
            onEvent?.call(AdkEvent(
              type: AdkEventType.toolCompleted,
              source: agentName,
              message: toolResult.isSuccess
                  ? 'Tool ${fc.name} succeeded'
                  : 'Tool ${fc.name} failed: ${toolResult.errorMessage}',
              metadata: {
                'tool': fc.name,
                'success': toolResult.isSuccess,
                'durationMs': toolStopwatch.elapsedMilliseconds,
              },
            ));
          }
        }

        // Continue the loop — call LLM again with tool results
        continue;
      }

      // ── No function calls → LLM produced a final text answer ──
      stopwatch.stop();

      if (config.emitEvents) {
        onEvent?.call(AdkEvent(
          type: AdkEventType.agentCompleted,
          source: agentName,
          message: 'Completed in $iteration iteration(s), ${toolExecutions.length} tool call(s)',
          metadata: {
            'iterations': iteration,
            'toolCalls': toolExecutions.length,
            'durationMs': stopwatch.elapsedMilliseconds,
          },
        ));
      }

      return ExecutorResult(
        text: result.text,
        toolExecutions: toolExecutions,
        iterations: iteration,
        totalDuration: stopwatch.elapsed,
        modelUsed: modelUsed,
        thinkingContent: lastThinking,
        sourceCitations: sourceCitations,
        interactionId: currentInteractionId,
      );
    }

    // ── Max iterations reached ──
    stopwatch.stop();
    _logger.w('AgentExecutor: Max iterations ($config.maxIterations) reached for $agentName');

    if (config.emitEvents) {
      onEvent?.call(AdkEvent(
        type: AdkEventType.agentCompleted,
        source: agentName,
        message: 'Max iterations reached ($iteration). Returning best result.',
      ));
    }

    return ExecutorResult(
      text: conversationParts.isNotEmpty
          ? conversationParts.last
          : 'I reached the maximum number of processing steps. Please try a more specific request.',
      toolExecutions: toolExecutions,
      iterations: iteration,
      totalDuration: stopwatch.elapsed,
      modelUsed: modelUsed,
      thinkingContent: lastThinking,
      sourceCitations: sourceCitations,
      interactionId: currentInteractionId,
    );
  }

  /// Build the prompt for a given iteration, incorporating previous tool results.
  String _buildPrompt({
    required String userPrompt,
    required List<String> previousToolResults,
    required int iteration,
  }) {
    if (previousToolResults.isEmpty) {
      return userPrompt;
    }

    final buffer = StringBuffer();
    buffer.writeln('USER REQUEST: $userPrompt');
    buffer.writeln();
    buffer.writeln('TOOL EXECUTION RESULTS (from your previous requests):');
    for (int i = 0; i < previousToolResults.length; i++) {
      buffer.writeln('${i + 1}. ${previousToolResults[i]}');
    }
    buffer.writeln();
    buffer.writeln('Based on the tool results above, provide your response to the user. '
        'You may call additional tools if needed, or provide your final answer.');
    return buffer.toString();
  }
}
