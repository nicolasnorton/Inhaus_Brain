import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../architecture/blackboard.dart';
import '../../features/chat/agents/agency_agents.dart';
import '../../features/proposals/models/proposal_model.dart';
import '../../features/proposals/services/proposals_lm_service.dart';
import '../../features/proposals/providers/proposals_provider.dart';

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
        final type = event.data['type'] ?? 'detailed';
        
        if (proposal != null) {
          await _generateProposal(proposal, type, event.id);
        } else if (proposalId != null) {
          final fetchedProposal = await _ref.read(proposalsServiceProvider).getProposal(proposalId);
          if (fetchedProposal != null) {
            await _generateProposal(fetchedProposal, type, event.id);
          } else {
             debugPrint('OrchestrationService: Proposal not found for ID: $proposalId');
          }
        }
      } catch (e) {
        debugPrint('OrchestrationService: Invalid proposal data in event: $e');
      }
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
      
    } catch (e) {
      debugPrint('OrchestrationService: Proposal generation failed: $e');
      blackboard.updateAgentStatus('Proposal Specialist', AgentStatus.failed);
      blackboard.addEvent(WorkflowEventType.errorOccurred, "Proposal Generation Failed: $e");
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

  Future<void> _triggerAgent(String agentName, String input) async {
    final blackboard = _ref.read(blackboardProvider.notifier);
    
    debugPrint('OrchestrationService: Triggering $agentName');
    blackboard.updateAgentStatus(agentName, AgentStatus.working);

    try {
      String resultText = "";
      
      if (agentName == 'Trend Scout') {
         final agent = TrendScoutAgent();
         resultText = await agent.execute(userPrompt: input, context: [], ref: _ref);
      } else if (agentName == 'Strategist') {
         final agent = StrategistAgent();
         resultText = await agent.execute(userPrompt: input, context: [], ref: _ref);
      } else if (agentName == 'Copywriter') {
         final agent = CopywriterAgent();
         resultText = await agent.execute(userPrompt: input, context: [], ref: _ref);
      } else if (agentName == 'Creative') {
         final agent = CreativeAgent();
         resultText = await agent.execute(userPrompt: input, context: [], ref: _ref);
      } else {
         debugPrint("Orchestration: No agent implementation mapped for $agentName");
         resultText = "Agent $agentName attempted to run but has no wiring.";
      }
      
      // Reset retries on success
      _agentRetries[agentName] = 0;

      // Robust JSON Handling: If the result is JSON, we can parse it before posting
      dynamic factValue = resultText;
      try {
        if (resultText.trim().startsWith('{') || resultText.trim().startsWith('[')) {
          factValue = jsonDecode(resultText);
        }
      } catch (e) {
        debugPrint('OrchestrationService: Result not valid JSON, posting as string.');
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
      
    } catch (e) {
      debugPrint('OrchestrationService: Error executing $agentName: $e');
      
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
