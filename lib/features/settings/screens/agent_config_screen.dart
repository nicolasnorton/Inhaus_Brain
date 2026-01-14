
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/globals.dart';
import '../../../core/services/system_prompts_service.dart';
import '../../chat/models/chat_models.dart';
import '../../adk/providers/pipeline_provider.dart';

class AgentConfigScreen extends ConsumerStatefulWidget {
  const AgentConfigScreen({super.key});

  @override
  ConsumerState<AgentConfigScreen> createState() => _AgentConfigScreenState();
}

class _AgentConfigScreenState extends ConsumerState<AgentConfigScreen> {
  MessageSender _selectedAgent = MessageSender.trendScoutAgent;
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = true;

  // Grouping agents for better UI
  final Map<String, List<MessageSender>> _agentGroups = {
    'Campaign Module': [
      MessageSender.trendScoutAgent,
      MessageSender.accountDirectorAgent,
      MessageSender.strategistAgent,
      MessageSender.mediaBuyerAgent,
      MessageSender.performanceAnalystAgent,
    ],
    'Creative Studio': [
      MessageSender.creativeAgent,
      MessageSender.copywriterAgent,
      MessageSender.editorialManagerAgent,
      MessageSender.visionAgent,
    ],
    'Utility & Core': [
      MessageSender.researchAgent,
      MessageSender.developerAgent,
      MessageSender.routerAgent,
      MessageSender.orchestratorAgent,
      MessageSender.securityAgent,
      MessageSender.dataEngineerAgent,
    ]
  };

  @override
  void initState() {
    super.initState();
    _loadPrompt();
  }

  Future<void> _loadPrompt() async {
    setState(() => _isLoading = true);
    final service = ref.read(systemPromptsProvider);
    final prompt = await service.getPromptForSender(_selectedAgent);
    if (mounted) {
      _promptController.text = prompt;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrompt() async {
    final service = ref.read(systemPromptsProvider);
    await service.savePromptForSender(_selectedAgent, _promptController.text);
    if (mounted) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Saved ${_selectedAgent.name} Configuration')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine associated workflows (dumb string matching for now)
    final allPipelines = ref.watch(pipelineProvider);
    final associatedPipelines = allPipelines.where(
      (p) => p.steps.any((s) => s.agentType == _selectedAgent)
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Agent Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                for (final group in _agentGroups.keys) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      group.toUpperCase(),
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  for (final agent in _agentGroups[group]!)
                    ListTile(
                      leading: Icon(_getIconForAgent(agent), size: 16, color: _selectedAgent == agent ? Colors.blueAccent : Colors.white70),
                      title: Text(
                        agent.name.replaceAll('Agent', ''),
                        style: TextStyle(
                          color: _selectedAgent == agent ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: _selectedAgent == agent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      tileColor: _selectedAgent == agent ? Colors.white.withValues(alpha: 0.05) : null,
                      dense: true,
                      onTap: () {
                        setState(() => _selectedAgent = agent);
                        _loadPrompt();
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Icon(_getIconForAgent(_selectedAgent), size: 24, color: Colors.blueAccent),
                      const SizedBox(width: 16),
                      Text(
                        _selectedAgent.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Save Configuration'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _savePrompt,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // System Prompt Section
                  const Text('SYSTEM PROMPT', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TextField(
                      controller: _promptController,
                      maxLines: 15,
                      style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 13, color: Colors.white70, height: 1.4),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        hintText: 'Enter behavior instructions for this agent...',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Associated Workflows
                  Row(
                    children: [
                      const Icon(FontAwesomeIcons.diagramProject, size: 14, color: Colors.white54),
                      const SizedBox(width: 8),
                      const Text('ACTIVE PIPELINES', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (associatedPipelines.isEmpty)
                    const Text('No active pipelines use this agent directly.', style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: associatedPipelines.map((p) => Chip(
                        label: Text(p.name),
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                        side: BorderSide.none,
                      )).toList(),
                    ),

                  const SizedBox(height: 32),
                  
                  // Configuration Toggles (Mock for now)
                  const Text('CAPABILITIES', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 12,
                    children: [
                      _CapabilityBadge(label: 'Web Search', isEnabled: true),
                      _CapabilityBadge(label: 'Image Generation', isEnabled: false),
                      _CapabilityBadge(label: 'Code Execution', isEnabled: false),
                      _CapabilityBadge(label: 'Knowledge Base Access', isEnabled: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      
      // Agency Roles
      case MessageSender.trendScoutAgent: return FontAwesomeIcons.binoculars;
      case MessageSender.accountDirectorAgent: return FontAwesomeIcons.userTie;
      case MessageSender.strategistAgent: return FontAwesomeIcons.chessKnight;
      case MessageSender.editorialManagerAgent: return FontAwesomeIcons.userPen;
      case MessageSender.mediaBuyerAgent: return FontAwesomeIcons.rectangleAd;
      case MessageSender.performanceAnalystAgent: return FontAwesomeIcons.chartLine;
      case MessageSender.visionAgent: return FontAwesomeIcons.eye;

      default: return FontAwesomeIcons.robot;
    }
  }
}

class _CapabilityBadge extends StatelessWidget {
  final String label;
  final bool isEnabled;

  const _CapabilityBadge({required this.label, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isEnabled ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isEnabled ? Icons.check_circle : Icons.cancel, size: 14, color: isEnabled ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isEnabled ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
        ],
      ),
    );
  }
}
