import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/adk/models/pipeline_models.dart';
import '../../chat/models/chat_models.dart';
import '../providers/pipeline_provider.dart';

// Temporary state provider for the builder
final pipelineBuilderProvider = StateProvider<List<PipelineStep>>((ref) => []);

class PipelineBuilderScreen extends ConsumerStatefulWidget {
  const PipelineBuilderScreen({super.key});

  @override
  ConsumerState<PipelineBuilderScreen> createState() => _PipelineBuilderScreenState();
}

class _PipelineBuilderScreenState extends ConsumerState<PipelineBuilderScreen> {
  final _nameController = TextEditingController();

  final List<MessageSender> _availableAgents = [
    MessageSender.trendScoutAgent, // 1
    MessageSender.accountDirectorAgent, // 2
    MessageSender.strategistAgent, // 3
    MessageSender.editorialManagerAgent, // 4
    MessageSender.creativeAgent, // 5
    MessageSender.copywriterAgent, // 6
    MessageSender.mediaBuyerAgent, // 7
    MessageSender.performanceAnalystAgent, // 8
    
    // Utilities
    MessageSender.researchAgent,
    MessageSender.developerAgent,
    MessageSender.securityAgent,
    MessageSender.dataEngineerAgent,
  ];

  @override
  Widget build(BuildContext context) {
    final steps = ref.watch(pipelineBuilderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('ADK Pipeline Builder', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
             icon: const Icon(FontAwesomeIcons.diagramProject, size: 18), // Visual Canvas
             tooltip: 'Visual Workflow Builder',
             onPressed: () => context.push('/workflow-canvas'),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty || steps.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a name and add at least one step.'))
                );
                return;
              }

              final newPipeline = Pipeline(
                id: const Uuid().v4(),
                name: name,
                description: 'Custom workflow created via Builder',
                steps: steps,
              );

              ref.read(pipelineProvider.notifier).savePipeline(newPipeline);
              
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pipeline Saved Successfully!')));
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar: Agent Toolbox
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AGENT TOOLBOX', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: _availableAgents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final agent = _availableAgents[index];
                      return Draggable<MessageSender>(
                        data: agent,
                        feedback: _buildAgentCard(agent, isFeedback: true),
                        child: _buildAgentCard(agent),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Canvas: Pipeline Assembly
          Expanded(
            child: DragTarget<MessageSender>(
              onAccept: (agent) {
                ref.read(pipelineBuilderProvider.notifier).update((state) => [
                  ...state,
                  PipelineStep(
                    id: const Uuid().v4(),
                    agentType: agent,
                    instruction: '',
                  ),
                ]);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  color: candidateData.isNotEmpty ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Header Input
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'Untitled Pipeline',
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Steps List
                      Expanded(
                        child: steps.isEmpty 
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline, size: 48, color: Colors.white.withOpacity(0.1)),
                                const SizedBox(height: 16),
                                const Text('Drag Agents here to build your flow', style: TextStyle(color: Colors.white24)),
                              ],
                            ),
                          )
                        : ReorderableListView.builder(
                            itemCount: steps.length,
                            onReorder: (oldIndex, newIndex) {
                                if (oldIndex < newIndex) newIndex -= 1;
                                final item = steps.removeAt(oldIndex);
                                steps.insert(newIndex, item);
                                ref.read(pipelineBuilderProvider.notifier).state = [...steps];
                            },
                            itemBuilder: (context, index) {
                              final step = steps[index];
                              return _buildPipelineStepCard(step, index);
                            },
                          ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(MessageSender agent, {bool isFeedback = false}) {
    return Container(
      width: isFeedback ? 220 : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: isFeedback ? [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        children: [
          Icon(_getIconForAgent(agent), size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(child: Text(agent.name.replaceAll('Agent', ''), style:  TextStyle(color: Colors.white, fontSize: 13, decoration: TextDecoration.none))),
        ],
      ),
    );
  }

  Widget _buildPipelineStepCard(PipelineStep step, int index) {
    return Container(
      key: ValueKey(step.id),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              
              // Type Selector
              DropdownButton<PipelineStepType>(
                value: step.type,
                dropdownColor: const Color(0xFF1E1E1E),
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent, size: 16),
                onChanged: (newType) {
                  if (newType == null) return;
                  ref.read(pipelineBuilderProvider.notifier).update((s) => s.map((e) => e.id == step.id ? PipelineStep(
                    id: e.id,
                    agentType: e.agentType,
                    instruction: e.instruction,
                    type: newType,
                    parallelSteps: newType == PipelineStepType.parallel ? [] : null,
                    loopCondition: newType == PipelineStepType.loop ? 'Until complete' : null,
                  ) : e).toList());
                },
                items: PipelineStepType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                )).toList(),
              ),

              const SizedBox(width: 8),
              if (step.type != PipelineStepType.parallel) ...[
                Icon(_getIconForAgent(step.agentType), size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                Text(step.agentType.name.toUpperCase().replaceAll('AGENT', ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.white24),
                onPressed: () {
                   ref.read(pipelineBuilderProvider.notifier).update((s) => s.where((element) => element.id != step.id).toList());
                },
              ),
              const Icon(Icons.drag_handle, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 12),
          
          // Dynamic Content based on Type
          if (step.type == PipelineStepType.sequential) 
            _buildSequentialContent(step)
          else if (step.type == PipelineStepType.parallel)
            _buildParallelContent(step)
          else if (step.type == PipelineStepType.loop)
            _buildLoopContent(step),
        ],
      ),
    );
  }

  Widget _buildSequentialContent(PipelineStep step) {
    return TextField(
      onChanged: (val) {
        ref.read(pipelineBuilderProvider.notifier).update((s) => s.map((e) => e.id == step.id ? PipelineStep(
          id: e.id,
          agentType: e.agentType,
          instruction: val,
          type: e.type,
        ) : e).toList());
      },
      controller: TextEditingController(text: step.instruction)..selection = TextSelection.collapsed(offset: step.instruction.length),
      style: const TextStyle(color: Colors.white70, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Enter specific instructions for this step (Optional)...',
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildParallelContent(PipelineStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Parallel Group (Drop Agents below)', style: TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 8),
        DragTarget<MessageSender>(
          onAccept: (agent) {
             final List<PipelineStep> newSteps = List<PipelineStep>.from(step.parallelSteps ?? []);
             newSteps.add(PipelineStep(id: const Uuid().v4(), agentType: agent));
             ref.read(pipelineBuilderProvider.notifier).update((s) => s.map((e) => e.id == step.id ? PipelineStep(
                id: e.id,
                agentType: e.agentType,
                type: e.type,
                parallelSteps: newSteps,
             ) : e).toList());
          },
          builder: (context, candidate, rejected) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: candidate.isNotEmpty ? Colors.blueAccent : Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  if (step.parallelSteps == null || step.parallelSteps!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Empty. Drag specialists here to run in parallel.', style: TextStyle(color: Colors.white12, fontSize: 12)),
                    ),
                  ...?step.parallelSteps?.map((pStep) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(_getIconForAgent(pStep.agentType), size: 14, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(pStep.agentType.name.toUpperCase().replaceAll('AGENT', ''), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                          onPressed: () {
                            final newParallel = step.parallelSteps!.where((e) => e.id != pStep.id).toList();
                            ref.read(pipelineBuilderProvider.notifier).update((s) => s.map((e) => e.id == step.id ? PipelineStep(
                                id: e.id,
                                agentType: e.agentType,
                                type: e.type,
                                parallelSteps: newParallel,
                            ) : e).toList());
                          },
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoopContent(PipelineStep step) {
    return Column(
      children: [
        Row(
          children: [
            Icon(_getIconForAgent(step.agentType), size: 16, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text('LOOPING: ${step.agentType.name.replaceAll('Agent','')}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (val) {
            ref.read(pipelineBuilderProvider.notifier).update((s) => s.map((e) => e.id == step.id ? PipelineStep(
              id: e.id,
              agentType: e.agentType,
              instruction: e.instruction,
              type: e.type,
              loopCondition: val,
            ) : e).toList());
          },
          controller: TextEditingController(text: step.loopCondition)..selection = TextSelection.collapsed(offset: step.loopCondition?.length ?? 0),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Enter loop condition (e.g. "Until text is polished")...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  IconData _getIconForAgent(MessageSender agent) {
    switch (agent) {
      case MessageSender.researchAgent: return FontAwesomeIcons.magnifyingGlass;
      case MessageSender.creativeAgent: return FontAwesomeIcons.paintbrush;
      case MessageSender.extractorAgent: return FontAwesomeIcons.bolt;
      case MessageSender.parserAgent: return FontAwesomeIcons.fileCode;
      case MessageSender.summarizerAgent: return FontAwesomeIcons.listCheck;
      case MessageSender.securityAgent: return FontAwesomeIcons.shieldHalved;
      case MessageSender.dataEngineerAgent: return FontAwesomeIcons.database;
      case MessageSender.copywriterAgent: return FontAwesomeIcons.penNib;
      case MessageSender.developerAgent: return FontAwesomeIcons.code;
      default: return FontAwesomeIcons.robot;
    }
  }
}
