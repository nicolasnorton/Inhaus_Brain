import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../agency/models/proposal_model.dart';
import '../../agency/providers/proposal_provider.dart';
import '../../agency/services/proposal_service.dart';
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
        final bytes = await ProposalService.generateProposalPdfBytes(proposal, ref);
        if (!mounted) return;
        Navigator.pop(context);
        
        final output = ProposalOutput(
          id: const Uuid().v4(),
          title: "Proposal Doc (${DateTime.now().minute})",
          type: ProposalOutputType.pdf,
          createdAt: DateTime.now(),
        );
        _addOutput(proposal, output);

        await Printing.layoutPdf(onLayout: (format) async => Uint8List.fromList(bytes));

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
        Navigator.pop(context);

        final output = ProposalOutput(
          id: const Uuid().v4(),
          title: "Slide Deck (${DateTime.now().minute})",
          type: ProposalOutputType.slides,
          createdAt: DateTime.now(),
        );
        _addOutput(proposal, output);

        await Printing.layoutPdf(onLayout: (format) async => Uint8List.fromList(bytes));

      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showErrorDialog(e.toString());
      }
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
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Proposal Not Found")),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(proposal.title),
        backgroundColor: AppTheme.surface,
      ),
      bottomNavigationBar: isMobile ? BottomNavigationBar(
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.white38,
        currentIndex: _mobileTabIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _mobileTabIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.source_outlined), label: "Sources"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Explorer"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_suggest_outlined), label: "Studio"),
        ],
      ) : null,
      body: isMobile
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
              const VerticalDivider(width: 1, color: Colors.white10),
              Expanded(flex: 5, child: _buildChatPane(proposal)),
              const VerticalDivider(width: 1, color: Colors.white10),
              Expanded(flex: 3, child: _buildStudioPane(proposal)),
            ],
          ),
    );
  }

  Widget _buildSourcesPane(Proposal proposal) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sources", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              if (mounted) _showAddSourceDialog(proposal);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text("+ Add Source", style: TextStyle(color: AppTheme.primary))),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: proposal.sources.length,
              itemBuilder: (_, index) {
                final s = proposal.sources[index];
                return ListTile(
                  leading: const Icon(Icons.description, color: Colors.white54, size: 20),
                  title: Text(s.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.type.name.toUpperCase(), style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  dense: true,
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
             ? const Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(FontAwesomeIcons.robot, size: 48, color: Colors.white24),
                     SizedBox(height: 16),
                     Text("Proposal Specialist", style: TextStyle(color: Colors.white54, fontSize: 18)),
                     Text("Ask me to analyze sources or draft sections.", style: TextStyle(color: Colors.white30)),
                   ],
                 ),
               )
             : ListView.builder(
                 padding: const EdgeInsets.all(16),
                 itemCount: _chatMessages.length,
                 itemBuilder: (_, index) {
                   final msg = _chatMessages[index];
                   final isUser = msg['role'] == 'user';
                   return MessageBubble(content: msg['content']!, isUser: isUser);
                 },
               ),
         ),
         Container(
           padding: const EdgeInsets.all(16),
           decoration: const BoxDecoration(
             color: AppTheme.surface,
             border: Border(top: BorderSide(color: Colors.white10)),
           ),
           child: Row(
             children: [
               Expanded(
                 child: TextField(
                   controller: _chatController,
                   onSubmitted: (_) => _handleChatSubmit(proposal),
                   style: const TextStyle(color: Colors.white),
                   decoration: InputDecoration(
                     hintText: "Ask about the proposal...",
                     hintStyle: const TextStyle(color: Colors.white30),
                     filled: true,
                     fillColor: AppTheme.background,
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                   ),
                 ),
               ),
               const SizedBox(width: 8),
               IconButton(
                 onPressed: _isChatLoading ? null : () => _handleChatSubmit(proposal),
                 icon: _isChatLoading 
                   ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                   : const Icon(Icons.send, color: AppTheme.primary),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Studio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(color: Colors.white10, height: 24),
          _buildActionCard(
            title: "Generate PDF Proposal",
            subtitle: "Executive summary, solution & pricing",
            icon: FontAwesomeIcons.filePdf,
            color: Colors.redAccent,
            onTap: () {
              if (mounted) _handlePdfGeneration(proposal);
            },
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            title: "Generate Slide Deck",
            subtitle: "Outline for Google Slides",
            icon: FontAwesomeIcons.filePowerpoint,
            color: Colors.orangeAccent,
            onTap: () {
              if (mounted) _handleSlideGeneration(proposal);
            },
          ),
          const SizedBox(height: 24),
          const Text("Outputs", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: proposal.outputs.length,
              itemBuilder: (_, index) {
                final o = proposal.outputs[index];
                return ListTile(
                  leading: Icon(
                    o.type == ProposalOutputType.pdf ? FontAwesomeIcons.filePdf : FontAwesomeIcons.filePowerpoint,
                    color: Colors.white54,
                    size: 16,
                  ),
                  title: Text(o.title, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  subtitle: Text(o.createdAt.toIso8601String().substring(0, 16), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  onTap: () => _showResultDialog(o.title, o.content ?? "No content."),
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
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isUser ? AppTheme.primary.withOpacity(0.5) : Colors.white10),
        ),
        constraints: const BoxConstraints(maxWidth: 600),
        child: SelectableText(
           content,
           style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
