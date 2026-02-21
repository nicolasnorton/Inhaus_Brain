import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/adk/models/pipeline_models.dart';
import '../../chat/models/chat_models.dart';
import '../../../../core/models/mcp_models.dart';

class NodeConfigurationSheet extends ConsumerStatefulWidget {
  final PipelineStep step;
  final List<PipelineStep> allSteps; // Required for resolving dependency names
  final VoidCallback onClose;
  final Function(String stepId, {Map<String, dynamic>? config, String? instruction, MessageSender? agentType, Map<String, String>? inputMappings}) onUpdate;

  const NodeConfigurationSheet({
    super.key,
    required this.step,
    required this.allSteps,
    required this.onClose,
    required this.onUpdate,
  });

  @override
  ConsumerState<NodeConfigurationSheet> createState() => _NodeConfigurationSheetState();
}

class _NodeConfigurationSheetState extends ConsumerState<NodeConfigurationSheet> {
  late PipelineStep step;

  @override
  void initState() {
    super.initState();
    step = widget.step;
  }

  @override
  void didUpdateWidget(NodeConfigurationSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step.id != oldWidget.step.id) {
       setState(() {
         step = widget.step;
       });
    }
  }
  
  void _updateStep(String id, {Map<String, dynamic>? config, String? instruction, MessageSender? agentType, Map<String, String>? inputMappings}) {
    setState(() {
      if (config != null) step = step.copyWith(config: config);
      if (instruction != null) step = step.copyWith(instruction: instruction);
      if (agentType != null) step = step.copyWith(agentType: agentType);
      if (inputMappings != null) step = step.copyWith(inputMappings: inputMappings);
    });
    widget.onUpdate(id, config: config, instruction: instruction, agentType: agentType, inputMappings: inputMappings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: double.infinity,
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getNodeIcon(step.nodeType), color: Colors.blueAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.label,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(step.instruction, (val) {
             _updateStep(step.id, instruction: val);
          }, "Node Label / Instruction"),
          
          if (step.dependencies.isNotEmpty) ...[
             const SizedBox(height: 16),
             _buildSubtitle("Input Mappings"),
             _buildInputMappings(step),
          ],
          
          const Divider(color: Colors.white10),
          Expanded(
            child: SingleChildScrollView(
              child: _buildConfigForm(step),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNodeIcon(WorkflowNodeType type) {
    switch (type) {
      case WorkflowNodeType.start: return FontAwesomeIcons.play;
      case WorkflowNodeType.userInput: return FontAwesomeIcons.keyboard;
      case WorkflowNodeType.llm: return FontAwesomeIcons.brain;
      case WorkflowNodeType.knowledgeRetrieval: return FontAwesomeIcons.bookOpen;
      case WorkflowNodeType.iteration: return FontAwesomeIcons.arrowsSpin;
      case WorkflowNodeType.loop: return FontAwesomeIcons.repeat;
      case WorkflowNodeType.listOperator: return FontAwesomeIcons.listCheck;
      case WorkflowNodeType.ifElse: return FontAwesomeIcons.codeBranch;
      case WorkflowNodeType.httpRequest: return FontAwesomeIcons.globe;
      case WorkflowNodeType.code: return FontAwesomeIcons.code;
      case WorkflowNodeType.template: return FontAwesomeIcons.fileCode;
      case WorkflowNodeType.variableAggregator: return FontAwesomeIcons.layerGroup;
      case WorkflowNodeType.documentExtractor: return FontAwesomeIcons.filePdf;
      case WorkflowNodeType.variableAssigner: return FontAwesomeIcons.penToSquare;
      case WorkflowNodeType.parameterExtractor: return FontAwesomeIcons.magnifyingGlass;
      case WorkflowNodeType.note: return FontAwesomeIcons.stickyNote;
      default: return FontAwesomeIcons.circle;
    }
  }

  Widget _buildInputMappings(PipelineStep step) {
    return Column(
      children: step.dependencies.map((depId) {
        final dep = widget.allSteps.firstWhere((s) => s.id == depId, orElse: () => PipelineStep(id: 'unknown', nodeType: WorkflowNodeType.trigger, instruction: 'Unknown'));
        final sourceLabel = dep.label.isNotEmpty ? dep.label : dep.nodeType.name.toUpperCase();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text("From $sourceLabel:", style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ),
              const Icon(Icons.arrow_right_alt, color: Colors.blueAccent, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  step.inputMappings[depId] ?? "result", 
                  (val) {
                    final newMappings = Map<String, String>.from(step.inputMappings);
                    newMappings[depId] = val;
                    _updateStep(step.id, inputMappings: newMappings);
                  }
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfigForm(PipelineStep step) {
    switch (step.nodeType) {
      case WorkflowNodeType.start:
        return _buildStartConfig(step);
      case WorkflowNodeType.llm:
        return _buildLLMConfig(step);
      case WorkflowNodeType.knowledgeRetrieval:
        return _buildKnowledgeRetrievalConfig(step);
      case WorkflowNodeType.iteration:
        return _buildIterationConfig(step);
      case WorkflowNodeType.loop:
        return _buildLoopConfig(step);
      case WorkflowNodeType.ifElse:
        return _buildIfElseConfig(step);
      case WorkflowNodeType.code:
        return _buildCodeConfig(step);
      case WorkflowNodeType.template:
        return _buildTemplateConfig(step);
      case WorkflowNodeType.variableAggregator:
        return _buildVariableAggregatorConfig(step);
      case WorkflowNodeType.documentExtractor:
        return _buildDocumentExtractorConfig(step);
      case WorkflowNodeType.variableAssigner:
        return _buildVariableAssignerConfig(step);
      case WorkflowNodeType.parameterExtractor:
        return _buildParameterExtractorConfig(step);
      case WorkflowNodeType.listOperator:
        return _buildListOperatorConfig(step);
      case WorkflowNodeType.httpRequest:
        return _buildHttpRequestConfig(step);
      case WorkflowNodeType.userInput:
        return _buildUserInputConfig(step);
      case WorkflowNodeType.trigger:
        return _buildTriggerConfig(step);
      case WorkflowNodeType.answer:
        return _buildAnswerConfig(step);
      case WorkflowNodeType.output:
        return _buildOutputConfig(step);
      case WorkflowNodeType.agent:
        return _buildAgentConfig(step);
      case WorkflowNodeType.tool:
        return _buildToolConfig(step);
      case WorkflowNodeType.questionClassifier:
        return _buildQuestionClassifierConfig(step);
      case WorkflowNodeType.note:
        return _buildNoteConfig(step);
      case WorkflowNodeType.dialogueScene:
        return const Center(child: Text("Dialogue Scene Config (Coming Soon)"));
      case WorkflowNodeType.deepResearch:
        return const Center(child: Text("Deep Research Config (Coming Soon)"));
      case WorkflowNodeType.imageGeneration:
        return const Center(child: Text("Image Generation Config (Coming Soon)"));
      case WorkflowNodeType.videoGeneration:
        return const Center(child: Text("Video Generation Config (Coming Soon)"));
    }
  }

  // --- Helper Widgets ---

  Widget _buildSubtitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(String initialValue, Function(String) onChanged, [String? hintText]) {
    return _ManagedTextField(
      initialValue: initialValue,
      onChanged: onChanged,
      hintText: hintText,
    );
  }

  Widget _buildTextArea(String initialValue, Function(String) onChanged, [String? hintText]) {
    return _ManagedTextArea(
      initialValue: initialValue,
      onChanged: onChanged,
      hintText: hintText,
    );
  }

  Widget _buildDropdown(List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          dropdownColor: Colors.black,
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 11),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // --- Configuration Builders ---

  Widget _buildLLMConfig(PipelineStep step) {
     final prompts = List<Map<String, dynamic>>.from(step.config['prompts'] ?? [{'role': 'user', 'content': ''}]);
     final model = step.config['model'] ?? 'gpt-4o';
     final vision = step.config['vision'] ?? false;
     final resolution = step.config['resolution'] ?? 'High';
     final memory = step.config['memory'] ?? false;
     final windowSize = step.config['window_size'] ?? 10;
     final contextVar = step.config['context_variable'] ?? '';
     final showParams = step.config['show_params'] ?? false;
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("MODEL"),
           Row(
              children: [
                 Expanded(
                    child: _buildDropdown(["gemini-2.5-pro", "gemini-3-pro-preview", "gemini-2.5-flash", "gemini-3-flash-preview", "claude-3-5-sonnet", "gpt-4o"], model, (val) {
                       _updateStep(step.id, config: {...step.config, 'model': val});
                    }),
                 ),
                 const SizedBox(width: 8),
                 IconButton(
                    onPressed: () => _updateStep(step.id, config: {...step.config, 'show_params': !showParams}),
                    icon: Icon(Icons.settings_outlined, size: 16, color: showParams ? Colors.blueAccent : Colors.white38),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                 ),
              ],
           ),
           if (showParams) ...[
              const SizedBox(height: 12),
              _buildLLMParametersPanel(step),
           ],
           const SizedBox(height: 16),

           _buildSubtitle("CONTEXT"),
           Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: Row(
                 children: [
                    const Icon(Icons.data_object, size: 12, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                       child: _buildTextField(contextVar, (val) {
                          _updateStep(step.id, config: {...step.config, 'context_variable': val});
                       }, "Set context variable..."),
                    ),
                 ],
              ),
           ),
           const SizedBox(height: 16),

           _buildPromptConfig(step, prompts),
           const SizedBox(height: 16),

           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 _buildSubtitle("VISION"),
                 Transform.scale(
                    scale: 0.7,
                    child: Switch(
                       value: vision,
                       activeThumbColor: Colors.blueAccent,
                       onChanged: (val) => _updateStep(step.id, config: {...step.config, 'vision': val}),
                    ),
                 ),
              ],
           ),
           if (vision) ...[
              const SizedBox(height: 8),
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    const Text("RESOLUTION", style: TextStyle(color: Colors.white38, fontSize: 10)),
                    Container(
                       decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                       padding: const EdgeInsets.all(2),
                       child: Row(
                          children: [
                             _buildResolutionButton("High", resolution == "High", (val) {
                                _updateStep(step.id, config: {...step.config, 'resolution': val});
                             }),
                             _buildResolutionButton("Low", resolution == "Low", (val) {
                                _updateStep(step.id, config: {...step.config, 'resolution': val});
                             }),
                          ],
                       ),
                    ),
                 ],
              ),
           ],
           const SizedBox(height: 16),

           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 _buildSubtitle("MEMORY"),
                 Transform.scale(
                    scale: 0.7,
                    child: Switch(
                       value: memory,
                       activeThumbColor: Colors.blueAccent,
                       onChanged: (val) => _updateStep(step.id, config: {...step.config, 'memory': val}),
                    ),
                 ),
              ],
           ),
           if (memory) ...[
              const SizedBox(height: 8),
              Row(
                 children: [
                    const Expanded(child: Text("WINDOW SIZE", style: TextStyle(color: Colors.white38, fontSize: 10))),
                    Text(windowSize.toString(), style: const TextStyle(color: Colors.white60, fontSize: 10)),
                 ],
              ),
              Slider(
                 value: windowSize.toDouble(),
                 min: 1, max: 50, divisions: 49,
                 activeColor: Colors.blueAccent,
                 onChanged: (val) => _updateStep(step.id, config: {...step.config, 'window_size': val.toInt()}),
              ),
           ],
           const SizedBox(height: 20),

           _buildSubtitle("OUTPUT VARIABLES"),
           Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                 border: Border.all(color: Colors.white10),
                 borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Row(
                       children: [
                          Icon(Icons.text_fields, size: 10, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text("text", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          SizedBox(width: 8),
                          Text("string", style: TextStyle(color: Colors.white38, fontSize: 10)),
                       ],
                    ),
                 ],
              ),
           ),
        ],
     );
  }

  Widget _buildResolutionButton(String label, bool isSelected, Function(String) onTap) {
     return GestureDetector(
        onTap: () => onTap(label),
        child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
           decoration: BoxDecoration(
              color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isSelected ? Colors.white10 : Colors.transparent),
           ),
           child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 10)),
        ),
     );
  }

  Widget _buildLLMParametersPanel(PipelineStep step) {
     final temp = (step.config['temperature'] ?? 0.7).toDouble();
     final topP = (step.config['top_p'] ?? 0.9).toDouble();
     final maxTokens = step.config['max_tokens'] ?? 4096;
     
     return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
        child: Column(
           children: [
              _buildParamSlider("Temperature", temp, 0, 2, (val) => _updateStep(step.id, config: {...step.config, 'temperature': val})),
              const SizedBox(height: 8),
              _buildParamSlider("Top P", topP, 0, 1, (val) => _updateStep(step.id, config: {...step.config, 'top_p': val})),
              const SizedBox(height: 8),
              Row(
                 children: [
                    const Expanded(child: Text("Max Tokens", style: TextStyle(color: Colors.white38, fontSize: 10))),
                    SizedBox(width: 60, child: _buildTextField(maxTokens.toString(), (val) {
                       _updateStep(step.id, config: {...step.config, 'max_tokens': int.tryParse(val) ?? 4096});
                    })),
                 ],
              ),
           ],
        ),
     );
  }

  Widget _buildParamSlider(String label, double value, double min, double max, Function(double) onChanged) {
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                 Text(value.toStringAsFixed(2), style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ],
           ),
           Slider(
              value: value, min: min, max: max,
              activeColor: Colors.blueAccent,
              onChanged: onChanged,
           ),
        ],
     );
  }

  Widget _buildPromptConfig(PipelineStep step, List<Map<String, dynamic>> prompts) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         _buildSubtitle("PROMPT"),
         ...prompts.asMap().entries.map((entry) => _buildPromptMessageItem(step, prompts, entry.key, entry.value)),
         const SizedBox(height: 8),
         SizedBox(
           width: double.infinity,
           child: OutlinedButton.icon(
             onPressed: () {
                final newPrompts = [...prompts, {'role': 'user', 'content': ''}];
                _updateStep(step.id, config: {...step.config, 'prompts': newPrompts});
             },
             icon: const Icon(Icons.add, size: 14),
             label: const Text("Add Message", style: TextStyle(fontSize: 11)),
             style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white10),
                padding: const EdgeInsets.symmetric(vertical: 12),
             ),
           ),
         ),
       ],
     );
  }

  Widget _buildPromptMessageItem(PipelineStep step, List<Map<String, dynamic>> allPrompts, int index, Map<String, dynamic> prompt) {
     final content = prompt['content'] ?? '';
     final role = (prompt['role'] ?? 'user').toString().toUpperCase();
     
     return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
           color: Colors.white.withValues(alpha: 0.02),
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
           children: [
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                 decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                 ),
                 child: Row(
                    children: [
                       Text(role, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                       const SizedBox(width: 4),
                       const Icon(Icons.help_outline, size: 12, color: Colors.white24),
                       const Spacer(),
                       Text("${content.length}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                       const SizedBox(width: 8),
                       const Icon(Icons.auto_awesome, size: 14, color: Colors.blueAccent),
                       const SizedBox(width: 8),
                       const Icon(Icons.data_object, size: 12, color: Colors.white24),
                       const SizedBox(width: 8),
                       const Icon(Icons.copy_outlined, size: 12, color: Colors.white24),
                       const SizedBox(width: 8),
                       const Icon(Icons.fullscreen, size: 14, color: Colors.white24),
                       const SizedBox(width: 8),
                       IconButton(
                          onPressed: () {
                             final newPrompts = [...allPrompts]..removeAt(index);
                             _updateStep(step.id, config: {...step.config, 'prompts': newPrompts});
                          },
                          icon: const Icon(Icons.close, size: 14, color: Colors.white38),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                       ),
                    ],
                 ),
              ),
              Padding(
                 padding: const EdgeInsets.all(8.0),
                 child: Row(
                    children: [
                       Expanded(
                          child: _buildTextArea(content, (val) {
                             final newPrompts = [...allPrompts];
                             newPrompts[index] = {...prompt, 'content': val};
                             _updateStep(step.id, config: {...step.config, 'prompts': newPrompts});
                          }, "Enter message content..."),
                       ),
                    ],
                 ),
              ),
              if (index == allPrompts.length - 1)
                 Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Row(
                       children: [
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                             child: const Row(
                                children: [
                                   Icon(Icons.info_outline, size: 10, color: Colors.blueAccent),
                                   SizedBox(width: 4),
                                   Text("Start", style: TextStyle(color: Colors.white60, fontSize: 9)),
                                   Text(" / ", style: TextStyle(color: Colors.white24, fontSize: 9)),
                                   Text("input_text", style: TextStyle(color: Colors.blueAccent, fontSize: 9)),
                                ],
                             ),
                          ),
                       ],
                    ),
                 ),
           ],
        ),
     );
  }

  Widget _buildKnowledgeRetrievalConfig(PipelineStep step) {
     final query = step.config['query'] ?? '{{sys.query}}';
     final knowledgeBases = List<String>.from(step.config['knowledge_bases'] ?? []);
     final topK = step.config['top_k'] ?? 3;
     final scoreThreshold = (step.config['score_threshold'] ?? 0.7).toDouble();
     final reranking = step.config['reranking'] ?? false;
     final rerankModel = step.config['rerank_model'] ?? 'rerank-english-v3.0';
     final weightedScore = (step.config['weighted_score'] ?? 0.5).toDouble();
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("QUERY VARIABLE"),
           Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: Row(
                 children: [
                    Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                       child: const Row(
                          children: [
                             Icon(Icons.home_outlined, size: 10, color: Colors.blueAccent),
                             SizedBox(width: 4),
                             Text("Start", style: TextStyle(color: Colors.white60, fontSize: 9)),
                          ],
                       ),
                    ),
                    const Text(" / ", style: TextStyle(color: Colors.white24, fontSize: 9)),
                    Expanded(
                       child: _buildTextField(query, (val) {
                          _updateStep(step.id, config: {...step.config, 'query': val});
                       }, "e.g. {{sys.query}}"),
                    ),
                    const SizedBox(width: 4),
                    const Text("String", style: TextStyle(color: Colors.white24, fontSize: 9)),
                 ],
              ),
           ),
           const SizedBox(height: 16),

           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 _buildSubtitle("SELECT KNOWLEDGE"),
                 IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16, color: Colors.blueAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                 ),
              ],
           ),
           if (knowledgeBases.isEmpty)
              Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                 ),
                 child: const Center(
                    child: Text("No knowledge base selected", style: TextStyle(color: Colors.white24, fontSize: 10)),
                 ),
              )
           else
              ...knowledgeBases.map((kb) => Container(
                 margin: const EdgeInsets.only(bottom: 8),
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                 decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                 child: Row(
                    children: [
                       const Icon(Icons.menu_book, size: 12, color: Colors.greenAccent),
                       const SizedBox(width: 8),
                       Expanded(child: Text(kb, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                       IconButton(
                          onPressed: () {
                             final newKbs = [...knowledgeBases]..remove(kb);
                             _updateStep(step.id, config: {...step.config, 'knowledge_bases': newKbs});
                          },
                          icon: const Icon(Icons.close, size: 12, color: Colors.white24),
                       ),
                    ],
                 ),
              )),
           const SizedBox(height: 16),

           _buildSubtitle("RETRIEVAL SETTING"),
           _buildSwitchRow("Enable Reranking", reranking, (val) {
              _updateStep(step.id, config: {...step.config, 'reranking': val});
           }, "Re-score and reorder results based on relevance"),
           
           if (reranking) ...[
              const SizedBox(height: 12),
              const Text("RERANK MODEL", style: TextStyle(color: Colors.white38, fontSize: 9)),
              const SizedBox(height: 4),
              _buildDropdown(["rerank-english-v3.0", "rerank-multilingual-v3.0", "bge-reranker-v2-m3"], rerankModel, (val) {
                 _updateStep(step.id, config: {...step.config, 'rerank_model': val});
              }),
              const SizedBox(height: 12),
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    const Text("WEIGHTED SCORE", style: TextStyle(color: Colors.white38, fontSize: 9)),
                    Text(weightedScore.toStringAsFixed(1), style: const TextStyle(color: Colors.white60, fontSize: 10)),
                 ],
              ),
              Slider(
                 value: weightedScore, min: 0, max: 1, divisions: 10,
                 activeColor: Colors.blueAccent,
                 onChanged: (val) => _updateStep(step.id, config: {...step.config, 'weighted_score': val}),
              ),
           ],

           const SizedBox(height: 16),
           Row(
              children: [
                 Expanded(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          const Text("TOP K", style: TextStyle(color: Colors.white38, fontSize: 9)),
                          _buildTextField(topK.toString(), (val) {
                             _updateStep(step.id, config: {...step.config, 'top_k': int.tryParse(val) ?? 3});
                          }),
                       ],
                    ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          const Text("SCORE THRESHOLD", style: TextStyle(color: Colors.white38, fontSize: 9)),
                          _buildTextField(scoreThreshold.toString(), (val) {
                             _updateStep(step.id, config: {...step.config, 'score_threshold': double.tryParse(val) ?? 0.7});
                          }),
                       ],
                    ),
                 ),
              ],
           ),
           const SizedBox(height: 20),

           _buildSubtitle("OUTPUT VARIABLES"),
           Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                 border: Border.all(color: Colors.white10),
                 borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Row(
                       children: [
                          Icon(Icons.list, size: 10, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text("result", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          SizedBox(width: 8),
                          Text("array[object]", style: TextStyle(color: Colors.white38, fontSize: 10)),
                       ],
                    ),
                    SizedBox(height: 4),
                    Text("Retrieved document chunks containing content and metadata.", style: TextStyle(color: Colors.white24, fontSize: 9)),
                 ],
              ),
           ),
        ],
     );
  }

  Widget _buildIterationConfig(PipelineStep step) {
     final arrayVar = step.config['array_var'] ?? '{{array}}';
     final mode = step.config['mode'] ?? 'sequential';
     final onError = step.config['on_error'] ?? 'continue';
     
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          _buildSubtitle("Input Array Variable"),
          _buildTextField(arrayVar, (val) {
             _updateStep(step.id, config: {...step.config, 'array_var': val});
          }),
          const SizedBox(height: 16),
          _buildSubtitle("Execution Mode"),
          _buildDropdown(["sequential", "parallel"], mode, (val) {
             _updateStep(step.id, config: {...step.config, 'mode': val});
          }),
          const SizedBox(height: 16),
          _buildSubtitle("On Error"),
          _buildDropdown(["continue", "terminate"], onError, (val) {
             _updateStep(step.id, config: {...step.config, 'on_error': val});
          }),
       ],
     );
  }

  Widget _buildLoopConfig(PipelineStep step) {
    final variables = List<Map<String, dynamic>>.from(step.config['variables'] ?? []);
    final termVar = step.config['term_var'] ?? '';
    final termOp = step.config['term_op'] ?? 'equals';
    final termVal = step.config['term_val'] ?? '';
    final maxCount = step.config['max_count'] ?? 10;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("Loop Variables"),
        const Text("Variables that persist across iterations.", style: TextStyle(color: Colors.white24, fontSize: 10)),
        const SizedBox(height: 8),
        ...variables.map((v) => _buildLoopVariableItem(step, variables, v)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final newVars = [...variables, {'name': 'count', 'value': '0'}];
              _updateStep(step.id, config: {...step.config, 'variables': newVars});
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text("Add Loop Variable", style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
          ),
        ),
        const SizedBox(height: 16),
        _buildSubtitle("Termination Condition"),
        Row(
           children: [
              Expanded(child: _buildTextField(termVar, (val) => _updateStep(step.id, config: {...step.config, 'term_var': val}), "Variable")),
              const SizedBox(width: 8),
              SizedBox(width: 80, child: _buildDropdown(["equals", "not equals", "greater", "less"], termOp, (val) => _updateStep(step.id, config: {...step.config, 'term_op': val}))),
           ],
        ),
        const SizedBox(height: 8),
        _buildTextField(termVal, (val) => _updateStep(step.id, config: {...step.config, 'term_val': val}), "Value"),
        
        const SizedBox(height: 16),
        _buildSubtitle("Max Iterations"),
        _buildTextField(maxCount.toString(), (val) => _updateStep(step.id, config: {...step.config, 'max_count': int.tryParse(val) ?? 10})),
      ],
    );
  }

  Widget _buildLoopVariableItem(PipelineStep step, List<Map<String, dynamic>> allVars, Map<String, dynamic> v) {
     return Container(
       margin: const EdgeInsets.only(bottom: 8),
       child: Row(
         children: [
            Expanded(child: _buildTextField(v['name'] ?? '', (val) {
               final idx = allVars.indexOf(v);
               final newVars = [...allVars];
               newVars[idx] = {...v, 'name': val};
               _updateStep(step.id, config: {...step.config, 'variables': newVars});
            }, "Name")),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField(v['value'] ?? '', (val) {
               final idx = allVars.indexOf(v);
               final newVars = [...allVars];
               newVars[idx] = {...v, 'value': val};
               _updateStep(step.id, config: {...step.config, 'variables': newVars});
            }, "Init Value")),
            IconButton(icon: const Icon(Icons.close, size: 14, color: Colors.white24), onPressed: () {
               final newVars = [...allVars]..remove(v);
               _updateStep(step.id, config: {...step.config, 'variables': newVars});
            })
         ],
       ),
     );
  }

  Widget _buildIfElseConfig(PipelineStep step) {
    final branches = List<Map<String, dynamic>>.from(step.config['branches'] ?? [{'conditions': [], 'label': 'IF'}]);
    
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          ...branches.asMap().entries.map((entry) => _buildLogicBranch(step, branches, entry.key, entry.value)),
          SizedBox(
             width: double.infinity,
             child: OutlinedButton.icon(
                onPressed: () {
                   final newBranches = [...branches, {'conditions': [], 'label': 'ELIF'}];
                   _updateStep(step.id, config: {...step.config, 'branches': newBranches});
                },
                icon: const Icon(Icons.add, size: 14),
                label: const Text("Add Branch (ELIF)"),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
             ),
          ),
       ],
    );
  }

  Widget _buildLogicBranch(PipelineStep step, List<Map<String, dynamic>> allBranches, int index, Map<String, dynamic> branch) {
     final conditions = List<Map<String, dynamic>>.from(branch['conditions'] ?? []);
     final isElse = index > 0 && index == allBranches.length - 1 && (branch['label'] == 'ELSE');

     return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
           border: Border.all(color: Colors.white10),
           borderRadius: BorderRadius.circular(8)
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Row(
                 children: [
                    Text(branch['label'] ?? (index == 0 ? "IF" : "ELIF"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                    const Spacer(),
                    if (index > 0)
                       IconButton(
                          icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                          onPressed: () {
                             final newBranches = [...allBranches]..removeAt(index);
                             _updateStep(step.id, config: {...step.config, 'branches': newBranches});
                          },
                       )
                 ],
              ),
              if (!isElse) ...[
                 ...conditions.asMap().entries.map((entry) => _buildConditionItem(step, allBranches, index, conditions, entry.key, entry.value)),
                 TextButton.icon(
                    onPressed: () {
                       final newConds = [...conditions, {'var': '', 'op': 'equals', 'val': ''}];
                       final newBranches = [...allBranches];
                       newBranches[index] = {...branch, 'conditions': newConds};
                       _updateStep(step.id, config: {...step.config, 'branches': newBranches});
                    },
                    icon: const Icon(Icons.add, size: 12),
                    label: const Text("Add Condition (AND)"),
                 )
              ] else
                 const Text("Fallback path if no conditions match.", style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic)),
           ],
        ),
     );
  }

  Widget _buildConditionItem(PipelineStep step, List<Map<String, dynamic>> allBranches, int branchIdx, List<Map<String, dynamic>> conditions, int condIdx, Map<String, dynamic> cond) {
     return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
           children: [
              Expanded(child: _buildTextField(cond['var'] ?? '', (val) {
                 final newConds = [...conditions];
                 newConds[condIdx] = {...cond, 'var': val};
                 final newBranches = [...allBranches];
                 newBranches[branchIdx] = {...allBranches[branchIdx], 'conditions': newConds};
                 _updateStep(step.id, config: {...step.config, 'branches': newBranches});
              }, "Variable")),
              const SizedBox(width: 4),
              SizedBox(width: 70, child: _buildDropdown(['equals', 'contains', 'starts_with', 'is_empty'], cond['op'] ?? 'equals', (val) {
                 final newConds = [...conditions];
                 newConds[condIdx] = {...cond, 'op': val};
                 final newBranches = [...allBranches];
                 newBranches[branchIdx] = {...allBranches[branchIdx], 'conditions': newConds};
                 _updateStep(step.id, config: {...step.config, 'branches': newBranches});
              })),
              const SizedBox(width: 4),
              Expanded(child: _buildTextField(cond['val'] ?? '', (val) {
                 final newConds = [...conditions];
                 newConds[condIdx] = {...cond, 'val': val};
                 final newBranches = [...allBranches];
                 newBranches[branchIdx] = {...allBranches[branchIdx], 'conditions': newConds};
                 _updateStep(step.id, config: {...step.config, 'branches': newBranches});
              }, "Value")),
           ],
        ),
     );
  }

  Widget _buildCodeConfig(PipelineStep step) {
    final code = step.config['code'] ?? '// Write JavaScript code here\nreturn inputs.arg1 + " processed";';
    final inputs = List<Map<String, dynamic>>.from(step.config['inputs'] ?? []);
    final outputs = List<Map<String, dynamic>>.from(step.config['outputs'] ?? []);
    final retries = step.config['retries'] ?? 0;
    
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildSubtitle("Input Variables"),
             _buildKeyValueList(step, inputs, 'inputs'),
             const SizedBox(height: 16),
             
             _buildSubtitle("Code (JavaScript)"),
             SizedBox(
               height: 300,
               child: _buildTextArea(code, (val) {
                  _updateStep(step.id, config: {...step.config, 'code': val});
               }),
             ),
             const SizedBox(height: 16),
             
             _buildSubtitle("Output Variables"),
             _buildKeyValueList(step, outputs, 'outputs'),
             const SizedBox(height: 16),
             
             _buildSubtitle("Retry Attempts"),
             _buildTextField(retries.toString(), (val) => _updateStep(step.id, config: {...step.config, 'retries': int.tryParse(val) ?? 0})),
             const SizedBox(height: 24),
          ],
       );
  }
  
  Widget _buildTemplateConfig(PipelineStep step) {
     final template = step.config['template'] ?? 'Hello {{name}}!';
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Template (Jinja2 Syntax)"),
           SizedBox(
              height: 200,
              child: _buildTextArea(template, (val) {
                 _updateStep(step.id, config: {...step.config, 'template': val});
              }, "Hello {{name}}!"),
           ),
           const SizedBox(height: 8),
           const Text("Use {{variable}} for substitution. {% if var %} logic {% endif %} available.", style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
     );
  }

  Widget _buildVariableAggregatorConfig(PipelineStep step) {
     final groups = List<Map<String, dynamic>>.from(step.config['groups'] ?? []);
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Aggregation Groups"),
           const Text("Group variables from multiple branches.", style: TextStyle(color: Colors.white24, fontSize: 10)),
           const SizedBox(height: 8),
           ...groups.asMap().entries.map((entry) => _buildAggregatorGroupItem(step, groups, entry.key, entry.value)),
           SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                 onPressed: () {
                    final newGroups = [...groups, {'target': 'new_var', 'sources': []}];
                    _updateStep(step.id, config: {...step.config, 'groups': newGroups});
                 },
                 icon: const Icon(Icons.add, size: 14),
                 label: const Text("Add Aggregation Group"),
                 style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
              ),
           ),
        ],
     );
  }

  Widget _buildAggregatorGroupItem(PipelineStep step, List<Map<String, dynamic>> allGroups, int index, Map<String, dynamic> group) {
     final sources = List<String>.from(group['sources'] ?? []);
     
     return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
        child: Column(
           children: [
              Row(
                 children: [
                    Expanded(child: _buildTextField(group['target'] ?? '', (val) {
                       final newGroups = [...allGroups];
                       newGroups[index] = {...group, 'target': val};
                       _updateStep(step.id, config: {...step.config, 'groups': newGroups});
                    }, "Target Variable")),
                    IconButton(
                       icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                       onPressed: () {
                          final newGroups = [...allGroups]..removeAt(index);
                          _updateStep(step.id, config: {...step.config, 'groups': newGroups});
                       },
                    ),
                 ],
              ),
              const SizedBox(height: 8),
              Wrap(
                 spacing: 8,
                 runSpacing: 4,
                 children: [
                    ...sources.map((s) => Chip(
                       label: Text(s, style: const TextStyle(fontSize: 10)),
                       onDeleted: () {
                          final newSources = [...sources]..remove(s);
                          final newGroups = [...allGroups];
                          newGroups[index] = {...group, 'sources': newSources};
                          _updateStep(step.id, config: {...step.config, 'groups': newGroups});
                       },
                       backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                       deleteIconColor: Colors.white54,
                    )),
                    ActionChip(
                       label: const Text("+ Source"),
                       onPressed: () {
                           // Ideally this opens a dialog to pick a variable, simplifying to text input for now
                           // In a real app, use a modal dialog.
                           _updateStep(step.id, config: {...step.config}); // Force rebuild if state changes
                       },
                    )
                 ],
              )
           ],
        ),
     );
  }

  Widget _buildDocumentExtractorConfig(PipelineStep step) {
     final mode = step.config['mode'] ?? 'single';
     final variable = step.config['variable'] ?? '{{sys.files}}';
     final showAdvanced = step.config['show_advanced'] ?? false;
     final tableExtraction = step.config['table_extraction'] ?? true;
     final enableChunking = step.config['enable_chunking'] ?? false;
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Input Mode"),
           SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                 segments: const [
                    ButtonSegment(value: 'single', label: Text('Single', style: TextStyle(fontSize: 10)), icon: Icon(Icons.description_outlined, size: 14)),
                    ButtonSegment(value: 'multiple', label: Text('Multiple', style: TextStyle(fontSize: 10)), icon: Icon(Icons.copy_all_outlined, size: 14)),
                 ],
                 selected: {mode},
                 onSelectionChanged: (Set<String> newSelection) {
                    _updateStep(step.id, config: {...step.config, 'mode': newSelection.first});
                 },
                 style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    selectedBackgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                    selectedForegroundColor: Colors.blueAccent,
                    visualDensity: VisualDensity.compact,
                 ),
              ),
           ),
           const SizedBox(height: 16),
           
           _buildSubtitle("Input Variable"),
           Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: Row(
                 children: [
                    Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                       child: const Row(
                          children: [
                             Icon(Icons.home_outlined, size: 10, color: Colors.blueAccent),
                             SizedBox(width: 4),
                             Text("Start", style: TextStyle(color: Colors.white60, fontSize: 9)),
                          ],
                       ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                       child: _buildTextField(variable, (val) {
                          _updateStep(step.id, config: {...step.config, 'variable': val});
                       }, "e.g. {{sys.files}}"),
                    ),
                 ],
              ),
           ),
           const SizedBox(height: 8),
           Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    const Text("Supported Formats:", style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                       "Text: TXT, MD, HTML\nOffice: DOCX, XLSX, CSV, PPTX\nOthers: PDF, EPUB, VTT, EML",
                       style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, height: 1.4),
                    ),
                 ],
              ),
           ),
           const SizedBox(height: 20),
           
           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 _buildSubtitle("Advanced Settings"),
                 Transform.scale(
                    scale: 0.7,
                    child: Switch(
                       value: showAdvanced,
                       activeThumbColor: Colors.blueAccent,
                       onChanged: (val) => _updateStep(step.id, config: {...step.config, 'show_advanced': val}),
                    ),
                 ),
              ],
           ),
           if (showAdvanced) ...[
              const SizedBox(height: 8),
              _buildSwitchRow("Table Extraction", tableExtraction, (val) {
                 _updateStep(step.id, config: {...step.config, 'table_extraction': val});
              }, "Convert data tables to Markdown format"),
              _buildSwitchRow("Enable Chunking", enableChunking, (val) {
                 _updateStep(step.id, config: {...step.config, 'enable_chunking': val});
              }, "Split large documents for context limits"),
           ],
           const SizedBox(height: 20),
           
           _buildSubtitle("Output Variables"),
           Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                 border: Border.all(color: Colors.white10),
                 borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Row(
                       children: [
                          const Text("text", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          const SizedBox(width: 8),
                          Text(mode == 'single' ? "string" : "array[string]", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                       ],
                    ),
                    const SizedBox(height: 4),
                    const Text("The extracted raw text content from the document(s).", style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
               ),
            ),
         ],
      );
   }

   Widget _buildSwitchRow(String label, bool value, Function(bool) onChanged, String subtitle) {
      return Padding(
         padding: const EdgeInsets.only(bottom: 12),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                     Transform.scale(
                        scale: 0.7,
                        child: Switch(
                           value: value,
                           activeThumbColor: Colors.blueAccent,
                           onChanged: onChanged,
                        ),
                     ),
                  ],
               ),
               Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 9)),
            ],
         ),
      );
   }

  Widget _buildVariableAssignerConfig(PipelineStep step) {
     final assignments = List<Map<String, dynamic>>.from(step.config['assignments'] ?? []);
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Assignments"),
           ...assignments.asMap().entries.map((entry) => _buildAssignmentItem(step, assignments, entry.key, entry.value)),
           SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                 onPressed: () {
                    final newAssigns = [...assignments, {'var': 'new_var', 'op': 'Set', 'val': ''}];
                    _updateStep(step.id, config: {...step.config, 'assignments': newAssigns});
                 },
                 icon: const Icon(Icons.add, size: 14),
                 label: const Text("Add Assignment"),
                 style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
              ),
           ),
        ],
     );
  }

  Widget _buildAssignmentItem(PipelineStep step, List<Map<String, dynamic>> allAssigns, int index, Map<String, dynamic> assign) {
     return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
           children: [
              Expanded(flex: 2, child: _buildTextField(assign['var'] ?? '', (val) {
                 final newAssigns = [...allAssigns];
                 newAssigns[index] = {...assign, 'var': val};
                 _updateStep(step.id, config: {...step.config, 'assignments': newAssigns});
              }, "Variable")),
              const SizedBox(width: 4),
              Expanded(flex: 2, child: _buildDropdown(['Set', 'Append', 'Extend', 'Clear'], assign['op'] ?? 'Set', (val) {
                 final newAssigns = [...allAssigns];
                 newAssigns[index] = {...assign, 'op': val};
                 _updateStep(step.id, config: {...step.config, 'assignments': newAssigns});
              })),
              const SizedBox(width: 4),
              Expanded(flex: 3, child: _buildTextField(assign['val'] ?? '', (val) {
                  final newAssigns = [...allAssigns];
                 newAssigns[index] = {...assign, 'val': val};
                 _updateStep(step.id, config: {...step.config, 'assignments': newAssigns});
              }, "Value")),
               IconButton(
                  icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                  onPressed: () {
                     final newAssigns = [...allAssigns]..removeAt(index);
                     _updateStep(step.id, config: {...step.config, 'assignments': newAssigns});
                  },
              )
           ],
        ),
     );
  }

  Widget _buildParameterExtractorConfig(PipelineStep step) {
     final schema = List<Map<String, dynamic>>.from(step.config['schema'] ?? []);
     final mode = step.config['mode'] ?? 'Function Calling';
     final model = step.config['model'] ?? 'gpt-4o';
     final inputVar = step.config['input_variable'] ?? '{{sys.query}}';
     final instructions = step.config['instructions'] ?? '';
     final memory = step.config['memory'] ?? false;
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("INPUT VARIABLE"),
           Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: Row(
                 children: [
                    Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                       child: const Row(
                          children: [
                             Icon(Icons.info_outline, size: 10, color: Colors.blueAccent),
                             SizedBox(width: 4),
                             Text("Generate Subtitles", style: TextStyle(color: Colors.white60, fontSize: 9)),
                          ],
                       ),
                    ),
                    const Text(" / ", style: TextStyle(color: Colors.white24, fontSize: 9)),
                    Expanded(
                       child: _buildTextField(inputVar, (val) {
                          _updateStep(step.id, config: {...step.config, 'input_variable': val});
                       }, "e.g. {{sys.query}}"),
                    ),
                    const SizedBox(width: 4),
                    const Text("String", style: TextStyle(color: Colors.white24, fontSize: 9)),
                 ],
              ),
           ),
           const SizedBox(height: 16),

           _buildSubtitle("MODEL"),
           Row(
              children: [
                 Expanded(
                    child: _buildDropdown(["gpt-4o", "claude-3-5-sonnet", "gemini-3-pro-preview"], model, (val) {
                       _updateStep(step.id, config: {...step.config, 'model': val});
                    }),
                 ),
                 const SizedBox(width: 8),
                 IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined, size: 16, color: Colors.white38),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                 ),
              ],
           ),
           const SizedBox(height: 16),

           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 _buildSubtitle("EXTRACT PARAMETERS"),
                 Row(
                    children: [
                       TextButton(
                          onPressed: () {},
                          child: const Text("Import from tools", style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
                       ),
                       IconButton(
                          onPressed: () {
                             final newSchema = [...schema, {'name': 'param', 'type': 'String', 'desc': '', 'required': true}];
                             _updateStep(step.id, config: {...step.config, 'schema': newSchema});
                          },
                          icon: const Icon(Icons.add, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                       ),
                    ],
                 ),
              ],
           ),
           const SizedBox(height: 8),
           ...schema.asMap().entries.map((entry) => _buildSchemaItem(step, schema, entry.key, entry.value)),
           const SizedBox(height: 16),

           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Row(
                    children: [
                       _buildSubtitle("INSTRUCTION"),
                       const Icon(Icons.help_outline, size: 12, color: Colors.white24),
                    ],
                 ),
                 Row(
                    children: [
                       Text("${instructions.length}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                       const SizedBox(width: 8),
                       const Icon(Icons.abc_outlined, size: 14, color: Colors.white24),
                       const SizedBox(width: 4),
                       const Icon(Icons.copy_outlined, size: 12, color: Colors.white24),
                       const SizedBox(width: 4),
                       const Icon(Icons.fullscreen, size: 14, color: Colors.white24),
                    ],
                 ),
              ],
           ),
           _buildTextArea(instructions, (val) {
              _updateStep(step.id, config: {...step.config, 'instructions': val});
           }, "Clear instructions describing what to extract and how to format it..."),
           const SizedBox(height: 16),

            Theme(
               data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
               child: ExpansionTile(
                  title: const Text("ADVANCED SETTING", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  iconColor: Colors.white38,
                  collapsedIconColor: Colors.white38,
                  children: [
                     SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                           segments: const [
                              ButtonSegment(value: 'Function Calling', label: Text('Function Call', style: TextStyle(fontSize: 10)), icon: Icon(Icons.code_outlined, size: 14)),
                              ButtonSegment(value: 'Prompt Engineering', label: Text('Prompt-based', style: TextStyle(fontSize: 10)), icon: Icon(Icons.abc_outlined, size: 14)),
                           ],
                           selected: {mode},
                           onSelectionChanged: (Set<String> newSelection) {
                              _updateStep(step.id, config: {...step.config, 'mode': newSelection.first});
                           },
                           style: SegmentedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              selectedBackgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                              selectedForegroundColor: Colors.blueAccent,
                              visualDensity: VisualDensity.compact,
                           ),
                        ),
                     ),
                     const SizedBox(height: 12),
                     _buildSwitchRow("Enable Memory", memory, (val) {
                        _updateStep(step.id, config: {...step.config, 'memory': val});
                     }, "Include conversation history for better context understanding"),
                  ],
               ),
            ),
            const SizedBox(height: 16),

            Theme(
               data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
               child: ExpansionTile(
                  title: const Text("OUTPUT VARIABLES", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  tilePadding: EdgeInsets.zero,
                  iconColor: Colors.white38,
                  collapsedIconColor: Colors.white38,
                  children: [
                     Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                           border: Border.all(color: Colors.white10),
                           borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              ...schema.map((s) => Padding(
                                 padding: const EdgeInsets.only(bottom: 6),
                                 child: Row(
                                    children: [
                                       const Icon(Icons.check_box_outline_blank, size: 10, color: Colors.blueAccent),
                                       const SizedBox(width: 8),
                                       Text(s['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                       const SizedBox(width: 8),
                                       Text((s['type'] ?? 'String').toLowerCase(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                       if (s['required'] == true) ...[
                                          const SizedBox(width: 4),
                                          const Text("*", style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                                       ],
                                    ],
                                 ),
                              )),
                              const Divider(color: Colors.white10, height: 16),
                              const Row(
                                 children: [
                                    Text("__is_success", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
                                    SizedBox(width: 8),
                                    Text("boolean", style: TextStyle(color: Colors.white24, fontSize: 9)),
                                 ],
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                 children: [
                                    Text("__reason", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
                                    SizedBox(width: 8),
                                    Text("string", style: TextStyle(color: Colors.white24, fontSize: 9)),
                                 ],
                              ),
                           ],
                        ),
                     ),
                  ],
               ),
            ),
        ],
     );
  }

  Widget _buildSchemaItem(PipelineStep step, List<Map<String, dynamic>> allSchema, int index, Map<String, dynamic> item) {
     
     return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
           color: Colors.white.withValues(alpha: 0.02),
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
           children: [
              Row(
                 children: [
                    const Icon(Icons.check_box_outline_blank, size: 12, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(item['name'] ?? '', (val) {
                       final newSchema = [...allSchema];
                       newSchema[index] = {...item, 'name': val};
                       _updateStep(step.id, config: {...step.config, 'schema': newSchema});
                    }, "Name")),
                    const SizedBox(width: 8),
                    Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                       child: Text(item['type'] ?? 'String', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                        onPressed: () {
                           final newSchema = [...allSchema]..removeAt(index);
                           _updateStep(step.id, config: {...step.config, 'schema': newSchema});
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                    )
                 ],
              ),
              const SizedBox(height: 8),
              _buildTextField(item['desc'] ?? '', (val) {
                  final newSchema = [...allSchema];
                  newSchema[index] = {...item, 'desc': val};
                  _updateStep(step.id, config: {...step.config, 'schema': newSchema});
              }, "Description"),
              const SizedBox(height: 8),
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     const Text("Required", style: TextStyle(color: Colors.white38, fontSize: 10)),
                     Transform.scale(
                        scale: 0.6,
                        child: Switch(
                           value: item['required'] ?? true,
                           onChanged: (val) {
                              final newSchema = [...allSchema];
                              newSchema[index] = {...item, 'required': val};
                              _updateStep(step.id, config: {...step.config, 'schema': newSchema});
                           },
                           activeThumbColor: Colors.blueAccent,
                        ),
                     ),
                  ],
               ),
            ],
         ),
      );
  }

  Widget _buildListOperatorConfig(PipelineStep step) {
    final inputVar = step.config['input_var'] ?? "{{input}}";
    final filters = List<Map<String, dynamic>>.from(step.config['filters'] ?? []);
    final sortAttr = step.config['sort_attr'] ?? 'None';
    final sortOrder = step.config['sort_order'] ?? 'ASC';
    final selection = step.config['selection'] ?? 'All';
    final takeN = step.config['take_n'] ?? 10;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("Input Variable"),
        _buildTextField(inputVar, (val) => _updateStep(step.id, config: {...step.config, 'input_var': val}), "{{array_var}}"),
        const SizedBox(height: 16),
        
        _buildSubtitle("Filter Conditions"),
        const Text("Filter elements by their attributes.", style: TextStyle(color: Colors.white24, fontSize: 10)),
        const SizedBox(height: 8),
        ...filters.asMap().entries.map((entry) => _buildListFilterItem(step, filters, entry.key, entry.value)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final newFilters = [...filters, {'attr': 'type', 'op': 'equals', 'val': 'image'}];
              _updateStep(step.id, config: {...step.config, 'filters': newFilters});
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text("Add Filter"),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
          ),
        ),
        const SizedBox(height: 16),
        
        _buildSubtitle("Sorting"),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(["None", "name", "size", "type", "extension"], sortAttr, (val) {
                _updateStep(step.id, config: {...step.config, 'sort_attr': val});
              }),
            ),
            const SizedBox(width: 8),
            if (sortAttr != 'None')
              SizedBox(
                width: 80,
                child: _buildDropdown(["ASC", "DESC"], sortOrder, (val) {
                  _updateStep(step.id, config: {...step.config, 'sort_order': val});
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        _buildSubtitle("Selection"),
        _buildDropdown(["All", "First Record", "Last Record", "Take First N"], selection, (val) {
          _updateStep(step.id, config: {...step.config, 'selection': val});
        }),
        if (selection == 'Take First N') ...[
          const SizedBox(height: 8),
          _buildTextField(takeN.toString(), (val) {
            _updateStep(step.id, config: {...step.config, 'take_n': int.tryParse(val) ?? 10});
          }, "Number of items (e.g. 5)"),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildListFilterItem(PipelineStep step, List<Map<String, dynamic>> allFilters, int index, Map<String, dynamic> filter) {
    final attrs = ['type', 'extension', 'size', 'name', 'mime_type', 'transfer_method'];
    final ops = ['equals', 'not equals', 'contains', 'not contains', 'starts_with', 'ends_with'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(attrs, filter['attr'] ?? 'type', (val) {
                  final newFilters = [...allFilters];
                  newFilters[index] = {...filter, 'attr': val};
                  _updateStep(step.id, config: {...step.config, 'filters': newFilters});
                }),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                onPressed: () {
                  final newFilters = [...allFilters]..removeAt(index);
                  _updateStep(step.id, config: {...step.config, 'filters': newFilters});
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDropdown(ops, filter['op'] ?? 'equals', (val) {
                  final newFilters = [...allFilters];
                  newFilters[index] = {...filter, 'op': val};
                  _updateStep(step.id, config: {...step.config, 'filters': newFilters});
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildTextField(filter['val'] ?? '', (val) {
                  final newFilters = [...allFilters];
                  newFilters[index] = {...filter, 'val': val};
                  _updateStep(step.id, config: {...step.config, 'filters': newFilters});
                }, "Value"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHttpRequestConfig(PipelineStep step) {
    final method = step.config['method'] ?? 'GET';
    final url = step.config['url'] ?? '';
    final headers = List<Map<String, dynamic>>.from(step.config['headers'] ?? []);
    final params = List<Map<String, dynamic>>.from(step.config['params'] ?? []);
    final bodyType = step.config['body_type'] ?? 'JSON';
    final body = step.config['body'] ?? '';
    final authType = step.config['auth_type'] ?? 'No Auth';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          _buildSubtitle("URL"),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: _buildDropdown(["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD"], method, (val) {
                  _updateStep(step.id, config: {...step.config, 'method': val});
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(url, (val) => _updateStep(step.id, config: {...step.config, 'url': val}), "https://api.example.com"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSubtitle("Headers"),
          _buildKeyValueList(step, headers, 'headers'),
          const SizedBox(height: 16),
          
          _buildSubtitle("Query Parameters"),
          _buildKeyValueList(step, params, 'params'),
          const SizedBox(height: 16),
          
          _buildSubtitle("Authentication"),
          _buildDropdown(["No Auth", "Bearer Token", "Basic Auth", "Custom Header"], authType, (val) {
             _updateStep(step.id, config: {...step.config, 'auth_type': val});
          }),
          if (authType != 'No Auth') ...[
             const SizedBox(height: 8),
             _buildAuthFields(step, authType),
          ],
          const SizedBox(height: 16),
          
          if (['POST', 'PUT', 'PATCH'].contains(method)) ...[
            _buildSubtitle("Request Body"),
            _buildDropdown(["JSON", "Form Data", "Raw Text", "Binary"], bodyType, (val) {
               _updateStep(step.id, config: {...step.config, 'body_type': val});
            }),
            const SizedBox(height: 8),
            _buildBodyEditor(step, bodyType, body),
            const SizedBox(height: 16),
          ],
          
          _buildSubtitle("Advanced Settings"),
          _buildAdvancedSettings(step),
          const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdvancedSettings(PipelineStep step) {
     final timeout = (step.config['timeout'] ?? 10.0).toDouble();
     final retries = step.config['retries'] ?? 0;
     final ssl = step.config['ssl_verify'] ?? true;
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
              children: [
                 const Expanded(child: Text("Timeout (seconds)", style: TextStyle(color: Colors.white60, fontSize: 10))),
                 SizedBox(
                    width: 60,
                    child: _buildTextField(timeout.toString(), (val) {
                       _updateStep(step.id, config: {...step.config, 'timeout': double.tryParse(val) ?? 10.0});
                    }),
                 ),
              ],
           ),
           const SizedBox(height: 8),
           Row(
              children: [
                 const Expanded(child: Text("Retries (on failure)", style: TextStyle(color: Colors.white60, fontSize: 10))),
                 SizedBox(
                    width: 60,
                    child: _buildTextField(retries.toString(), (val) {
                       _updateStep(step.id, config: {...step.config, 'retries': int.tryParse(val) ?? 0});
                    }),
                 ),
              ],
           ),
           const SizedBox(height: 8),
           Row(
              children: [
                 const Expanded(child: Text("Verify SSL", style: TextStyle(color: Colors.white60, fontSize: 10))),
                 Transform.scale(
                   scale: 0.7,
                   child: Switch(
                     value: ssl,
                     onChanged: (val) {
                       _updateStep(step.id, config: {...step.config, 'ssl_verify': val});
                     },
                     activeThumbColor: Colors.blueAccent,
                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                   ),
                 ),
              ],
           ),
        ],
     );
  }

  Widget _buildBodyEditor(PipelineStep step, String type, String body) {
     if (type == 'JSON' || type == 'Raw Text') {
        return SizedBox(
           height: 120,
           child: _buildTextArea(body, (val) {
              _updateStep(step.id, config: {...step.config, 'body': val});
           }, type == 'JSON' ? '{"key": "value"}' : 'Enter raw text...'),
        );
     } else if (type == 'Form Data') {
        final formItems = List<Map<String, dynamic>>.from(step.config['form_data'] ?? []);
        return _buildKeyValueList(step, formItems, 'form_data');
     } else if (type == 'Binary') {
        return _buildTextField(step.config['binary_file_var'] ?? '{{file}}', (val) {
           _updateStep(step.id, config: {...step.config, 'binary_file_var': val});
        }, "File Variable (e.g. {{upload}})");
     }
     return const SizedBox.shrink();
  }

  Widget _buildAuthFields(PipelineStep step, String authType) {
     if (authType == 'Bearer Token') {
        return _buildTextField(step.config['auth_token'] ?? '', (val) {
           _updateStep(step.id, config: {...step.config, 'auth_token': val});
        }, "Token");
     } else if (authType == 'Basic Auth') {
        return Column(
           children: [
              _buildTextField(step.config['auth_user'] ?? '', (val) {
                 _updateStep(step.id, config: {...step.config, 'auth_user': val});
              }, "Username"),
              const SizedBox(height: 8),
              _buildTextField(step.config['auth_pass'] ?? '', (val) {
                 _updateStep(step.id, config: {...step.config, 'auth_pass': val});
              }, "Password"),
           ],
        );
     } else if (authType == 'Custom Header') {
        return Column(
           children: [
              _buildTextField(step.config['auth_header_name'] ?? 'X-API-Key', (val) {
                 _updateStep(step.id, config: {...step.config, 'auth_header_name': val});
              }, "Header Name"),
              const SizedBox(height: 8),
              _buildTextField(step.config['auth_header_value'] ?? '', (val) {
                 _updateStep(step.id, config: {...step.config, 'auth_header_value': val});
              }, "Header Value"),
           ],
        );
     }
     return const SizedBox.shrink();
  }

   Widget _buildUserInputConfig(PipelineStep step) {
    final fields = List<Map<String, dynamic>>.from(step.config['fields'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("System Variables"),
        const Text("userinput.files (Legacy), userinput.query (Chatflow)", style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),
        _buildSubtitle("Input Fields"),
        ...fields.asMap().entries.map((entry) => _buildUserInputFieldItem(step, fields, entry.key, entry.value)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
               final newFields = [...fields, {'name': 'variable', 'type': 'text', 'label': 'Label', 'required': true, 'hidden': false}];
               _updateStep(step.id, config: {...step.config, 'fields': newFields});
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text("Add Field"),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInputFieldItem(PipelineStep step, List<Map<String, dynamic>> allFields, int index, Map<String, dynamic> field) {
      final type = field['type'] ?? 'text';
      final isRequired = field['required'] ?? true;
      final isHidden = field['hidden'] ?? false;
      final options = List<String>.from(field['options'] ?? []);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField(field['name'] ?? '', (val) {
                   final newFields = [...allFields];
                   newFields[index] = {...field, 'name': val};
                   _updateStep(step.id, config: {...step.config, 'fields': newFields});
                }, "Variable Name")),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: _buildDropdown(["text", "paragraph", "select", "number", "checkbox", "file", "file_list"], type, (val) {
                     final newFields = [...allFields];
                     newFields[index] = {...field, 'type': val};
                     _updateStep(step.id, config: {...step.config, 'fields': newFields});
                  }),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                  onPressed: () {
                     final newFields = [...allFields]..removeAt(index);
                     _updateStep(step.id, config: {...step.config, 'fields': newFields});
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(field['label'] ?? '', (val) {
               final newFields = [...allFields];
               newFields[index] = {...field, 'label': val};
               _updateStep(step.id, config: {...step.config, 'fields': newFields});
            }, "Field Label"),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Required", style: TextStyle(color: Colors.white60, fontSize: 10)),
                Transform.scale(
                  scale: 0.6,
                  child: Switch(
                    value: isRequired, 
                    activeThumbColor: Colors.blueAccent,
                    onChanged: (val) {
                      final newFields = [...allFields];
                      newFields[index] = {...field, 'required': val};
                      _updateStep(step.id, config: {...step.config, 'fields': newFields});
                    }
                  ),
                ),
                const Spacer(),
                const Text("Hidden", style: TextStyle(color: Colors.white60, fontSize: 10)),
                Transform.scale(
                  scale: 0.6,
                  child: Switch(
                    value: isHidden, 
                    activeThumbColor: Colors.blueAccent,
                    onChanged: isRequired ? null : (val) {
                      final newFields = [...allFields];
                      newFields[index] = {...field, 'hidden': val};
                      _updateStep(step.id, config: {...step.config, 'fields': newFields});
                    }
                  ),
                ),
              ],
            ),
            if (type == 'select') ...[
              const SizedBox(height: 8),
              _buildSubtitle("Options (comma separated)"),
              _buildTextField(options.join(', '), (val) {
                final newFields = [...allFields];
                newFields[index] = {...field, 'options': val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()};
                _updateStep(step.id, config: {...step.config, 'fields': newFields});
              }, "Option 1, Option 2, etc"),
            ],
            if (type == 'file' || type == 'file_list') ...[
              const SizedBox(height: 4),
              const Text("Files will be accessible as metadata objects.", style: TextStyle(color: Colors.white24, fontSize: 9)),
            ]
          ],
        ),
      );
  }

  Widget _buildTriggerConfig(PipelineStep step) {
    final triggerType = step.config['trigger_type'] ?? 'Schedule';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("Trigger Type"),
        _buildDropdown(["Schedule", "Webhook", "Plugin"], triggerType, (val) {
           _updateStep(step.id, config: {...step.config, 'trigger_type': val});
        }),
        const SizedBox(height: 16),
        
        if (triggerType == 'Schedule') ...[
           _buildScheduleConfig(step),
        ] else if (triggerType == 'Webhook') ...[
           _buildWebhookConfig(step),
        ] else if (triggerType == 'Plugin') ...[
           _buildPluginConfig(step),
        ],
        
        const SizedBox(height: 16),
        const Text("System Variables: sys.timestamp, sys.user_id automatically populated.", style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildScheduleConfig(PipelineStep step) {
     final mode = step.config['schedule_mode'] ?? 'Cron'; // Cron or Frequency
     final cron = step.config['cron'] ?? '0 9 * * MON-FRI';
     final freq = step.config['frequency'] ?? 'Daily';
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
              children: [
                 _buildSubtitle("Schedule Mode"),
                 const Spacer(),
                 SegmentedButton<String>(
                    segments: const [
                       ButtonSegment(value: 'Frequency', label: Text('Freq', style: TextStyle(fontSize: 10))),
                       ButtonSegment(value: 'Cron', label: Text('Cron', style: TextStyle(fontSize: 10))),
                    ],
                    selected: {mode},
                    onSelectionChanged: (val) {
                       _updateStep(step.id, config: {...step.config, 'schedule_mode': val.first});
                    },
                    style: SegmentedButton.styleFrom(
                       visualDensity: VisualDensity.compact,
                       padding: EdgeInsets.zero,
                       backgroundColor: Colors.black26,
                       selectedBackgroundColor: Colors.blueAccent.withValues(alpha: 0.3),
                    ),
                 ),
              ],
           ),
           const SizedBox(height: 12),
           if (mode == 'Frequency') ...[
              _buildDropdown(['Hourly', 'Daily', 'Weekly', 'Monthly'], freq, (val) {
                 _updateStep(step.id, config: {...step.config, 'frequency': val});
              }),
              if (freq == 'Weekly') ...[
                 const SizedBox(height: 8),
                 _buildSubtitle("On Days"),
                 _buildTextField(step.config['days'] ?? 'MON, WED, FRI', (val) => _updateStep(step.id, config: {...step.config, 'days': val}), "e.g. MON, TUE"),
              ],
              if (freq == 'Monthly') ...[
                 const SizedBox(height: 8),
                 _buildSubtitle("On Dates"),
                 _buildTextField(step.config['dates'] ?? '1, 15', (val) => _updateStep(step.id, config: {...step.config, 'dates': val}), "e.g. 1, 15, L"),
              ],
           ] else ...[
              _buildTextField(cron, (val) => _updateStep(step.id, config: {...step.config, 'cron': val}), "0 9 * * *"),
              const SizedBox(height: 8),
              Wrap(
                 spacing: 4,
                 children: ['@hourly', '@daily', '@weekly', '@monthly', '@yearly'].map((e) => ActionChip(
                    label: Text(e, style: const TextStyle(fontSize: 9)),
                    onPressed: () => _updateStep(step.id, config: {...step.config, 'cron': e}),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: EdgeInsets.zero,
                 )).toList(),
              ),
           ],
        ],
     );
  }

  Widget _buildPluginConfig(PipelineStep step) {
     final plugin = step.config['plugin_id'] ?? 'Github';
     final event = step.config['event_type'] ?? 'Star Event';
     final auth = step.config['auth_method'] ?? 'OAuth';
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Plugin"),
           _buildDropdown(['Github', 'Slack', 'Gmail', 'Notion'], plugin, (val) {
              _updateStep(step.id, config: {...step.config, 'plugin_id': val});
           }),
           const SizedBox(height: 12),
           _buildSubtitle("Event Type"),
           _buildDropdown(['Star Event', 'New Message', 'Form Submitted', 'Webhook Incoming'], event, (val) {
              _updateStep(step.id, config: {...step.config, 'event_type': val});
           }),
           const SizedBox(height: 12),
           _buildSubtitle("Authentication"),
           _buildDropdown(['OAuth', 'API Key', 'Personal Access Token'], auth, (val) {
              _updateStep(step.id, config: {...step.config, 'auth_method': val});
           }),
           const SizedBox(height: 12),
           OutlinedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.add, size: 14),
              label: const Text("Manage Subscriptions", style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
           ),
        ],
     );
  }

  Widget _buildWebhookConfig(PipelineStep step) {
     final method = step.config['method'] ?? 'POST';
     final contentType = step.config['content_type'] ?? 'application/json';
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Endpoint"),
           const Text("Production URL", style: TextStyle(color: Colors.white60, fontSize: 10)),
           const Text("https://api.inhaus.brain/webhook/prod-xxx", style: TextStyle(color: Colors.blueAccent, fontSize: 11)),
           const SizedBox(height: 8),
           const Text("Test URL", style: TextStyle(color: Colors.white60, fontSize: 10)),
           const Text("https://api.inhaus.brain/webhook/test-xxx", style: TextStyle(color: Colors.blueAccent, fontSize: 11)),
           const SizedBox(height: 16),
           
           Row(
              children: [
                 Expanded(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          _buildSubtitle("HTTP Method"),
                          _buildDropdown(['POST', 'GET', 'PUT', 'DELETE'], method, (val) {
                             _updateStep(step.id, config: {...step.config, 'method': val});
                          }),
                       ],
                    ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          _buildSubtitle("Content Type"),
                          _buildDropdown(['application/json', 'multipart/form-data', 'application/x-www-form-urlencoded', 'text/plain'], contentType, (val) {
                             _updateStep(step.id, config: {...step.config, 'content_type': val});
                          }),
                       ],
                    ),
                 ),
              ],
           ),
           const SizedBox(height: 16),
           
           _buildSubtitle("Parameter Extraction"),
           _buildWebhookParameterList(step, 'header', "Header Parameters"),
           const SizedBox(height: 12),
           _buildWebhookParameterList(step, 'query', "Query Parameters"),
           const SizedBox(height: 12),
           _buildWebhookParameterList(step, 'body', "Body Parameters"),
           
           const SizedBox(height: 16),
           _buildWebhookResponseConfig(step),
        ],
     );
  }

  Widget _buildWebhookParameterList(PipelineStep step, String category, String label) {
     final key = 'webhook_$category';
     final params = List<Map<String, dynamic>>.from(step.config[key] ?? []);
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           ...params.asMap().entries.map((entry) {
              final idx = entry.key;
              final param = entry.value;
              return Container(
                 margin: const EdgeInsets.only(bottom: 8),
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                 child: Column(
                    children: [
                       Row(
                          children: [
                             Expanded(child: _buildTextField(param['name'] ?? '', (val) {
                                final newParams = [...params];
                                newParams[idx] = {...param, 'name': val};
                                _updateStep(step.id, config: {...step.config, key: newParams});
                             }, "Key")),
                             const SizedBox(width: 8),
                             if (category != 'header') 
                                SizedBox(width: 80, child: _buildDropdown(['String', 'Number', 'Boolean', 'Object', 'Array', 'File'], param['type'] ?? 'String', (val) {
                                   final newParams = [...params];
                                   newParams[idx] = {...param, 'type': val};
                                   _updateStep(step.id, config: {...step.config, key: newParams});
                                })),
                             IconButton(
                                icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                                onPressed: () {
                                   final newParams = [...params]..removeAt(idx);
                                   _updateStep(step.id, config: {...step.config, key: newParams});
                                },
                             ),
                          ],
                       ),
                       Row(
                          children: [
                             const Text("Required", style: TextStyle(color: Colors.white60, fontSize: 10)),
                             Transform.scale(
                                scale: 0.6,
                                child: Switch(
                                   value: param['required'] ?? true,
                                   activeThumbColor: Colors.blueAccent,
                                   onChanged: (val) {
                                      final newParams = [...params];
                                      newParams[idx] = {...param, 'required': val};
                                      _updateStep(step.id, config: {...step.config, key: newParams});
                                   },
                                ),
                             ),
                          ],
                       ),
                    ],
                 ),
              );
           }),
           OutlinedButton.icon(
              onPressed: () {
                 final newParams = [...params, {'name': '', 'type': 'String', 'required': true}];
                 _updateStep(step.id, config: {...step.config, key: newParams});
              },
              icon: const Icon(Icons.add, size: 12),
              label: const Text("Add Parameter", style: TextStyle(fontSize: 10)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10), minimumSize: const Size(0, 32)),
           ),
        ],
     );
  }

  Widget _buildWebhookResponseConfig(PipelineStep step) {
     final code = step.config['response_code'] ?? 200;
     final body = step.config['response_body'] ?? '{"message": "OK"}';
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Custom Response"),
           Row(
              children: [
                 const Text("Status Code", style: TextStyle(color: Colors.white60, fontSize: 10)),
                 const SizedBox(width: 12),
                 SizedBox(
                    width: 60,
                    child: _buildTextField(code.toString(), (val) {
                       _updateStep(step.id, config: {...step.config, 'response_code': int.tryParse(val) ?? 200});
                    }),
                 ),
              ],
           ),
           const SizedBox(height: 12),
           const Text("Response Body", style: TextStyle(color: Colors.white60, fontSize: 10)),
           const SizedBox(height: 4),
           _buildTextArea(body, (val) {
              _updateStep(step.id, config: {...step.config, 'response_body': val});
           }, "JSON or plain text"),
        ],
     );
  }

  Widget _buildAnswerConfig(PipelineStep step) {
    final template = step.config['answer_template'] ?? 'Result: {{llm_result}}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("Final Answer Template"),
        SizedBox(
          height: 200,
          child: _buildTextArea(template, (val) => _updateStep(step.id, config: {...step.config, 'answer_template': val})),
        ),
        const SizedBox(height: 8),
        const Text("Use {{variable}} to inject workflow results.", style: TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _buildOutputConfig(PipelineStep step) {
    final outputs = List<Map<String, dynamic>>.from(step.config['outputs'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("Workflow Outputs"),
        ...outputs.asMap().entries.map((entry) => _buildOutputMappingItem(step, outputs, entry.key, entry.value)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
               final newOutputs = [...outputs, {'key': 'result', 'value': '{{llm_output}}'}];
               _updateStep(step.id, config: {...step.config, 'outputs': newOutputs});
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text("Add Output Variable"),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputMappingItem(PipelineStep step, List<Map<String, dynamic>> allOutputs, int index, Map<String, dynamic> output) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 8),
       child: Row(
         children: [
           Expanded(child: _buildTextField(output['key'] ?? '', (val) {
              final newOutputs = [...allOutputs];
              newOutputs[index] = {...output, 'key': val};
              _updateStep(step.id, config: {...step.config, 'outputs': newOutputs});
           }, "Key (e.g. status)")),
           const SizedBox(width: 8),
           const Icon(Icons.arrow_right_alt, color: Colors.blueAccent, size: 14),
           const SizedBox(width: 8),
           Expanded(child: _buildTextField(output['value'] ?? '', (val) {
              final newOutputs = [...allOutputs];
              newOutputs[index] = {...output, 'value': val};
              _updateStep(step.id, config: {...step.config, 'outputs': newOutputs});
           }, "Variable (e.g. {{res}})")),
           IconButton(
             icon: const Icon(Icons.close, size: 14, color: Colors.white24),
             onPressed: () {
                final newOutputs = [...allOutputs]..removeAt(index);
                _updateStep(step.id, config: {...step.config, 'outputs': newOutputs});
             },
           ),
         ],
       ),
     );
  }

  Widget _buildAgentConfig(PipelineStep step) {
    final strategy = step.config['strategy'] ?? 'Function Calling';
    final model = step.config['model'] ?? 'Gemini 1.5 Pro';
    final maxIters = step.config['max_iterations'] ?? 5;
    
    // Filter MessageSender values to only include agents
    final agentBrains = MessageSender.values
        .where((e) => e.name.contains('Agent'))
        .map((e) => e.name)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("Agent Brain"),
        _buildDropdown(agentBrains, step.agentType?.name ?? MessageSender.researchAgent.name, (val) {
           final sender = MessageSender.values.firstWhere((e) => e.name == val);
           _updateStep(step.id, agentType: sender);
        }),
        const SizedBox(height: 16),
        _buildSubtitle("Reasoning Strategy"),
        _buildDropdown(["Function Calling", "ReAct"], strategy, (val) => _updateStep(step.id, config: {...step.config, 'strategy': val})),
        const SizedBox(height: 16),
        _buildSubtitle("Model"),
        _buildDropdown(["Gemini 1.5 Pro", "GPT-4o", "Claude 3.5 Sonnet"], model, (val) => _updateStep(step.id, config: {...step.config, 'model': val})),
        const SizedBox(height: 16),
        _buildSubtitle("Max Iterations: $maxIters"),
        Slider(
          value: maxIters.toDouble(),
          min: 1, max: 20,
          onChanged: (val) => _updateStep(step.id, config: {...step.config, 'max_iterations': val.toInt()}),
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildStartConfig(PipelineStep step) {
    return _buildUserInputConfig(step); // Reusing User Input UI for now as Start node usually handles inputs
  }

  Widget _buildNoteConfig(PipelineStep step) {
    final text = step.config['text'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("Note Text"),
        _buildTextArea(text, (val) {
          _updateStep(step.id, config: {...step.config, 'text': val});
        }, "Enter your notes here..."),
      ],
    );
  }

  Widget _buildToolConfig(PipelineStep step) {
     final availableTools = ref.watch(availableToolsProvider);
     final toolId = step.config['tool_id'] ?? (availableTools.isNotEmpty ? availableTools.first.id : 'google_search');
     final retries = step.config['retries'] ?? 3;
     final customParams = List<Map<String, dynamic>>.from(step.config['params'] ?? []);
     
     final toolNames = availableTools.map((t) => t.id).toList();
     if (!toolNames.contains(toolId)) toolNames.add(toolId);

     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Select Tool"),
           _buildDropdown(toolNames, toolId, (val) => _updateStep(step.id, config: {...step.config, 'tool_id': val!})),
           if (availableTools.any((t) => t.id == toolId)) 
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  availableTools.firstWhere((t) => t.id == toolId).description,
                  style: const TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
                ),
              ),
           const SizedBox(height: 16),
           _buildSubtitle("Tool Parameters"),
           _buildKeyValueList(step, customParams, 'params'),
           const SizedBox(height: 16),
           _buildSubtitle("Retry Attempts"),
           _buildTextField(retries.toString(), (val) => _updateStep(step.id, config: {...step.config, 'retries': int.tryParse(val) ?? 3})),
        ],
     );
  }

  Widget _buildQuestionClassifierConfig(PipelineStep step) {
    final categories = List<Map<String, dynamic>>.from(step.config['categories'] ?? []);
    final inputVar = step.config['input_var'] ?? '{{input}}';
    final model = step.config['model'] ?? 'Gemini 1.5 Pro';

    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          _buildSubtitle("Input Variable"),
          _buildTextField(inputVar, (val) => _updateStep(step.id, config: {...step.config, 'input_var': val})),
          const SizedBox(height: 16),
          _buildSubtitle("Model"),
          _buildDropdown(["Gemini 1.5 Pro", "GPT-4o", "Claude 3.5 Sonnet"], model, (val) => _updateStep(step.id, config: {...step.config, 'model': val})),
          const SizedBox(height: 16),
          _buildSubtitle("Classification Categories"),
          ...categories.asMap().entries.map((entry) => _buildClassifierCategoryItem(step, categories, entry.key, entry.value)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                 final newCats = [...categories, {'name': 'billing', 'desc': 'User asking about money'}];
                 _updateStep(step.id, config: {...step.config, 'categories': newCats});
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text("Add Category"),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
            ),
          ),
       ],
    );
  }

  Widget _buildClassifierCategoryItem(PipelineStep step, List<Map<String, dynamic>> allCats, int index, Map<String, dynamic> cat) {
     return Container(
       margin: const EdgeInsets.only(bottom: 12),
       padding: const EdgeInsets.all(8),
       decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
       child: Column(
         children: [
            Row(
              children: [
                Expanded(child: _buildTextField(cat['name'] ?? '', (val) {
                   final newCats = [...allCats];
                   newCats[index] = {...cat, 'name': val};
                   _updateStep(step.id, config: {...step.config, 'categories': newCats});
                }, "Category Name")),
                IconButton(
                  icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                  onPressed: () {
                     final newCats = [...allCats]..removeAt(index);
                     _updateStep(step.id, config: {...step.config, 'categories': newCats});
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(cat['desc'] ?? '', (val) {
               final newCats = [...allCats];
               newCats[index] = {...cat, 'desc': val};
               _updateStep(step.id, config: {...step.config, 'categories': newCats});
            }, "Description for LLM"),
         ],
       ),
     );
  }

  Widget _buildKeyValueList(PipelineStep step, List<Map<String, dynamic>> items, String key) {
     return Column(
        children: [
           ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Padding(
                 padding: const EdgeInsets.only(bottom: 8),
                 child: Row(
                    children: [
                       Expanded(
                          child: _buildTextField(item['key'] ?? '', (val) {
                             final newItems = List<Map<String, dynamic>>.from(items);
                             newItems[idx] = {...item, 'key': val};
                             _updateStep(step.id, config: {...step.config, key: newItems});
                          }, "Key"),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                          child: _buildTextField(item['value'] ?? '', (val) {
                             final newItems = List<Map<String, dynamic>>.from(items);
                             newItems[idx] = {...item, 'value': val};
                             _updateStep(step.id, config: {...step.config, key: newItems});
                          }, "Value"),
                       ),
                       IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 14, color: Colors.white24),
                          onPressed: () {
                             final newItems = List<Map<String, dynamic>>.from(items)..removeAt(idx);
                             _updateStep(step.id, config: {...step.config, key: newItems});
                          },
                       )
                    ],
                 ),
              );
           }),
           SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                   final newItems = [...items, {'key': '', 'value': ''}];
                   _updateStep(step.id, config: {...step.config, key: newItems});
                },
                icon: const Icon(Icons.add, size: 12),
                label: Text("Add ${key == 'headers' ? 'Header' : 'Param'}", style: const TextStyle(fontSize: 10)),
              ),
           ),
        ],
     );
  }

}

class _ManagedTextField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hintText;

  const _ManagedTextField({
    required this.initialValue,
    required this.onChanged,
    this.hintText,
  });

  @override
  State<_ManagedTextField> createState() => _ManagedTextFieldState();
}

class _ManagedTextFieldState extends State<_ManagedTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_ManagedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      if (widget.initialValue.isNotEmpty) {
         _controller.selection = TextSelection.collapsed(offset: widget.initialValue.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black,
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
      ),
    );
  }
}

class _ManagedTextArea extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hintText;

  const _ManagedTextArea({
    required this.initialValue,
    required this.onChanged,
    this.hintText,
  });

  @override
  State<_ManagedTextArea> createState() => _ManagedTextAreaState();
}

class _ManagedTextAreaState extends State<_ManagedTextArea> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_ManagedTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
       if (widget.initialValue.isNotEmpty) {
         _controller.selection = TextSelection.collapsed(offset: widget.initialValue.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
      maxLines: null,
      expands: false,
      minLines: 3,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black,
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
      ),
    );
  }
}

