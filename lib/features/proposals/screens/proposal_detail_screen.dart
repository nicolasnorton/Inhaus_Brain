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
import '../providers/proposal_session_provider.dart';
import '../../agency/providers/service_catalog_riverpod_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

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
  int _leftTabIndex = 0; // 0: Chat, 1: Packages, 2: History
  String _activeTab = 'chat'; // 'chat' or 'packages'
  
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

    final session = ref.read(proposalSessionProvider);
    if (session == null) return;

    if (mounted) {
      setState(() {
        _chatMessages.add({'role': 'user', 'content': text});
        _chatController.clear();
      });
    }

    try {
      final buffer = StringBuffer();
      await for (final chunk in ProposalsLMService.chatWithProposal(
        session.proposal, text, ref,
        selectedServices: session.selectedServices,
        client: _getClient(session.proposal),
      )) {
        buffer.write(chunk);
      }
      
      _processChatAction(buffer.toString());
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': 'Error: $e'});
        });
      }
    }
  }

  void _processChatAction(String rawResponse) {
    try {
      final jsonStr = _extractJsonLocal(rawResponse);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      
      final reply = data['reply'] as String? ?? '';
      final action = data['action'] as String? ?? 'none';
      final clientName = data['client'] as String?;
      final packages = data['packages'] as List?;
      final removeIds = data['removeIds'] as List?;
      final discount = (data['discount'] as num?)?.toDouble();

      final notifier = ref.read(proposalSessionProvider.notifier);

      if (action == 'add' && packages != null) {
        _addPackagesByIds(packages.cast<String>());
      } else if (action == 'remove' && removeIds != null) {
        for (final id in removeIds) {
          notifier.removeService(id.toString());
        }
      } else if (action == 'set_client' && clientName != null) {
        notifier.setClientName(clientName);
      } else if (action == 'set_discount' && discount != null) {
        notifier.setDiscount(discount);
      } else if (action == 'set_iva_on') {
        notifier.setIva(true);
      } else if (action == 'set_iva_off') {
        notifier.setIva(false);
      } else if (action == 'save') {
        notifier.saveSession();
      }

      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': reply});
        });
      }
    } catch (e) {
       // Fallback for non-json or malformed json
       if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': rawResponse});
        });
      }
    }
  }

  Future<void> _addPackagesByIds(List<String> ids) async {
    final catalog = await ref.read(serviceCatalogProvider.future);
    if (catalog == null) return;
    final notifier = ref.read(proposalSessionProvider.notifier);
    for (final id in ids) {
      try {
        final service = catalog.services.firstWhere((s) => s.id == id);
        notifier.addService(service);
      } catch (_) {}
    }
  }

  String _extractJsonLocal(String raw) {
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    return match?.group(0) ?? raw;
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
    final session = ref.read(proposalSessionProvider);
    if (session == null) return;
    
    _startLoading('detailed');
    
    try {
      // Call ProposalsLMService directly with session context
      final result = await ProposalsLMService.generateDetailedProposal(
        session.proposal,
        ref,
        selectedServices: session.selectedServices,
        client: _getClient(session.proposal),
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
    final session = ref.read(proposalSessionProvider);
    if (session == null) return;
    
    _startLoading('one_page');
    
    try {
      // Call ProposalsLMService directly with session context
      final result = await ProposalsLMService.generateOnePageQuote(
        session.proposal,
        ref,
        selectedServices: session.selectedServices,
        client: _getClient(session.proposal),
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
    final session = ref.watch(proposalSessionProvider);

    return proposalAsync.when(
      data: (proposal) {
        if (proposal == null) {
          return const Scaffold(body: Center(child: Text("Proposal not found")));
        }

        // Initialize session if it's null and we have the proposal
        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(proposalSessionProvider.notifier).loadProposal(proposal);
          });
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          );
        }

        final isDesktop = MediaQuery.of(context).size.width > 900;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(proposal.title, style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/agency/sales'),
            ),
          ),
          body: isDesktop ? _buildDesktopLayout(proposal) : _buildMobileLayout(proposal),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.accent),
              SizedBox(height: 16),
              Text("Connecting to Data Lake...", style: TextStyle(color: Colors.white24)),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
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
                    color: isUser ? AppTheme.accent.withValues(alpha: 0.1) : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isUser ? AppTheme.accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(
                    msg['content']!,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Active Quote Bar
        _buildActiveQuoteBar(),
        
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          color: const Color(0xFF0D0D0D),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  onSubmitted: (_) => _handleChatSubmit(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Escribe tu comando o consulta...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _handleChatSubmit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveQuoteBar() {
    final session = ref.watch(proposalSessionProvider);
    if (session == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(top: BorderSide(color: Colors.white10), bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          _buildActiveQuoteStat("CLIENTE", session.proposal.clientName.isEmpty ? "PENDIENTE" : session.proposal.clientName.toUpperCase()),
          _buildActiveQuoteStat("ITEMS", session.selectedServices.length.toString()),
          _buildActiveQuoteStat("DSCTO", "${session.proposal.discount.toStringAsFixed(0)}%"),
          _buildActiveQuoteStat("IVA", session.proposal.applyIva ? "15%" : "0%"),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("INVERSIÓN TOTAL", style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text(
                "USD ${session.total.toStringAsFixed(2)}",
                style: GoogleFonts.outfit(color: AppTheme.accent, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuoteStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
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
                const SizedBox(height: 12),
                _buildStudioButton(
                  icon: Icons.save,
                  label: "Guardar Cambios",
                  subtitle: "Sincronizar con la nube",
                  onPressed: () async {
                    await ref.read(proposalSessionProvider.notifier).saveSession();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Cambios guardados correctamente"), backgroundColor: Colors.green),
                      );
                    }
                  },
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
