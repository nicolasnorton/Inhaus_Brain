/// AgentDAG — Directed Acyclic Graph execution engine for agent orchestration.
///
/// Replaces the hardcoded if/else chain in OrchestrationService with a
/// dynamic, parallel execution engine that:
/// - Resolves task dependencies
/// - Executes independent tasks in parallel via Future.wait()
/// - Merges results for downstream consumers
/// - Handles timeouts and failures per-node
///
/// Competitive parity:
/// - Google ADK 2.0: Graph-based workflows
/// - Claude Workspace: Agent Teams with shared task list
/// - Grok 4.2 Heavy: 4-16 agents running in parallel
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../features/knowledge/models/knowledge_source.dart';
import '../adk/services/adk_event_bus.dart';

/// A single node in the execution DAG.
class DAGNode {
  /// Unique identifier for this node.
  final String id;

  /// The agent to execute at this node.
  final String agentName;

  /// IDs of nodes that must complete before this node can start.
  final List<String> dependencies;

  /// The prompt/task for this node's agent.
  final String task;

  /// Timeout for this individual node.
  final Duration timeout;

  /// Priority (higher = executed first among ready nodes).
  final int priority;

  const DAGNode({
    required this.id,
    required this.agentName,
    this.dependencies = const [],
    required this.task,
    this.timeout = const Duration(seconds: 120),
    this.priority = 0,
  });

  @override
  String toString() => 'DAGNode($id: $agentName, deps: $dependencies)';
}

/// Result of a single DAG node execution.
class DAGNodeResult {
  final String nodeId;
  final String agentName;
  final String output;
  final Duration duration;
  final bool success;
  final String? error;

  const DAGNodeResult({
    required this.nodeId,
    required this.agentName,
    required this.output,
    required this.duration,
    this.success = true,
    this.error,
  });
}

/// Result of a full DAG execution.
class DAGExecutionResult {
  final List<DAGNodeResult> nodeResults;
  final Duration totalDuration;
  final bool allSucceeded;
  final String? mergedOutput;

  const DAGExecutionResult({
    required this.nodeResults,
    required this.totalDuration,
    required this.allSucceeded,
    this.mergedOutput,
  });

  /// Get the result for a specific node.
  DAGNodeResult? getResult(String nodeId) {
    try {
      return nodeResults.firstWhere((r) => r.nodeId == nodeId);
    } catch (_) {
      return null;
    }
  }
}

/// The DAG execution engine.
///
/// Usage:
/// ```dart
/// final dag = AgentDAG(nodes: [
///   DAGNode(id: 'research', agentName: 'Research Agent', task: 'Research X'),
///   DAGNode(id: 'creative', agentName: 'Creative Agent', task: 'Create concepts', dependencies: ['research']),
///   DAGNode(id: 'copy', agentName: 'Copywriter Agent', task: 'Write copy', dependencies: ['research']),
///   DAGNode(id: 'review', agentName: 'Editorial Manager', task: 'Review all', dependencies: ['creative', 'copy']),
/// ]);
///
/// final result = await dag.execute(agentResolver: (name) => getAgent(name), ref: ref);
/// ```
class AgentDAG {
  final List<DAGNode> nodes;
  final Duration totalTimeout;

  AgentDAG({
    required this.nodes,
    this.totalTimeout = const Duration(seconds: 300),
  }) {
    _validateDAG();
  }

  /// Validate that the DAG has no cycles and all dependencies exist.
  void _validateDAG() {
    final nodeIds = nodes.map((n) => n.id).toSet();
    for (final node in nodes) {
      for (final dep in node.dependencies) {
        if (!nodeIds.contains(dep)) {
          throw ArgumentError('DAGNode "${node.id}" depends on "$dep" which does not exist');
        }
      }
    }
    // Simple cycle detection via topological sort attempt
    final visited = <String>{};
    final visiting = <String>{};

    void visit(String nodeId) {
      if (visited.contains(nodeId)) return;
      if (visiting.contains(nodeId)) {
        throw ArgumentError('Cycle detected in DAG involving node "$nodeId"');
      }
      visiting.add(nodeId);
      final node = nodes.firstWhere((n) => n.id == nodeId);
      for (final dep in node.dependencies) {
        visit(dep);
      }
      visiting.remove(nodeId);
      visited.add(nodeId);
    }

    for (final node in nodes) {
      visit(node.id);
    }
  }

  /// Get nodes that are ready to execute (all dependencies completed).
  List<DAGNode> _getReadyNodes(Set<String> completedIds) {
    return nodes
        .where((n) => !completedIds.contains(n.id))
        .where((n) => n.dependencies.every(completedIds.contains))
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Execute the DAG.
  ///
  /// [agentExecutor] resolves an agent name to an execute function.
  /// The engine executes independent nodes in parallel and waits for
  /// dependencies before starting downstream nodes.
  Future<DAGExecutionResult> execute({
    required Future<String> Function(String agentName, String task, List<KnowledgeSource> upstreamContext) agentExecutor,
    Function(AdkEvent)? onEvent,
    List<KnowledgeSource> initialContext = const [],
  }) async {
    final stopwatch = Stopwatch()..start();
    final results = <DAGNodeResult>[];
    final completedIds = <String>{};
    final nodeOutputs = <String, String>{}; // nodeId → output text

    onEvent?.call(AdkEvent(
      type: AdkEventType.pipelineStarted,
      source: 'DAG Engine',
      message: 'Starting pipeline with ${nodes.length} tasks',
      metadata: {'nodeCount': nodes.length, 'nodes': nodes.map((n) => n.id).toList()},
    ));

    while (completedIds.length < nodes.length) {
      final readyNodes = _getReadyNodes(completedIds);

      if (readyNodes.isEmpty && completedIds.length < nodes.length) {
        // This shouldn't happen in a valid DAG, but safety check
        debugPrint('AgentDAG: No ready nodes but not all complete. Remaining: ${nodes.where((n) => !completedIds.contains(n.id)).map((n) => n.id).join(', ')}');
        break;
      }

      // Execute all ready nodes in parallel
      final futures = readyNodes.map((node) async {
        final nodeStopwatch = Stopwatch()..start();

        onEvent?.call(AdkEvent(
          type: AdkEventType.agentStarted,
          source: node.agentName,
          message: 'Starting: ${node.task.length > 80 ? '${node.task.substring(0, 80)}...' : node.task}',
          metadata: {'nodeId': node.id, 'dependencies': node.dependencies},
        ));

        // Build upstream context from dependency outputs
        final upstreamContext = <KnowledgeSource>[...initialContext];
        for (final depId in node.dependencies) {
          final depOutput = nodeOutputs[depId];
          if (depOutput != null && depOutput.isNotEmpty) {
            upstreamContext.add(KnowledgeSource(
              id: 'dag_$depId',
              title: 'Output from ${nodes.firstWhere((n) => n.id == depId).agentName}',
              content: depOutput,
              type: KnowledgeSourceType.text,
              createdAt: DateTime.now(),
            ));
          }
        }

        try {
          final output = await agentExecutor(node.agentName, node.task, upstreamContext)
              .timeout(node.timeout);
          nodeStopwatch.stop();

          onEvent?.call(AdkEvent(
            type: AdkEventType.agentCompleted,
            source: node.agentName,
            message: 'Completed in ${nodeStopwatch.elapsed.inSeconds}s',
            metadata: {'nodeId': node.id, 'durationMs': nodeStopwatch.elapsedMilliseconds},
          ));

          return DAGNodeResult(
            nodeId: node.id,
            agentName: node.agentName,
            output: output,
            duration: nodeStopwatch.elapsed,
          );
        } catch (e) {
          nodeStopwatch.stop();

          onEvent?.call(AdkEvent(
            type: AdkEventType.agentError,
            source: node.agentName,
            message: 'Failed: $e',
            metadata: {'nodeId': node.id},
          ));

          return DAGNodeResult(
            nodeId: node.id,
            agentName: node.agentName,
            output: 'Error: $e',
            duration: nodeStopwatch.elapsed,
            success: false,
            error: e.toString(),
          );
        }
      }).toList();

      final batchResults = await Future.wait(futures);

      for (final result in batchResults) {
        results.add(result);
        completedIds.add(result.nodeId);
        nodeOutputs[result.nodeId] = result.output;
      }

      // Check total timeout
      if (stopwatch.elapsed > totalTimeout) {
        debugPrint('AgentDAG: Total timeout exceeded (${totalTimeout.inSeconds}s)');
        break;
      }
    }

    stopwatch.stop();

    // Merge outputs — last node's output is the "final" result,
    // but we also provide the full merged output for complex pipelines.
    final mergedOutput = StringBuffer();
    for (final result in results) {
      if (result.success) {
        mergedOutput.writeln('## ${result.agentName}\n${result.output}\n');
      }
    }

    final dagResult = DAGExecutionResult(
      nodeResults: results,
      totalDuration: stopwatch.elapsed,
      allSucceeded: results.every((r) => r.success),
      mergedOutput: mergedOutput.toString(),
    );

    onEvent?.call(AdkEvent(
      type: AdkEventType.pipelineCompleted,
      source: 'DAG Engine',
      message: 'Pipeline completed: ${results.where((r) => r.success).length}/${results.length} tasks succeeded in ${stopwatch.elapsed.inSeconds}s',
      metadata: {
        'totalDurationMs': stopwatch.elapsedMilliseconds,
        'successCount': results.where((r) => r.success).length,
        'failCount': results.where((r) => !r.success).length,
      },
    ));

    return dagResult;
  }

  /// Create a DAG from a router's pipeline plan output.
  ///
  /// Expected format from router:
  /// ```json
  /// [
  ///   {"agent": "research", "task": "Research X", "deps": []},
  ///   {"agent": "creative", "task": "Create concepts", "deps": ["research"]}
  /// ]
  /// ```
  factory AgentDAG.fromPlan(List<Map<String, dynamic>> plan) {
    final nodes = plan.asMap().entries.map((entry) {
      final step = entry.value;
      final id = step['id'] as String? ?? step['agent'] as String? ?? 'step_${entry.key}';
      return DAGNode(
        id: id,
        agentName: step['agent'] as String? ?? 'directChat',
        task: step['task'] as String? ?? '',
        dependencies: List<String>.from(step['deps'] ?? step['dependencies'] ?? []),
        priority: step['priority'] as int? ?? 0,
      );
    }).toList();

    return AgentDAG(nodes: nodes);
  }
}
