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

  void _handleChatSubmit(Proposal proposal) async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'content': query});
      _chatController.clear();
      _chatMessages.add({'role': 'ai', 'content': ''});
    });

    try {
      final stream = ProposalsLMService.chatWithProposal(proposal, query, ref);

      await for (final chunk in stream) {
        if (!mounted) break;
        setState(() {
          final lastIdx = _chatMessages.length - 1;
          _chatMessages[lastIdx]['content'] = _chatMessages[lastIdx]['content']! + chunk;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final lastIdx = _chatMessages.length - 1;
          _chatMessages[lastIdx]['content'] = "Error: $e";
        });
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _addSource(Proposal proposal, ProposalSource source) async {
    try {
      final updatedProposal = proposal.copyWith(
        updatedAt: DateTime.now(),
        sources: [...proposal.sources, source],
      );

      await ref.read(proposalsServiceProvider).updateProposal(updatedProposal);
      ref.invalidate(proposalProvider(widget.proposalId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Added ${source.name}"), backgroundColor: AppTheme.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding source: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddSourceDialog(Proposal proposal) async {
    showDialog(
      context: context,
      builder: (context) => AddSourceDialog(
        onSourceAdded: (knowledgeSource) async {
          final source = ProposalSource(
            id: const Uuid().v4(),
            proposalId: proposal.id,
            type: ProposalSourceType.text,
            name: knowledgeSource.title,
            content: knowledgeSource.content,
            addedAt: DateTime.now(),
          );
          await _addSource(proposal, source);
        },
      ),
    );
  }

  Future<void> _generateDetailedProposal(Proposal proposal) async {
    if (proposal.sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add sources first"), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ProposalsLMService.generateDetailedProposal(proposal, ref);

      if (mounted) Navigator.pop(context);

      if (result.pdfBytes != null) {
        await ProposalPdfService.saveAndOpenPdf(
          result.pdfBytes!,
          "Proposal_${proposal.clientName.replaceAll(' ', '_')}.pdf",
        );

        final output = ProposalOutput(
          id: const Uuid().v4(),
          title: "Detailed Proposal",
          type: ProposalOutputType.detailedPdf,
          createdAt: DateTime.now(),
        );

        final updatedProposal = proposal.copyWith(
          outputs: [...proposal.outputs, output],
          status: ProposalStatus.generated,
          updatedAt: DateTime.now(),
        );

        await ref.read(proposalsServiceProvider).updateProposal(updatedProposal);
        ref.invalidate(proposalProvider(widget.proposalId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Proposal generated successfully!"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateOnePageQuote(Proposal proposal) async {
    if (proposal.sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add sources first"), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ProposalsLMService.generateOnePageQuote(proposal, ref);

      if (mounted) Navigator.pop(context);

      if (result.pdfBytes != null) {
        await ProposalPdfService.saveAndOpenPdf(
          result.pdfBytes!,
          "Quote_${proposal.clientName.replaceAll(' ', '_')}.pdf",
        );

        final output = ProposalOutput(
          id: const Uuid().v4(),
          title: "One-Page Quote",
          type: ProposalOutputType.onePagePdf,
          createdAt: DateTime.now(),
        );

        final updatedProposal = proposal.copyWith(
          outputs: [...proposal.outputs, output],
          status: ProposalStatus.generated,
          updatedAt: DateTime.now(),
        );

        await ref.read(proposalsServiceProvider).updateProposal(updatedProposal);
        ref.invalidate(proposalProvider(widget.proposalId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Quote generated successfully!"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text("Error: $error", style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildMobileLayout(Proposal proposal) {
    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: null,
            onTap: (index) => setState(() => _mobileTabIndex = index),
            indicatorColor: AppTheme.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: "Sources"),
              Tab(text: "Chat"),
              Tab(text: "Studio"),
            ],
          ),
        ),
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
      ],
    );
  }

  Widget _buildDesktopLayout(Proposal proposal) {
    return Row(
      children: [
        SizedBox(width: 280, child: _buildSourcesPanel(proposal)),
        const VerticalDivider(width: 1, color: Colors.white12),
        Expanded(child: _buildChatPanel(proposal)),
        const VerticalDivider(width: 1, color: Colors.white12),
        SizedBox(width: 320, child: _buildStudioPanel(proposal)),
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
              children: [
                const Text("Sources", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.primary, size: 20),
                  onPressed: () => _showAddSourceDialog(proposal),
                  tooltip: "Add Source",
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: proposal.sources.isEmpty
                ? const Center(
                    child: Text("No sources added yet", style: TextStyle(color: Colors.white38)),
                  )
                : ListView.builder(
                    itemCount: proposal.sources.length,
                    itemBuilder: (context, index) {
                      final source = proposal.sources[index];
                      return ListTile(
                        leading: Icon(_getSourceIcon(source.type), color: AppTheme.primary, size: 20),
                        title: Text(source.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(source.type.displayName, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel(Proposal proposal) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[index];
              final isUser = message['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(message['content']!, style: const TextStyle(color: Colors.white)),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Ask about this proposal...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _handleChatSubmit(proposal),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: AppTheme.primary),
                onPressed: () => _handleChatSubmit(proposal),
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
                ),
                const SizedBox(height: 12),
                _buildStudioButton(
                  icon: Icons.receipt,
                  label: "One-Page Quote",
                  subtitle: "Quick summary PDF",
                  onPressed: () => _generateOnePageQuote(proposal),
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
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary.withValues(alpha: onPressed == null ? 0.3 : 1.0),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
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
