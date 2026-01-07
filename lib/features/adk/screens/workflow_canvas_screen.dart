import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/adk/models/pipeline_models.dart';
import '../providers/pipeline_provider.dart';
import '../../chat/models/chat_models.dart';

class WorkflowCanvasScreen extends ConsumerStatefulWidget {
  final String? pipelineId; // Optional: Launch with existing pipeline

  const WorkflowCanvasScreen({super.key, this.pipelineId});

  @override
  ConsumerState<WorkflowCanvasScreen> createState() => _WorkflowCanvasScreenState();
}

class _WorkflowCanvasScreenState extends ConsumerState<WorkflowCanvasScreen> {
  late List<PipelineStep> _steps;
  Offset _offset = Offset.zero; // Pan offset
  final double _scale = 1.0; // Zoom level
  
  // Pipeline Metadata
  String _pipelineName = 'New Workflow';
  String _pipelineDescription = 'Created via Visual Canvas';

  // Selection
  String? _selectedStepId;

  // Connection Creation
  String? _connectingFromId;
  Offset? _mousePos;

  @override
  void initState() {
    super.initState();
    _loadPipeline();
  }

  void _loadPipeline() {
    if (widget.pipelineId != null) {
      final pipelines = ref.read(pipelineProvider);
      final match = pipelines.firstWhere((p) => p.id == widget.pipelineId, orElse: () => Pipeline(id: '', name: '', description: '', steps: []));
      if (match.id.isNotEmpty) {
        _pipelineName = match.name;
        _pipelineDescription = match.description;
        // Deep copy to ensure mutability
        _steps = match.steps.map((s) => PipelineStep(
          id: s.id,
          agentType: s.agentType,
          instruction: s.instruction,
          type: s.type,
          parallelSteps: s.parallelSteps,
          loopCondition: s.loopCondition,
          dependencies: List.from(s.dependencies), // Mutable copy
          uiPosition: s.uiPosition != null ? Map.from(s.uiPosition!) : null,
        )).toList();
      } else {
        _steps = [];
      }
    } else {
      _steps = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('Workflow Canvas', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _showSaveDialog,
          )
        ],
      ),
      body: Stack(
        children: [
          // Infinite Canvas
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _offset += details.delta;
              });
            },
            onTap: () {
              setState(() {
                _selectedStepId = null;
                _connectingFromId = null;
              });
            },
            child: MouseRegion(
              onHover: (details) {
                 _mousePos = details.localPosition;
                 if (_connectingFromId != null) setState(() {});
              },
              child: DragTarget<MessageSender>(
                onAcceptWithDetails: (details) {
                  final renderBox = context.findRenderObject() as RenderBox;
                  final localPos = renderBox.globalToLocal(details.offset);
                  
                  // Adjust for canvas offset/scale to get world coordinates
                  final worldPos = (localPos - _offset) / _scale; // Simple logic assuming scale=1 for now

                  _addNode(details.data, worldPos);
                },
                builder: (context, candidate, rejected) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: GridPainter(
                      offset: _offset, 
                      scale: _scale, 
                      steps: _steps, 
                      connectingFromId: _connectingFromId,
                      mousePos: _mousePos != null ? (_mousePos! - _offset) : null // Pass relative mouse pos
                    ),
                    child: Stack(
                      children: _steps.map((step) {
                        final pos = step.uiPosition != null 
                          ? Offset(step.uiPosition!['x']!, step.uiPosition!['y']!)
                          : const Offset(100, 100);
                        
                        return Positioned(
                          left: pos.dx + _offset.dx,
                          top: pos.dy + _offset.dy,
                          child: _buildNode(step),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Toolbar (Left)
          Positioned(
            left: 16,
            top: 16,
            bottom: 16,
            width: 70,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTool(FontAwesomeIcons.magnifyingGlass, "Research", MessageSender.researchAgent),
                  const SizedBox(height: 24),
                  _buildTool(FontAwesomeIcons.paintbrush, "Creative", MessageSender.creativeAgent),
                  const SizedBox(height: 24),
                  _buildTool(FontAwesomeIcons.penNib, "Copy", MessageSender.copywriterAgent),
                  const SizedBox(height: 24),
                  _buildTool(FontAwesomeIcons.code, "Code", MessageSender.developerAgent),
                   const SizedBox(height: 24),
                  _buildTool(FontAwesomeIcons.shieldHalved, "Security", MessageSender.securityAgent),
                ],
              ),
            ),
          ),

          // Properties Panel (Right - Only if selected)
          if (_selectedStepId != null)
            Positioned(
              right: 16,
              top: 16,
              bottom: 16,
              width: 250,
              child: _buildPropertiesPanel(),
            ),
        ],
      ),
    );
  }

  void _addNode(MessageSender agent, Offset pos) {
    setState(() {
      _steps.add(PipelineStep(
        id: const Uuid().v4(),
        agentType: agent,
        instruction: '',
        uiPosition: {'x': pos.dx, 'y': pos.dy},
        dependencies: [], // Mutable list
      ));
    });
  }

  Widget _buildTool(IconData icon, String label, MessageSender agent) {
    return Tooltip(
      message: label,
      child: Draggable<MessageSender>(
        data: agent,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(50)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildNode(PipelineStep step) {
    final isSelected = _selectedStepId == step.id;

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // Update position relative to World
          final currentX = step.uiPosition!['x']!;
          final currentY = step.uiPosition!['y']!;
          step.uiPosition!['x'] = currentX + details.delta.dx;
          step.uiPosition!['y'] = currentY + details.delta.dy;
        });
      },
      onTap: () {
        setState(() {
          _selectedStepId = step.id;
          // Loop connection logic?
          if (_connectingFromId != null && _connectingFromId != step.id) {
             // Create connection
             if (!step.dependencies.contains(_connectingFromId)) {
                step.dependencies.add(_connectingFromId!);
             }
             _connectingFromId = null;
          }
        });
      },
      child: Container(
        width: 160,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1
          ),
          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Header
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(_getIconForAgent(step.agentType), size: 12, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(step.agentType.name.toUpperCase().replaceAll('AGENT', ''), 
                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Connection Point
                  GestureDetector(
                    onTap: () {
                       setState(() {
                         _connectingFromId = step.id;
                       });
                    },
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: _connectingFromId == step.id ? Colors.greenAccent : Colors.white24,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black)
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  step.instruction.isEmpty ? "No instructions..." : step.instruction, 
                  maxLines: 3, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 10)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveDialog() {
    final nameController = TextEditingController(text: _pipelineName);
    final descController = TextEditingController(text: _pipelineDescription);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Save Workflow', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Workflow Name',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final newPipeline = Pipeline(
                id: widget.pipelineId ?? const Uuid().v4(),
                name: nameController.text,
                description: descController.text,
                steps: _steps,
              );
              ref.read(pipelineProvider.notifier).savePipeline(newPipeline);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Workflow "${newPipeline.name}" saved!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    final step = _steps.firstWhere((s) => s.id == _selectedStepId);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit Step', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          const Text('Instruction:', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: step.instruction)..selection = TextSelection.collapsed(offset: step.instruction.length),
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (val) {
               setState(() {
                  // Direct mutation for prototype - in prod use immutable copy
                  // But PipelineStep fields are final... need to replace object in list
                  final index = _steps.indexWhere((s) => s.id == step.id);
                  if (index != -1) {
                    _steps[index] = PipelineStep(
                       id: step.id,
                       agentType: step.agentType,
                       instruction: val,
                       type: step.type,
                       dependencies: step.dependencies,
                       uiPosition: step.uiPosition,
                    );
                  }
               });
            },
            decoration: InputDecoration(
               filled: true,
               fillColor: Colors.black,
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
             icon: const Icon(Icons.delete, size: 16),
             label: const Text('Delete Step'),
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
               foregroundColor: Colors.redAccent,
             ),
             onPressed: () {
                setState(() {
                   _steps.removeWhere((s) => s.id == step.id);
                   // Also remove dependencies pointing to this
                   for (var s in _steps) {
                      s.dependencies.remove(step.id);
                   }
                   _selectedStepId = null;
                });
             },
          )
        ],
      ),
    );
  }

    IconData _getIconForAgent(MessageSender agent) {
    switch (agent) {
      case MessageSender.researchAgent: return FontAwesomeIcons.magnifyingGlass;
      case MessageSender.creativeAgent: return FontAwesomeIcons.paintbrush;
      case MessageSender.copywriterAgent: return FontAwesomeIcons.penNib;
      case MessageSender.developerAgent: return FontAwesomeIcons.code;
      case MessageSender.securityAgent: return FontAwesomeIcons.shieldHalved;
      default: return FontAwesomeIcons.robot;
    }
  }
}

class GridPainter extends CustomPainter {
  final Offset offset;
  final double scale;
  final List<PipelineStep> steps;
  final String? connectingFromId;
  final Offset? mousePos; // Relative to grid origin (0,0) of canvas content? No, passed as relative to transform

  GridPainter({required this.offset, required this.scale, required this.steps, this.connectingFromId, this.mousePos});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const gridSize = 40.0;
    
    // Draw Grid
    for (double x = offset.dx % gridSize; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = offset.dy % gridSize; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw Connections
    final connectionPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final step in steps) {
       final toPos = Offset(step.uiPosition!['x']! + offset.dx + 80, step.uiPosition!['y']! + offset.dy + 45); // Centerish

       for (final depId in step.dependencies) {
          final parent = steps.firstWhere((s) => s.id == depId, orElse: () => PipelineStep(id: 'null', agentType: MessageSender.user));
          if (parent.id != 'null' && parent.uiPosition != null) {
              final fromPos = Offset(parent.uiPosition!['x']! + offset.dx + 80, parent.uiPosition!['y']! + offset.dy + 45);
              _drawCurve(canvas, fromPos, toPos, connectionPaint);
          }
       }
    }

    // Draw Active Dragging Line
    if (connectingFromId != null && mousePos != null) {
       final parent = steps.firstWhere((s) => s.id == connectingFromId);
       final fromPos = Offset(parent.uiPosition!['x']! + offset.dx + 80, parent.uiPosition!['y']! + offset.dy + 45);
       
       // mousePos is relative to widget top-left. offset is handled? 
       // In CustomPaint child of GestureDetector:
       // If I passed mousePos - offset in builder, then here I can use it directly? 
       // Let's assume mousePos passed is already corrected or raw relative to widget.
       // Actually simpler: mousePos passed is (details.localPosition - offset)? 
       // Let's use raw localPosition from mouse region and add offset? 
       // wait, we want screen coords.
       final activePaint = Paint()..color = Colors.greenAccent..style = PaintingStyle.stroke..strokeWidth = 2;
       canvas.drawLine(fromPos, mousePos! + offset, activePaint);
    }
  }

  void _drawCurve(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final path = Path();
    path.moveTo(p1.dx, p1.dy);
    
    final dx = p2.dx - p1.dx;
    final controlPoint1 = Offset(p1.dx + dx / 2, p1.dy);
    final controlPoint2 = Offset(p2.dx - dx / 2, p2.dy);

    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p2.dx, p2.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return true; // Simple refresh
  }
}
