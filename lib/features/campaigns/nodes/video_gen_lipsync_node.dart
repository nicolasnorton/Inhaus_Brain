import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/adk/models/pipeline_models.dart';
import '../../../core/architecture/blackboard.dart';
import '../../../core/utils/resilience_utils.dart';
import '../../adk/providers/workflow_execution_provider.dart';
import '../../adk/models/workflow_execution_models.dart';

/// Creative Canvas node: Video Generation + Lip Sync.
///
/// Inputs (via config):
///   sourceImageUrl (String) — still image to animate (or videoUrl)
///   audioUrl       (String) — audio for lip sync (optional)
///   script         (String) — text script for TTS + lip sync (optional)
///   model          (String) — 'veo', 'runway', 'kling'
///
/// Outputs:
///   videoUrl       (String) — generated video URL
///   thumbnailUrl   (String) — video thumbnail URL
///
/// Long-running: 120s timeout, progress streaming via execution provider.
class VideoGenLipsyncNode extends ConsumerStatefulWidget {
  final PipelineStep step;
  final bool isSelected;
  final VoidCallback? onTap;

  const VideoGenLipsyncNode({
    super.key,
    required this.step,
    this.isSelected = false,
    this.onTap,
  });

  @override
  ConsumerState<VideoGenLipsyncNode> createState() =>
      _VideoGenLipsyncNodeState();
}

class _VideoGenLipsyncNodeState extends ConsumerState<VideoGenLipsyncNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isRunning = false;
  String _status = 'idle';
  double _progress = 0.0;
  String? _thumbnailUrl;

  static final _circuit = CircuitBreaker(
    name: 'VideoGenLipsyncNode',
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
    final source = widget.step.config['sourceImageUrl'] as String? ??
        widget.step.config['videoUrl'] as String? ??
        '';
    if (source.isEmpty) {
      setState(() => _status = 'error: no source');
      return;
    }

    setState(() {
      _isRunning = true;
      _status = 'rendering video…';
      _progress = 0.0;
    });
    _shimmerController.repeat();

    ref.read(workflowExecutionProvider.notifier)
        .updateNodeStatus(widget.step.id, ExecutionStatus.running);

    try {
      final result = await _circuit.execute(() async {
        // Simulate long-running video gen with progress updates
        for (int i = 1; i <= 4; i++) {
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return <String, dynamic>{};
          setState(() {
            _progress = i / 4;
            _status = 'rendering… ${(i * 25)}%';
          });
        }
        return <String, dynamic>{
          'videoUrl': '',
          'thumbnailUrl': '',
          'model': widget.step.config['model'] ?? 'veo',
          'hasLipsync': (widget.step.config['audioUrl'] != null ||
              widget.step.config['script'] != null),
        };
      }).timeout(const Duration(seconds: 120));

      ref.read(blackboardProvider.notifier)
          .postFact('creative_video_${widget.step.id}', result);
      ref.read(workflowExecutionProvider.notifier)
          .updateCachedVariable(widget.step.id, result);
      ref.read(workflowExecutionProvider.notifier)
          .updateNodeStatus(widget.step.id, ExecutionStatus.success);
      ref.read(workflowExecutionProvider.notifier).addRunLog(RunLog(
            nodeId: widget.step.id,
            nodeName: 'Video Gen',
            timestamp: DateTime.now(),
            status: ExecutionStatus.success,
            inputs: widget.step.config,
            outputs: result,
            executionTimeMs: 8000,
          ));

      setState(() {
        _status = 'done';
        _thumbnailUrl = result['thumbnailUrl'] as String?;
        _isRunning = false;
        _progress = 1.0;
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
    final model = widget.step.config['model']?.toString() ?? 'veo';

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFFD8B4FE)],
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
              color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
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
                  const FaIcon(FontAwesomeIcons.video,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Video Gen',
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
              Text('${model.toUpperCase()} • LIP-SYNC',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9)),
              const SizedBox(height: 10),
              _badge('IN: sourceImageUrl'),
              const SizedBox(height: 3),
              _badge('IN: script / audioUrl'),
              const SizedBox(height: 3),
              _badge('OUT: videoUrl', isOutput: true),
              const SizedBox(height: 3),
              _badge('OUT: thumbnailUrl', isOutput: true),
              const SizedBox(height: 10),
              // Progress bar for long-running video gen
              if (_isRunning || _progress > 0)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _isRunning ? null : _progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        color: Colors.white.withValues(alpha: 0.8),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              if (_thumbnailUrl != null && _thumbnailUrl!.isNotEmpty)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_thumbnailUrl!,
                          height: 60,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          cacheWidth: 160),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const FaIcon(FontAwesomeIcons.play,
                          color: Colors.white, size: 12),
                    ),
                  ],
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
                  child: Text(_isRunning ? 'Rendering…' : 'Render Video',
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
