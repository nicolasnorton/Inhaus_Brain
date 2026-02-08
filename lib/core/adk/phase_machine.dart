import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../features/chat/agents/base_agent.dart';
import '../../features/chat/agents/agency_agents.dart'; // For context/types
import '../../features/knowledge/models/knowledge_source.dart';
import 'services/adk_event_bus.dart';

enum AgentPhase {
  idle,
  planning,
  executing,
  validating,
  completed,
  failed,
}

/// The Phase Machine orchestrates agent execution with strict guards.
class PhaseMachine {
  final Function(AdkEvent)? onEvent;
  // Simple in-memory idempotency cache (key -> result)
  final Map<String, String> _idempotencyCache = {};
  
  // Handoff depth tracking
  int _current depth = 0;
  static const int maxDepth = 5;

  PhaseMachine({this.onEvent});

  /// Executes an agent with full Phase Machine protection:
  /// 1. Validation of Input
  /// 2. Idempotency Check
  /// 3. Phase Transition Logging
  /// 4. Execution
  /// 5. Output Validation
  Future<String> executeAgent(
    BaseAgent agent, {
    required String userPrompt,
    List<KnowledgeSource> context = const [],
    String? idempotencyKey,
    // Add other execute params as needed
    String? apiKey,
    dynamic ref,
  }) async {
    // 1. Idempotency Check
    if (idempotencyKey != null && _idempotencyCache.containsKey(idempotencyKey)) {
      debugPrint('[PhaseMachine] ⏭️ Skipping execution (Idempotency Key Hit): $idempotencyKey');
      return _idempotencyCache[idempotencyKey]!;
    }

    _transition(AgentPhase.planning, agent.name);

    // 2. Input Validation (Optional, if agent defines input schema)
    // We construct a mock input map for validation purposes if needed
    // In a real scenario, 'userPrompt' might be a structured JSON string.
    try {
       if (agent.inputSchema != null) {
          // Attempt to parse userPrompt if it looks like JSON
          if (userPrompt.trim().startsWith('{')) {
             final inputMap = jsonDecode(userPrompt);
             agent.validateInput(inputMap);
          }
       }
    } catch (e) {
       _transition(AgentPhase.failed, agent.name, error: "Input Validation Error: $e");
       rethrow;
     }

    _transition(AgentPhase.executing, agent.name);
    
    try {
      final result = await agent.execute(
        userPrompt: userPrompt,
        context: context,
        apiKey: apiKey,
        onEvent: onEvent,
        ref: ref,
      );

      _transition(AgentPhase.validating, agent.name);

      // 3. Output Validation
      if (agent.outputSchema != null) {
         try {
            // Try to find JSON in the result
            String jsonStr = result;
            if (result.contains('```json')) {
                jsonStr = result.split('```json').last.split('```').first.trim();
            } else if (result.contains('{')) {
                final start = result.indexOf('{');
                final end = result.lastIndexOf('}');
                if (end > start) {
                   jsonStr = result.substring(start, end + 1);
                }
            }
            
            final outputMap = jsonDecode(jsonStr);
            agent.validateOutput(outputMap);
         } catch (e) {
             throw FormatException("Output Validation Failed: $e");
         }
      }

      // 4. Cache Result
      if (idempotencyKey != null) {
        _idempotencyCache[idempotencyKey] = result;
      }

      _transition(AgentPhase.completed, agent.name);
      return result;

    } catch (e) {
      _transition(AgentPhase.failed, agent.name, error: e.toString());
      rethrow;
    }
  }

  void _transition(AgentPhase phase, String agentName, {String? error}) {
    debugPrint('[PhaseMachine] 🔄 $agentName -> ${phase.name.toUpperCase()} ${error ?? ''}');
    // Broadcast event if needed
    onEvent?.call(AdkEvent(
        type: phase == AgentPhase.completed ? AdkEventType.agentCompleted : AdkEventType.agentStarted, 
        source: "PhaseMachine: $agentName ($phase)",
        payload: error
    ));
  }
}
