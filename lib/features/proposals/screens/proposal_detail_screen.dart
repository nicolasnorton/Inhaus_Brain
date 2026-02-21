import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/proposal_model.dart';
import '../providers/proposals_provider.dart';
import '../providers/proposal_session_provider.dart';
import '../services/proposals_lm_service.dart';
import '../services/proposal_pdf_service.dart';
import '../widgets/quote_preview_modal.dart';
import '../widgets/quote_editor_modal.dart';
import '../widgets/create_package_modal.dart';
import '../../knowledge/widgets/add_source_dialog.dart';
import '../../agency/providers/service_catalog_riverpod_provider.dart';
import '../../agency/models/agency_service_model.dart';
import '../../clients/providers/client_provider.dart';
import '../../clients/models/client_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../widgets/editor_modal.dart';
import '../widgets/preview_modal.dart';
import '../../agency/services/proposal_storage_service.dart';
import '../../proposalsLM/widgets/cotizador_panel.dart';

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
  String _centerTab = 'chat'; // 'chat' or 'cotizador' — Center panel tab
  
  // Progress tracking for PDF generation
  bool _isGeneratingDetailed = false;
  bool _isGeneratingQuote = false;
  int _elapsedSeconds = 0;
  String _loadingMessage = 'Generating...';
  Timer? _progressTimer;

  // Research Panel State
  final _researchController = TextEditingController();
  String _researchSourceType = 'Web';
  String _researchDepthType = 'Fast Research';
  bool _isResearching = false;

  @override
  void dispose() {
    _chatController.dispose();
    _researchController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startLoading(String type, {String? message}) {
    _progressTimer?.cancel();
    _elapsedSeconds = 0;
    setState(() {
      _loadingMessage = message ?? 'Generating...';
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
    String cleanReply = rawResponse;
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Servicios agregados a la cotización."), backgroundColor: Colors.green));
      } else if (action == 'remove' && removeIds != null) {
        for (final id in removeIds) {
          notifier.removeService(id.toString());
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Servicios removidos de la cotización.")));
      } else if (action == 'set_client' && clientName != null) {
        notifier.setClientName(clientName);
        
        // Auto-create stub client in Firestore if it doesn't exist
        final clientState = ref.read(clientProvider);
        if (!clientState.clients.any((c) => c.name.toLowerCase() == clientName.toLowerCase())) {
          ref.read(clientProvider.notifier).addClient(
            name: clientName,
            clientType: ClientType.corporate,
            industry: 'Sin Especificar', 
          );
        }
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cliente actualizado a $clientName.")));
      } else if (action == 'set_discount' && discount != null) {
        notifier.setDiscount(discount);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Descuento del ${discount.toStringAsFixed(0)}% aplicado.")));
      } else if (action == 'set_iva_on') {
        notifier.setIva(true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("IVA 15% aplicado.")));
      } else if (action == 'set_iva_off') {
        notifier.setIva(false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("IVA removido.")));
      } else if (action == 'save') {
        notifier.saveSession();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cambios guardados."), backgroundColor: Colors.blue));
      }

      if (reply.isNotEmpty) {
        cleanReply = reply;
      } else {
        // If reply is empty but we have an action, stay silent or show action text
        cleanReply = rawResponse.replaceAll(RegExp(r'```(?:json)?[\s\S]*?```'), '').trim();
        if (cleanReply.isEmpty) {
           cleanReply = rawResponse.replaceAll(RegExp(r'\{[\s\S]*\}'), '').trim();
        }
      }

      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': cleanReply});
        });
      }
    } catch (e) {
       // Fallback: strip the JSON block if it exists but failed to parse, otherwise show raw
       String displayResponse = rawResponse.replaceAll(RegExp(r'```(?:json)?[\s\S]*?```'), '').trim();
       if (displayResponse.isEmpty) {
          displayResponse = rawResponse.replaceAll(RegExp(r'\{[\s\S]*\}'), '').trim();
       }
       if (displayResponse.isEmpty) displayResponse = rawResponse;
       
       if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': displayResponse});
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
        final idLower = id.toLowerCase();
        final service = catalog.services.firstWhere((s) {
          final sName = s.name.toLowerCase();
          return s.id == id || sName == idLower || sName.contains(idLower);
        });
        notifier.addService(service);
      } catch (_) {}
    }
  }

  String _extractJsonLocal(String raw) {
    // Try to find content between ```json and ```
    final blockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
    if (blockMatch != null) {
      return blockMatch.group(1) ?? "";
    }
    
    // Fallback to finding outermost curly braces
    final curlyMatch = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    return curlyMatch?.group(0) ?? raw;
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

  Future<void> _showEditorForGeneration({
    required String initialTitle,
    required String generationType, // 'detailed' or 'one_page'
  }) async {
    final session = ref.read(proposalSessionProvider);
    if (session == null) return;
    
    // 1. Generate text draft first
    _startLoading(generationType, message: 'Drafting content...');
    String draftContent = '';
    
    try {
      if (generationType == 'detailed' || generationType == 'slides') {
         final result = await ProposalsLMService.generateDetailedProposal(
           session.proposal,
           ref,
           selectedServices: session.selectedServices,
           client: _getClient(session.proposal),
           textOnly: true, // We need to add this flag to the service if it doesn't exist
         );
         // Simulate text draft if textOnly is not supported yet
         draftContent = result.content;
      } else {
         final result = await ProposalsLMService.generateOnePageQuote(
           session.proposal,
           ref,
           selectedServices: session.selectedServices,
           client: _getClient(session.proposal),
           textOnly: true, // We need to add this flag to the service if it doesn't exist
         );
         draftContent = result.content;
      }
    } catch (e) {
       _stopLoading();
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error drafting: $e"), backgroundColor: Colors.red));
       }
       return;
    }
    
    _stopLoading();

    // 2. Show Editor Modal
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditorModal(
        initialTitle: initialTitle,
        initialContent: draftContent,
        onPreview: () {
          // Open Preview on top
          showDialog(
            context: context,
            builder: (context) => PreviewModal(
              title: initialTitle, // Would normally grab from Editor but keeping simple
              content: draftContent, // Would actually be the current edited content
            ),
          );
        },
        onSave: (finalTitle, finalContent) async {
          // 3. Generate PDF with finalized content
          Navigator.pop(context); // Close Editor
          _startLoading(generationType, message: 'Generating PDF from your text...');
          
          try {
             final isOnePage = generationType == 'one_page';
             final isSlides = generationType == 'slides';
             final result = await ProposalsLMService.generatePdfFromEditedText(
               session.proposal,
               finalTitle,
               finalContent,
               ref,
               isOnePage: isOnePage,
               isSlides: isSlides,
               client: _getClient(session.proposal),
               discount: session.proposal.discount,
               applyIva: session.proposal.applyIva,
             );
             
             if (result.pdfBytes == null) {
               throw Exception("Failed to generate PDF. Check if JSON conversion worked.");
             }

             // Upload PDF to Storage
             final pdfUrl = await ProposalStorageService.uploadProposalOutput(
                proposalId: session.proposal.id,
                outputId: '${DateTime.now().millisecondsSinceEpoch}',
                fileBytes: result.pdfBytes!,
                fileExtension: 'pdf',
             );
             
             final output = ProposalOutput(
               id: DateTime.now().millisecondsSinceEpoch.toString(),
               type: isOnePage ? ProposalOutputType.onePagePdf : ProposalOutputType.detailedPdf,
               title: finalTitle,
               uri: pdfUrl,
               createdAt: DateTime.now(),
             );
             
             final proposal = session.proposal;
             final updatedProposal = proposal.copyWith(
               outputs: [...proposal.outputs, output],
               status: ProposalStatus.generated,
               updatedAt: DateTime.now(),
             );
             await ref.read(proposalsServiceProvider).updateProposal(updatedProposal);
             
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text("$finalTitle Generated successfully!"), backgroundColor: Colors.green),
               );
             }
          } catch (e) {
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating PDF: $e"), backgroundColor: Colors.red));
            }
          } finally {
            _stopLoading();
          }
        },
      ),
    );
  }

  Future<void> _generateDetailedProposal(Proposal proposal) async {
    await _showEditorForGeneration(
      initialTitle: "Detailed Proposal - ${proposal.clientName}",
      generationType: 'detailed',
    );
  }

  Future<void> _generateOnePageQuote(Proposal proposal) async {
    await _showEditorForGeneration(
      initialTitle: "One-Page Quote - ${proposal.clientName}",
      generationType: 'one_page',
    );
  }

  Future<void> _generateSlideDeck(Proposal proposal) async {
    await _showEditorForGeneration(
      initialTitle: "Slide Deck Proposal - ${proposal.clientName}",
      generationType: 'slides',
    );
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
              _buildLeftPanel(proposal),
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
        SizedBox(width: 320, child: _buildLeftPanel(proposal)),
        const VerticalDivider(width: 1, color: Colors.white12),
        Expanded(child: _buildChatPanel(proposal)),
        const VerticalDivider(width: 1, color: Colors.white12),
        SizedBox(width: 300, child: _buildStudioPanel(proposal)),
      ],
    );
  }

  Widget _buildLeftPanel(Proposal proposal) {
    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          _buildLeftTabs(),
          Expanded(
            child: _leftTabIndex == 0
                ? _buildSourcesTab(proposal)
                : _buildPackagesTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _leftTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _leftTabIndex == 0 ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Sources",
                    style: TextStyle(
                      color: _leftTabIndex == 0 ? AppTheme.primary : Colors.white54,
                      fontWeight: _leftTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _leftTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _leftTabIndex == 1 ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Packages",
                    style: TextStyle(
                      color: _leftTabIndex == 1 ? AppTheme.primary : Colors.white54,
                      fontWeight: _leftTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesTab(Proposal proposal) {
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
          
          // NotebookLM Style Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _researchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Search the web for new sources",
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                      suffixIcon: IconButton(
                        icon: _isResearching 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white38)))
                          : const Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 18),
                        onPressed: _isResearching ? null : () => _handleResearchSubmit(),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        _buildResearchOption(
                          icon: Icons.public,
                          label: _researchSourceType,
                          onChanged: (val) => setState(() => _researchSourceType = val!),
                          options: ['Web', 'Drive'],
                        ),
                        const SizedBox(width: 8),
                        _buildResearchOption(
                          icon: Icons.auto_awesome,
                          label: _researchDepthType,
                          onChanged: (val) => setState(() => _researchDepthType = val!),
                          options: ['Fast Research', 'Deep Research'],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

  Widget _buildPackagesTab() {
    final servicesAsync = ref.watch(servicesListProvider);
    
    return servicesAsync.when(
      data: (services) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Crear Paquete Personalizado", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CreatePackageModal(),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: services.isEmpty 
                ? const Center(child: Text("No packages available.", style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('USD ${service.basePrice.toStringAsFixed(2)} • ${service.frequency}', style: const TextStyle(color: AppTheme.primary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(service.description, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                         ref.read(proposalSessionProvider.notifier).addService(service);
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${service.name} agregado a la cotización"), backgroundColor: Colors.green));
                      },
                      child: const Text("+ Agregar", style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildResearchOption({
    required IconData icon,
    required String label,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: label,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38, size: 14),
          dropdownColor: AppTheme.surface,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _handleResearchSubmit() async {
    final query = _researchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isResearching = true);
    
    try {
      final session = ref.read(proposalSessionProvider);
      if (session == null) return;
      
      final isDeep = _researchDepthType == 'Deep Research';
      final result = await ProposalsLMService.researchContent(query, isDeep: isDeep);
      
      if (mounted) {
        final newSource = ProposalSource(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          proposalId: session.proposal.id,
          name: "Research: $query",
          type: ProposalSourceType.web, // Use .web instead of .website
          content: result,
          addedAt: DateTime.now(), // Use addedAt instead of createdAt
        );

        ref.read(proposalSessionProvider.notifier).addRawSource(newSource);
        
        setState(() {
          _isResearching = false;
          _researchController.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Research added as a new source: $query"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Research failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
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
        // ---- Center Panel Tab Switcher ----
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              _centerTabBtn('Chat', Icons.chat_bubble_outline, 'chat'),
              const SizedBox(width: 8),
              _centerTabBtn('Cotizador', Icons.receipt_long_outlined, 'cotizador'),
            ],
          ),
        ),
        // ---- Tab Content ----
        Expanded(
          child: _centerTab == 'cotizador'
              ? CotizadorPanel(
                  onClose: () => setState(() => _centerTab = 'chat'),
                )
              : _buildChatContent(proposal),
        ),
      ],
    );
  }

  Widget _centerTabBtn(String label, IconData icon, String tab) {
    final isActive = _centerTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _centerTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.accent.withValues(alpha: 0.5) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? AppTheme.accent : Colors.white38),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppTheme.accent : Colors.white54,
                )),
          ],
        ),
      ),
    );
  }

  /// The original chat content — extracted so it can live alongside the Cotizador tab.
  Widget _buildChatContent(Proposal proposal) {
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

  Widget _buildPricingSummary() {
    final session = ref.watch(proposalSessionProvider);
    if (session == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal", style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text("\$${session.subtotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          if (session.proposal.discount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Descuento (${session.proposal.discount.toStringAsFixed(0)}%)", style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                Text("-\$${session.discountAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
            ),
          ],
          if (session.proposal.applyIva) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("IVA (15%)", style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text("\$${session.ivaAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ],
          const Divider(height: 16, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Text("\$${session.total.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => QuotePreviewModal(proposal: session.proposal),
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye, size: 16, color: AppTheme.primary),
                  label: const Text("Ver", style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => QuoteEditorModal(proposal: session.proposal),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16, color: Colors.white70),
                  label: const Text("Editar", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
            ],
          ),
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
                _buildPricingSummary(),
                const SizedBox(height: 24),
                // Core Generation Tools
                const Text("CORE OUTPUTS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _buildStudioButton(
                  icon: Icons.description,
                  label: "Detailed Proposal",
                  subtitle: "Full PDF",
                  onPressed: () => _generateDetailedProposal(proposal),
                  isGenerating: _isGeneratingDetailed,
                ),
                const SizedBox(height: 12),
                _buildStudioButton(
                  icon: Icons.receipt_long,
                  label: "One-Page Quote",
                  subtitle: "Quick summary",
                  onPressed: () => _generateOnePageQuote(proposal),
                  isGenerating: _isGeneratingQuote,
                ),
                const SizedBox(height: 12),
                _buildStudioButton(
                  icon: Icons.view_carousel,
                  label: "Slide Deck",
                  subtitle: "Horizontal PDF",
                  onPressed: () => _generateSlideDeck(proposal),
                  isGenerating: false,
                ),
                
                const SizedBox(height: 24),
                const Text("SYSTEM", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _buildStudioButton(
                  icon: Icons.save,
                  label: "Guardar Cambios",
                  subtitle: "Sync to cloud",
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
                const Text("OUTPUTS", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (proposal.outputs.isEmpty)
                  const Text("No outputs yet", style: TextStyle(color: Colors.white38, fontSize: 12))
                else
                  ...proposal.outputs.map((output) => ListTile(
                        leading: Icon(_getOutputIcon(output.type), color: AppTheme.primary, size: 20),
                        title: Text(output.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(_formatDate(output.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        onTap: () {
                          if (output.uri != null && output.uri!.isNotEmpty) {
                             launchUrl(Uri.parse(output.uri!));
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: const Text("PDF disponible en caché local para compartir. Vuelve a generarlo para abrirlo si recargaste la página."), 
                                 backgroundColor: AppTheme.primary,
                                 action: SnackBarAction(label: "OK", textColor: Colors.white, onPressed: () {}),
                               ),
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

  Widget _buildGridButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return Container(
      width: 128, // Fix width for grid-like appearance in Wrap
      height: 70,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surface.withValues(alpha: 0.5),
          side: BorderSide(color: onPressed != null ? AppTheme.primary.withValues(alpha: 0.2) : Colors.white12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: onPressed != null ? AppTheme.primary : Colors.white12, size: 18),
            const SizedBox(height: 4),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: TextStyle(color: onPressed != null ? Colors.white : Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showOverviewModal(String target) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F16),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text(
                "Create Audio and Video Overviews from",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.normal),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF10B981)],
                ).createShader(Offset.zero & bounds.size),
                child: Text(
                  target,
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 48),
              
              // Mock Search bar
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white38),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text("Search the web for new sources", style: TextStyle(color: Colors.white24, fontSize: 16)),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.white24),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const Text("or drop your files", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const Text("pdf, images, docs, audio, and more", style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 48),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModalAction(Icons.upload, "Upload files"),
                  const SizedBox(width: 16),
                  _buildModalAction(Icons.link, "Websites"),
                  const SizedBox(width: 16),
                  _buildModalAction(Icons.cloud_queue, "Drive"),
                  const SizedBox(width: 16),
                  _buildModalAction(Icons.content_paste, "Copied text"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
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
                      isGenerating ? "$_loadingMessage ${_elapsedSeconds}s" : subtitle,
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
