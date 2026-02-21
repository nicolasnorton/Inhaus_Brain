import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/report_model.dart';
import '../models/source_model.dart';
import '../../../../core/services/sources_service.dart';
import '../../../../core/services/reports_lm_service.dart';
import '../providers/reports_provider.dart';
import '../../../../core/widgets/video_preview_player.dart';
import '../../connectors/models/connected_account_model.dart';
import '../../../../core/services/integration_service.dart';
import '../../knowledge/widgets/add_source_dialog.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../knowledge/providers/knowledge_service_providers.dart';
import '../../knowledge/providers/knowledge_provider.dart';
import '../../../../core/services/edge_ai_service.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  // Chat State
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;
  int _mobileTabIndex = 1; // Default to Chat on mobile

  void _handleChatSubmit(Report report) async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'content': query});
      _chatController.clear();
      _isChatLoading = true;
      // Add empty AI bubble to fill
      _chatMessages.add({'role': 'ai', 'content': ''});
    });

    try {
      final stream = ReportsLMService.chatWithReport(report, query, ref);
      
      await for (final chunk in stream) {
        if (!mounted) break;
        setState(() {
          // Append to last AI message
          final lastIdx = _chatMessages.length - 1;
          _chatMessages[lastIdx]['content'] = _chatMessages[lastIdx]['content']! + chunk;
        });
      }
    } catch (e) {
      if (mounted) {
         setState(() {
           final lastIdx = _chatMessages.length - 1;
           _chatMessages[lastIdx]['content'] = "Error generating response: $e";
         });
      }
    } finally {
      if (mounted) setState(() => _isChatLoading = false);
    }
  }

  Future<void> _addSource(Report report, ReportSource source) async {
    try {
      final updatedReport = report.copyWith(
         updatedAt: DateTime.now(),
         sources: [...report.sources, source],
      );

      await ref.read(reportsServiceProvider).updateReport(updatedReport);
      
      // Invalidate to fetch fresh data
      ref.invalidate(reportProvider(widget.reportId));
      
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

  Future<void> _showAddSourceDialog(Report report) async {
    showDialog(
      context: context,
      builder: (context) => AddSourceDialog(
        onSourceAdded: (ks) => _handleKnowledgeSourceAdded(report, ks),
      ),
    );
  }

  Future<void> _handleKnowledgeSourceAdded(Report report, KnowledgeSource ks) async {
    // 0. Ensure Report has a Dataset ID (Knowledge Base)
    String? datasetId = report.datasetId;
    if (datasetId == null) {
        // Create new KB
        try {
            final api = ref.read(knowledgeApiServiceProvider);
            final kb = await api.createKnowledgeBase(
                name: "KB for ${report.title}", 
                description: "Auto-generated knowledge base for report."
            );
            datasetId = kb.id;
            
            // Update Report with new Dataset ID immediately
            final updatedReport = report.copyWith(datasetId: datasetId);
            await ref.read(reportsServiceProvider).updateReport(updatedReport);
            
            // Update local report reference to ensure subsequent calls use the new ID
            report = updatedReport;
            
        } catch (e) {
            _showErrorDialog("Failed to create Knowledge Base: $e");
            return;
        }
    }

    // 1. Ingest/Index Source (Async)
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Row(
             children: [
               const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
               const SizedBox(width: 12),
               Text("Ingesting ${ks.title} into Knowledge Base..."),
             ],
           ),
           backgroundColor: AppTheme.primary.withOpacity(0.8),
           duration: const Duration(seconds: 2),
         ),
       );
    }

    try {
      // 2. Index via ReportsLMService (Chunking & Embedding)
      final sourceType = _mapKnowledgeSourceTypeToReportSourceType(ks.type);
      final reportSource = ReportSource(
        id: ks.id,
        reportId: report.id,
        type: sourceType,
        name: ks.title,
        content: ks.content.isNotEmpty ? ks.content : "No extracted text", 
        addedAt: ks.createdAt,
        metadata: ks.metadata ?? {},
        uri: ks.type == KnowledgeSourceType.url || ks.type == KnowledgeSourceType.youtube ? ks.content : null,
      );

      // Trigger Indexing (Background or Await based on UX preference)
      // We await it to ensure it's ready before user asks questions
      // Note: We use reportSource.content which is assumed to be populated (e.g. text/file text)
      // If it's a URL without content scraped, indexSource might need to scrape it first, 
      // but typically AddSourceDialog handles that.
      await ReportsLMService.indexSource(reportSource, datasetId!, ref);

      // 3. Add to Report UI/DB
      // We add AFTER indexing so we know it's ready, or we could add BEFORE and show state.
      // Current flow: Add after.
      await _addSource(report, reportSource);

    } catch (e) {
      if (mounted) _showErrorDialog("Ingestion Error: $e");
    }
  }

  SourceType _mapKnowledgeSourceTypeToReportSourceType(KnowledgeSourceType type) {
    switch (type) {
      case KnowledgeSourceType.file:
      case KnowledgeSourceType.pdf:
        return SourceType.file;
      case KnowledgeSourceType.url:
      case KnowledgeSourceType.youtube:
        return SourceType.web;
      case KnowledgeSourceType.text:
        return SourceType.pastedText;
      case KnowledgeSourceType.googleAds:
        return SourceType.adAccount;
      case KnowledgeSourceType.ga4:
        return SourceType.analytics;
      default:
        return SourceType.file;
    }
  }



  Future<void> _addOutput(Report report, ReportOutput output) async {
    try {
      final updatedReport = report.copyWith(
         updatedAt: DateTime.now(),
         outputs: [...report.outputs, output],
      );

      await ref.read(reportsServiceProvider).updateReport(updatedReport);
      ref.invalidate(reportProvider(widget.reportId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Saved ${output.title}"), backgroundColor: AppTheme.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error saving output: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleAudioGeneration(Report report, {bool isPreview = true}) async {
    _showLoadingDialog(isPreview ? "Analyzing Themes (LiteRT)..." : "Drafting & Synthesizing Podcast...");
    try {
      final result = await ReportsLMService.generateAudioOverview(report, ref, isPreview: isPreview);
      if (mounted) Navigator.pop(context); 
      if (mounted) {
        if (isPreview) {
          _showPreviewDialog(
            "Audio Script Preview", 
            result.content, 
            onGenerateFinal: () => _handleAudioGeneration(report, isPreview: false)
          );
        } else {
          final output = ReportOutput(
            id: const Uuid().v4(),
            title: "Audio Overview (${DateTime.now().hour}:${DateTime.now().minute})",
            type: ReportOutputType.audio,
            content: result.content,
            uri: result.uri,
            createdAt: DateTime.now(),
            citations: result.citations,
          );
          await _addOutput(report, output);

          _showResultDialog("Audio Overview Ready", result.content, url: result.uri, isAudio: true, citations: result.citations);
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context); 
      if (mounted) _showErrorDialog(e.toString());
    }
  }

  Future<void> _handleMindMapGeneration(Report report, {bool isPreview = true}) async {
      _showLoadingDialog(isPreview ? "Generating Mind Map Preview (LiteRT)..." : "Generating Final Mind Map...");
      try {
        final result = await ReportsLMService.generateMindMap(report, ref, isPreview: isPreview);
        if (mounted) Navigator.pop(context);
        if (mounted) {
           if (isPreview) {
             _showPreviewDialog(
               "Mind Map Preview", 
               "JSON Structure:\n${result.content}", 
               onGenerateFinal: () => _handleMindMapGeneration(report, isPreview: false)
             );
           } else {
             final output = ReportOutput(
                id: const Uuid().v4(),
                title: "Mind Map (${DateTime.now().hour}:${DateTime.now().minute})",
                type: ReportOutputType.text,
                content: result.content,
                createdAt: DateTime.now(),
             );
             await _addOutput(report, output);
             _showResultDialog("Final Mind Map", result.content); 
           }
        }
      } catch (e) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) _showErrorDialog(e.toString());
      }
  }

  Future<void> _handleInfographicGeneration(Report report, {bool isPreview = true}) async {
      _showLoadingDialog(isPreview ? "Generating Infographic Concept (LiteRT)..." : "Designing Final Infographic...");
      try {
        final result = await ReportsLMService.generateInfographic(report, ref, isPreview: isPreview);
        if (mounted) Navigator.pop(context);
        if (mounted) {
            if (isPreview) {
              _showPreviewDialog(
                "Infographic Concept Preview", 
                result.content, 
                onGenerateFinal: () => _handleInfographicGeneration(report, isPreview: false)
              );
            } else {
               final output = ReportOutput(
                  id: const Uuid().v4(),
                  title: "Infographic (${DateTime.now().hour}:${DateTime.now().minute})",
                  type: ReportOutputType.image,
                  content: result.content,
                  uri: result.uri,
                  createdAt: DateTime.now(),
               );
               await _addOutput(report, output);

              _showResultDialog("Infographic Design", result.content, url: result.uri);
            }
        }
      } catch (e) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) _showErrorDialog(e.toString());
      }
  }

  Future<void> _handleReportGeneration(Report report, {bool isPreview = true}) async {
      _showLoadingDialog(isPreview ? "Analyzing Sources (LiteRT)..." : "Generating Comprehensive Report...");
      try {
        final result = await ReportsLMService.generateReport(report, ref, isPreview: isPreview);
        if (mounted) Navigator.pop(context);
        if (mounted) {
            if (isPreview) {
              _showPreviewDialog(
                "Report Draft Preview", 
                result.content, 
                onGenerateFinal: () => _handleReportGeneration(report, isPreview: false)
              );
            } else {
              final output = ReportOutput(
                  id: const Uuid().v4(),
                  title: "Deep Dive Report (${DateTime.now().hour}:${DateTime.now().minute})",
                  type: ReportOutputType.text,
                  content: result.content,
                  createdAt: DateTime.now(),
                  citations: result.citations,
               );
               await _addOutput(report, output);
              _showResultDialog("Final Report", result.content, citations: result.citations);
            }
        }
      } catch (e) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) _showErrorDialog(e.toString());
      }
  }

  Future<void> _handleSlideDeckGeneration(Report report, {bool isPreview = true}) async {
      _showLoadingDialog(isPreview ? "Drafting Slide Deck (LiteRT)..." : "Building Final Deck...");
      try {
        final result = await ReportsLMService.generateSlideDeck(report, ref, isPreview: isPreview);
        if (mounted) Navigator.pop(context);
        if (mounted) {
            if (isPreview) {
              _showPreviewDialog(
                "Deck Outline Preview", 
                result.content, 
                onGenerateFinal: () => _handleSlideDeckGeneration(report, isPreview: false)
              );
            } else {
              final output = ReportOutput(
                  id: const Uuid().v4(),
                  title: "Slide Deck Outline (${DateTime.now().hour}:${DateTime.now().minute})",
                  type: ReportOutputType.text,
                  content: result.content,
                  createdAt: DateTime.now(),
               );
               await _addOutput(report, output);
              _showResultDialog("Final Slide Deck", result.content);
            }
        }
      } catch (e) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) _showErrorDialog(e.toString());
      }
  }

  void _showPreviewDialog(String title, String content, {required VoidCallback onGenerateFinal}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(color: Colors.white70)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onGenerateFinal();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text("Generate Final (Vertex AI)")
          ),
        ],
      ),
    );
  }

  Future<void> _handleVideoGeneration(Report report, {bool isFinal = false, bool includeSubtitles = false}) async {
    String status = isFinal ? "Rendering Final (HQ)..." : "Generating fast preview (LiteRT)...";
    if (includeSubtitles) status += " (With Subtitles)";
    
    _showLoadingDialog(status);

    try {
      if (!isFinal) {
         final result = await ReportsLMService.generateVideoOverview(
            report, 
            ref, 
            isPreview: true,
         );
         if (mounted) Navigator.pop(context);
         
         if (mounted) {
            _showPreviewDialog(
              "Video Structure Preview", 
              result.content, 
              onGenerateFinal: () => _handleVideoGeneration(report, isFinal: true)
            );
         }
      } else {
         final result = await ReportsLMService.generateVideoOverview(
            report, 
            ref, 
            isPreview: false,
         );
         
         if (mounted) Navigator.pop(context);

         final output = ReportOutput(
            id: const Uuid().v4(),
            title: "Video Overview (${DateTime.now().hour}:${DateTime.now().minute})",
            type: ReportOutputType.video,
            content: result.content,
            uri: result.uri,
            createdAt: DateTime.now(),
         );
         await _addOutput(report, output);

         if (mounted && result.uri != null) _showVideoResultDialog(report, result.uri!, isFinal: true);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) _showErrorDialog(e.toString());
    }
  }



  void _showVideoResultDialog(Report report, String url, {bool isFinal = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(isFinal ? "Final Video Ready" : "Video Preview Ready", style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 500,
          child: VideoPreviewPlayer(
            videoUrl: url,
            isFinal: isFinal,
            onRefine: (withSubtitles) {
              Navigator.pop(context);
              _handleVideoGeneration(report, isFinal: false, includeSubtitles: withSubtitles);
            },
            onRenderFinal: (withSubtitles) {
              Navigator.pop(context);
              _handleVideoGeneration(report, isFinal: true, includeSubtitles: withSubtitles);
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }



  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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

  void _showResultDialog(String title, String content, {String? url, bool isVideo = false, bool isAudio = false, List<Citation>? citations}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(content, style: const TextStyle(color: Colors.white70)),
              if (url != null) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                       // Could launch URL
                    },
                    child: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                       child: Row(
                         children: [
                           Icon(isVideo ? Icons.video_library : (isAudio ? Icons.audiotrack : Icons.image), color: Colors.white),
                           const SizedBox(width: 8),
                           Expanded(child: Text(url, style: const TextStyle(color: Colors.blueAccent))),
                         ],
                       ),
                    ),
                  )
              ],
              if (citations != null && citations.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text("References", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: citations.map((c) => ActionChip(
                      label: Text(c.sourceName + (c.pageNumber != null ? " (p.${c.pageNumber})" : ""), style: const TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.description, size: 14, color: AppTheme.primary),
                      backgroundColor: AppTheme.background,
                      side: const BorderSide(color: Colors.white24),
                      onPressed: () {
                         // TODO: Highlight source
                         Navigator.pop(context);
                         // Logic to show source would go here
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Source: ${c.sourceName}"), duration: const Duration(seconds: 1)));
                      },
                    )).toList(),
                  )
              ]
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Error", style: TextStyle(color: Colors.redAccent)),
        content: Text(error, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportProvider(widget.reportId));
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => context.go('/reports'),
        ),
        title: reportAsync.when(
            data: (report) => Text(report?.title ?? "Report Not Found", style: const TextStyle(color: Colors.white, fontSize: 16)),
            loading: () => const Text("Loading...", style: TextStyle(color: Colors.white)),
            error: (_, __) => const Text("Error", style: TextStyle(color: Colors.red))
        ),
        actions: [
           IconButton(
             icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 20),
             onPressed: () {},
           ),
           const SizedBox(width: 8),
        ],
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
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (err, stack) => Center(child: Text("Error loading report: $err", style: const TextStyle(color: Colors.red))),
        data: (report) {
          if (report == null) {
            return const Center(child: Text("Report not found.", style: TextStyle(color: Colors.white)));
          }

          if (isMobile) {
            return IndexedStack(
              index: _mobileTabIndex,
              children: [
                _buildSourcesPane(report),
                _buildChatPane(report),
                _buildStudioPane(report),
              ],
            );
          }

          return Row(
            children: [
              // PANE 1: SOURCES
              Expanded(
                flex: 2,
                child: _buildSourcesPane(report),
              ),
              
              const VerticalDivider(width: 1, color: Colors.white10),

              // PANE 2: CHAT
              Expanded(
                flex: 4,
                child: _buildChatPane(report),
              ),

              const VerticalDivider(width: 1, color: Colors.white10),

              // PANE 3: STUDIO
              Expanded(
                flex: 4,
                child: _buildStudioPane(report),
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildSourcesPane(Report report) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sources", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showAddSourceDialog(report),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text("+ Add Source", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: report.sources.length,
              itemBuilder: (context, index) {
                return _buildSourceItem(report.sources[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPane(Report report) {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          Expanded(
            child: _chatMessages.isEmpty 
            ? Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 48),
                   const SizedBox(height: 16),
                   Text("Explore ${report.title}", style: const TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center),
                   const SizedBox(height: 8),
                   const Text("Ask questions based on your sources.", style: TextStyle(color: Colors.white54)),
                 ],
               ),
            )
            : ListView.builder(
               padding: const EdgeInsets.all(16),
               itemCount: _chatMessages.length,
               itemBuilder: (context, index) {
                 final msg = _chatMessages[index];
                 final isUser = msg['role'] == 'user';
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
                        msg['content']!, 
                        style: const TextStyle(color: Colors.white)
                     ),
                   ),
                 );
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
                    onSubmitted: (_) => _handleChatSubmit(report),
                    decoration: InputDecoration(
                      hintText: "Ask about this notebook...",
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: IconButton(
                    icon: _isChatLoading 
                       ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                       : const Icon(Icons.arrow_upward, color: Colors.white),
                    onPressed: () => _handleChatSubmit(report),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioPane(Report report) {
     return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text("Studio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                 const Icon(Icons.more_horiz, color: Colors.white54),
               ],
             ),
           ),
           const Divider(height: 1, color: Colors.white10),
           
           // Studio Options
           SingleChildScrollView(
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: GridView.count(
                 crossAxisCount: MediaQuery.of(context).size.width < 500 ? 1 : 2,
                 mainAxisSpacing: 12,
                 crossAxisSpacing: 12,
                 childAspectRatio: 2.2,
                 primary: false,
                 shrinkWrap: true,
                 children: [
                   _buildStudioCard("Audio Overview", FontAwesomeIcons.headphones, Colors.blue, onTap: () => _handleAudioGeneration(report)),
                   _buildStudioCard("Video Overview", FontAwesomeIcons.video, Colors.green, onTap: () => _handleVideoGeneration(report)),
                   _buildStudioCard("Mind Map", FontAwesomeIcons.diagramProject, Colors.purple, onTap: () => _handleMindMapGeneration(report)),
                   _buildStudioCard("Reports", FontAwesomeIcons.fileLines, Colors.orange, onTap: () => _handleReportGeneration(report)),
                   _buildStudioCard("Infographic", FontAwesomeIcons.chartPie, Colors.pink, onTap: () => _handleInfographicGeneration(report)),
                   _buildStudioCard(
                     "Slide Deck", 
                     FontAwesomeIcons.layerGroup, 
                     Colors.amber,
                     onTap: () => _handleSlideDeckGeneration(report),
                   ),
                 ],
               ),
             ),
           ),

           const Divider(height: 1, color: Colors.white10),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
             child: Row(
               children: [
                 const Text("Generated Assets", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                 const Spacer(),
                 if (report.outputs.isNotEmpty)
                    Text("${report.outputs.length} items", style: const TextStyle(color: Colors.white30, fontSize: 12)),
               ],
             ),
           ),

           // Generated Output List
           Expanded(
             child: report.outputs.isEmpty 
               ? const Center(child: Text("No assets generated yet.", style: TextStyle(color: Colors.white30)))
               : ListView.builder(
                   itemCount: report.outputs.length,
                   itemBuilder: (context, index) {
                     final output = report.outputs[index];
                     return _buildOutputItem(output);
                   },
                 ),
           ),
        ],
      ),
    );
  }

  Widget _buildOutputItem(ReportOutput output) {
    IconData icon = Icons.insert_drive_file;
    Color color = Colors.white;
    
    switch (output.type) {
      case ReportOutputType.audio:
        icon = Icons.headphones;
        color = Colors.blueAccent;
        break;
      case ReportOutputType.video:
        icon = Icons.video_library;
        color = Colors.greenAccent;
        break;
      case ReportOutputType.image:
        icon = Icons.image;
        color = Colors.pinkAccent;
        break;
      case ReportOutputType.text:
      case ReportOutputType.pdf:
        icon = Icons.description;
        color = Colors.orangeAccent;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(output.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(
        "${output.type.toString().split('.').last.toUpperCase()} • ${output.createdAt.hour}:${output.createdAt.minute}", 
        style: const TextStyle(color: Colors.white38, fontSize: 11)
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Colors.white70),
            onPressed: () {
               // Play or View
               if (output.uri != null) {
                  _showResultDialog(output.title, output.content ?? '', url: output.uri, isVideo: output.type == ReportOutputType.video, isAudio: output.type == ReportOutputType.audio);
               } else {
                  _showResultDialog(output.title, output.content ?? '');
               }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudioCard(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceItem(ReportSource source) {
    IconData icon = Icons.insert_drive_file;
    if (source.type == SourceType.web) icon = FontAwesomeIcons.globe;
    if (source.type == SourceType.dataConnector) icon = FontAwesomeIcons.database;
    if (source.type == SourceType.social) icon = FontAwesomeIcons.hashtag;
    if (source.type == SourceType.adAccount) icon = Icons.ads_click;
    if (source.type == SourceType.analytics) icon = Icons.analytics;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(child: Text(source.name, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
