import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/adk/models/pipeline_models.dart';
import '../../../../core/architecture/blackboard.dart';
import '../../services/brainweave_pipeline_service.dart';

/// ADK Canvas node that encapsulates the BrainWeave 6R Pipeline.
/// Drop this node onto the workflow canvas to run the BrainWeave
/// pipeline as part of any multi-step agentic workflow.
///
/// Inputs:
///   rawInput  (String) — knowledge to push through the 6R pipeline.
///   clientId  (String) — owner/client context for Core Space lookup.
///
/// Outputs:
///   sessionId  (String) — created Firestore session document ID.
///   nodeCount  (int)    — number of nodes written to Weave Space.
class BrainWeavePipelineNode extends ConsumerStatefulWidget {
  final PipelineStep step;
  final bool isSelected;
  final VoidCallback? onTap;

  const BrainWeavePipelineNode({
    super.key,
    required this.step,
    this.isSelected = false,
    this.onTap,
  });

  @override
  ConsumerState<BrainWeavePipelineNode> createState() =>
      _BrainWeavePipelineNodeState();
}

class _BrainWeavePipelineNodeState
    extends ConsumerState<BrainWeavePipelineNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double>    _shimmerAnimation;
  bool   _isRunning  = false;
  String _nodeStatus = 'idle';

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _execute() async {
    final rawInput = widget.step.config['rawInput'] as String? ?? '';
    final clientId = widget.step.config['clientId'] as String? ?? 'default';
    if (rawInput.isEmpty) return;

    setState(() {
      _isRunning  = true;
      _nodeStatus = 'running';
    });
    _shimmerController.repeat();

    try {
      final pipeline  = ref.read(brainWeavePipelineServiceProvider);
      final sessionId = 'bw_node_${DateTime.now().millisecondsSinceEpoch}';
      await pipeline.runPipeline(sessionId, '$clientId: $rawInput');
      setState(() {
        _nodeStatus = 'awaiting_approval';
        _isRunning  = false;
      });
    } catch (e) {
      setState(() {
        _nodeStatus = 'error: ${e.toString().substring(0, 40)}';
        _isRunning  = false;
      });
    } finally {
      _shimmerController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final blackboard = ref.watch(blackboardProvider);
    final phase      = blackboard.phase;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4C1D95), Color(0xFF6C3DE8), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.2),
            width: widget.isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C3DE8).withValues(alpha: 0.5),
              blurRadius: widget.isSelected ? 20 : 10,
              spreadRadius: widget.isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.brain,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'BrainWeave',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_isRunning)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '6R Pipeline',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 12),

              // Input / Output badges
              _IOBadge(label: 'IN: rawInput (String)'),
              const SizedBox(height: 4),
              _IOBadge(label: 'IN: clientId (String)'),
              const SizedBox(height: 6),
              _IOBadge(label: 'OUT: sessionId (String)', isOutput: true),
              const SizedBox(height: 4),
              _IOBadge(label: 'OUT: nodeCount (int)', isOutput: true),
              const SizedBox(height: 12),

              // Phase status
              _PhaseChip(phase: phase),
              const SizedBox(height: 8),

              // Status line
              Text(
                _nodeStatus,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Execute button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRunning ? null : _execute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isRunning ? 'Running…' : 'Execute',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IOBadge extends StatelessWidget {
  final String label;
  final bool isOutput;
  const _IOBadge({required this.label, this.isOutput = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOutput
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: isOutput ? Colors.greenAccent : Colors.lightBlueAccent,
        ),
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final BlackboardPhase phase;
  const _PhaseChip({required this.phase});

  static const _phaseLabels = {
    BlackboardPhase.brainweaveRecord:  'RECORD',
    BlackboardPhase.brainweaveReduce:  'REDUCE',
    BlackboardPhase.brainweaveReflect: 'REFLECT',
    BlackboardPhase.brainweaveReweave: 'REWEAVE',
    BlackboardPhase.brainweaveVerify:  'VERIFY',
    BlackboardPhase.brainweaveRethink: 'RETHINK',
    BlackboardPhase.reviewPending:     'GAVEL ⏸',
    BlackboardPhase.idle:              'IDLE',
  };

  @override
  Widget build(BuildContext context) {
    final label = _phaseLabels[phase] ?? phase.name.toUpperCase();
    final isBW  = label != 'IDLE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isBW
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isBW
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isBW ? Colors.white : Colors.white38,
        ),
      ),
    );
  }
}
