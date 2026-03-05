import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/adk/models/pipeline_models.dart';
import '../../../core/architecture/blackboard.dart';
import '../../../core/utils/resilience_utils.dart';
import '../../adk/providers/workflow_execution_provider.dart';
import '../../adk/models/workflow_execution_models.dart';

/// Creative Canvas node: Product Relighting.
///
/// Inputs (via config):
///   productImageUrl  (String) — product photo to relight
///   lightingPreset   (String) — 'studio', 'natural', 'dramatic', 'neon'
///   environmentHDRI  (String) — optional HDRI environment URL
///
/// Outputs:
///   relitImageUrl    (String) — relit product image URL
class RelightProductNode extends ConsumerStatefulWidget {
  final PipelineStep step;
  final bool isSelected;
  final VoidCallback? onTap;

  const RelightProductNode({
    super.key,
    required this.step,
    this.isSelected = false,
    this.onTap,
  });

  @override
  ConsumerState<RelightProductNode> createState() =>
      _RelightProductNodeState();
}

class _RelightProductNodeState extends ConsumerState<RelightProductNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isRunning = false;
  String _status = 'idle';
  String? _previewUrl;

  static final _circuit = CircuitBreaker(
    name: 'RelightProductNode',
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
    final productImage =
        widget.step.config['productImageUrl'] as String? ?? '';
    if (productImage.isEmpty) {
      setState(() => _status = 'error: no product image');
      return;
    }

    final preset = widget.step.config['lightingPreset'] as String? ?? 'studio';
    setState(() {
      _isRunning = true;
      _status = 'relighting ($preset)…';
    });
    _shimmerController.repeat();

    ref.read(workflowExecutionProvider.notifier)
        .updateNodeStatus(widget.step.id, ExecutionStatus.running);

    try {
      final result = await _circuit.execute(() async {
        await Future.delayed(const Duration(seconds: 3));
        return <String, dynamic>{
          'relitImageUrl': '',
          'lightingPreset': preset,
          'environmentHDRI': widget.step.config['environmentHDRI'] ?? '',
        };
      });

      ref.read(blackboardProvider.notifier)
          .postFact('creative_relight_${widget.step.id}', result);
      ref.read(workflowExecutionProvider.notifier)
          .updateCachedVariable(widget.step.id, result);
      ref.read(workflowExecutionProvider.notifier)
          .updateNodeStatus(widget.step.id, ExecutionStatus.success);
      ref.read(workflowExecutionProvider.notifier).addRunLog(RunLog(
            nodeId: widget.step.id,
            nodeName: 'Relight Product',
            timestamp: DateTime.now(),
            status: ExecutionStatus.success,
            inputs: widget.step.config,
            outputs: result,
          ));

      setState(() {
        _status = 'done';
        _previewUrl = result['relitImageUrl'] as String?;
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

  IconData _presetIcon(String preset) {
    switch (preset) {
      case 'studio':
        return FontAwesomeIcons.lightbulb;
      case 'natural':
        return FontAwesomeIcons.sun;
      case 'dramatic':
        return FontAwesomeIcons.bolt;
      case 'neon':
        return FontAwesomeIcons.star;
      default:
        return FontAwesomeIcons.lightbulb;
    }
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.step.config['lightingPreset']?.toString() ?? 'studio';

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEA580C), Color(0xFFF97316), Color(0xFFFBBF24)],
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
              color: const Color(0xFFEA580C).withValues(alpha: 0.4),
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
                  FaIcon(_presetIcon(preset),
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Relight',
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
              Text(preset.toUpperCase(),
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9)),
              const SizedBox(height: 10),
              _badge('IN: productImageUrl'),
              const SizedBox(height: 3),
              _badge('IN: lightingPreset'),
              const SizedBox(height: 3),
              _badge('OUT: relitImageUrl', isOutput: true),
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
                  child: Text(_isRunning ? 'Relighting…' : 'Relight',
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
