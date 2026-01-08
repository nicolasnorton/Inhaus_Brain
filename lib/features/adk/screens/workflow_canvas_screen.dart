import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:inhaus_brain/features/adk/widgets/node_configuration_sheet.dart';
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
        // Deep copy using copyWith
        _steps = match.steps.map((s) => s.copyWith(
          dependencies: List.from(s.dependencies),
          uiPosition: s.uiPosition != null ? Map<String, double>.from(s.uiPosition!) : null,
          config: Map<String, dynamic>.from(s.config),
          inputMappings: Map<String, String>.from(s.inputMappings),
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
              child: DragTarget<WorkflowNodeType>(
                onAcceptWithDetails: (details) {
                  final renderBox = context.findRenderObject() as RenderBox;
                  final localPos = renderBox.globalToLocal(details.offset);
                  
                  // Adjust for canvas offset/scale to get world coordinates
                  final worldPos = (localPos - _offset) / _scale;

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
                      mousePos: _mousePos != null ? (_mousePos! - _offset) : null 
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
            width: 80,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      _buildCategoryHeader("INPUTS"),
                      _buildTool(FontAwesomeIcons.keyboard, "User Input", WorkflowNodeType.userInput),
                      _buildTool(FontAwesomeIcons.bolt, "Trigger", WorkflowNodeType.trigger),
                      _buildTool(FontAwesomeIcons.fileArrowUp, "Doc Extractor", WorkflowNodeType.documentExtractor),
                      const Divider(color: Colors.white10, height: 32),
                      
                      _buildCategoryHeader("BRAIN"),
                      _buildTool(FontAwesomeIcons.brain, "LLM", WorkflowNodeType.llm),
                      _buildTool(FontAwesomeIcons.robot, "Agent", WorkflowNodeType.agent),
                      const Divider(color: Colors.white10, height: 32),
                      
                      _buildCategoryHeader("LOGIC"),
                      _buildTool(FontAwesomeIcons.codeBranch, "If-Else", WorkflowNodeType.ifElse),
                      _buildTool(FontAwesomeIcons.arrowsSpin, "Loop", WorkflowNodeType.loop),
                      _buildTool(FontAwesomeIcons.listCheck, "Iteration", WorkflowNodeType.iteration),
                      _buildTool(FontAwesomeIcons.filter, "Classifier", WorkflowNodeType.questionClassifier),
                      _buildTool(FontAwesomeIcons.code, "Code", WorkflowNodeType.code),
                      const Divider(color: Colors.white10, height: 32),
                      
                      _buildCategoryHeader("TOOLS"),
                      _buildTool(FontAwesomeIcons.globe, "HTTP Req", WorkflowNodeType.httpRequest),
                      _buildTool(FontAwesomeIcons.toolbox, "Tool", WorkflowNodeType.tool),
                      _buildTool(FontAwesomeIcons.database, "Knowledge", WorkflowNodeType.knowledgeRetrieval),
                      const Divider(color: Colors.white10, height: 32),
                      
                      _buildCategoryHeader("OUTPUT"),
                      _buildTool(FontAwesomeIcons.commentDots, "Answer", WorkflowNodeType.answer),
                      _buildTool(FontAwesomeIcons.rightFromBracket, "Exit", WorkflowNodeType.output),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_selectedStepId != null)
            Positioned(
              right: 16,
              top: 16,
              bottom: 16,
              width: 400,
              child: _buildPropertiesPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  void _addNode(WorkflowNodeType type, Offset pos) {
    setState(() {
      _steps.add(PipelineStep(
        id: const Uuid().v4(),
        nodeType: type,
        agentType: type == WorkflowNodeType.agent ? MessageSender.researchAgent : null,
        instruction: '',
        uiPosition: {'x': pos.dx, 'y': pos.dy},
        dependencies: [],
        config: {},
      ));
    });
  }

  Widget _buildTool(IconData icon, String label, WorkflowNodeType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Tooltip(
        message: label,
        child: Draggable<WorkflowNodeType>(
          data: type,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getNodeColor(type).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
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
                  Icon(_getNodeIcon(step.nodeType), size: 12, color: _getNodeColor(step.nodeType)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.nodeType == WorkflowNodeType.agent && step.agentType != null
                        ? step.agentType!.name.toUpperCase().replaceAll('AGENT', '')
                        : step.nodeType.name.toUpperCase(), 
                      style: TextStyle(color: _getNodeColor(step.nodeType), fontWeight: FontWeight.bold, fontSize: 10),
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
                  step.instruction.isEmpty ? "Config: ${step.config.keys.length} params" : step.instruction, 
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
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: NodeConfigurationSheet(
          step: step,
          allSteps: _steps,
          onUpdate: (id, {config, instruction, agentType, inputMappings}) {
             _updateStep(id, config: config, instruction: instruction, agentType: agentType, inputMappings: inputMappings);
          },
        ),
      ),
    );
  }
  void _updateStep(String id, {String? instruction, MessageSender? agentType, Map<String, dynamic>? config, Map<String, String>? inputMappings}) {
    setState(() {
      final index = _steps.indexWhere((s) => s.id == id);
      if (index != -1) {
        _steps[index] = _steps[index].copyWith(
           agentType: agentType,
           instruction: instruction,
           config: config,
           inputMappings: inputMappings,
        );
      }
    });
  }


  IconData _getNodeIcon(WorkflowNodeType type) {
    switch (type) {
      case WorkflowNodeType.userInput: return FontAwesomeIcons.keyboard;
      case WorkflowNodeType.trigger: return FontAwesomeIcons.bolt;
      case WorkflowNodeType.llm: return FontAwesomeIcons.brain;
      case WorkflowNodeType.agent: return FontAwesomeIcons.robot;
      case WorkflowNodeType.ifElse: return FontAwesomeIcons.codeBranch;
      case WorkflowNodeType.loop: return FontAwesomeIcons.arrowsSpin;
      case WorkflowNodeType.iteration: return FontAwesomeIcons.listCheck;
      case WorkflowNodeType.questionClassifier: return FontAwesomeIcons.filter;
      case WorkflowNodeType.code: return FontAwesomeIcons.code;
      case WorkflowNodeType.httpRequest: return FontAwesomeIcons.globe;
      case WorkflowNodeType.listOperator: return FontAwesomeIcons.listCheck;
      case WorkflowNodeType.knowledgeRetrieval: return FontAwesomeIcons.bookOpen;
      case WorkflowNodeType.answer: return FontAwesomeIcons.checkDouble;
      case WorkflowNodeType.output: return FontAwesomeIcons.rightFromBracket;
      case WorkflowNodeType.tool: return FontAwesomeIcons.screwdriverWrench;
      case WorkflowNodeType.template: return FontAwesomeIcons.fileCode;
      case WorkflowNodeType.variableAggregator: return FontAwesomeIcons.layerGroup;
      case WorkflowNodeType.documentExtractor: return FontAwesomeIcons.filePdf;
      case WorkflowNodeType.variableAssigner: return FontAwesomeIcons.penToSquare;
      case WorkflowNodeType.parameterExtractor: return FontAwesomeIcons.magnifyingGlass;
    }
  }

  Color _getNodeColor(WorkflowNodeType type) {
    switch (type) {
      case WorkflowNodeType.userInput:
      case WorkflowNodeType.trigger:
        return Colors.greenAccent;
      case WorkflowNodeType.llm:
      case WorkflowNodeType.agent:
      case WorkflowNodeType.questionClassifier:
        return Colors.blueAccent;
      case WorkflowNodeType.ifElse:
      case WorkflowNodeType.loop:
      case WorkflowNodeType.iteration:
      case WorkflowNodeType.code:
      case WorkflowNodeType.template:
      case WorkflowNodeType.variableAggregator:
      case WorkflowNodeType.variableAssigner:
      case WorkflowNodeType.parameterExtractor:
      case WorkflowNodeType.documentExtractor:
      case WorkflowNodeType.listOperator:
        return Colors.purpleAccent;
      case WorkflowNodeType.httpRequest:
      case WorkflowNodeType.tool:
      case WorkflowNodeType.knowledgeRetrieval:
        return Colors.tealAccent;
      case WorkflowNodeType.answer:
      case WorkflowNodeType.output:
        return Colors.pinkAccent;
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
