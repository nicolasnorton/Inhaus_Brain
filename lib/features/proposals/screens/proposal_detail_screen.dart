import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/proposal_model.dart';
import '../providers/proposals_provider.dart';
import '../services/proposals_lm_service.dart';
import '../services/proposal_pdf_service.dart';
import '../../knowledge/widgets/add_source_dialog.dart';


import 'package:url_launcher/url_launcher.dart';
import '../../../core/architecture/blackboard.dart';
import '../../knowledge/models/knowledge_source.dart' as ks;

class ProposalDetailScreen extends ConsumerStatefulWidget {
  final String proposalId;

  const ProposalDetailScreen({super.key, required this.proposalId});

  @override
  ConsumerState<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends ConsumerState<ProposalDetailScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  int _mobileTabIndex = 1; // Default to Chat on mobile
  
  // Progress tracking for PDF generation
  bool _isGeneratingDetailed = false;
  bool _isGeneratingQuote = false;
  int _elapsedSeconds = 0;
  Timer? _progressTimer;

  @override
  void dispose() {
    _chatController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startLoading(String type) {
    _progressTimer?.cancel();
    _elapsedSeconds = 0;
    setState(() {
      if (type == 'detailed') _isGeneratingDetailed = true;
      if (type == 'one_page') _isGeneratingQuote = true;
    });
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _stopLoading() {
    _progressTimer?.cancel();
    if (mounted) {
      setState(() {
        _isGeneratingDetailed = false;
        _isGeneratingQuote = false;
      });
    }
  }

  Future<void> _handleChatSubmit() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    if (mounted) {
      setState(() {
        _chatMessages.add({'role': 'user', 'content': text});
        _chatController.clear();
      });
    }

    // DISPATCH TO BLACKBOARD via OrchestrationService
    ref.read(blackboardProvider.notifier).addEvent(
      WorkflowEventType.userRequested, 
      "User Chat Message",
      data: {
        'action': 'proposal_chat',
        'message': text,
        'proposalId': widget.proposalId,
      }
    );
  }

  Future<void> _addSource() async {
    await showDialog(
      context: context,
      builder: (context) => AddSourceDialog(
        onSourceAdded: (ks.KnowledgeSource newSource) async {
          final proposal = ref.read(proposalProvider(widget.proposalId)).value;
          if (proposal != null) {
            final propSource = ProposalSource(
              id: newSource.id,
              proposalId: proposal.id,
              type: _mapKnowledgeToProposalSourceType(newSource.type),
              name: newSource.title,
              content: newSource.content,
              uri: newSource.metadata?['uri'],
              addedAt: DateTime.now(),
            );
            
            final updatedProposal = proposal.copyWith(
              sources: [...proposal.sources, propSource],
              updatedAt: DateTime.now(),
            );
            await ref.read(proposalsServiceProvider).updateProposal(updatedProposal);
          }
        },
      ),
    );
  }

  ProposalSourceType _mapKnowledgeToProposalSourceType(ks.KnowledgeSourceType type) {
    switch (type) {
      case ks.KnowledgeSourceType.file:
      case ks.KnowledgeSourceType.pdf:
      case ks.KnowledgeSourceType.image:
        return ProposalSourceType.file;
      case ks.KnowledgeSourceType.url:
      case ks.KnowledgeSourceType.youtube:
      case ks.KnowledgeSourceType.ga4:
      case ks.KnowledgeSourceType.googleAds:
        return ProposalSourceType.web;
      case ks.KnowledgeSourceType.text:
      default:
        return ProposalSourceType.text;
    }
  }

  Future<void> _generateDetailedProposal(Proposal proposal) async {
    _startLoading('detailed');
    // DISPATCH TO BLACKBOARD via OrchestrationService
    ref.read(blackboardProvider.notifier).addEvent(
      WorkflowEventType.userRequested, 
      "Generate Detailed Proposal",
      data: {
        'action': 'create_proposal',
        'proposalId': proposal.id,
        'type': 'detailed',
        // Pass the full proposal object if available to avoid null lookups in OrchestrationService
        'proposal': proposal,
      }
    );
  }

  Future<void> _generateOnePageQuote(Proposal proposal) async {
    _startLoading('one_page');
    // DISPATCH TO BLACKBOARD via OrchestrationService
    ref.read(blackboardProvider.notifier).addEvent(
      WorkflowEventType.userRequested, 
      "Generate One-Page Quote",
      data: {
        'action': 'create_proposal',
        'proposalId': proposal.id,
        'type': 'one_page',
        // Pass the full proposal object if available to avoid null lookups in OrchestrationService
        'proposal': proposal,
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for Proposal Updates to handle completion of async generation
    ref.listen<AsyncValue<Proposal?>>(proposalProvider(widget.proposalId), (previous, next) {
      if (next.hasValue && next.value != null && previous?.hasValue == true && previous?.value != null) {
        final prevProps = previous!.value!;
        final nextProps = next.value!;
        
        // Check if a new output was added
        if (nextProps.outputs.length > prevProps.outputs.length) {
          _stopLoading();
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Proposal Generated Successfully!"), backgroundColor: Colors.green),
          );
        }
        
        // Check if status changed to generated
        if (prevProps.status != ProposalStatus.generated && nextProps.status == ProposalStatus.generated) {
           _stopLoading();
        }
      }
    });

    // Listen for Agent Responses (Chat)
    ref.listen<BlackboardState>(blackboardProvider, (previous, next) {
      if (next.events.length > (previous?.events.length ?? 0)) {
        final newEvent = next.events.last;
        if (newEvent.type == WorkflowEventType.agentFinished && 
            newEvent.data['agent'] == 'Proposal Chat Agent') {
          
          final output = newEvent.data['output'];
          if (output != null && mounted) {
            setState(() {
              _chatMessages.add({'role': 'assistant', 'content': output.toString()});
            });
          }
        }
      }
    });

    final proposalAsync = ref.watch(proposalProvider(widget.proposalId));
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: proposalAsync.when(
          data: (proposal) => Text(proposal?.title ?? "Proposal", style: const TextStyle(color: Colors.white)),
          loading: () => const Text("Loading...", style: TextStyle(color: Colors.white)),
          error: (_, __) => const Text("Error", style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/agency/sales'),
        ),
      ),
      body: proposalAsync.when(
        data: (proposal) {
          if (proposal == null) {
            return const Center(child: Text("Proposal not found", style: TextStyle(color: Colors.white)));
          }

          if (isMobile) {
            return _buildMobileLayout(proposal);
          } else {
            return _buildDesktopLayout(proposal);
          }
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Connecting to Data Lake...", style: TextStyle(color: Colors.white24)),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text("Error: $error", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(proposalProvider(widget.proposalId)),
                  child: const Text("Retry Connection"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Proposal proposal) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _mobileTabIndex,
            children: [
              _buildSourcesPanel(proposal),
              _buildChatPanel(proposal),
              _buildStudioPanel(proposal),
            ],
          ),
        ),
        BottomNavigationBar(
          currentIndex: _mobileTabIndex,
          onTap: (index) => setState(() => _mobileTabIndex = index),
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: Colors.white38,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.source), label: "Sources"),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
            BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Studio"),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(Proposal proposal) {
    return Row(
      children: [
        SizedBox(width: 300, child: _buildSourcesPanel(proposal)),
        const VerticalDivider(width: 1, color: Colors.white12),
        Expanded(child: _buildChatPanel(proposal)),
        const VerticalDivider(width: 1, color: Colors.white12),
        SizedBox(width: 300, child: _buildStudioPanel(proposal)),
      ],
    );
  }

  Widget _buildSourcesPanel(Proposal proposal) {
    return Container(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sources", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: _addSource,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...proposal.sources.map((source) => ListTile(
                      leading: Icon(_getSourceIcon(source.type), color: Colors.white70, size: 20),
                      title: Text(source.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text((source.content ?? '').length > 50 ? "${source.content!.substring(0, 50)}..." : (source.content ?? ''),
                          style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    )),
                const SizedBox(height: 24),
                _buildTargetServicesSection(proposal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetServicesSection(Proposal proposal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Target Services", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: proposal.serviceIds
              .map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5))),
                    child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildChatPanel(Proposal proposal) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(msg['content']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  onSubmitted: (_) => _handleChatSubmit(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Ask Brian anything...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.send, color: AppTheme.primary),
                onPressed: _handleChatSubmit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudioPanel(Proposal proposal) {
    return Container(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Studio", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStudioButton(
                  icon: Icons.description,
                  label: "Detailed Proposal",
                  subtitle: "Full PDF with sections",
                  onPressed: () => _generateDetailedProposal(proposal),
                  isGenerating: _isGeneratingDetailed,
                ),
                const SizedBox(height: 12),
                _buildStudioButton(
                  icon: Icons.receipt,
                  label: "One-Page Quote",
                  subtitle: "Quick summary PDF",
                  onPressed: () => _generateOnePageQuote(proposal),
                  isGenerating: _isGeneratingQuote,
                ),
                const SizedBox(height: 12),
                _buildStudioButton(
                  icon: Icons.slideshow,
                  label: "Google Slides",
                  subtitle: "Coming soon",
                  onPressed: null,
                ),
                const SizedBox(height: 24),
                const Text("Outputs", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (proposal.outputs.isEmpty)
                  const Text("No outputs yet", style: TextStyle(color: Colors.white38, fontSize: 12))
                else
                  ...proposal.outputs.map((output) => ListTile(
                        leading: Icon(_getOutputIcon(output.type), color: AppTheme.primary, size: 20),
                        title: Text(output.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(_formatDate(output.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        onTap: () {
                          if (output.uri != null) {
                             launchUrl(Uri.parse(output.uri!));
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("File not found (Url is empty)"), backgroundColor: Colors.red),
                             );
                          }
                        },
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback? onPressed,
    bool isGenerating = false,
  }) {
    return ElevatedButton(
      onPressed: isGenerating ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary.withValues(alpha: (onPressed == null || isGenerating) ? 0.3 : 1.0),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isGenerating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              else
                Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(
                      isGenerating ? "Generating... ${_elapsedSeconds}s" : subtitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isGenerating) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getSourceIcon(ProposalSourceType type) {
    switch (type) {
      case ProposalSourceType.clientBrief:
        return Icons.assignment;
      case ProposalSourceType.campaignData:
        return Icons.campaign;
      case ProposalSourceType.file:
        return Icons.insert_drive_file;
      case ProposalSourceType.text:
        return Icons.text_fields;
      case ProposalSourceType.web:
        return Icons.language;
      case ProposalSourceType.dataConnector:
        return Icons.cloud_sync;
      case ProposalSourceType.pastedText:
        return Icons.content_paste;
    }
  }

  IconData _getOutputIcon(ProposalOutputType type) {
    switch (type) {
      case ProposalOutputType.detailedPdf:
        return Icons.description;
      case ProposalOutputType.onePagePdf:
        return Icons.receipt;
      case ProposalOutputType.googleSlides:
        return Icons.slideshow;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }
}
