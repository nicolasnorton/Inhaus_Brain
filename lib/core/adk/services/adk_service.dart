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
      case WorkflowNodeType.userInput:
        return _handleUserInput(step, input, context, onStepLog);
      case WorkflowNodeType.agent:
        return _handleAgentNode(step, input, apiKey, gemmaKey, onStepLog, context);
      case WorkflowNodeType.llm:
        return _handleLLMNode(step, input, apiKey, gemmaKey, onStepLog, context);
      case WorkflowNodeType.iteration:
        return _handleIteration(step, input, onStepLog);
      case WorkflowNodeType.listOperator:
        return _handleListOperator(step, input, onStepLog);
      case WorkflowNodeType.ifElse:
        return _handleIfElse(step, input, context, onStepLog);
      case WorkflowNodeType.httpRequest:
        return _handleHttpRequest(step, input, context, onStepLog);
      case WorkflowNodeType.template:
        return _handleTemplate(step, input, context);
      case WorkflowNodeType.variableAggregator:
        return _handleVariableAggregator(step, context);
      case WorkflowNodeType.knowledgeRetrieval:
        return _handleKnowledgeRetrieval(step, input);
      case WorkflowNodeType.questionClassifier:
        return _handleQuestionClassifier(step, input, apiKey, gemmaKey, onStepLog);
      case WorkflowNodeType.code:
        return _handleCodeExecution(step, input, onStepLog);
      case WorkflowNodeType.parameterExtractor:
        return _handleParameterExtractor(step, input, apiKey, gemmaKey, onStepLog);
      default:
        // Fallback to basic agent logic if it's a legacy or unhandled node
        return _executeSingleStep(step, input, context, apiKey, gemmaKey, onStepLog);
    }
  }

  Future<String> _handleIfElse(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final condition = step.config['condition'] ?? 'contains';
    final target = step.config['targetValue']?.toString().toLowerCase() ?? '';
    final val = input.toLowerCase();

    bool result = false;
    if (condition == 'contains') {
      result = val.contains(target);
    } else if (condition == 'equals') {
      result = val == target;
    } else if (condition == 'starts_with') {
      result = val.startsWith(target);
    }

    onStepLog?.call("If-Else", "Condition '$condition' against '$target' evaluated to: $result");
    return result ? "TRUE" : "FALSE";
  }

  Future<String> _handleHttpRequest(PipelineStep step, String input, PipelineContext context, Function(String,String)? onStepLog) async {
    final urlRaw = step.config['url'] ?? '';
    final url = _resolveVariables(urlRaw, context, input);
    final method = step.config['method'] ?? 'GET';
    if (url.isEmpty) return "Error: No URL provided for HTTP node";

    onStepLog?.call("HTTP Request", "Executing $method to $url...");
    try {
      http.Response response;
      if (method == 'POST') {
        response = await http.post(Uri.parse(url), body: jsonEncode({'input': input}), headers: {'Content-Type': 'application/json'});
      } else {
        response = await http.get(Uri.parse(url));
      }
      return "Status: ${response.statusCode}\nBody: ${response.body}";
    } catch (e) {
      return "HTTP Error: $e";
    }
  }

  Future<String> _handleTemplate(PipelineStep step, String input, PipelineContext context) async {
    String tpl = step.config['template'] ?? "Input: {{input}}";
    return _resolveVariables(tpl, context, input);
  }

  Future<String> _handleVariableAggregator(PipelineStep step, PipelineContext context) async {
    return context.getArtifactsSummary();
  }

  Future<String> _handleKnowledgeRetrieval(PipelineStep step, String query) async {
    // Placeholder for semantic search
    return "Knowledge Insights for '$query': [Simulation] Found 3 matching documents in 'Brand Strategy' folder.";
  }

  Future<String> _handleQuestionClassifier(PipelineStep step, String input, String? apiKey, String? gemmaKey, Function(String,String)? onStepLog) async {
    onStepLog?.call("Classifier", "Clasifying intent...");
    final agent = SecurityAgent(); // Reuse security for classifying
    return await agent.execute(
      userPrompt: "Classify this input into one of these categories: ${step.config['classes'] ?? 'General, Support, Billing'}. Return ONLY the category name. Input: $input",
      context: [], 
      apiKey: apiKey,
      gemmaKey: gemmaKey
    );
  }

  Future<String> _handleLLMNode(PipelineStep step, String input, String? apiKey, String? gemmaKey, Function(String,String)? onStepLog, PipelineContext context) async {
    final rawPrompt = step.config['prompt'] ?? "You are a helpful assistant.";
    final systemPrompt = _resolveVariables(rawPrompt, context, input);
    onStepLog?.call("LLM Node", "Generating response with model ${step.config['model']}...");
    
    // leveraging ResearchAgent as a generic LLM runner for now
    final agent = ResearchAgent(); 
    return await agent.execute(
      userPrompt: "Process this input: $input",
      systemPrompt: systemPrompt,
      context: [],
      apiKey: apiKey,
      gemmaKey: gemmaKey
    );
  }

  Future<String> _handleAgentNode(PipelineStep step, String input, String? apiKey, String? gemmaKey, Function(String,String)? onStepLog, PipelineContext context) async {
    final sender = step.agentType ?? MessageSender.researchAgent;
    final promptsService = ref.read(systemPromptsProvider);
    final basePrompt = await promptsService.getPromptForSender(sender);
    final instruction = step.instruction;
    
    final systemPrompt = "$basePrompt\n\nSpecific Instruction for this step: $instruction";
    final resolvedPrompt = _resolveVariables(systemPrompt, context, input);
    
    onStepLog?.call("Agent Node", "Executing as ${sender.name}...");
    
    // leveraging ResearchAgent as a generic LLM runner for now
    final agent = ResearchAgent(); 
    return await agent.execute(
      userPrompt: "Process this input: $input",
      systemPrompt: resolvedPrompt,
      context: [],
      apiKey: apiKey,
      gemmaKey: gemmaKey
    );
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

  Future<String> _handleCodeExecution(PipelineStep step, String input, Function(String,String)? onStepLog) async {
    final code = step.config['code'] ?? "";
    onStepLog?.call("Code Node", "Executing Javascript/Dart sandbox...");
    
    // MOCK: In a real app, use flutter_js or similar.
    // Here we simulate simple string manipulation if the code comments suggest it.
    if (code.contains("toUpperCase")) {
      return input.toUpperCase();
    } else if (code.contains("length")) {
      return "Length: ${input.length}";
    }
    
    return "Code Output: Executed successfully. (Mock Sandbox). Input size: ${input.length}";
  }

  Future<String> _handleParameterExtractor(PipelineStep step, String input, String? apiKey, String? gemmaKey, Function(String,String)? onStepLog) async {
    onStepLog?.call("Extractor", "Extracting JSON parameters...");
    final agent = SecurityAgent();
    return await agent.execute(
      userPrompt: "Extract these parameters as a JSON object: ${step.config['parameters'] ?? 'name, email, topic'}. If not found, use null. Input: $input",
      context: [], 
      apiKey: apiKey,
      gemmaKey: gemmaKey
    );
  }

  Future<String> _handleIteration(PipelineStep step, String input, Function(String,String)? onStepLog) async {
    // Simple splitter for demo: split by newlines or commas
    final items = input.split(RegExp(r'\n|,'));
    onStepLog?.call("Iterator", "Split input into ${items.length} items for processing.");
    
    // In a real engine, this would trigger a sub-pipeline for each item.
    // For now, we just return a summary.
    return "Iteration Block: Ready to process ${items.length} items. [${items.take(3).join(', ')}...]";
  }

  Future<String> _handleListOperator(PipelineStep step, String input, Function(String,String)? onStepLog) async {
    final operation = step.config['operation'] ?? 'sort';
    var items = input.split('\n').where((s) => s.trim().isNotEmpty).toList();
    
    onStepLog?.call("List Operator", "Performing '$operation' on ${items.length} items...");
    
    switch (operation) {
      case 'sort':
        items.sort();
        break;
      case 'reverse':
        items = items.reversed.toList();
        break;
      case 'unique':
        items = items.toSet().toList();
        break;
      case 'limit':
        final limit = int.tryParse(step.config['limit'] ?? '5') ?? 5;
        items = items.take(limit).toList();
        break;
    }
    
    return items.join('\n');
  }
}

final adkServiceProvider = Provider<AdkService>((ref) => AdkService(ref));
