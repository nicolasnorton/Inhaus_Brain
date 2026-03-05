import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/adk/models/pipeline_models.dart';
import '../../adk/providers/workflow_execution_provider.dart';
import '../../adk/models/workflow_execution_models.dart';

/// Simplified "App Mode" UI for a campaign canvas workflow.
///
/// Reads a list of PipelineSteps and renders:
/// - Input fields for nodes of type `userInput`
/// - A "Generate" button to execute the pipeline
/// - An output gallery for results from `answer`/`output` nodes
///
/// This mirrors Weavy's "Workflow → App Mode" concept, providing
/// a clean form UI for non-technical users.
class CampaignAppModeScreen extends ConsumerStatefulWidget {
  final String campaignId;
  final List<PipelineStep> steps;

  const CampaignAppModeScreen({
    super.key,
    required this.campaignId,
    required this.steps,
  });

  @override
  ConsumerState<CampaignAppModeScreen> createState() =>
      _CampaignAppModeScreenState();
}

class _CampaignAppModeScreenState extends ConsumerState<CampaignAppModeScreen> {
  final Map<String, TextEditingController> _inputControllers = {};
  bool _isExecuting = false;

  late List<PipelineStep> _inputNodes;
  late List<PipelineStep> _outputNodes;

  @override
  void initState() {
    super.initState();
    // Separate input and output nodes
    _inputNodes = widget.steps
        .where((s) =>
            s.nodeType == WorkflowNodeType.userInput ||
            s.nodeType == WorkflowNodeType.start)
        .toList();
    _outputNodes = widget.steps
        .where((s) =>
            s.nodeType == WorkflowNodeType.answer ||
            s.nodeType == WorkflowNodeType.output)
        .toList();

    // Create controllers for each input node
    for (final node in _inputNodes) {
      _inputControllers[node.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _inputControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _executeAll() async {
    setState(() => _isExecuting = true);

    final execNotifier = ref.read(workflowExecutionProvider.notifier);
    execNotifier.startExecution();

    // Feed input values into workflow variables
    for (final node in _inputNodes) {
      final value = _inputControllers[node.id]?.text ?? '';
      execNotifier.updateCachedVariable(node.id, {'value': value});
      execNotifier.updateNodeStatus(node.id, ExecutionStatus.success);
    }

    // Execute remaining nodes in topological order
    for (final step in widget.steps) {
      if (_inputNodes.contains(step)) continue;
      final inputs = <String, dynamic>{};
      for (final dep in step.dependencies) {
        inputs[dep] =
            ref.read(workflowExecutionProvider).cachedVariables[dep] ?? {};
      }
      await execNotifier.executeNode(widget.campaignId, step.id, inputs);
    }

    execNotifier.endExecution();
    setState(() => _isExecuting = false);
  }

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(workflowExecutionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Campaign App', style: TextStyle(fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(
                  '${widget.steps.length} nodes',
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9C1AFF).withValues(alpha: 0.2),
                      const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF9C1AFF).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.wandMagicSparkles,
                        color: Color(0xFF9C1AFF), size: 20),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('App Mode',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(height: 2),
                          Text(
                            'Fill in the inputs and hit Generate. The pipeline runs automatically.',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Input Fields
              if (_inputNodes.isNotEmpty) ...[
                Text('Inputs',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 12),
                ..._inputNodes.map((node) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: _inputControllers[node.id],
                        style: const TextStyle(color: Colors.white),
                        maxLines:
                            node.config['inputType'] == 'text' ? 3 : 1,
                        decoration: InputDecoration(
                          labelText:
                              node.config['label']?.toString() ??
                                  node.instruction,
                          labelStyle:
                              TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF9C1AFF)),
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isExecuting ? null : _executeAll,
                  icon: _isExecuting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const FaIcon(FontAwesomeIcons.play,
                          size: 14, color: Colors.white),
                  label: Text(
                      _isExecuting ? 'Running Pipeline…' : 'Generate',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C1AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Output Gallery
              if (_outputNodes.isNotEmpty) ...[
                Text('Results',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 12),
                ..._outputNodes.map((node) {
                  final result =
                      executionState.cachedVariables[node.id];
                  final status =
                      executionState.nodeStatuses[node.id] ??
                          ExecutionStatus.idle;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: status == ExecutionStatus.success
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status == ExecutionStatus.success
                                  ? Icons.check_circle
                                  : status == ExecutionStatus.running
                                      ? Icons.autorenew
                                      : Icons.circle_outlined,
                              color: status == ExecutionStatus.success
                                  ? Colors.greenAccent
                                  : Colors.white38,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(node.instruction.isNotEmpty
                                ? node.instruction
                                : 'Output',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12)),
                          ],
                        ),
                        if (result != null) ...[
                          const SizedBox(height: 8),
                          Text(result.toString(),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
