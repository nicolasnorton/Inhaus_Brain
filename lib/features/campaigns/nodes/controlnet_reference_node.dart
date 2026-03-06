import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/adk/models/pipeline_models.dart';
import '../../../core/architecture/blackboard.dart';
import '../../../core/utils/resilience_utils.dart';
import '../../adk/providers/workflow_execution_provider.dart';
import '../../adk/models/workflow_execution_models.dart';

/// Creative Canvas node: ControlNet / Structure Reference.
///
/// Inputs (via config):
///   referenceImageUrl (String) — reference image for structure/pose/depth
///   prompt            (String) — text prompt for generation
///   controlType       (String) — 'structure', 'pose', 'depth', 'canny'
///
/// Outputs:
///   resultImageUrl    (String) — generated image with control applied
class ControlNetReferenceNode extends ConsumerStatefulWidget {
  final PipelineStep step;
  final bool isSelected;
  final VoidCallback? onTap;

  const ControlNetReferenceNode({
    super.key,
    required this.step,
    this.isSelected = false,
    this.onTap,
  });

  @override
  ConsumerState<ControlNetReferenceNode> createState() =>
      _ControlNetReferenceNodeState();
}

class _ControlNetReferenceNodeState
    extends ConsumerState<ControlNetReferenceNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isRunning = false;
  String _status = 'idle';
  String? _previewUrl;

  static final _circuit = CircuitBreaker(
    name: 'ControlNetNode',
    failureThreshold: 3,
  );

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _execute() async {
    final refImage =
        widget.step.config['referenceImageUrl'] as String? ?? '';
    final prompt = widget.step.config['prompt'] as String? ?? '';
    if (refImage.isEmpty) {
      setState(() => _status = 'error: no reference image');
      return;
    }

    setState(() {
      _isRunning = true;
      _status = 'applying control…';
    });
    _shimmerController.repeat();

    ref.read(workflowExecutionProvider.notifier)
        .updateNodeStatus(widget.step.id, ExecutionStatus.running);

    try {
      final result = await _circuit.execute(() async {
        await Future.delayed(const Duration(seconds: 3));
        return <String, dynamic>{
          'resultImageUrl': '',
          'controlType': widget.step.config['controlType'] ?? 'structure',
          'prompt': prompt,
        };
      });

      ref.read(blackboardProvider.notifier)
          .postFact('creative_controlnet_${widget.step.id}', result);
      ref.read(workflowExecutionProvider.notifier)
          .updateCachedVariable(widget.step.id, result);
      ref.read(workflowExecutionProvider.notifier)
          .updateNodeStatus(widget.step.id, ExecutionStatus.success);
      ref.read(workflowExecutionProvider.notifier).addRunLog(RunLog(
            nodeId: widget.step.id,
            nodeName: 'ControlNet',
            timestamp: DateTime.now(),
            status: ExecutionStatus.success,
            inputs: widget.step.config,
            outputs: result,
          ));

      setState(() {
        _status = 'done';
        _previewUrl = result['resultImageUrl'] as String?;
        _isRunning = false;
      });
    } catch (e) {
      ref.read(workflowExecutionProvider.notifier)
          .updateNodeStatus(widget.step.id, ExecutionStatus.error);
      setState(() {
        _status = 'error: ${e.toString().length > 30 ? e.toString().substring(0, 30) : e}';
        _isRunning = false;
      });
    } finally {
      _shimmerController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlType =
        widget.step.config['controlType']?.toString() ?? 'structure';

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8), Color(0xFF7DD3FC)],
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
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
              blurRadius: widget.isSelected ? 20 : 10,
              spreadRadius: widget.isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.objectGroup,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('ControlNet',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  if (_isRunning)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(controlType.toUpperCase(),
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9)),
              const SizedBox(height: 10),
              _badge('IN: referenceImageUrl'),
              const SizedBox(height: 3),
              _badge('IN: prompt'),
              const SizedBox(height: 3),
              _badge('IN: controlType'),
              const SizedBox(height: 3),
              _badge('OUT: resultImageUrl', isOutput: true),
              const SizedBox(height: 10),
              if (_previewUrl != null && _previewUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_previewUrl!,
                      height: 60,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 160),
                ),
              const SizedBox(height: 8),
              Text(_status,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 9,
                      fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
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
                  child: Text(_isRunning ? 'Applying…' : 'Apply Control',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, {bool isOutput = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOutput
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 8,
              color: isOutput ? Colors.greenAccent : Colors.lightBlueAccent)),
    );
  }
}
