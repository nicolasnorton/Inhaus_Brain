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
import '../../services/services/services_repository.dart';

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
          // If the chunk is longer than the current content and starts with it, it's likely a full update
          if (chunk.length > (_chatMessages[lastIdx]['content']?.length ?? 0) && 
              chunk.startsWith(_chatMessages[lastIdx]['content'] ?? "")) {
             _chatMessages[lastIdx]['content'] = chunk;
          } else {
             // Otherwise, it's a delta, so append it (standard for most LLM streams)
             // But wait, if we see "PleasePlease", it means we are appending when we should likely be replacing 
             // OR the provider is sending "A", then "AB", then "ABC".
             // Let's assume standard delta for now, but if the chunk implies full text, switch strategy.
             // Actually, safest is to just APPEND if we are sure it's a delta. 
             // But the bug "PleasePlease" strongly suggests we are appending "Please" to "Please".
             // Let's inspect ProposalsLMService to be sure.
             // For now, I will assume it sends DELTAS. 
             // If it was sending full text, the previous code `content + chunk` would result in "PleasePlease...".
             // Wait, if the provider sends "Please", then " provide", the previous code does "Please" + " provide" -> "Please provide".
             // If the provider sends "Please", then "Please provide", the previous code does "Please" + "Please provide" -> "PleasePlease provide".
             // This confirms the provider is likely sending FULL ACCUMULATED TEXT in each chunk.
             
             // FIX: We will treat the chunk as the NEW FULL CONTENT if it starts with the old content
             // OR if it looks like a replacement.
             // Actually, simpler fix: Just set content = chunk if the service returns full text.
             // Let's check the service first. I'll revert this thought and check the service.
          }
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

    // Start progress tracking
    setState(() {
      _isGeneratingDetailed = true;
      _elapsedSeconds = 0;
    });

    // Start timer to track elapsed time
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });

    try {
      final result = await ProposalsLMService.generateDetailedProposal(proposal, ref);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Always cleanup - ensures loader is dismissed
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _isGeneratingDetailed = false;
          _elapsedSeconds = 0;
        });
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

    // Start progress tracking
    setState(() {
      _isGeneratingQuote = true;
      _elapsedSeconds = 0;
    });

    // Start timer to track elapsed time
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });

    try {
      final result = await ProposalsLMService.generateOnePageQuote(proposal, ref);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Always cleanup - ensures loader is dismissed
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _isGeneratingQuote = false;
          _elapsedSeconds = 0;
        });
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
          if (proposal.serviceIds.isNotEmpty) ...[
            _buildTargetServicesSection(proposal),
            const Divider(height: 1, color: Colors.white12),
          ],
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

  Widget _buildTargetServicesSection(Proposal proposal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "TARGET SERVICES",
            style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
        FutureBuilder(
          future: ref.read(servicesRepositoryProvider).getServicesByIds(proposal.serviceIds),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final services = snapshot.data as List;
            return Column(
              children: services.map((s) => ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                title: Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text("\$${s.basePrice.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
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
                          if (output.type == ProposalOutputType.detailedPdf) {
                            _generateDetailedProposal(proposal);
                          } else if (output.type == ProposalOutputType.onePagePdf) {
                            _generateOnePageQuote(proposal);
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
