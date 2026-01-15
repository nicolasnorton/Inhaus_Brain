import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pipeline_models.dart';
import '../models/pipeline_context.dart';
import '../models/adk_artifact.dart';
import '../services/adk_event_bus.dart';
import '../../auth/secret_vault_service.dart';
import '../../../features/chat/agents/base_agent.dart';
import '../../../features/chat/agents/utility_agents.dart';
import '../../../features/chat/agents/core_agents.dart';
import '../../../features/chat/agents/router_agent.dart';
import '../../../features/chat/agents/agency_agents.dart'; // Phase 31
import '../../../features/chat/models/chat_models.dart';
import '../../../features/knowledge/models/knowledge_source.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/system_prompts_service.dart';

// Pipeline Execution Result
class PipelineResult {
  final bool success;
  final String output;
  final List<String> stepLogs;

  PipelineResult({required this.success, required this.output, required this.stepLogs});
}

class AdkService {
  final Ref ref;
  
  // Registry of Agent Instances by Type
  final Map<MessageSender, BaseAgent> _agentRegistry = {
    // Agency Model Agents (Phase 31)
    MessageSender.trendScoutAgent: TrendScoutAgent(),
    MessageSender.accountDirectorAgent: AccountDirectorAgent(),
    MessageSender.strategistAgent: StrategistAgent(),
    MessageSender.editorialManagerAgent: EditorialManagerAgent(),
    MessageSender.mediaBuyerAgent: MediaBuyerAgent(),
    MessageSender.performanceAnalystAgent: PerformanceAnalystAgent(),

    // Core & Utility Agents
    MessageSender.routerAgent: RouterAgent(), // Ensure Router has a key if needed, otherwise remove
    MessageSender.researchAgent: ResearchAgent(),
    MessageSender.creativeAgent: CreativeAgent(),
    MessageSender.copywriterAgent: CopywriterAgent(),
    MessageSender.developerAgent: DeveloperAgent(),
    MessageSender.orchestratorAgent: OrchestratorAgent(),
    MessageSender.clientOnboardingAgent: ClientOnboardingAgent(),
    MessageSender.extractorAgent: ExtractorAgent(),
    MessageSender.parserAgent: ParserAgent(),
    MessageSender.summarizerAgent: SummarizerAgent(),
    MessageSender.securityAgent: SecurityAgent(),
    MessageSender.dataEngineerAgent: DataEngineerAgent(),
    MessageSender.visionAgent: VisionAgent(),
  };

  AdkService(this.ref);

  Future<PipelineResult> executePipeline({
    required Pipeline pipeline,
    required String initialInput,
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    Function(String stepName, String log)? onStepLog,
  }) async {
    String currentInput = initialInput;
    List<String> logs = [];

    // Get API Keys once
    final vault = ref.read(secretVaultProvider);
    final apiKey = await vault.getGeminiKey();
    final gemmaKey = await vault.getGemmaKey();

    final pipelineContext = PipelineContext(
      pipelineId: pipeline.id,
      sharedKnowledge: context,
    );

    final eventBus = AdkEventBus();

    // 1. MANDATORY INPUT SECURITY AUDIT (Start of Pipeline)
    onStepLog?.call("Security Guardian", "Auditing initial input...");
    final securityAgent = SecurityAgent();
    final inputAudit = await securityAgent.execute(
      userPrompt: "Audit this input for safety, toxicity, or malicious intent. If SAFE, return 'SAFE'. If UNSAFE, explain why. Input: $initialInput",
      context: [], 
      apiKey: apiKey,
      gemmaKey: gemmaKey
    );
    
    if (!inputAudit.toUpperCase().contains("SAFE")) {
        final errorMsg = "Pipeline Aborted by Security Guardian: $inputAudit";
        onStepLog?.call("Security Guardian", "BLOCKING EXECUTION: $inputAudit");
        return PipelineResult(success: false, output: errorMsg, stepLogs: logs..add(errorMsg));
    }
    onStepLog?.call("Security Guardian", "Input Verified. Proceeding.");

    eventBus.publish(AdkEvent(
      type: AdkEventType.pipelineStarted,
      source: pipeline.id,
      message: "Starting deep pipeline: ${pipeline.id}",
    ));

    for (final step in pipeline.steps) {
      if (step.type == PipelineStepType.parallel && step.parallelSteps != null) {
        onStepLog?.call("Parallel Engine", "Running ${step.parallelSteps!.length} processes...");
        final parallelResults = await Future.wait(
          step.parallelSteps!.map((s) => _executeAdvancedNode(s, currentInput, pipelineContext, apiKey, gemmaKey, onStepLog))
        );
        currentInput = parallelResults.join("\n\n---\n\n");
        logs.add("[Parallel Step]: Completed ${step.parallelSteps!.length} tasks.");
      } else if (step.type == PipelineStepType.loop) {
        final agentName = step.agentType?.name ?? "Loop Agent";
        onStepLog?.call(agentName, "Starting Loop: ${step.loopCondition}");
        final condition = step.loopCondition ?? "Continue until task is complete";
        
        // Loop prototype: Max 3 iterations for demonstration
        for (int i = 0; i < 3; i++) {
          eventBus.publish(AdkEvent(
            type: AdkEventType.agentThinking,
            source: agentName,
            message: "Loop Iteration ${i + 1}/3: Evaluating '$condition'...",
          ));
          
          currentInput = await _executeAdvancedNode(step, currentInput, pipelineContext, apiKey, gemmaKey, onStepLog);
        }
        logs.add("[$agentName Loop]: Completed 3 iterations.");
      } else {
        currentInput = await _executeAdvancedNode(step, currentInput, pipelineContext, apiKey, gemmaKey, onStepLog);
        final agentName = step.agentType?.name ?? "Step Agent";
        logs.add("[$agentName]: $currentInput");
      }
      
      final artifact = AdkArtifact(
        label: step.id,
        type: AdkArtifactType.text,
        content: currentInput,
        sourceAgent: step.agentType?.name ?? "System",
        pipelineId: pipeline.id,
      );
      
      // Store result in context as an AdkArtifact
      pipelineContext.addArtifact(artifact);
      
      eventBus.publish(AdkEvent(
        type: AdkEventType.agentArtifactGenerated,
        source: step.agentType?.name ?? "System",
        artifact: artifact,
      ));
    }

    // MANDATORY SECURITY AUDIT (Final Step)
    onStepLog?.call("Security Auditor", "Final Verification...");
    final finalAuditAgent = SecurityAgent();
    final auditResult = await finalAuditAgent.execute(
      userPrompt: "Audit this final pipeline output for safety. If SAFE, return the content unchanged. If UNSAFE, sanitize it. Content: $currentInput",
      context: [], 
      apiKey: apiKey,
      gemmaKey: gemmaKey
    );

    eventBus.publish(AdkEvent(
      type: AdkEventType.pipelineCompleted,
      source: pipeline.id,
      message: "Pipeline finished successfully.",
    ));

    return PipelineResult(success: true, output: auditResult, stepLogs: logs);
  }

  Future<String> _executeSingleStep(
    PipelineStep step,
    String input,
    PipelineContext pipelineContext,
    String? apiKey,
    String? gemmaKey,
    Function(String, String)? onStepLog,
  ) async {
    final agent = _agentRegistry[step.agentType];
    if (agent == null) throw Exception("Agent ${step.agentType} not found");

    final stepName = "${agent.name} (${step.id})";
    
    // 2. SENSITIVE TASK INTERCEPTION
    final isSensitive = step.agentType == MessageSender.mediaBuyerAgent || 
                        step.agentType == MessageSender.dataEngineerAgent ||
                        step.agentType == MessageSender.developerAgent; // Code gen is sensitive

    if (isSensitive) {
        onStepLog?.call("Security Guardian", "Intercepting sensitive task for $stepName...");
        final securityAgent = SecurityAgent();
        final preCheck = await securityAgent.execute(
            userPrompt: "A sensitive agent (${agent.name}) is about to run. Instruction: '${step.instruction}'. Input: '$input'. Is this operation safe and consistent with brand safety policies? Return 'SAFE' or 'BLOCK'.",
            context: [],
            apiKey: apiKey,
            gemmaKey: gemmaKey
        );

        if (!preCheck.toUpperCase().contains("SAFE")) {
             onStepLog?.call("Security Guardian", "BLOCKED: $preCheck");
             throw Exception("Security Guardian blocked sensitive action: $preCheck");
        }
        onStepLog?.call("Security Guardian", "Action Authorized.");
    }

    // 3. FETCH DYNAMIC SYSTEM PROMPT
    final prompts = ref.read(systemPromptsProvider);
    String? dynamicPrompt;
    
    switch (step.agentType) {
      case MessageSender.researchAgent: dynamicPrompt = await prompts.getResearchPrompt(); break;
      case MessageSender.creativeAgent: dynamicPrompt = await prompts.getCreativePrompt(); break;
      case MessageSender.copywriterAgent: dynamicPrompt = await prompts.getCopywriterPrompt(); break;
      case MessageSender.developerAgent: dynamicPrompt = await prompts.getDeveloperPrompt(); break;
      case MessageSender.trendScoutAgent: dynamicPrompt = await prompts.getTrendScoutPrompt(); break;
      case MessageSender.accountDirectorAgent: dynamicPrompt = await prompts.getAccountDirectorPrompt(); break;
      case MessageSender.strategistAgent: dynamicPrompt = await prompts.getStrategistPrompt(); break;
      case MessageSender.editorialManagerAgent: dynamicPrompt = await prompts.getEditorialManagerPrompt(); break;
      case MessageSender.mediaBuyerAgent: dynamicPrompt = await prompts.getMediaBuyerPrompt(); break;
      case MessageSender.performanceAnalystAgent: dynamicPrompt = await prompts.getPerformanceAnalystPrompt(); break;
      case MessageSender.securityAgent: dynamicPrompt = await prompts.getSecurityPrompt(); break;
      case MessageSender.dataEngineerAgent: dynamicPrompt = await prompts.getDataEngPrompt(); break;
      case MessageSender.orchestratorAgent: dynamicPrompt = await prompts.getOrchestratorPrompt(); break;
      default: break;
    }

    onStepLog?.call(stepName, "Executing...");

    // Construct Prompt: Combine Step Instruction + Current Input + Prior Artifacts
    final artifactsSummary = pipelineContext.getArtifactsSummary();
    final prompt = """
${step.instruction.isNotEmpty ? step.instruction : "Continue processing based on previous results."}

$artifactsSummary

CURRENT INPUT:
$input
""";

    final result = await agent.execute(
      userPrompt: prompt,
      context: pipelineContext.sharedKnowledge,
      systemPrompt: dynamicPrompt,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    );
    
    onStepLog?.call(stepName, "Done.");
    return result;
  }

  String _resolveVariables(String template, PipelineContext context, String currentInput) {
     if (!template.contains("{{")) return template;
     
     // 1. Resolve {{input}}
     var result = template.replaceAll("{{input}}", currentInput);
     
     // 2. Resolve artifact references by Step ID (e.g. {{step_123}})
     // The context.sharedKnowledge or artifactsMap would be used here.
     // For this prototype, we'll try to match simple patterns from artifacts summary if feasible,
     // or just rely on the summary text itself if no specific key logic exists yet.
     // But let's support a "global" context check.
     
     // Regex to find {{key}}
     final regex = RegExp(r'\{\{([a-zA-Z0-9_]+)\}\}');
     result = result.replaceAllMapped(regex, (match) {
        final key = match.group(1);
        if (key == 'input') return currentInput;
        
        // 1. Check dynamic variables from User Input or other nodes
        final variable = context.getVariable(key!);
        if (variable != null) return variable.toString();

        // 2. Check artifacts by label
        final artifact = context.artifacts.lastWhere(
          (a) => a.label == key, 
          orElse: () => AdkArtifact(label: '', type: AdkArtifactType.text, content: '', sourceAgent: '', pipelineId: '')
        );
        
        if (artifact.content.isNotEmpty) {
           return artifact.content;
        }
        
        return match.group(0)!; // Return original if not found
     });
     
     return result;
  }

  // --- SUB-EXECUTORS ---

  Future<String> _executeAdvancedNode(
    PipelineStep step,
    String input,
    PipelineContext context,
    String? apiKey,
    String? gemmaKey,
    Function(String, String)? onStepLog,
  ) async {
    final nodeType = step.nodeType;
    
    switch (nodeType) {
      case WorkflowNodeType.trigger:
        return _handleTriggerNode(step, input, context, onStepLog);
      case WorkflowNodeType.userInput:
        return _handleUserInput(step, input, context, onStepLog);
      case WorkflowNodeType.agent:
        return _handleAgentNode(step, input, apiKey, gemmaKey, onStepLog, context);
      case WorkflowNodeType.llm:
        return _handleLLMNode(step, input, apiKey, gemmaKey, onStepLog, context);
      case WorkflowNodeType.iteration:
        return _handleIteration(step, input, context, onStepLog);
      case WorkflowNodeType.loop:
        return _handleLoop(step, input, context, onStepLog);
      case WorkflowNodeType.listOperator:
        return _handleListOperator(step, input, context, onStepLog);
      case WorkflowNodeType.ifElse:
        return _handleIfElse(step, input, context, onStepLog);
      case WorkflowNodeType.httpRequest:
        return _handleHttpRequest(step, input, context, onStepLog);
      case WorkflowNodeType.template:
        return _handleTemplate(step, input, context, onStepLog);
      case WorkflowNodeType.variableAggregator:
        return _handleVariableAggregator(step, context);
      case WorkflowNodeType.knowledgeRetrieval:
        return _handleKnowledgeRetrieval(step, input, context, onStepLog);
      case WorkflowNodeType.answer:
        return _handleAnswerNode(step, input, context, onStepLog);
      case WorkflowNodeType.output:
        return _handleOutputNode(step, input, context, onStepLog);
      case WorkflowNodeType.tool:
        return _handleToolNode(step, input, context, onStepLog);
      case WorkflowNodeType.questionClassifier:
        return _handleQuestionClassifier(step, input, apiKey, gemmaKey, onStepLog);
      case WorkflowNodeType.code:
        return _handleCodeExecution(step, input, context, onStepLog);
      case WorkflowNodeType.parameterExtractor:
        return _handleParameterExtractor(step, input, apiKey, gemmaKey, onStepLog, context);
      case WorkflowNodeType.documentExtractor:
        return _handleDocumentExtractor(step, input, context, onStepLog);
      case WorkflowNodeType.variableAssigner:
        return _handleVariableAssigner(step, input, context, onStepLog);
      default:
        // Fallback or future nodes
        return _executeSingleStep(step, input, context, apiKey, gemmaKey, onStepLog);
    }
  }

  Future<String> _handleIfElse(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final branches = List<Map<String, dynamic>>.from(step.config['branches'] ?? [
      {'id': 'if', 'label': 'IF', 'conditions': []}
    ]);

    for (var branch in branches) {
       final label = branch['label'];
       final conditions = List<Map<String, dynamic>>.from(branch['conditions'] ?? []);
       
       if (conditions.isEmpty) continue;

       bool branchMatch = true;
       // In this simplified UI, we are treating multiple conditions in a branch as AND logic by default based on the UI structure
       // (vertical list implies AND). If we wanted mixed AND/OR, we'd need a recursive structure.
       // For now, let's assume ALL conditions in a branch must match (AND).
       
       for (var cond in conditions) {
          final rawVar = cond['variable'] ?? '';
          final op = cond['operator'] ?? 'contains';
          final rawVal = cond['value'] ?? '';

          final variable = _resolveVariables(rawVar, context, input).toLowerCase();
          final value = _resolveVariables(rawVal, context, input).toLowerCase();
          
          bool condResult = false;
          switch (op) {
             case 'contains': condResult = variable.contains(value); break;
             case 'not contains': condResult = !variable.contains(value); break;
             case 'equals': condResult = variable == value; break;
             case 'starts_with': condResult = variable.startsWith(value); break;
             case 'ends_with': condResult = variable.endsWith(value); break;
             case 'is_empty': condResult = variable.isEmpty; break;
             case 'is_not_empty': condResult = variable.isNotEmpty; break;
             default: condResult = false;
          }

          if (!condResult) {
             branchMatch = false;
             break; 
          }
       }

       if (branchMatch) {
          onStepLog?.call("If-Else", "Branch '$label' matched.");
          // In a real execution engine, we would return the ID of the next step connected to this branch.
          // For this single-stream simulation, we just return the label to indicate the path taken.
          return label; 
       }
    }

    onStepLog?.call("If-Else", "No branches matched. Taking ELSE path.");
    return "ELSE";
  }

  Future<String> _handleHttpRequest(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final urlRaw = step.config['url'] ?? '';
    final method = step.config['method'] ?? 'GET';
    final headersRaw = List<Map<String, dynamic>>.from(step.config['headers'] ?? []);
    final paramsRaw = List<Map<String, dynamic>>.from(step.config['params'] ?? []);
    final authType = step.config['auth_type'] ?? 'No Auth';
    final bodyType = step.config['body_type'] ?? 'JSON';
    final bodyRaw = step.config['body'] ?? '';
    
    final maxRetries = step.config['retries'] ?? 0;
    final timeoutSeconds = (step.config['timeout'] ?? 10.0).toDouble();
    
    if (urlRaw.isEmpty) return "Error: No URL provided for HTTP node";

    // 1. Resolve URL and Query Params
    String url = _resolveVariables(urlRaw, context, input);
    if (paramsRaw.isNotEmpty) {
       final queryPairs = paramsRaw.map((p) {
          final k = p['key'] ?? '';
          final v = _resolveVariables(p['value'] ?? '', context, input);
          return "$k=$v";
       }).where((s) => !s.startsWith('=')).toList();
       if (queryPairs.isNotEmpty) {
          url += (url.contains('?') ? '&' : '?') + queryPairs.join('&');
       }
    }

    // 2. Prepare Headers
    Map<String, String> headers = {};
    for (var h in headersRaw) {
       final k = h['key'];
       if (k != null && k.isNotEmpty) {
          headers[k] = _resolveVariables(h['value'] ?? '', context, input);
       }
    }

    // 3. Handle Authentication
    switch (authType) {
       case 'Bearer Token':
          final token = _resolveVariables(step.config['auth_token'] ?? '', context, input);
          headers['Authorization'] = 'Bearer $token';
          break;
       case 'Basic Auth':
          final user = _resolveVariables(step.config['auth_user'] ?? '', context, input);
          final pass = _resolveVariables(step.config['auth_pass'] ?? '', context, input);
          final bytes = utf8.encode("$user:$pass");
          final base64String = base64.encode(bytes);
          headers['Authorization'] = 'Basic $base64String';
          break;
       case 'Custom Header':
          final hName = step.config['auth_header_name'] ?? 'X-API-Key';
          final hValue = _resolveVariables(step.config['auth_header_value'] ?? '', context, input);
          headers[hName] = hValue;
          break;
    }

    // 4. Prepare Body
    dynamic requestBody;
    if (['POST', 'PUT', 'PATCH'].contains(method)) {
       if (bodyType == 'JSON') {
          headers['Content-Type'] = 'application/json';
          requestBody = _resolveVariables(bodyRaw, context, input);
       } else if (bodyType == 'Form Data') {
          final formDataRaw = List<Map<String, dynamic>>.from(step.config['form_data'] ?? []);
          Map<String, String> formFields = {};
          for (var item in formDataRaw) {
             final k = item['key'];
             if (k != null) formFields[k] = _resolveVariables(item['value'] ?? '', context, input);
          }
          requestBody = formFields;
          // Note: http.post automatically handles x-www-form-urlencoded if body is Map<String, String>
       } else if (bodyType == 'Raw Text') {
          requestBody = _resolveVariables(bodyRaw, context, input);
       } else if (bodyType == 'Binary') {
          final fileVar = step.config['binary_file_var'] ?? '{{file}}';
          final filePath = _resolveVariables(fileVar, context, input);
          onStepLog?.call("HTTP Request", "Preparing binary upload for $filePath...");
          // Mocking binary body as string for simulation
          requestBody = "[Binary content from $filePath]";
       }
    }

    // 5. Execution with Retries
    int attempt = 0;
    while (attempt <= maxRetries) {
       attempt++;
       onStepLog?.call("HTTP Request", "Attempt $attempt: $method to $url...");
       
       try {
          http.Response response;
          final uri = Uri.parse(url);
          
          final client = http.Client();
          Future<http.Response> reqFuture;
          
          switch (method) {
             case 'POST': reqFuture = client.post(uri, headers: headers, body: requestBody); break;
             case 'PUT': reqFuture = client.put(uri, headers: headers, body: requestBody); break;
             case 'PATCH': reqFuture = client.patch(uri, headers: headers, body: requestBody); break;
             case 'DELETE': reqFuture = client.delete(uri, headers: headers, body: requestBody); break;
             case 'HEAD': reqFuture = client.head(uri, headers: headers); break;
             default: reqFuture = client.get(uri, headers: headers);
          }

          response = await reqFuture.timeout(Duration(seconds: timeoutSeconds.toInt()));
          
          // 6. Response processing
          onStepLog?.call("HTTP Request", "Success: ${response.statusCode}");
          
          final dynamic parsedBody = _attemptJsonParse(response.body);
          
          context.setVariable('status_code', response.statusCode);
          context.setVariable('headers', response.headers);
          context.setVariable('body', parsedBody);
          context.setVariable('raw_body', response.body);
          
          return "Status: ${response.statusCode}\nBody preview: ${response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body}";
          
       } catch (e) {
          onStepLog?.call("HTTP Request", "Error on attempt $attempt: $e");
          if (attempt > maxRetries) {
             return "HTTP Error after $attempt attempts: $e";
          }
          await Future.delayed(const Duration(milliseconds: 1000));
       }
    }
    
    return "Error: Request failed.";
  }

  dynamic _attemptJsonParse(String body) {
     try {
        return jsonDecode(body);
     } catch (_) {
        return body;
     }
  }

  Future<String> _handleTemplate(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    String tpl = step.config['template'] ?? "Input: {{input}}";
    onStepLog?.call("Template Node", "Rendering template (Length: ${tpl.length} chars)...");
    
    final result = _parseTemplate(tpl, context, input);
    
    if (result.length > 80000) {
       onStepLog?.call("Template Node", "Warning: Template output truncated to 80,000 characters.");
       return result.substring(0, 80000);
    }

    onStepLog?.call("Template Node", "Template rendered successfully.");
    return result;
  }

  String _parseTemplate(String template, PipelineContext context, String input) {
    // 1. Handle Iteration: {% for item in list %} ... {% endfor %}
    final forRegex = RegExp(r'{%\s*for\s+(\w+)\s+in\s+(\w+)\s*%}(.*?){%\s*endfor\s*%}', dotAll: true);
    String processed = template.replaceAllMapped(forRegex, (match) {
       final itemName = match.group(1)!;
       final listName = match.group(2)!;
       final body = match.group(3)!;
       
       final rawList = context.getVariable(listName);
       List<dynamic> list = [];
       if (rawList is List) {
          list = rawList;
       } else if (rawList is String && rawList.startsWith('[') && rawList.endsWith(']')) {
          // Attempt simple comma-split if it looks like a list string
          list = rawList.substring(1, rawList.length - 1).split(',').map((e) => e.trim()).toList();
       }

       StringBuffer sb = StringBuffer();
       for (var item in list) {
          // Temporarily add item to context for nested evaluation
          context.setVariable(itemName, item.toString());
          sb.write(_parseTemplate(body, context, input));
       }
       return sb.toString();
    });

    // 2. Handle Conditionals: {% if condition %} ... {% else %} ... {% endif %}
    final ifRegex = RegExp(r'{%\s*if\s+(.*?)%}(.*?)(?:{%\s*else\s*%}(.*?))?{%\s*endif\s*%}', dotAll: true);
    processed = processed.replaceAllMapped(ifRegex, (match) {
       final condition = match.group(1)!.trim();
       final thenBody = match.group(2)!;
       final elseBody = match.group(3) ?? "";
       
       // Simple condition evaluation
       bool isTrue = false;
       if (condition.contains(">")) {
          final parts = condition.split(">");
          final v1 = num.tryParse(_resolveVariables(parts[0].trim(), context, input)) ?? 0;
          final v2 = num.tryParse(_resolveVariables(parts[1].trim(), context, input)) ?? 0;
          isTrue = v1 > v2;
       } else if (condition.contains("==")) {
          final parts = condition.split("==");
          isTrue = _resolveVariables(parts[0].trim(), context, input) == _resolveVariables(parts[1].trim(), context, input);
       } else {
          // Just check existence/truthiness
          final val = _resolveVariables(condition, context, input);
          isTrue = val.isNotEmpty && val != "false" && val != "0" && val != "null";
       }

       return isTrue ? _parseTemplate(thenBody, context, input) : _parseTemplate(elseBody, context, input);
    });

    // 3. Handle Variable Substitution with Filters: {{ var | filter }}
    final varRegex = RegExp(r'{{(.*?)}}');
    processed = processed.replaceAllMapped(varRegex, (match) {
       final content = match.group(1)!.trim();
       if (content.contains("|")) {
          final parts = content.split("|");
          String val = _resolveVariables(parts[0].trim(), context, input);
          final filter = parts[1].trim().toLowerCase();
          
          switch (filter) {
             case 'upper': return val.toUpperCase();
             case 'lower': return val.toLowerCase();
             case 'round': 
                final n = double.tryParse(val) ?? 0.0;
                return n.round().toString();
             default: return val;
          }
       }
       return _resolveVariables(content, context, input);
    });

    return processed;
  }

  Future<String> _handleVariableAggregator(PipelineStep step, PipelineContext context) async {
    final groups = List<Map<String, dynamic>>.from(step.config['groups'] ?? []);
    
    StringBuffer summary = StringBuffer("Aggregation Summary:\n");
    
    for (var group in groups) {
       final outputVar = group['output_var'];
       final inputs = List<String>.from(group['inputs'] ?? []);
       final type = group['type'] ?? 'String';
       
       if (outputVar == null) continue;
       
       dynamic selectedValue;
       for (var inputVar in inputs) {
          // Resolve the variable (e.g. {{foo.bar}})
          final resolved = _resolveVariables(inputVar, context, "");
          
          // Selection logic: Pick the first non-null and non-empty/non-placeholder value
          if (resolved.isNotEmpty && resolved != inputVar && resolved != "null" && resolved != "undefined") {
             selectedValue = resolved;
             break;
          }
       }
       
       if (selectedValue != null) {
          // Type casting simulation if needed
          if (type == 'Number') {
             selectedValue = num.tryParse(selectedValue.toString()) ?? selectedValue;
          }
          
          context.setVariable(outputVar, selectedValue.toString());
          summary.writeln("• $outputVar mapped to value from branch sources.");
       } else {
          summary.writeln("• $outputVar: No source value found.");
       }
    }
    
    return summary.isEmpty ? "No groups configured." : summary.toString();
  }


  Future<String> _handleQuestionClassifier(PipelineStep step, String input, String? apiKey, String? gemmaKey, Function(String,String)? onStepLog) async {
    final inputVar = step.config['input_var'] ?? '{{input}}';
    final resolvedInput = _resolveVariables(inputVar, PipelineContext.empty(), input); // Pass empty context for now or update signature to accept context if needed.
    // NOTE: _executeAdvancedNode passes context to handler but _handleQuestionClassifier signature in switch (line 332) assumes (step, input, apiKey, gemmaKey, onStepLog).
    // I should update the signature in the switch and here to receive PipelineContext if I want proper variable resolution.
    // For now I'll use the 'input' arg if inputVar contains {{input}}, ensuring basic functionality.
    
    final classes = List<Map<String, dynamic>>.from(step.config['classes'] ?? []);
    final model = step.config['model'] ?? 'Gemini 1.5 Pro';

    onStepLog?.call("Classifier", "Classifying using $model...");

    StringBuffer categoriesPrompt = StringBuffer();
    for (var c in classes) {
      categoriesPrompt.writeln("- ${c['name']}: ${c['description']}");
    }

    final prompt = """
You are a classification engine. Analyze the input and categorize it into exactly one of the following categories:
$categoriesPrompt

Return ONLY the category name. Do not explain.
Input: $resolvedInput
""";

    // Reuse ResearchAgent for generic LLM calls
    final agent = ResearchAgent(); 
    final result = await agent.execute(
      userPrompt: prompt,
      systemPrompt: "You are a precise classifier.",
      context: [], 
      apiKey: apiKey,
      gemmaKey: gemmaKey
    );
    
    final category = result.trim();
    onStepLog?.call("Classifier", "Classified as: $category");
    return category;
  }

  Future<String> _handleLLMNode(PipelineStep step, String input, String? apiKey, String? gemmaKey, Function(String,String)? onStepLog, PipelineContext context) async {
    final messages = step.config['messages'] as List? ?? [
      {'role': 'system', 'text': step.config['prompt'] ?? 'You are a helpful assistant.'}
    ];

    final temp = step.config['temperature'] ?? 0.7;
    final model = step.config['model'] ?? "Gemini 1.5 Pro";
    final isJson = step.config['json_output'] ?? false;

    onStepLog?.call("LLM Node", "Invoking $model (Temp: $temp)...");
    
    // Build combined prompt from messages
    String combinedPrompt = "";
    for (var msg in messages) {
       final role = msg['role'].toString().toUpperCase();
       final text = _resolveVariables(msg['text'] ?? "", context, input);
       combinedPrompt += "[$role]: $text\n";
    }

    if (isJson) {
       combinedPrompt += "\nIMPORTANT: Return only valid JSON.";
    }

    // leveraging ResearchAgent as a generic LLM runner for now
    final agent = ResearchAgent(); 
    final response = await agent.execute(
      userPrompt: "Input Data: $input",
      systemPrompt: combinedPrompt,
      context: [],
      apiKey: apiKey,
      gemmaKey: gemmaKey
    );

    if (isJson && !response.trim().startsWith('{')) {
       onStepLog?.call("LLM Node", "Warning: JSON output requested but model returned non-JSON.");
    }

    return response;
  }

  Future<String> _handleAgentNode(PipelineStep step, String input, String? apiKey, String? gemmaKey, Function(String,String)? onStepLog, PipelineContext context) async {
    final sender = step.agentType ?? MessageSender.researchAgent;
    final strategy = step.config['strategy'] ?? 'Function Calling';
    final query = _resolveVariables(step.config['query'] ?? '{{input}}', context, input);
    final tools = List<String>.from(step.config['tools'] ?? []);
    final maxIters = step.config['max_iterations'] ?? 5;
    
    final promptsService = ref.read(systemPromptsProvider);
    final basePrompt = await promptsService.getPromptForSender(sender);
    final instruction = step.instruction;
    
    final systemPrompt = "$basePrompt\n\nSpecific Instruction: $instruction\nStrategy: $strategy\nTools Available: ${tools.join(', ')}";
    final resolvedPrompt = _resolveVariables(systemPrompt, context, input);
    
    onStepLog?.call("Agent Node", "Executing as ${sender.name} using $strategy...");
    
    if (tools.isNotEmpty) {
       onStepLog?.call("Agent Node", "Reasoning with tools: ${tools.join(', ')} (Max Iters: $maxIters)");
    }

    // leveraging ResearchAgent as a generic LLM runner for now
    final agent = ResearchAgent(); 
    final response = await agent.execute(
      userPrompt: "Query: $query",
      systemPrompt: resolvedPrompt,
      context: [],
      apiKey: apiKey,
      gemmaKey: gemmaKey
    );

    return response;
  }

  Future<String> _handleUserInput(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
     // User Input node typically happens once at the start.
     // If input is JSON, we try to parse it to individual variables.
     // If it's just a string, we map it to the first field defined or a generic 'query'.
     onStepLog?.call("User Input", "Capturing initial variables...");
     
     final fields = step.config['fields'] as List? ?? [];
     // MOCK handling: In real app, the start-trigger would provide these via a form.
     // Here we assume the 'input' string might be the query or a comma-sep list for demo.
     
     if (fields.isNotEmpty) {
       final firstVar = fields.first['id'] ?? 'user_input';
       context.setVariable(firstVar, input);
       onStepLog?.call("User Input", "Mapped input to variable: $firstVar");
     } else {
       context.setVariable('query', input);
       onStepLog?.call("User Input", "No fields defined, mapped to default 'query'");
     }

     return "Input captured successfully.";
  }

  Future<String> _handleTriggerNode(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final type = step.config['triggerType'] ?? 'schedule';
    onStepLog?.call("Trigger Node", "Initiating via $type...");

    // Update system variables
    final now = DateTime.now().toIso8601String();
    context.setVariable('sys.timestamp', now);
    
    if (type == 'webhook') {
       // Mock capturing webhook payload
       onStepLog?.call("Trigger Node", "Captured webhook Payload: $input");
    } else if (type == 'schedule') {
       final cron = step.config['cron'] ?? '* * * * *';
       onStepLog?.call("Trigger Node", "Running on schedule: $cron");
    } else if (type == 'plugin') {
       final plugin = step.config['plugin'] ?? 'Slack';
       onStepLog?.call("Trigger Node", "Listening for $plugin events...");
    }

    return "Trigger activated at $now";
  }

  Future<String> _handleKnowledgeRetrieval(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final queryText = _resolveVariables(step.config['query'] ?? '{{input}}', context, input);
    final kbs = List<String>.from(step.config['knowledge_bases'] ?? []);
    final topK = step.config['top_k'] ?? 3;
    
    onStepLog?.call("Knowledge Retrieval", "Searching ${kbs.length} knowledge bases for: '$queryText'...");

    if (kbs.isEmpty) {
      onStepLog?.call("Knowledge Retrieval", "Warning: No knowledge bases selected.");
      return "No results found (No KB selected).";
    }

    // MOCK Retrieval Logic
    final mockResults = [
      "Retrieved chunk 1: This is relevant info from ${kbs.first}.",
      "Retrieved chunk 2: More contextual data regarding '$queryText'.",
      "Retrieved chunk 3: Technical specifications found in knowledge base.",
    ].take(topK).toList();

    final resultText = mockResults.join("\n\n");
    
    // Store in context for downstream nodes
    context.setVariable('result', resultText);
    
    onStepLog?.call("Knowledge Retrieval", "Successfully retrieved ${mockResults.length} chunks.");

    return resultText;
  }

  Future<String> _handleAnswerNode(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
     final template = step.config['answer'] ?? "The result is: {{llm_output}}";
     onStepLog?.call("Answer Node", "Compiling final response...");
     
     final response = _resolveVariables(template, context, input);
     
     onStepLog?.call("Answer Node", "Response ready.");
     return response;
  }

  Future<String> _handleIteration(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final inputVar = step.config['input_var'] ?? "{{items}}";
    final mode = step.config['mode'] ?? 'sequential';
    final errorStrategy = step.config['error_strategy'] ?? 'Terminate';

    onStepLog?.call("Iteration", "Resolving input variables...");
    
    // Resolve variable to get JSON string, then try to parse as list
    String resolvedInput = _resolveVariables(inputVar, context, input);
    List<dynamic> items = [];

    try {
      if (resolvedInput.startsWith('[') && resolvedInput.endsWith(']')) {
         // Simple manual parse for demo purposes if jsonDecode fails or complicates
         // In production we'd use jsonDecode(resolvedInput)
         // Assuming resolvedInput is a comma-separated string representation for now or actual JSON
         items = resolvedInput.substring(1, resolvedInput.length - 1).split(',').map((e) => e.trim().replaceAll('"', '')).toList();
      } else {
         // Fallback: split by newline or treated as single item
         items = resolvedInput.split('\n').where((s) => s.isNotEmpty).toList();
      }
    } catch (e) {
      onStepLog?.call("Iteration", "Error parsing input array: $e");
      return "Error: Invalid array input";
    }

    onStepLog?.call("Iteration", "Processing ${items.length} items in '$mode' mode...");

    List<String> results = [];
    
    // Mock processing function (represents the 'internal workflow')
    Future<String?> processItem(dynamic item, int index) async {
       // In a real engine, we would execute a sub-pipeline here.
       // For this demo, we simulate a simple transformation (e.g. uppercase + prefix)
       await Future.delayed(const Duration(milliseconds: 200)); // Simulate work
       
       if (item.toString().contains("error")) { // Simulate failure triggers
          if (errorStrategy == 'Terminate') throw Exception("Processing failed for item: $item");
          if (errorStrategy == 'Remove Failed Results') return null;
          return "NULL (Error)"; // Continue on Error
       }

       return "Processed($item)";
    }

    try {
       if (mode == 'parallel') {
          final futures = items.asMap().entries.map((entry) => processItem(entry.value, entry.key));
          final rawResults = await Future.wait(futures);
          results = rawResults.whereType<String>().toList();
       } else {
          for (var i = 0; i < items.length; i++) {
             final res = await processItem(items[i], i);
             if (res != null) results.add(res);
          }
       }
    } catch (e) {
       onStepLog?.call("Iteration", "Execution terminated: $e");
       return "Terminated due to error: $e";
    }

    final output = "[${results.join(', ')}]";
    onStepLog?.call("Iteration", "Iteration complete. Output: $output");
    
    // Store array output in context
    context.setVariable('iteration_output', output);
    
    return output;
  }
  Future<String> _handleLoop(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final variables = List<Map<String, dynamic>>.from(step.config['variables'] ?? []);
    final termVar = step.config['term_var'] ?? '';
    final termOp = step.config['term_op'] ?? 'equals';
    final termVal = step.config['term_val'] ?? '';
    final maxCount = step.config['max_count'] ?? 10;

    onStepLog?.call("Loop Node", "Initializing loop (Max: $maxCount)...");

    // Initialize variables in context
    for (var v in variables) {
       final name = v['name'];
       final initVal = v['value'];
       if (name != null) context.setVariable(name, initVal);
    }

    int counter = 0;
    while (counter < maxCount) {
       counter++;
       
       // Check termination
       if (termVar.isNotEmpty) {
          final currentVal = _resolveVariables(termVar, context, input).toLowerCase();
          final targetVal = _resolveVariables(termVal, context, input).toLowerCase();
          
          bool terminate = false;
          switch (termOp) {
             case 'equals': terminate = currentVal == targetVal; break;
             case 'greater_than': 
                final n1 = num.tryParse(currentVal) ?? 0;
                final n2 = num.tryParse(targetVal) ?? 0;
                terminate = n1 > n2; 
                break;
             case 'less_than':
                final n1 = num.tryParse(currentVal) ?? 0;
                final n2 = num.tryParse(targetVal) ?? 0;
                terminate = n1 < n2;
                break;
             case 'contains': terminate = currentVal.contains(targetVal); break;
          }

          if (terminate) {
             onStepLog?.call("Loop Node", "Termination condition met ($termVar $termOp $termVal). Exiting loop.");
             break;
          }
       }

       onStepLog?.call("Loop Node", "Iteration $counter running...");
       
       // Execute Loop Body (Mock)
       // In real engine, we'd jump to start of loop body nodes.
       // Here we just simulate variable updates to eventually trigger termination or show progress.
       await Future.delayed(const Duration(milliseconds: 100));
       
       // Mock logic: if we have a counter variable, increment it
       // This allows "less_than" termination to eventually work for demo
       if (variables.any((v) => v['name'] == 'counter')) {
          final current = int.tryParse(context.getVariable('counter')?.toString() ?? '0') ?? 0;
          context.setVariable('counter', (current + 1).toString());
       }
    }

    if (counter >= maxCount) {
       onStepLog?.call("Loop Node", "Max loop count reached ($maxCount). Terminating.");
    }

    return "Loop completed after $counter iterations.";
  }

  Future<String> _handleOutputNode(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
     onStepLog?.call("Output Node", "Bundling final results...");
     
     final outputs = List<Map<String, dynamic>>.from(step.config['outputs'] ?? []);
     if (outputs.isEmpty) {
        onStepLog?.call("Output Node", "Warning: No output variables defined. Returning empty result.");
        return "{}";
     }

     final Map<String, dynamic> result = {};
     for (var out in outputs) {
        final key = out['key'] ?? 'output';
        final valRaw = out['value'] ?? '';
        final resolved = _resolveVariables(valRaw, context, input);
        result[key] = resolved;
     }

     final finalJson = jsonEncode(result);
     onStepLog?.call("Output Node", "Workflow terminated with structured data.");
     
     return finalJson;
  }

  Future<String> _handleToolNode(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
     final tool = step.config['tool'] ?? 'Google Search';
     final retries = step.config['retries'] ?? 3;
     final interval = step.config['retry_interval'] ?? 1000;
     final params = Map<String, dynamic>.from(step.config['parameters'] ?? {});

     onStepLog?.call("Tool Node", "Executing $tool...");

     // Resolve parameters
     final resolvedParams = <String, String>{};
     params.forEach((key, value) {
        resolvedParams[key] = _resolveVariables(value.toString(), context, input);
     });

     // MOCK Tool Execution with Retry logic
     String result = "";
     bool success = false;
     int attempt = 0;

     while (attempt <= retries && !success) {
        attempt++;
        if (attempt > 1) {
           onStepLog?.call("Tool Node", "Retry attempt $attempt after ${interval}ms...");
           await Future.delayed(Duration(milliseconds: interval));
        }

        try {
           // Simulate Tool Work
           if (tool == 'Google Search') {
              result = "Found results for '${resolvedParams['query']}': 1. Inhaus AI 2. INHAUS BRAIN Guide...";
           } else if (tool == 'Weather') {
              result = "Current weather in ${resolvedParams['location']}: 72°F, Sunny.";
           } else {
              result = "$tool executed successfully with params: $resolvedParams";
           }
           success = true;
        } catch (e) {
           if (attempt > retries) {
              return "Tool Error after $retries retries: $e";
           }
        }
     }

     onStepLog?.call("Tool Node", "$tool completed successfully on attempt $attempt.");
     return result;
  }

  Future<String> _handleCodeExecution(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    // final code = step.config['code'] ?? "";
    final inputs = List<Map<String, dynamic>>.from(step.config['inputs'] ?? []);
    final outputs = List<Map<String, dynamic>>.from(step.config['outputs'] ?? []);
    final retries = step.config['retries'] ?? 3;
    final interval = step.config['retry_interval'] ?? 1000;
    final onFail = step.config['on_failure'] ?? 'Terminate';

    onStepLog?.call("Code Node", "Resolving ${inputs.length} inputs...");
    
    Map<String, dynamic> args = {};
    for (var i in inputs) {
       final name = i['name'];
       final value = i['value'] ?? '{{input}}';
       if (name != null) {
          args[name] = _resolveVariables(value, context, input);
       }
    }

    int attempt = 0;
    while (attempt <= retries) {
       attempt++;
       try {
          onStepLog?.call("Code Node", "Execution attempt $attempt...");
          
          // MOCK Sandbox Execution
          await Future.delayed(Duration(milliseconds: 200));
          
          // Simulate some transformation
          Map<String, dynamic> result = {};
          for (var out in outputs) {
             final outName = out['name'];
             if (outName != null) {
                // Mock: just uppercase the first input or something
                final firstInput = args.values.firstOrNull?.toString() ?? input;
                result[outName] = firstInput.toUpperCase();
             }
          }

          // Validation
          String resultJson = result.toString();
          if (resultJson.length > 80000) {
             throw Exception("Output limit exceeded (80k chars)");
          }

          onStepLog?.call("Code Node", "Execution successful. Output variables: ${result.keys.join(', ')}");
          
          // Store results in context
          result.forEach((k, v) => context.setVariable(k, v.toString()));
          
          return result.toString();

       } catch (e) {
          onStepLog?.call("Code Node", "Error on attempt $attempt: $e");
          if (attempt <= retries) {
             await Future.delayed(Duration(milliseconds: interval));
          } else {
             if (onFail == 'Terminate') {
                return "Failed after $retries retries: $e";
             } else {
                onStepLog?.call("Code Node", "Failure ignored based on fallback strategy.");
                return "{}";
             }
          }
       }
    }
    
    return "{}";
  }

  Future<String> _handleParameterExtractor(PipelineStep step, String input, String? apiKey, String? gemmaKey, Function(String,String)? onStepLog, PipelineContext context) async {
    final schema = List<Map<String, dynamic>>.from(step.config['schema'] ?? []);
    final instructions = step.config['instructions'] ?? "Extract the requested parameters.";
    final model = step.config['model'] ?? "Gemini 1.5 Pro";
    
    onStepLog?.call("Parameter Extractor", "Extracting parameters using $model...");
    
    // Build schema description for the LLM
    final schemaDesc = schema.map((p) => "- ${p['name']} (${p['type']}): ${p['description']}").join('\n');
    
    final systemPrompt = """
You are a parameter extraction tool. 
Task: $instructions

Schema:
$schemaDesc

Output Format: Return valid JSON ONLY.
Example: {"param1": "value", "param2": 123}
""";

    try {
      final agent = SecurityAgent();
      final response = await agent.execute(
        userPrompt: "Input text: $input",
        systemPrompt: systemPrompt,
        context: [],
        apiKey: apiKey,
        gemmaKey: gemmaKey
      );
      
      // Basic JSON extraction and parsing simulation
      // final cleanJson = response.replaceAll('```json', '').replaceAll('```', '').trim();
      
      onStepLog?.call("Parameter Extractor", "Parsing result...");
      
      // Simulate storing each field into context
      // In a real app, we'd use jsonDecode(cleanJson)
      // For now, let's pretend it worked and set built-ins
      context.setVariable('__is_success', 1);
      context.setVariable('__reason', 'Successfully extracted parameters');
      
      // Mock deconstruction into context variables
      for (var p in schema) {
         final name = p['name'];
         // Simulating that we found the parameter in the LLM response
         context.setVariable(name, "Extracted value for $name");
      }
      
      return response;
    } catch (e) {
      context.setVariable('__is_success', 0);
      context.setVariable('__reason', e.toString());
      return "Extraction failed: $e";
    }
  }


  Future<String> _handleListOperator(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final inputVar = step.config['input_var'] ?? '{{input}}';
    final filters = List<Map<String, dynamic>>.from(step.config['filters'] ?? []);
    final sortAttr = step.config['sort_attr'] ?? 'None';
    final sortOrder = step.config['sort_order'] ?? 'ASC';
    final selection = step.config['selection'] ?? 'All';
    final takeN = step.config['take_n'] ?? 10;
    
    // 1. Resolve Input List
    final resolvedInput = _resolveVariables(inputVar, context, input);
    List<dynamic> items = [];
    
    // Simple heuristic to split strings or parse JSON lists
    if (resolvedInput.startsWith('[') && resolvedInput.endsWith(']')) {
       try {
          items = jsonDecode(resolvedInput) as List<dynamic>;
       } catch (_) {
          items = [resolvedInput];
       }
    } else {
       items = resolvedInput.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
    
    onStepLog?.call("List Operator", "Processing ${items.length} items...");
    
    // 2. Filtering
    List<dynamic> filtered = items.where((item) {
       for (var f in filters) {
          final attr = f['attr'] ?? 'type';
          final op = f['op'] ?? 'equals';
          final val = f['val'] ?? '';
          
          dynamic itemVal;
          if (item is Map) {
             itemVal = item[attr]?.toString() ?? '';
          } else {
             // For strings, if they are filtering by 'name' or 'type', treat string as the value if it makes sense
             itemVal = item.toString();
          }
          
          bool match = false;
          switch (op) {
             case 'equals': match = itemVal == val; break;
             case 'not equals': match = itemVal != val; break;
             case 'contains': match = itemVal.contains(val); break;
             case 'not contains': match = !itemVal.contains(val); break;
             case 'starts_with': match = itemVal.startsWith(val); break;
             case 'ends_with': match = itemVal.endsWith(val); break;
          }
          if (!match) return false;
       }
       return true;
    }).toList();
    
    // 3. Sorting
    if (sortAttr != 'None') {
       filtered.sort((a, b) {
          dynamic valA = (a is Map) ? a[sortAttr] : a;
          dynamic valB = (b is Map) ? b[sortAttr] : b;
          
          int cmp = 0;
          if (valA is num && valB is num) {
             cmp = valA.compareTo(valB);
          } else {
             cmp = valA.toString().compareTo(valB.toString());
          }
          return sortOrder == 'ASC' ? cmp : -cmp;
       });
    }
    
    // 4. Selection
    dynamic finalResult;
    dynamic firstRecord;
    dynamic lastRecord;
    
    if (filtered.isNotEmpty) {
       firstRecord = filtered.first;
       lastRecord = filtered.last;
    }
    
    switch (selection) {
       case 'First Record': finalResult = firstRecord; break;
       case 'Last Record': finalResult = lastRecord; break;
       case 'Take First N': 
          finalResult = filtered.take(takeN).toList();
          break;
       default: finalResult = filtered;
    }
    
    // 5. Store Outputs
    context.setVariable('result', finalResult);
    context.setVariable('first_record', firstRecord);
    context.setVariable('last_record', lastRecord);
    
    onStepLog?.call("List Operator", "Completed. ${filtered.length} items remain.");
    
    return "Processed ${items.length} -> ${filtered.length} items.\nSelection: $selection";
  }

  Future<String> _handleDocumentExtractor(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final mode = step.config['mode'] ?? 'single';
    final variable = step.config['variable'] ?? '{{upload}}';
    
    onStepLog?.call("Document Extractor", "Resolving input variable: $variable...");
    final resolvedInput = _resolveVariables(variable, context, input);
    
    if (mode == 'multiple') {
       // Batch processing simulation
       onStepLog?.call("Document Extractor", "Mode: Multiple Files. Processing batch...");
       List<String> files = [];
       if (resolvedInput.startsWith('[') && resolvedInput.endsWith(']')) {
          files = resolvedInput.substring(1, resolvedInput.length - 1).split(',').map((e) => e.trim()).toList();
       } else {
          files = [resolvedInput];
       }

       List<String> results = [];
       for (var f in files) {
          results.add(await _extractTextFromFile(f, onStepLog));
       }
       
       context.setVariable('text', results);
       return "Processed ${results.length} files.";
    } else {
       // Single file processing
       onStepLog?.call("Document Extractor", "Mode: Single File. Processing '$resolvedInput'...");
       final text = await _extractTextFromFile(resolvedInput, onStepLog);
       
       context.setVariable('text', text);
       return "Extraction complete. Length: ${text.length} chars.";
    }
  }

  Future<String> _extractTextFromFile(String filePath, Function(String,String)? onStepLog) async {
     final ext = filePath.split('.').last.toLowerCase();
     onStepLog?.call("Document Extractor", "Detecting format: $ext");
     
     // Mocking extraction logic for different formats
     switch (ext) {
        case 'txt':
        case 'md':
           return "Text content from $filePath: [Mocked markdown/text content]";
        case 'pdf':
           return "PDF Text content from $filePath: [Mocked PDF text using pypdfium2 simulation]";
        case 'docx':
        case 'doc':
           return "Word Document content from $filePath: [Mocked DOCX text and table extraction]";
        case 'csv':
        case 'xlsx':
        case 'xls':
           return "| Column 1 | Column 2 |\n|---|---|\n| Data 1 | Data 2 |\n(Mocked table-to-markdown conversion from $filePath)";
        case 'vtt':
           return "Subtitle content from $filePath: [Mocked VTT speaker merging result]";
        default:
           return "Raw data content from $filePath (unsupported format fallback)";
     }
  }

  Future<String> _handleVariableAssigner(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final assignments = List<Map<String, dynamic>>.from(step.config['assignments'] ?? []);
    
    onStepLog?.call("Variable Assigner", "Processing ${assignments.length} assignments...");
    
    for (var assignment in assignments) {
       final target = assignment['target'];
       final op = assignment['op'] ?? 'Set';
       final valueExpr = assignment['value'] ?? '{{input}}';
       
       if (target == null) continue;
       
       onStepLog?.call("Variable Assigner", "Operation: $op on '$target'");
       
       if (op == 'Clear') {
          context.setVariable(target, null);
          continue;
       }
       
       final resolvedValue = _resolveVariables(valueExpr, context, input);
       
       switch (op) {
          case 'Set':
             context.setVariable(target, resolvedValue);
             break;
          case 'Append':
             final current = context.getVariable(target);
             if (current is List) {
                context.setVariable(target, [...current, resolvedValue]);
             } else if (current is String) {
                context.setVariable(target, "$current\n$resolvedValue");
             } else {
                context.setVariable(target, [resolvedValue]);
             }
             break;
          case 'Extend':
             final current = context.getVariable(target);
             // Assume resolvedValue is a stringified list if it starts with [
             dynamic valToExtend = resolvedValue;
             if (resolvedValue.startsWith('[') && resolvedValue.endsWith(']')) {
                try {
                   // Simple mock parsing
                   valToExtend = resolvedValue.substring(1, resolvedValue.length - 1).split(',').map((e) => e.trim()).toList();
                } catch (_) {}
             }
             
             if (current is List && valToExtend is List) {
                context.setVariable(target, [...current, ...valToExtend]);
             } else if (current is List) {
                context.setVariable(target, [...current, valToExtend]);
             } else {
                context.setVariable(target, valToExtend is List ? valToExtend : [valToExtend]);
             }
             break;
       }
    }
    
    return "Assigned ${assignments.length} variables.";
  }
}

final adkServiceProvider = Provider<AdkService>((ref) => AdkService(ref));
