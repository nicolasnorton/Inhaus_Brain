import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/adk/models/pipeline_models.dart';
import '../../../core/architecture/blackboard.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/services/figma_service.dart';
import '../../../core/utils/resilience_utils.dart';
import '../../adk/providers/workflow_execution_provider.dart';
import '../../adk/models/workflow_execution_models.dart';

/// Creative Canvas node: Figma Import/Export.
///
/// Bidirectional synchronization with Figma:
/// - **Import mode**: Pulls Figma file JSON + rendered images, making them
///   available as upstream inputs for other creative nodes.
/// - **Export mode**: Posts canvas output images as Figma comments
///   with attached render URLs.
///
/// Inputs (via config):
///   figmaFileKey  (String) — Figma file key from URL
///   nodeIds       (String, optional) — comma-separated node IDs for targeted export
///   direction     (String) — 'import' or 'export'
///   exportFormat  (String) — 'png', 'svg', 'pdf' (default: 'png')
///   figmaToken    (String) — Figma PAT (from user secrets)
///
/// Outputs:
///   designJson       (Map)    — file structure (import mode)
///   exportedUrls     (List)   — exported image URLs (import mode)
///   componentsList   (List)   — file components (import mode)
///   commentPosted    (bool)   — success flag (export mode)
class FigmaSyncNode extends ConsumerStatefulWidget {
  final PipelineStep step;
  final bool isSelected;
  final VoidCallback? onTap;

  const FigmaSyncNode({
    super.key,
    required this.step,
    this.isSelected = false,
    this.onTap,
  });

  @override
  ConsumerState<FigmaSyncNode> createState() => _FigmaSyncNodeState();
}

class _FigmaSyncNodeState extends ConsumerState<FigmaSyncNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isRunning = false;
  String _status = 'idle';
  int _exportedCount = 0;

  static final _circuit = CircuitBreaker(
    name: 'FigmaSyncNode',
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
    final fileKey = widget.step.config['figmaFileKey'] as String? ?? '';
    final token = widget.step.config['figmaToken'] as String? ?? '';

    if (fileKey.isEmpty || token.isEmpty) {
      setState(() => _status = 'error: no file key or token');
      return;
    }

    if (!FeatureFlags.enableFigmaIntegration) {
      setState(() => _status = 'Figma integration disabled');
      return;
    }

    final direction =
        widget.step.config['direction'] as String? ?? 'import';
    final isImport = direction == 'import';

    setState(() {
      _isRunning = true;
      _status = isImport ? 'importing from Figma…' : 'exporting to Figma…';
    });
    _shimmerController.repeat();

    ref.read(workflowExecutionProvider.notifier)
        .updateNodeStatus(widget.step.id, ExecutionStatus.running);

    try {
      final figma = ref.read(figmaServiceProvider);

      if (isImport) {
        final result = await _circuit.execute(() async {
          // Step 1: Get file structure
          setState(() => _status = 'fetching file structure…');
          final file = await figma.getFile(fileKey, token: token);

          // Step 2: Export node images if specific nodes requested
          List<String> exportedUrls = [];
          final nodeIdsStr =
              widget.step.config['nodeIds'] as String? ?? '';
          if (nodeIdsStr.isNotEmpty) {
            setState(() => _status = 'exporting node images…');
            final nodeIds =
                nodeIdsStr.split(',').map((s) => s.trim()).toList();
            exportedUrls = await figma.exportNodes(
              fileKey,
              nodeIds,
              format:
                  widget.step.config['exportFormat'] as String? ?? 'png',
              token: token,
            );
          }

          return <String, dynamic>{
            'designJson': file.toJson(),
            'exportedUrls': exportedUrls,
            'componentsList': file.styles.keys.toList(),
            'fileName': file.name,
          };
        });

        _exportedCount =
            (result['exportedUrls'] as List?)?.length ?? 0;

        ref.read(blackboardProvider.notifier)
            .postFact('figma_import_${widget.step.id}', result);
        ref.read(workflowExecutionProvider.notifier)
            .updateCachedVariable(widget.step.id, result);
        ref.read(workflowExecutionProvider.notifier)
            .updateNodeStatus(widget.step.id, ExecutionStatus.success);
        ref.read(workflowExecutionProvider.notifier).addRunLog(RunLog(
              nodeId: widget.step.id,
              nodeName: 'Figma Import',
              timestamp: DateTime.now(),
              status: ExecutionStatus.success,
              inputs: widget.step.config,
              outputs: result,
            ));

        setState(() {
          _status =
              'imported "${result['fileName']}" ($_exportedCount images)';
          _isRunning = false;
        });
      } else {
        // Export mode — post comment with upstream outputs
        final result = await _circuit.execute(() async {
          final message = widget.step.config['exportMessage'] as String? ??
              'Creative Canvas output attached.';
          final imageUrl =
              widget.step.config['exportImageUrl'] as String?;

          await figma.postComment(
            fileKey,
            message,
            imageUrl: imageUrl,
            token: token,
          );

          return <String, dynamic>{
            'commentPosted': true,
            'fileKey': fileKey,
          };
        });

        ref.read(blackboardProvider.notifier)
            .postFact('figma_export_${widget.step.id}', result);
        ref.read(workflowExecutionProvider.notifier)
            .updateCachedVariable(widget.step.id, result);
        ref.read(workflowExecutionProvider.notifier)
            .updateNodeStatus(widget.step.id, ExecutionStatus.success);
        ref.read(workflowExecutionProvider.notifier).addRunLog(RunLog(
              nodeId: widget.step.id,
              nodeName: 'Figma Export',
              timestamp: DateTime.now(),
              status: ExecutionStatus.success,
              inputs: widget.step.config,
              outputs: result,
            ));

        setState(() {
          _status = 'comment posted to Figma';
          _isRunning = false;
        });
      }
    } catch (e) {
      ref.read(workflowExecutionProvider.notifier)
          .updateNodeStatus(widget.step.id, ExecutionStatus.error);
      setState(() {
        _status =
            'error: ${e.toString().length > 40 ? e.toString().substring(0, 40) : e}';
        _isRunning = false;
      });
    } finally {
      _shimmerController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final direction =
        widget.step.config['direction']?.toString() ?? 'import';
    final isImport = direction == 'import';

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 210,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isImport
                ? const [
                    Color(0xFF0ACF83),
                    Color(0xFF1ABCFE),
                    Color(0xFFA259FF)
                  ]
                : const [
                    Color(0xFFF24E1E),
                    Color(0xFFFF7262),
                    Color(0xFFA259FF)
                  ],
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
              color: (isImport
                      ? const Color(0xFF0ACF83)
                      : const Color(0xFFF24E1E))
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
                  const FaIcon(FontAwesomeIcons.figma,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isImport ? 'Figma Import' : 'Figma Export',
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
              const SizedBox(height: 4),
              Text(
                isImport ? 'PULL FROM FIGMA' : 'PUSH TO FIGMA',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9),
              ),
              const SizedBox(height: 10),
              _badge('IN: figmaFileKey'),
              const SizedBox(height: 3),
              _badge('IN: figmaToken'),
              const SizedBox(height: 3),
              if (isImport) ...[
                _badge('OUT: designJson', isOutput: true),
                const SizedBox(height: 3),
                _badge('OUT: exportedUrls', isOutput: true),
              ] else ...[
                _badge('IN: exportImageUrl'),
                const SizedBox(height: 3),
                _badge('OUT: commentPosted', isOutput: true),
              ],
              const SizedBox(height: 10),
              if (_exportedCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_exportedCount images exported',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10),
                  ),
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
                  child: Text(
                    _isRunning
                        ? (isImport ? 'Importing…' : 'Exporting…')
                        : (isImport ? 'Import' : 'Export'),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
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
