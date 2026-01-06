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
          step.parallelSteps!.map((s) => _executeSingleStep(s, currentInput, pipelineContext, apiKey, gemmaKey, onStepLog))
        );
        currentInput = parallelResults.join("\n\n---\n\n");
        logs.add("[Parallel Step]: Completed ${step.parallelSteps!.length} tasks.");
      } else if (step.type == PipelineStepType.loop) {
        onStepLog?.call(step.agentType.name, "Starting Loop: ${step.loopCondition}");
        final condition = step.loopCondition ?? "Continue until task is complete";
        
        // Loop prototype: Max 3 iterations for demonstration
        for (int i = 0; i < 3; i++) {
          eventBus.publish(AdkEvent(
            type: AdkEventType.agentThinking,
            source: step.agentType.name,
            message: "Loop Iteration ${i + 1}/3: Evaluating '$condition'...",
          ));
          
          currentInput = await _executeSingleStep(step, currentInput, pipelineContext, apiKey, gemmaKey, onStepLog);
        }
        logs.add("[${step.agentType.name} Loop]: Completed 3 iterations.");
      } else {
        currentInput = await _executeSingleStep(step, currentInput, pipelineContext, apiKey, gemmaKey, onStepLog);
        logs.add("[${step.agentType.name}]: $currentInput");
      }
      
      final artifact = AdkArtifact(
        label: step.id,
        type: AdkArtifactType.text,
        content: currentInput,
        sourceAgent: step.agentType.name,
        pipelineId: pipeline.id,
      );
      
      // Store result in context as an AdkArtifact
      pipelineContext.addArtifact(artifact);
      
      eventBus.publish(AdkEvent(
        type: AdkEventType.agentArtifactGenerated,
        source: step.agentType.name,
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
}

final adkServiceProvider = Provider<AdkService>((ref) => AdkService(ref));
