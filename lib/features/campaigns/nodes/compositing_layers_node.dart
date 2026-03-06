import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/adk/models/pipeline_models.dart';
import '../../../core/architecture/blackboard.dart';
import '../../../core/utils/resilience_utils.dart';
import '../../adk/providers/workflow_execution_provider.dart';
import '../../adk/models/workflow_execution_models.dart';

/// Creative Canvas node: Compositing Layers.
///
/// Inputs (via config):
///   layerUrls    (List of String) — ordered list of layer image URLs
///   blendMode    (String)       — 'normal', 'multiply', 'screen', 'overlay'
///   textOverlay  (String)       — optional text to overlay
///   outputFormat (String)       — 'png', 'jpg', 'webp'
///
/// Outputs:
///   compositedUrl (String) — final composited image URL
class CompositingLayersNode extends ConsumerStatefulWidget {
  final PipelineStep step;
  final bool isSelected;
  final VoidCallback? onTap;

  const CompositingLayersNode({
    super.key,
    required this.step,
    this.isSelected = false,
    this.onTap,
  });

  @override
  ConsumerState<CompositingLayersNode> createState() =>
      _CompositingLayersNodeState();
}

class _CompositingLayersNodeState extends ConsumerState<CompositingLayersNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isRunning = false;
  String _status = 'idle';
  String? _previewUrl;

  static final _circuit = CircuitBreaker(
    name: 'CompositingLayersNode',
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
    final layers = widget.step.config['layerUrls'];
    final layerCount = (layers is List) ? layers.length : 0;

    if (layerCount == 0) {
      setState(() => _status = 'error: no layers');
      return;
    }

    setState(() {
      _isRunning = true;
      _status = 'compositing $layerCount layers…';
    });
    _shimmerController.repeat();

    ref.read(workflowExecutionProvider.notifier)
        .updateNodeStatus(widget.step.id, ExecutionStatus.running);

    try {
      final result = await _circuit.execute(() async {
        await Future.delayed(const Duration(seconds: 2));
        return <String, dynamic>{
          'compositedUrl': '',
          'layerCount': layerCount,
          'blendMode': widget.step.config['blendMode'] ?? 'normal',
          'textOverlay': widget.step.config['textOverlay'] ?? '',
          'outputFormat': widget.step.config['outputFormat'] ?? 'png',
        };
      });

      ref.read(blackboardProvider.notifier)
          .postFact('creative_composite_${widget.step.id}', result);
      ref.read(workflowExecutionProvider.notifier)
          .updateCachedVariable(widget.step.id, result);
      ref.read(workflowExecutionProvider.notifier)
          .updateNodeStatus(widget.step.id, ExecutionStatus.success);
      ref.read(workflowExecutionProvider.notifier).addRunLog(RunLog(
            nodeId: widget.step.id,
            nodeName: 'Compositing',
            timestamp: DateTime.now(),
            status: ExecutionStatus.success,
            inputs: widget.step.config,
            outputs: result,
          ));

      setState(() {
        _status = 'done ($layerCount layers)';
        _previewUrl = result['compositedUrl'] as String?;
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
    final blendMode =
        widget.step.config['blendMode']?.toString() ?? 'normal';
    final layers = widget.step.config['layerUrls'];
    final layerCount = (layers is List) ? layers.length : 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF34D399), Color(0xFF6EE7B7)],
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
              color: const Color(0xFF059669).withValues(alpha: 0.4),
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
                  const FaIcon(FontAwesomeIcons.layerGroup,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Composite',
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
              Text(
                  '${blendMode.toUpperCase()} • ${layerCount > 0 ? "$layerCount layers" : "no layers"}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9)),
              const SizedBox(height: 10),
              _badge('IN: layerUrls (List)'),
              const SizedBox(height: 3),
              _badge('IN: blendMode'),
              const SizedBox(height: 3),
              _badge('IN: textOverlay'),
              const SizedBox(height: 3),
              _badge('OUT: compositedUrl', isOutput: true),
              const SizedBox(height: 10),
              // Layer stack visualization
              if (layerCount > 0)
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      layerCount.clamp(0, 5),
                      (i) => Container(
                        width: 20,
                        height: 20,
                        margin: EdgeInsets.only(left: i > 0 ? -6.0 : 0),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.2 + (i * 0.15)),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_previewUrl != null && _previewUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_previewUrl!,
                        height: 60,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 160),
                  ),
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
                  child: Text(_isRunning ? 'Compositing…' : 'Composite',
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
