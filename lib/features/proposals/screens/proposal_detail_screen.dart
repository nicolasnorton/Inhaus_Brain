import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/proposal_model.dart';
import '../providers/proposals_provider.dart';
import '../services/proposals_lm_service.dart';
import '../services/proposal_pdf_service.dart';
import '../../knowledge/widgets/add_source_dialog.dart';
import '../../agency/providers/service_catalog_riverpod_provider.dart';
import '../../agency/models/agency_service_model.dart';
import '../../clients/providers/client_provider.dart';
import '../../clients/models/client_model.dart';

import 'package:url_launcher/url_launcher.dart';
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

  /// Fetch the selected AgencyService objects for this proposal
  Future<List<AgencyService>> _fetchSelectedServices(Proposal proposal) async {
    if (proposal.serviceIds.isEmpty) return [];
    try {
      final repo = ref.read(serviceCatalogRepositoryProvider);
      return await repo.getServicesByIds(proposal.serviceIds);
    } catch (e) {
      debugPrint('ProposalDetail: Failed to fetch services: $e');
      return [];
    }
  }

  /// Fetch the Client object for this proposal
  Client? _getClient(Proposal proposal) {
    final clientState = ref.read(clientProvider);
    try {
      return clientState.clients.firstWhere((c) => c.id == proposal.clientId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleChatSubmit() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final proposal = ref.read(proposalProvider(widget.proposalId)).value;
    if (proposal == null) return;

    if (mounted) {
      setState(() {
        _chatMessages.add({'role': 'user', 'content': text});
        _chatController.clear();
      });
    }

    // Direct call to ProposalsLMService with service/client context
    try {
      final services = await _fetchSelectedServices(proposal);
      final client = _getClient(proposal);
      
      final buffer = StringBuffer();
      await for (final chunk in ProposalsLMService.chatWithProposal(
        proposal, text, ref,
        selectedServices: services,
        client: client,
      )) {
        buffer.write(chunk);
      }
      
      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': buffer.toString()});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': 'Error: $e'});
        });
      }
    }
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
    
    try {
      // Fetch service catalog data and client details
      final services = await _fetchSelectedServices(proposal);
      final client = _getClient(proposal);
      
      // Call ProposalsLMService directly with all context
      final result = await ProposalsLMService.generateDetailedProposal(
        proposal,
        ref,
        selectedServices: services,
        client: client,
      );
      
      if (result.pdfBytes != null) {
        // Save the output to the proposal
        final output = ProposalOutput(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: ProposalOutputType.detailedPdf,
          title: 'Detailed Proposal - ${proposal.clientName}',
          createdAt: DateTime.now(),
        );
        
        final updatedProposal = proposal.copyWith(
          outputs: [...proposal.outputs, output],
          status: ProposalStatus.generated,
          updatedAt: DateTime.now(),
        );
        await ref.read(proposalsServiceProvider).updateProposal(updatedProposal);
        
        // Share/open the PDF
        await ProposalPdfService.saveAndOpenPdf(result.pdfBytes!, 'proposal_${proposal.id}_detailed.pdf');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Detailed Proposal Generated!"), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Generation completed but no PDF: ${result.content.substring(0, 100)}..."), backgroundColor: Colors.orange),
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
      _stopLoading();
    }
  }

  Future<void> _generateOnePageQuote(Proposal proposal) async {
    _startLoading('one_page');
    
    try {
      // Fetch service catalog data and client details
      final services = await _fetchSelectedServices(proposal);
      final client = _getClient(proposal);
      
      // Call ProposalsLMService directly with all context
      final result = await ProposalsLMService.generateOnePageQuote(
        proposal,
        ref,
        selectedServices: services,
        client: client,
      );
      
      if (result.pdfBytes != null) {
        // Save the output to the proposal
        final output = ProposalOutput(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: ProposalOutputType.onePagePdf,
          title: 'One-Page Quote - ${proposal.clientName}',
          createdAt: DateTime.now(),
        );
        
        final updatedProposal = proposal.copyWith(
          outputs: [...proposal.outputs, output],
          status: ProposalStatus.generated,
          updatedAt: DateTime.now(),
        );
        await ref.read(proposalsServiceProvider).updateProposal(updatedProposal);
        
        // Share/open the PDF
        await ProposalPdfService.saveAndOpenPdf(result.pdfBytes!, 'proposal_${proposal.id}_quote.pdf');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("One-Page Quote Generated!"), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Generation completed but no PDF: ${result.content.substring(0, 100)}..."), backgroundColor: Colors.orange),
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
      _stopLoading();
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
    if (proposal.serviceIds.isEmpty) {
      return const Text("No services selected", style: TextStyle(color: Colors.white38, fontSize: 12));
    }

    // Fetch and display actual service data with prices
    final servicesAsync = ref.watch(servicesListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Target Services", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        servicesAsync.when(
          data: (allServices) {
            final selectedServices = allServices.where((s) => proposal.serviceIds.contains(s.id)).toList();
            if (selectedServices.isEmpty) {
              // Fallback: show raw IDs if no matching services found
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: proposal.serviceIds
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5))),
                          child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ))
                    .toList(),
              );
            }
            
            return Column(
              children: selectedServices.map((service) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(service.frequency, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      'USD ${service.basePrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )).toList(),
            );
          },
          loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => Wrap(
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
