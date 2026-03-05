import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/adk/models/pipeline_models.dart';
import '../../../core/architecture/blackboard.dart';
import '../../../core/utils/resilience_utils.dart';
import '../../../core/services/stitch_service.dart';
import '../../../core/config/feature_flags.dart';
import '../../adk/providers/workflow_execution_provider.dart';
import '../../adk/models/workflow_execution_models.dart';

/// Creative Canvas node: Google Stitch UI Design.
///
/// Wraps the existing StitchService to generate screen designs from prompts,
/// extract design context (tokens, components), and create Stitch projects
/// — all from within the canvas.
///
/// Inputs (via config):
///   projectId (String, optional) — existing Stitch project ID; auto-creates if blank
///   prompt    (String)           — design generation prompt
///   screenId  (String, optional) — refine an existing screen
///
/// Outputs (posted to Blackboard):
///   screenId      (String) — generated screen ID
///   imageUrl      (String) — preview image URL
///   designContext (Map)    — extracted styles/components
class StitchDesignNode extends ConsumerStatefulWidget {
  final PipelineStep step;
  final bool isSelected;
  final VoidCallback? onTap;

  const StitchDesignNode({
    super.key,
    required this.step,
    this.isSelected = false,
    this.onTap,
  });

  @override
  ConsumerState<StitchDesignNode> createState() => _StitchDesignNodeState();
}

class _StitchDesignNodeState extends ConsumerState<StitchDesignNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isRunning = false;
  String _status = 'idle';
  String? _previewUrl;

  static final _circuit = CircuitBreaker(
    name: 'StitchDesignNode',
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
    final prompt = widget.step.config['prompt'] as String? ?? '';
    if (prompt.isEmpty) {
      setState(() => _status = 'error: no prompt');
      return;
    }

    // Check Stitch feature flag
    if (!FeatureFlags.enableStitch) {
      setState(() => _status = 'Stitch disabled');
      return;
    }

    setState(() {
      _isRunning = true;
      _status = 'creating design…';
    });
    _shimmerController.repeat();

    ref.read(workflowExecutionProvider.notifier)
        .updateNodeStatus(widget.step.id, ExecutionStatus.running);

    try {
      final stitch = ref.read(stitchServiceProvider);

      final result = await _circuit.execute(() async {
        // Step 1: Create project if no projectId
        var projectId = widget.step.config['projectId'] as String? ?? '';
        if (projectId.isEmpty) {
          setState(() => _status = 'creating project…');
          final project = await stitch.createProject(
            name: 'Campaign Canvas ${DateTime.now().millisecondsSinceEpoch}',
            description: 'Auto-created by Creative Campaign Canvas',
          );
          projectId = project.id;
        }

        // Step 2: Generate screen
        setState(() => _status = 'generating screen…');
        final screenId = widget.step.config['screenId'] as String?;
        final screen = await stitch.generateScreen(
          projectId: projectId,
          prompt: prompt,
          screenId: screenId,
        );

        // Step 3: Extract design context
        setState(() => _status = 'extracting design tokens…');
        final designCtx = await stitch.extractDesignContext(
          projectId: projectId,
          screenId: screen.id,
        );

        return <String, dynamic>{
          'projectId': projectId,
          'screenId': screen.id,
          'imageUrl': screen.imageUrl ?? '',
          'designContext': {
            'styles': designCtx.styles,
            'components': designCtx.components,
          },
        };
      });

      // Post to Blackboard for downstream nodes
      ref.read(blackboardProvider.notifier)
          .postFact('creative_stitch_${widget.step.id}', result);
      ref.read(blackboardProvider.notifier)
          .postFact('stitch_design_context', result['designContext']);
      ref.read(workflowExecutionProvider.notifier)
          .updateCachedVariable(widget.step.id, result);
      ref.read(workflowExecutionProvider.notifier)
          .updateNodeStatus(widget.step.id, ExecutionStatus.success);
      ref.read(workflowExecutionProvider.notifier).addRunLog(RunLog(
            nodeId: widget.step.id,
            nodeName: 'Stitch Design',
            timestamp: DateTime.now(),
            status: ExecutionStatus.success,
            inputs: widget.step.config,
            outputs: result,
          ));

      setState(() {
        _status = 'done';
        _previewUrl = result['imageUrl'] as String?;
        _isRunning = false;
      });
    } catch (e) {
      ref.read(workflowExecutionProvider.notifier)
          .updateNodeStatus(widget.step.id, ExecutionStatus.error);
      setState(() {
        _status = 'error: ${e.toString().length > 40 ? e.toString().substring(0, 40) : e}';
        _isRunning = false;
      });
    } finally {
      _shimmerController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 210,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF4285F4), Color(0xFF8AB4F8)],
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
              color: const Color(0xFF1A73E8).withValues(alpha: 0.4),
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
              // Header
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.google,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Stitch Design',
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
              Text('Google Stitch',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9)),
              const SizedBox(height: 10),
              _badge('IN: prompt (String)'),
              const SizedBox(height: 3),
              _badge('IN: projectId (opt)'),
              const SizedBox(height: 3),
              _badge('OUT: screenId', isOutput: true),
              const SizedBox(height: 3),
              _badge('OUT: imageUrl', isOutput: true),
              const SizedBox(height: 3),
              _badge('OUT: designContext', isOutput: true),
              const SizedBox(height: 10),
              // Preview
              if (_previewUrl != null && _previewUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_previewUrl!,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 200),
                ),
              const SizedBox(height: 8),
              Text(_status,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 9,
                      fontStyle: FontStyle.italic),
                  maxLines: 2,
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
                  child: Text(_isRunning ? 'Designing…' : 'Generate Design',
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
