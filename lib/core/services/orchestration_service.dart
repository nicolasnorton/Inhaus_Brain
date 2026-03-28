import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../architecture/blackboard.dart';
import '../architecture/agent_dag.dart';
import '../../features/chat/agents/agency_agents.dart';
import '../../features/chat/agents/core_agents.dart' hide CopywriterAgent, CreativeAgent;
import '../../features/proposals/models/proposal_model.dart';
import '../../features/proposals/services/proposals_lm_service.dart';
import '../../features/proposals/providers/proposals_provider.dart';

import '../../features/knowledge/models/knowledge_source.dart';
import 'analytics_service.dart';

class OrchestrationService {
  final Ref _ref;
  bool _isListening = false;

  OrchestrationService(this._ref);

  void init() {
    if (_isListening) return;
    _isListening = true;
    
    debugPrint('OrchestrationService: Initialized and listening to Blackboard.');

    // Listen for Phase Changes
    _ref.listen<BlackboardState>(blackboardProvider, (previous, next) {
      if (previous?.phase != next.phase) {
        _handlePhaseChange(next.phase, next);
      }
      
      // Listen for New Events
      if (next.events.length > (previous?.events.length ?? 0)) {
        final newEvent = next.events.last;
        if (newEvent.type == WorkflowEventType.userRequested) {
          _handleUserRequest(newEvent);
        }
      }
    });
  }

  Future<void> _handleUserRequest(WorkflowEvent event) async {
    final action = event.data['action'];
    if (action == 'create_proposal') {
      try {
        final proposal = event.data['proposal'] as Proposal?;
        final proposalId = event.data['proposalId'] as String?;
        final type = event.data['type'] as String? ?? 'detailed';
        
        debugPrint('OrchestrationService: Decision to generate $type proposal. Proposal: $proposal, ID: $proposalId');

        if (proposal != null) {
          await _generateProposal(proposal, type, event.id);
        } else if (proposalId != null) {
          final fetchedProposal = await _ref.read(proposalsServiceProvider).getProposal(proposalId);
          if (fetchedProposal != null) {
            await _generateProposal(fetchedProposal, type, event.id);
          } else {
             debugPrint('OrchestrationService: ERROR - Proposal not found for ID: $proposalId');
          }
        } else {
          debugPrint('OrchestrationService: ERROR - Missing both proposal object and ID in event.');
        }
      } catch (e, stack) {
        debugPrint('OrchestrationService: CRASH in _handleUserRequest: $e\n$stack');
      }
    } else if (action == 'execute_pipeline') {
      // Execute DAG Pipeline if requested
      final dagPlan = event.data['dag_plan'] as List<dynamic>?;
      if (dagPlan != null) {
        await _executeDagPipeline(dagPlan.cast<Map<String, dynamic>>());
      }
    } else if (action == 'proposal_chat') {
      final message = event.data['message'] as String;
      final proposalId = event.data['proposalId'] as String?;
      
      List<KnowledgeSource> context = [];
      if (proposalId != null) {
         final proposal = await _ref.read(proposalsServiceProvider).getProposal(proposalId);
         if (proposal != null) {
            context.add(KnowledgeSource(
              id: 'prop_ctx_${proposal.id}',
              title: 'Current Proposal: ${proposal.title}',
              content: jsonEncode(proposal.toJson()),
              type: KnowledgeSourceType.text,
              createdAt: DateTime.now()
            ));
         }
      }

      // Trigger Proposal Chat for conversational interaction
      await _triggerAgent('Proposal Chat Agent', message, context: context);
    }
  }

  Future<void> _generateProposal(Proposal proposal, String type, String requestId) async {
    final blackboard = _ref.read(blackboardProvider.notifier);
    final proposalsService = _ref.read(proposalsServiceProvider);
    
    blackboard.updateAgentStatus('Proposal Specialist', AgentStatus.working);
    
    try {
      GenerationResult result;
      if (type == 'one_page') {
         result = await ProposalsLMService.generateOnePageQuote(proposal, _ref);
      } else {
         result = await ProposalsLMService.generateDetailedProposal(proposal, _ref);
      }

      // Upload PDF if available
      String? pdfUrl;
      if (result.pdfBytes != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('proposals/${proposal.id}/${DateTime.now().millisecondsSinceEpoch}.pdf');
          
          await storageRef.putData(result.pdfBytes!, SettableMetadata(contentType: 'application/pdf'));
          pdfUrl = await storageRef.getDownloadURL();
        } catch (e) {
          debugPrint('OrchestrationService: PDF upload failed: $e');
        }
      }
      
      // Create Proposal Output
      final output = ProposalOutput(
        id: const Uuid().v4(),
        title: type == 'one_page' ? 'One Page Quote' : 'Detailed Proposal',
        type: type == 'one_page' ? ProposalOutputType.onePagePdf : ProposalOutputType.detailedPdf,
        uri: pdfUrl,
        createdAt: DateTime.now(),
      );

      // Save Updates to Firestore
      final updatedProposal = proposal.copyWith(
        status: ProposalStatus.generated,
        outputs: [...proposal.outputs, output],
        updatedAt: DateTime.now(),
      );
      
      await proposalsService.updateProposal(updatedProposal);
      
      blackboard.updateAgentStatus('Proposal Specialist', AgentStatus.idle);
      blackboard.addEvent(
        WorkflowEventType.taskFinished, 
        "Proposal Generated: ${proposal.title}",
        data: {
          'requestId': requestId,
          'proposalId': proposal.id,
          'content': result.content,
          'pdfUrl': pdfUrl
        }
      );

      // Analytics
      _ref.read(analyticsServiceProvider).logEvent(
        'proposal_generated',
        parameters: {
          'proposalId': proposal.id,
          'type': type,
          'hasPdf': pdfUrl != null,
          'agentId': 'Proposal Specialist',
        },
      );
      
    } catch (e) {
      debugPrint('OrchestrationService: Proposal generation failed: $e');
      blackboard.updateAgentStatus('Proposal Specialist', AgentStatus.failed);
      blackboard.addEvent(WorkflowEventType.errorOccurred, "Proposal Generation Failed: $e");
    }
  }

  Future<void> _executeDagPipeline(List<Map<String, dynamic>> plan) async {
    final blackboard = _ref.read(blackboardProvider.notifier);
    debugPrint('OrchestrationService: Executing AgentDAG with ${plan.length} nodes');
    
    final dag = AgentDAG.fromPlan(plan);
    try {
      final result = await dag.execute(
        agentExecutor: (agentName, task, upstreamContext) async {
          blackboard.updateAgentStatus(agentName, AgentStatus.working);
          try {
            // We use the same _triggerAgent logic but wrapped to return String
            if (agentName == 'Trend Scout') {
              return await TrendScoutAgent().execute(userPrompt: task, context: upstreamContext, ref: _ref);
            } else if (agentName == 'Strategist') {
              return await StrategistAgent().execute(userPrompt: task, context: upstreamContext, ref: _ref);
            } else if (agentName == 'Copywriter') {
              return await CopywriterAgent().execute(userPrompt: task, context: upstreamContext, ref: _ref);
            } else if (agentName == 'Creative') {
              return await CreativeAgent().execute(userPrompt: task, context: upstreamContext, ref: _ref);
            } else if (agentName == 'Research Agent') {
              return await ResearchAgent().execute(userPrompt: task, context: upstreamContext, ref: _ref);
            } else if (agentName == 'Editorial Manager') {
              return await EditorialManagerAgent().execute(userPrompt: task, context: upstreamContext, ref: _ref);
            } else {
              debugPrint("Orchestration (DAG): Unknown agent $agentName, using generic strategy fallback.");
              return await StrategistAgent().execute(userPrompt: task, context: upstreamContext, ref: _ref);
            }
          } finally {
            blackboard.updateAgentStatus(agentName, AgentStatus.idle);
          }
        },
        onEvent: (event) {
          // You could optionally forward ADK events from DAG to blackboard UI
          debugPrint('DAG Event: \${event.message}');
        }
      );

      if (result.allSucceeded) {
        blackboard.addEvent(
          WorkflowEventType.taskFinished, 
          "Pipeline completed successfully",
          data: {'output': result.mergedOutput}
        );
        blackboard.postFact('pipeline_result', result.mergedOutput);
      } else {
        blackboard.addEvent(
          WorkflowEventType.errorOccurred, 
          "Pipeline partially failed",
          data: {'output': result.mergedOutput}
        );
      }
    } catch (e) {
      debugPrint('OrchestrationService: DAG Execution Failed: $e');
      blackboard.addEvent(WorkflowEventType.errorOccurred, "Pipeline Failed: $e");
    }
  }

  Future<void> _handlePhaseChange(BlackboardPhase phase, BlackboardState state) async {
    debugPrint('OrchestrationService: Phase changed to ${phase.name}');
    
    // Safety check to prevent infinite loops or re-triggering busy agents
    if (state.activeAgents.values.any((s) => s == AgentStatus.working)) {
      debugPrint('OrchestrationService: Agents are already working. Skipping trigger.');
      return;
    }

    final blackboard = _ref.read(blackboardProvider.notifier);
    final input = state.facts['user_intent'] ?? state.events.lastOrNull?.message ?? "Run task";

    switch (phase) {
      case BlackboardPhase.analyzingIntent:
        // Already handled by Router, usually transitions to another phase immediately
        break;

      case BlackboardPhase.strategy:
        await _triggerAgent('Strategist', input);
        break;

      case BlackboardPhase.creative:
        await _triggerAgent('Creative', input);
        break;
        
      case BlackboardPhase.copywriting:
        await _triggerAgent('Copywriter', input);
        break;

      default:
        break;
    }
  }

  final Map<String, int> _agentRetries = {};
  static const int _maxRetries = 2;

  Future<void> _triggerAgent(String agentName, String input, {List<KnowledgeSource> context = const []}) async {
    final blackboard = _ref.read(blackboardProvider.notifier);
    
    debugPrint('OrchestrationService: Triggering $agentName');
    blackboard.updateAgentStatus(agentName, AgentStatus.working);
    final analytics = _ref.read(analyticsServiceProvider);
    
    analytics.logEvent('agent_start', parameters: {'agentId': agentName, 'input_length': input.length});

    try {
      String resultText = "";
      
      if (agentName == 'Trend Scout') {
         final agent = TrendScoutAgent();
         resultText = await agent.execute(userPrompt: input, context: context, ref: _ref);
      } else if (agentName == 'Strategist') {
         final agent = StrategistAgent();
         resultText = await agent.execute(userPrompt: input, context: context, ref: _ref);
      } else if (agentName == 'Copywriter') {
         final agent = CopywriterAgent();
         resultText = await agent.execute(userPrompt: input, context: context, ref: _ref);
      } else if (agentName == 'Creative') {
         final agent = CreativeAgent();
         resultText = await agent.execute(userPrompt: input, context: context, ref: _ref);
      } else if (agentName == 'Proposal Specialist') {
         final agent = ProposalSpecialistAgent();
         resultText = await agent.execute(userPrompt: input, context: context, ref: _ref);
      } else if (agentName == 'Proposal Chat Agent') {
         final agent = ProposalChatAgent();
        resultText = await agent.execute(userPrompt: input, context: context, ref: _ref);
      } else {
         debugPrint("Orchestration: No agent implementation mapped for $agentName");
         resultText = "Agent $agentName attempted to run but has no wiring.";
      }
      
      // Reset retries on success
      _agentRetries[agentName] = 0;

      // Robust JSON Handling: If the result is JSON, we can parse it before posting
      dynamic factValue = resultText;
      if (resultText.trim().isNotEmpty) {
        try {
          final trimmed = resultText.trim();
          if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
            factValue = jsonDecode(trimmed);
          }
        } catch (e) {
          debugPrint('OrchestrationService: Result for $agentName is not valid JSON, posting as string. Error: $e');
        }
      }

      debugPrint('OrchestrationService: $agentName finished work.');
      blackboard.updateAgentStatus(agentName, AgentStatus.idle);
      blackboard.postFact('${agentName.toLowerCase().replaceAll(' ', '_')}_output', factValue);
      
      // If an agent finished, add an event
      blackboard.addEvent(
        WorkflowEventType.agentFinished, 
        "$agentName completed task",
        data: {'agent': agentName, 'output': factValue}
      );
      
      analytics.logEvent('agent_complete', parameters: {'agentId': agentName, 'result_length': resultText.length});
      
    } catch (e) {
      debugPrint('OrchestrationService: Error executing $agentName: $e');
      _ref.read(analyticsServiceProvider).logEvent(
        'agent_error', 
        parameters: {
           'agentId': agentName, 
           'severity': 'error',
           'error': e.toString()
        }
      );
      
      final currentRetries = _agentRetries[agentName] ?? 0;
      if (currentRetries < _maxRetries) {
        _agentRetries[agentName] = currentRetries + 1;
        debugPrint('OrchestrationService: Retrying $agentName (Attempt ${currentRetries + 1})...');
        await _triggerAgent(agentName, input);
      } else {
        debugPrint('OrchestrationService: $agentName failed after $_maxRetries retries. Activating Arbiter fallback.');
        blackboard.updateAgentStatus(agentName, AgentStatus.failed);
        blackboard.addEvent(WorkflowEventType.errorOccurred, "Agent $agentName failed after retries: $e");
        
        // Arbiter Fallback Strategy
        _handleAgentFailure(agentName, input);
      }
    }
  }

  void _handleAgentFailure(String agentName, String input) {
    final blackboard = _ref.read(blackboardProvider.notifier);
    
    // Simple Arbiter Logic: If a specialized agent fails, fall back to a "Generalist" (Management Agent) 
    // or post a request for clarification.
    blackboard.addEvent(
      WorkflowEventType.errorOccurred, 
      "The $agentName is currently unavailable. I will attempt to handle this with a generalist agent.",
      data: {'failed_agent': agentName, 'input': input}
    );
    
    // In a real scenario, we might trigger a 'Management' phase or 'Clarification' phase.
  }
}

final orchestrationServiceProvider = Provider<OrchestrationService>((ref) {
  return OrchestrationService(ref);
});
