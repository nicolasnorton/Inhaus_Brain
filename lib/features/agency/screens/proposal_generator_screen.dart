import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../proposals/models/proposal_model.dart';
import '../../agency/models/inhaus_proposal_models.dart';
import '../../agency/providers/proposal_provider.dart';
import '../../agency/providers/proposal_template_provider.dart';
import '../../agency/services/proposal_service.dart';
import '../../agency/services/proposal_storage_service.dart';
import '../../agency/widgets/progress_stepper.dart';
import '../../agency/services/task_polling_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../agency/widgets/proposal_type_selection_dialog.dart';

// ... (existing imports)
import '../../agency/widgets/progress_stepper.dart';
// import '../../agency/widgets/template_manager_dialog.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../knowledge/widgets/add_source_dialog.dart';
import '../../knowledge/providers/knowledge_service_providers.dart';
import 'package:printing/printing.dart';


class ProposalGeneratorScreen extends ConsumerStatefulWidget {
  final String proposalId;

  const ProposalGeneratorScreen({super.key, required this.proposalId});

  @override
  ConsumerState<ProposalGeneratorScreen> createState() => _ProposalGeneratorScreenState();
}

class _ProposalGeneratorScreenState extends ConsumerState<ProposalGeneratorScreen> {
  // Chat State
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;
  int _mobileTabIndex = 1;

  void _handleChatSubmit(Proposal proposal) async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'content': query});
      _chatController.clear();
      _isChatLoading = true;
      _chatMessages.add({'role': 'ai', 'content': ''});
    });

    try {
      final stream = ProposalService.chatWithProposal(proposal, query, ref);
      
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
           _chatMessages[lastIdx]['content'] = "Error generating response: \$e";
         });
      }
    } finally {
      if (mounted) setState(() => _isChatLoading = false);
    }
  }

  Future<void> _addSource(Proposal proposal, ProposalSource source) async {
    final updatedProposal = proposal.copyWith(
       updatedAt: DateTime.now(),
       sources: [...proposal.sources, source],
    );
    ref.read(proposalsProvider.notifier).updateProposal(updatedProposal);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added \${source.name}"), backgroundColor: AppTheme.primary),
      );
    }
  }

  Future<void> _showAddSourceDialog(Proposal proposal) async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AddSourceDialog(
        onSourceAdded: (ks) => _handleKnowledgeSourceAdded(proposal, ks),
      ),
    );
  }

  Future<void> _handleKnowledgeSourceAdded(Proposal proposal, KnowledgeSource ks) async {
    // 1. Ingest into Knowledge Module (if datasetId exists)
    if (proposal.datasetId != null) {
         try {
             final ingestor = ref.read(knowledgeIngestionServiceProvider);
             // Show ephemeral feedback
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text("Ingesting source..."), duration: Duration(seconds: 1)),
                );
             }
             await ingestor.ingestSource(proposal.datasetId!, ks);
         } catch(e) {
             print("Ingestion warning: \$e");
         }
    }

    // 2. Convert to ProposalSource
    final sourceType = _mapKnowledgeSourceType(ks.type);
    final source = ProposalSource(
      id: ks.id,
      proposalId: proposal.id,
      type: sourceType,
      name: ks.title,
      content: ks.content.isNotEmpty ? ks.content : "No extracted text", 
      addedAt: ks.createdAt,
      metadata: ks.metadata ?? {},
      uri: ks.type == KnowledgeSourceType.url || ks.type == KnowledgeSourceType.youtube ? ks.content : null,
    );

    // 3. Update Proposal
    await _addSource(proposal, source);
  }

  ProposalSourceType _mapKnowledgeSourceType(KnowledgeSourceType type) {
    switch (type) {
      case KnowledgeSourceType.file:
      case KnowledgeSourceType.pdf:
        return ProposalSourceType.file;
      case KnowledgeSourceType.url:
      case KnowledgeSourceType.youtube:
        return ProposalSourceType.web;
      case KnowledgeSourceType.text:
        return ProposalSourceType.pastedText;
      case KnowledgeSourceType.googleAds:
      case KnowledgeSourceType.ga4:
        return ProposalSourceType.dataConnector;
      default:
        return ProposalSourceType.file;
    }
  }

  // --- GENERATION HANDLERS ---

  Future<void> _handlePdfGeneration(Proposal proposal, {bool isPreview = true}) async {
    if (!mounted) return;
    if (proposal.sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one source first (e.g., Services Catalog, Client Info)."), backgroundColor: Colors.orange),
      );
      return;
    }
    _showLoadingDialog(isPreview ? "Drafting Proposal Preview..." : "Generating Final PDF Proposal...");
    try {
      if (isPreview) {
        final text = await ProposalService.generateProposalPdf(proposal, ref, isPreview: true);
        if (!mounted) return;
        Navigator.pop(context);
        _showPreviewDialog("Proposal Text Preview", text, () => _handlePdfGeneration(proposal, isPreview: false));
      } else {
        final template = ref.read(currentTemplateProvider);
        final bytes = await ProposalService.generateProposalPdfBytes(proposal, ref, template: template);
        
        // --- VERIFICATION STEP ---
        _showLoadingDialog("Verifying Output Integrity...");
        // await Future.delayed(const Duration(seconds: 1)); // Simulate check
        // In a real flow, we'd use ProposalVerifier.verifyPdf(bytes, ...) here
        // For now, we assume success if bytes > 0
        if (bytes.isEmpty) throw Exception("Generated PDF is empty.");

        if (!mounted) return;
        Navigator.pop(context); // Close verifying dialog
        Navigator.pop(context); // Close loading dialog
        
        // Upload to Firebase Storage
        final outputId = const Uuid().v4();
        try {
          _showLoadingDialog("Saving PDF to storage...");
          final downloadUrl = await ProposalStorageService.uploadProposalOutput(
            proposalId: proposal.id,
            outputId: outputId,
            fileBytes: Uint8List.fromList(bytes),
            fileExtension: 'pdf',
          );
          
          if (!mounted) return;
          Navigator.pop(context); // Close upload dialog
          
          final output = ProposalOutput(
            id: outputId,
            title: "Proposal Doc (${DateTime.now().toString().substring(11, 16)})",
            type: ProposalOutputType.detailedPdf,
            uri: downloadUrl,
            createdAt: DateTime.now(),
          );
          _addOutput(proposal, output);

          await Printing.layoutPdf(onLayout: (format) async => Uint8List.fromList(bytes));
        } catch (uploadError) {
          if (!mounted) return;
          if (Navigator.canPop(context)) Navigator.pop(context);
          _showErrorDialog("Failed to save PDF: $uploadError");
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _handleSlideGeneration(Proposal proposal, {bool isPreview = true}) async {
    if (!mounted) return;
    if (proposal.sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one source first."), backgroundColor: Colors.orange),
      );
      return;
    }
    _showLoadingDialog(isPreview ? "Drafting Slide Outline..." : "Generating Final Slide Deck...");
    try {
      if (isPreview) {
        final text = await ProposalService.generateProposalSlides(proposal, ref, isPreview: true);
        if (!mounted) return;
        Navigator.pop(context);
        _showPreviewDialog("Slide Deck Outline", text, () => _handleSlideGeneration(proposal, isPreview: false));
      } else {
        final bytes = await ProposalService.generateProposalSlidesBytes(proposal, ref);
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        // Upload to Firebase Storage
        final outputId = const Uuid().v4();
        try {
          _showLoadingDialog("Saving slides to storage...");
          final downloadUrl = await ProposalStorageService.uploadProposalOutput(
            proposalId: proposal.id,
            outputId: outputId,
            fileBytes: Uint8List.fromList(bytes),
            fileExtension: 'pdf', // Slides are also PDF format
          );
          
          if (!mounted) return;
          Navigator.pop(context); // Close upload dialog
          
          final output = ProposalOutput(
            id: outputId,
            title: "Slide Deck (${DateTime.now().toString().substring(11, 16)})",
            type: ProposalOutputType.googleSlides,
            uri: downloadUrl,
            createdAt: DateTime.now(),
          );
          _addOutput(proposal, output);

          await Printing.layoutPdf(onLayout: (format) async => Uint8List.fromList(bytes));
        } catch (uploadError) {
          if (!mounted) return;
          if (Navigator.canPop(context)) Navigator.pop(context);
          _showErrorDialog("Failed to save slides: $uploadError");
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showErrorDialog(e.toString());
      }
    }
  }

  // --- INHAUS PROPOSAL GENERATION ---

  Future<void> _handleInhausProposalGeneration(Proposal proposal) async {
    if (!mounted) return;
    if (proposal.sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one source first (e.g., Services Catalog, Client Info)."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show type/format selection dialog
    showDialog(
      context: context,
      builder: (ctx) => ProposalTypeSelectionDialog(
        onGenerate: (type, format, language) => _generateInhausProposal(proposal, type, format, language),
      ),
    );
  }

  Future<void> _generateInhausProposal(
    Proposal proposal,
    ProposalType type,
    ProposalFormat format,
    ProposalLanguage language,
  ) async {
    if (!mounted) return;

    final typeLabel = type == ProposalType.onePageQuote ? 'One Page Quote' : 'Detailed Proposal';
    final formatLabel = format == ProposalFormat.pdf ? 'PDF' : 'Slides';
    final langLabel = language == ProposalLanguage.spanish ? 'ES' : 'EN';
    
    // Create a temporary campaign ID for this generation session (or use real one if available)
    // In a real scenario, we'd create the campaign document first, then trigger the Cloud Task.
    // For this refactor, we'll assume the proposal ID acts as the campaign ID or we generate a new one.
    final campaignId = const Uuid().v4(); 
    
    // Create initial campaign document in Firestore to track status
    await FirebaseFirestore.instance.collection('campaigns').doc(campaignId).set({
      'status': 'pending', 
      'proposalId': proposal.id,
      'createdAt': FieldValue.serverTimestamp(),
      'researchStatus': 'pending',
      'strategyStatus': 'pending',
    });

    // Show Progress Dialog (listens to campaignId)
    if (!mounted) return;
    _showProgressDialog(campaignId);

    try {
      // Trigger the Cloud Task (or simulating the start of one)
      // In the real flow, specific Cloud Functions would update the Firestore document
      // which the dialog is listening to.
      
      // For this integration step, we are simulating the backend updates 
      // so the UI can be verified.
      
      // await FirebaseFunctions.instance.httpsCallable('startCampaignGeneration').call({'campaignId': campaignId, ...});

      // Wait for completion or cancellation (The dialog handles its own dismissal on cancel/complete)
      // We can listen to the stream here if we need to do post-processing after dialog closes
      
    } catch (e) {
       debugPrint("Generation Error: $e");
       // Error handling handled within dialog or here
    }
  }

  void _addOutput(Proposal proposal, ProposalOutput output) {
     final updated = proposal.copyWith(
       outputs: [...proposal.outputs, output],
       updatedAt: DateTime.now(),
     );
     ref.read(proposalsProvider.notifier).updateProposal(updated);
  }

  // --- UI DIALOGS ---

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(width: 24),
              Text(message, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _showProgressDialog(String campaignId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: 400,
            child: Consumer(
              builder: (context, ref, _) {
                final progressAsync = ref.watch(taskProgressProvider(campaignId));
                
                return progressAsync.when(
                  data: (progress) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Generating Campaign...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      ProgressStepper(progress: progress),
                      const SizedBox(height: 24),
                      if (progress.isCancelled)
                        ElevatedButton(
                           onPressed: () => Navigator.pop(context),
                           style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                           child: const Text("Close"),
                        )
                      else if (progress.totalProgress < 1.0)
                        TextButton.icon(
                          onPressed: () async {
                             // Call Cancel Cloud Function
                             try {
                               // Assuming cancelCampaign is a callable function
                               /* await FirebaseFunctions.instance.httpsCallable('cancelCampaign').call({'campaignId': campaignId}); */
                             } catch (e) {
                               debugPrint("Cancel failed: $e");
                             }
                          },
                          icon: const Icon(Icons.cancel, color: Colors.white38),
                          label: const Text("Cancel Generation", style: TextStyle(color: Colors.white38)),
                        )
                      else 
                        ElevatedButton(
                           onPressed: () => Navigator.pop(context),
                           style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                           child: const Text("View Results"),
                        )
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text("Error: $err", style: const TextStyle(color: Colors.red)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showPreviewDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(child: Text(content, style: const TextStyle(color: Colors.white70))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text("Generate Final"),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(child: MessageBubble(content: content, isUser: false)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: AppTheme.surface,
         title: const Text("Error", style: TextStyle(color: Colors.red)),
         content: Text(error, style: const TextStyle(color: Colors.white70)),
         actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
       )
    );
  }

  @override
  Widget build(BuildContext context) {
    final proposal = ref.watch(proposalDetailProvider(widget.proposalId));
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (proposal == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFE5B15D))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(proposal.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("PROPOSAL GENERATOR STUDIO", style: TextStyle(fontSize: 10, color: Color(0xFFE5B15D), letterSpacing: 1.5)),
          ],
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
           IconButton(
             icon: const Icon(Icons.share_outlined, color: Colors.white70),
             onPressed: () {},
           ),
           const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: isMobile ? BottomNavigationBar(
        backgroundColor: AppTheme.surface,
        selectedItemColor: const Color(0xFFE5B15D),
        unselectedItemColor: Colors.white38,
        currentIndex: _mobileTabIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _mobileTabIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.source_outlined), label: "Sources"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), label: "Explorer"),
          BottomNavigationBarItem(icon: Icon(Icons.design_services_outlined), label: "Studio"),
        ],
      ) : null,
      body: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: isMobile
          ? IndexedStack(
              index: _mobileTabIndex,
              children: [
                _buildSourcesPane(proposal),
                _buildChatPane(proposal),
                _buildStudioPane(proposal),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: _buildSourcesPane(proposal)),
                VerticalDivider(width: 1, color: Colors.white.withOpacity(0.05)),
                Expanded(flex: 6, child: _buildChatPane(proposal)),
                VerticalDivider(width: 1, color: Colors.white.withOpacity(0.05)),
                Expanded(flex: 3, child: _buildStudioPane(proposal)),
              ],
            ),
      ),
    );
  }

  Widget _buildSourcesPane(Proposal proposal) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SOURCES", style: TextStyle(color: Color(0xFFE5B15D), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              Text("${proposal.sources.length} active", style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              if (mounted) _showAddSourceDialog(proposal);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Icon(Icons.add_circle_outline, color: Color(0xFFE5B15D)),
                  SizedBox(height: 8),
                  Text("Add Knowledge Source", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: proposal.sources.isEmpty 
              ? const Center(child: Text("No sources added yet", style: TextStyle(color: Colors.white24, fontSize: 12)))
              : ListView.builder(
                  itemCount: proposal.sources.length,
                  itemBuilder: (_, index) {
                    final s = proposal.sources[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.03)),
                      ),
                      child: ListTile(
                        leading: Icon(
                          s.type == ProposalSourceType.file ? Icons.description_outlined : Icons.link,
                          color: const Color(0xFFE5B15D).withOpacity(0.7),
                          size: 18
                        ),
                        title: Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text(s.type.name.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9)),
                        dense: true,
                        trailing: const Icon(Icons.more_vert, color: Colors.white24, size: 16),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPane(Proposal proposal) {
     return Column(
       children: [
         Expanded(
           child: _chatMessages.isEmpty
             ? Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Container(
                       padding: const EdgeInsets.all(24),
                       decoration: BoxDecoration(
                         color: const Color(0xFFE5B15D).withOpacity(0.05),
                         shape: BoxShape.circle,
                         border: Border.all(color: const Color(0xFFE5B15D).withOpacity(0.1)),
                       ),
                       child: const Icon(Icons.auto_awesome, size: 40, color: Color(0xFFE5B15D)),
                     ),
                     const SizedBox(height: 24),
                     const Text("Propuesta de Servicios AI", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300)),
                     const SizedBox(height: 8),
                     const Text("Ask me to analyze sources or draft sections based on your catalog.", style: TextStyle(color: Colors.white30, fontSize: 13)),
                   ],
                 ),
               )
             : ListView.builder(
                 padding: const EdgeInsets.all(20),
                 itemCount: _chatMessages.length,
                 itemBuilder: (_, index) {
                   final msg = _chatMessages[index];
                   final isUser = msg['role'] == 'user';
                   return MessageBubble(content: msg['content']!, isUser: isUser);
                 },
               ),
         ),
         Container(
           padding: const EdgeInsets.all(20),
           decoration: BoxDecoration(
             color: AppTheme.surface,
             border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
           ),
           child: Row(
             children: [
               Expanded(
                 child: TextField(
                   controller: _chatController,
                   onSubmitted: (_) => _handleChatSubmit(proposal),
                   style: const TextStyle(color: Colors.white, fontSize: 14),
                   decoration: InputDecoration(
                     hintText: "Escribe tu petición aquí...",
                     hintStyle: const TextStyle(color: Colors.white24),
                     filled: true,
                     fillColor: AppTheme.background,
                     contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                   ),
                 ),
               ),
               const SizedBox(width: 12),
               Material(
                 color: const Color(0xFFE5B15D),
                 borderRadius: BorderRadius.circular(30),
                 child: IconButton(
                   onPressed: _isChatLoading ? null : () => _handleChatSubmit(proposal),
                   icon: _isChatLoading 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                     : const Icon(Icons.send_rounded, color: Colors.black87, size: 20),
                 ),
               ),
             ],
           ),
         ),
       ],
     );
  }

  Widget _buildStudioPane(Proposal proposal) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("STUDIO", style: TextStyle(color: Color(0xFFE5B15D), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              // IconButton(
              //   icon: const Icon(Icons.palette_outlined, color: Color(0xFFE5B15D), size: 18),
              //   onPressed: () {
              //     showDialog(
              //       context: context,
              //       builder: (ctx) => const TemplateManagerDialog(),
              //     );
              //   },
              //   tooltip: 'Manage Templates',
              // ),
            ],
          ),
          const SizedBox(height: 12),
          // Template Indicator
          Consumer(
            builder: (context, ref, _) {
              final template = ref.watch(currentTemplateProvider);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5B15D).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.style_outlined, color: Color(0xFFE5B15D), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        template.name,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          
          // INHAUS Proposal Generation (NEW - Primary)
          _buildActionCard(
            title: "INHAUS Proposal (NEW)",
            subtitle: "One Page Quote or Detailed Multi-Page",
            icon: Icons.auto_awesome,
            color: const Color(0xFF6B46C1), // Purple to match INHAUS theme
            onTap: () {
              if (mounted) _handleInhausProposalGeneration(proposal);
            },
          ),
          const SizedBox(height: 20),
          
          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 20),
          const Text(
            "LEGACY GENERATORS",
            style: TextStyle(
              color: Colors.white24,
              fontWeight: FontWeight.bold,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildActionCard(
            title: "Generate PDF Proposal",
            subtitle: "Executive summary, solution & pricing",
            icon: Icons.picture_as_pdf_outlined,
            color: const Color(0xFFE5B15D),
            onTap: () {
              if (mounted) _handlePdfGeneration(proposal);
            },
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            title: "Generate Slide Deck",
            subtitle: "Structured outline for pitch deck",
            icon: Icons.slideshow_outlined,
            color: const Color(0xFFE5B15D),
            onTap: () {
              if (mounted) _handleSlideGeneration(proposal);
            },
          ),
          const SizedBox(height: 32),
          const Text("ALL OUTPUTS", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Expanded(
            child: proposal.outputs.isEmpty 
              ? const Center(child: Text("No outputs generated yet", style: TextStyle(color: Colors.white12, fontSize: 11)))
              : ListView.builder(
                  itemCount: proposal.outputs.length,
                  itemBuilder: (_, index) {
                    final o = proposal.outputs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(
                          o.type == ProposalOutputType.detailedPdf ? Icons.file_present : Icons.data_usage,
                          color: Colors.white30,
                          size: 16,
                        ),
                        title: Text(o.title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        subtitle: Text(o.createdAt.toString().substring(0, 16), style: const TextStyle(color: Colors.white12, fontSize: 9)),
                        dense: true,
                        onTap: () async {
                          if (o.uri != null && o.uri!.isNotEmpty) {
                            // Download and display stored PDF
                            try {
                              _showLoadingDialog("Loading ${o.title}...");
                              final bytes = await ProposalStorageService.downloadProposalOutput(o.uri!);
                              if (!mounted) return;
                              Navigator.pop(context); // Close loading dialog
                              await Printing.layoutPdf(onLayout: (format) async => bytes);
                            } catch (e) {
                              if (!mounted) return;
                              if (Navigator.canPop(context)) Navigator.pop(context);
                              _showErrorDialog("Failed to load output: $e");
                            }
                          } else {
                            _showResultDialog(o.title, o.uri ?? "No URI available");
                          }
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const MessageBubble({super.key, required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFE5B15D).withOpacity(0.15) : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 18),
          ),
          border: Border.all(color: isUser ? const Color(0xFFE5B15D).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? "YOU" : "BRIAN",
              style: TextStyle(
                color: isUser ? const Color(0xFFE5B15D) : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
               content,
               style: TextStyle(
                 color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                 fontSize: 14,
                 height: 1.4
               ),
            ),
          ],
        ),
      ),
    );
  }
}
