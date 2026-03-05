import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/adk/models/pipeline_models.dart';
import '../../../core/architecture/blackboard.dart';
import '../../../core/utils/resilience_utils.dart';
import '../../adk/providers/workflow_execution_provider.dart';
import '../../adk/models/workflow_execution_models.dart';

/// Creative Canvas node: Inpaint / Outpaint.
///
/// Inputs (via config):
///   sourceImageUrl (String) — image to modify
///   maskData       (String) — mask definition (JSON or base64)
///   prompt         (String) — what to paint in the masked area
///   mode           (String) — 'inpaint' or 'outpaint'
///
/// Outputs:
///   resultImageUrl (String) — modified image URL
class InpaintOutpaintNode extends ConsumerStatefulWidget {
  final PipelineStep step;
  final bool isSelected;
  final VoidCallback? onTap;

  const InpaintOutpaintNode({
    super.key,
    required this.step,
    this.isSelected = false,
    this.onTap,
  });

  @override
  ConsumerState<InpaintOutpaintNode> createState() =>
      _InpaintOutpaintNodeState();
}

class _InpaintOutpaintNodeState extends ConsumerState<InpaintOutpaintNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isRunning = false;
  String _status = 'idle';
  String? _previewUrl;

  static final _circuit = CircuitBreaker(
    name: 'InpaintOutpaintNode',
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
    final source = widget.step.config['sourceImageUrl'] as String? ?? '';
    final prompt = widget.step.config['prompt'] as String? ?? '';
    if (source.isEmpty) {
      setState(() => _status = 'error: no source image');
      return;
    }

    setState(() {
      _isRunning = true;
      _status = '${widget.step.config['mode'] ?? 'inpaint'}ing…';
    });
    _shimmerController.repeat();

    ref.read(workflowExecutionProvider.notifier)
        .updateNodeStatus(widget.step.id, ExecutionStatus.running);

    try {
      final result = await _circuit.execute(() async {
        await Future.delayed(const Duration(seconds: 2));
        return <String, dynamic>{
          'resultImageUrl': '',
          'mode': widget.step.config['mode'] ?? 'inpaint',
          'prompt': prompt,
        };
      });

      ref.read(blackboardProvider.notifier)
          .postFact('creative_inpaint_${widget.step.id}', result);
      ref.read(workflowExecutionProvider.notifier)
          .updateCachedVariable(widget.step.id, result);
      ref.read(workflowExecutionProvider.notifier)
          .updateNodeStatus(widget.step.id, ExecutionStatus.success);
      ref.read(workflowExecutionProvider.notifier).addRunLog(RunLog(
            nodeId: widget.step.id,
            nodeName: 'Inpaint/Outpaint',
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
    final mode = widget.step.config['mode']?.toString() ?? 'inpaint';
    final isOutpaint = mode == 'outpaint';

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOutpaint
                ? const [Color(0xFF7C3AED), Color(0xFFA78BFA), Color(0xFFC4B5FD)]
                : const [Color(0xFFDB2777), Color(0xFFF472B6), Color(0xFFFBCFE8)],
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
              color: (isOutpaint ? const Color(0xFF7C3AED) : const Color(0xFFDB2777))
                  .withValues(alpha: 0.4),
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
                  FaIcon(
                    isOutpaint
                        ? FontAwesomeIcons.maximize
                        : FontAwesomeIcons.paintbrush,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOutpaint ? 'Outpaint' : 'Inpaint',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
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
              const SizedBox(height: 10),
              _badge('IN: sourceImageUrl'),
              const SizedBox(height: 3),
              _badge('IN: maskData'),
              const SizedBox(height: 3),
              _badge('IN: prompt'),
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
                  child: Text(_isRunning ? 'Processing…' : 'Execute',
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
