import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/adk/models/pipeline_models.dart';
import '../../chat/models/chat_models.dart';

class NodeConfigurationSheet extends StatefulWidget {
  final PipelineStep step;
  final List<PipelineStep> allSteps; // Required for resolving dependency names
  final Function(String stepId, {Map<String, dynamic>? config, String? instruction, MessageSender? agentType, Map<String, String>? inputMappings}) onUpdate;

  const NodeConfigurationSheet({
    super.key,
    required this.step,
    required this.allSteps,
    required this.onUpdate,
  });

  @override
  State<NodeConfigurationSheet> createState() => _NodeConfigurationSheetState();
}

class _NodeConfigurationSheetState extends State<NodeConfigurationSheet> {
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
                onPressed: () => Navigator.of(context).pop(),
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
        return _buildHTTPConfig(step);
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
    }
  }

  // --- Helper Widgets ---

  Widget _buildSubtitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(String initialValue, Function(String) onChanged, [String? hintText]) {
    return TextField(
      controller: TextEditingController(text: initialValue)..selection = TextSelection.collapsed(offset: initialValue.length),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTextArea(String initialValue, Function(String) onChanged, [String? hintText]) {
    return TextField(
      controller: TextEditingController(text: initialValue)..selection = TextSelection.collapsed(offset: initialValue.length),
      style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
      maxLines: null,
      expands: false,
      minLines: 3,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
      ),
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
    final model = step.config['model'] ?? 'Gemini 1.5 Pro';
    final temp = (step.config['temperature'] ?? 0.7).toDouble();
    final topP = (step.config['top_p'] ?? 0.9).toDouble();
    final jsonMode = step.config['json_mode'] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("Model"),
        _buildDropdown(["Gemini 1.5 Pro", "GPT-4o", "Claude 3.5 Sonnet", "Grok Beta"], model, (val) {
           _updateStep(step.id, config: {...step.config, 'model': val});
        }),
        const SizedBox(height: 16),
        _buildSubtitle("Parameters"),
        Row(
           children: [
              const Text("Temp", style: TextStyle(color: Colors.white70, fontSize: 10)),
              Expanded(
                 child: Slider(
                    value: temp, min: 0, max: 2, divisions: 20, 
                    activeColor: Colors.blueAccent,
                    onChanged: (val) => _updateStep(step.id, config: {...step.config, 'temperature': val})
                 ),
              ),
              Text(temp.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 10)),
           ],
        ),
        Row(
           children: [
              const Text("Top P", style: TextStyle(color: Colors.white70, fontSize: 10)),
              Expanded(
                 child: Slider(
                    value: topP, min: 0, max: 1, divisions: 10,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) => _updateStep(step.id, config: {...step.config, 'top_p': val})
                 ),
              ),
              Text(topP.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 10)),
           ],
        ),
        const SizedBox(height: 8),
        Row(
           children: [
              const Expanded(child: Text("Structured JSON Output", style: TextStyle(color: Colors.white70, fontSize: 11))),
              Transform.scale(
                 scale: 0.7,
                 child: Switch(
                    value: jsonMode,
                    activeThumbColor: Colors.blueAccent,
                    onChanged: (val) => _updateStep(step.id, config: {...step.config, 'json_mode': val}),
                 ),
              ),
           ],
        ),
        const SizedBox(height: 16),
        _buildPromptConfig(step, prompts),
      ],
    );
  }

  Widget _buildPromptConfig(PipelineStep step, List<Map<String, dynamic>> prompts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("Prompts"),
        ...prompts.asMap().entries.map((entry) => _buildPromptMessageItem(step, prompts, entry.key, entry.value)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
               final newPrompts = [...prompts, {'role': 'user', 'content': ''}];
               _updateStep(step.id, config: {...step.config, 'prompts': newPrompts});
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text("Add Message"),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptMessageItem(PipelineStep step, List<Map<String, dynamic>> allPrompts, int index, Map<String, dynamic> prompt) {
     return Container(
       margin: const EdgeInsets.only(bottom: 12),
       padding: const EdgeInsets.all(8),
       decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
       child: Column(
         children: [
           Row(
             children: [
               SizedBox(
                 width: 80,
                 child: _buildDropdown(["system", "user", "assistant"], prompt['role'] ?? 'user', (val) {
                    final newPrompts = [...allPrompts];
                    newPrompts[index] = {...prompt, 'role': val};
                    _updateStep(step.id, config: {...step.config, 'prompts': newPrompts});
                 }),
               ),
               const Spacer(),
               IconButton(
                 icon: const Icon(Icons.close, size: 14, color: Colors.white38),
                 onPressed: () {
                    final newPrompts = [...allPrompts]..removeAt(index);
                    _updateStep(step.id, config: {...step.config, 'prompts': newPrompts});
                 },
               ),
             ],
           ),
           const SizedBox(height: 8),
           _buildTextArea(prompt['content'] ?? '', (val) {
              final newPrompts = [...allPrompts];
              newPrompts[index] = {...prompt, 'content': val};
              _updateStep(step.id, config: {...step.config, 'prompts': newPrompts});
           }, "Enter prompt message..."),
         ],
       ),
     );
  }

  Widget _buildKnowledgeRetrievalConfig(PipelineStep step) {
    final query = step.config['query'] ?? '{{input}}';
    final topK = step.config['top_k'] ?? 3;
    final scoreThreshold = (step.config['score_threshold'] ?? 0.7).toDouble();
    final reranking = step.config['reranking'] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle("Query Variable"),
        _buildTextField(query, (val) => _updateStep(step.id, config: {...step.config, 'query': val})),
        const SizedBox(height: 16),
        _buildSubtitle("Retrieval Settings"),
        Row(
           children: [
              Expanded(child: _buildTextField(topK.toString(), (val) => _updateStep(step.id, config: {...step.config, 'top_k': int.tryParse(val) ?? 3}), "Top K")),
              const SizedBox(width: 8),
              Expanded(child: _buildTextField(scoreThreshold.toString(), (val) => _updateStep(step.id, config: {...step.config, 'score_threshold': double.tryParse(val) ?? 0.7}), "Threshold")),
           ],
        ),
        const SizedBox(height: 16),
        Row(
           children: [
              const Expanded(child: Text("Enable Reranking (Cohere)", style: TextStyle(color: Colors.white70, fontSize: 11))),
              Transform.scale(
                 scale: 0.7,
                 child: Switch(
                    value: reranking,
                    activeThumbColor: Colors.blueAccent,
                    onChanged: (val) => _updateStep(step.id, config: {...step.config, 'reranking': val}),
                 ),
              ),
           ],
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
    
    return SingleChildScrollView(
      child: Column(
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
      ),
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
    
    return SingleChildScrollView(
       child: Column(
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
       ),
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
     final variable = step.config['variable'] ?? '{{upload}}';
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Processing Mode"),
           _buildDropdown(["single", "multiple"], mode, (val) {
              _updateStep(step.id, config: {...step.config, 'mode': val});
           }),
           const SizedBox(height: 16),
           _buildSubtitle("Input File Variable"),
           _buildTextField(variable, (val) {
              _updateStep(step.id, config: {...step.config, 'variable': val});
           }),
           const SizedBox(height: 8),
           const Text("Supported: PDF, DOCX, TXT, CSV, EML, etc.", style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
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
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Extraction Mode"),
           _buildDropdown(['Function Calling', 'Prompt Engineering'], mode, (val) {
              _updateStep(step.id, config: {...step.config, 'mode': val});
           }),
           const SizedBox(height: 16),
           _buildSubtitle("Schema Definition"),
           ...schema.asMap().entries.map((entry) => _buildSchemaItem(step, schema, entry.key, entry.value)),
           SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                 onPressed: () {
                    final newSchema = [...schema, {'name': 'param', 'type': 'String', 'desc': ''}];
                    _updateStep(step.id, config: {...step.config, 'schema': newSchema});
                 },
                 icon: const Icon(Icons.add, size: 14),
                 label: const Text("Add Parameter"),
                 style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
              ),
           ),
        ],
     );
  }

  Widget _buildSchemaItem(PipelineStep step, List<Map<String, dynamic>> allSchema, int index, Map<String, dynamic> item) {
     return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
        child: Column(
           children: [
              Row(
                 children: [
                    Expanded(child: _buildTextField(item['name'] ?? '', (val) {
                       final newSchema = [...allSchema];
                       newSchema[index] = {...item, 'name': val};
                       _updateStep(step.id, config: {...step.config, 'schema': newSchema});
                    }, "Param Name")),
                    const SizedBox(width: 8),
                    SizedBox(width: 80, child: _buildDropdown(['String', 'Number', 'Boolean', 'Array', 'Object'], item['type'] ?? 'String', (val) {
                       final newSchema = [...allSchema];
                       newSchema[index] = {...item, 'type': val};
                       _updateStep(step.id, config: {...step.config, 'schema': newSchema});
                    })),
                    IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                        onPressed: () {
                           final newSchema = [...allSchema]..removeAt(index);
                           _updateStep(step.id, config: {...step.config, 'schema': newSchema});
                        },
                    )
                 ],
              ),
              const SizedBox(height: 4),
              _buildTextField(item['desc'] ?? '', (val) {
                  final newSchema = [...allSchema];
                  newSchema[index] = {...item, 'desc': val};
                  _updateStep(step.id, config: {...step.config, 'schema': newSchema});
              }, "Description"),
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
    
    return SingleChildScrollView(
      child: Column(
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
      ),
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

  Widget _buildHTTPConfig(PipelineStep step) {
    final method = step.config['method'] ?? 'GET';
    final url = step.config['url'] ?? '';
    final headers = List<Map<String, dynamic>>.from(step.config['headers'] ?? []);
    final params = List<Map<String, dynamic>>.from(step.config['params'] ?? []);
    final bodyType = step.config['body_type'] ?? 'JSON';
    final body = step.config['body'] ?? '';
    final authType = step.config['auth_type'] ?? 'No Auth';
    
    return SingleChildScrollView(
      child: Column(
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
      ),
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
                     activeColor: Colors.blueAccent,
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
        _buildSubtitle("Input Fields"),
        ...fields.asMap().entries.map((entry) => _buildUserInputFieldItem(step, fields, entry.key, entry.value)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
               final newFields = [...fields, {'name': 'variable', 'type': 'text', 'label': 'Label'}];
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
                 child: _buildDropdown(["text", "paragraph", "select", "number", "checkbox"], field['type'] ?? 'text', (val) {
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
           _buildSubtitle("Cron Expression"),
           _buildTextField(step.config['cron'] ?? '0 9 * * MON-FRI', (val) => _updateStep(step.id, config: {...step.config, 'cron': val})),
        ] else if (triggerType == 'Webhook') ...[
           _buildSubtitle("Webhook URL"),
           const Text("https://api.inhaus.brain/webhook/xxx", style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
        ],
        const SizedBox(height: 16),
        const Text("System Variables: sys.timestamp, sys.user_id automatically populated.", style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic)),
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

  Widget _buildToolConfig(PipelineStep step) {
     final toolId = step.config['tool_id'] ?? 'google_search';
     final retries = step.config['retries'] ?? 3;
     final customParams = List<Map<String, dynamic>>.from(step.config['params'] ?? []);
     
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSubtitle("Select Tool"),
           _buildDropdown(["google_search", "web_scraper", "slack_notify", "gmail_send", "custom_webhook"], toolId, (val) => _updateStep(step.id, config: {...step.config, 'tool_id': val})),
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
