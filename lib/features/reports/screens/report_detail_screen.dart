import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/report_model.dart';
import '../models/source_model.dart';
import '../../../../core/services/sources_service.dart';
import '../widgets/reports_notebook_view.dart';
import '../widgets/slide_deck_config_dialog.dart';
import '../../../../core/services/reports_lm_service.dart';
import '../providers/reports_provider.dart';
import '../../../../core/widgets/video_preview_player.dart';
import '../../connectors/models/connected_account_model.dart';
import '../../../../core/services/integration_service.dart';

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
    // Create updated copy
    final updatedReport = Report(
       id: report.id,
       title: report.title,
       clientId: report.clientId,
       createdAt: report.createdAt,
       updatedAt: DateTime.now(), // Update timestamp
       sources: [...report.sources, source],
    );

    try {
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
      builder: (context) => SimpleDialog(
        title: const Text('Add Source', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.surface,
        children: [
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              final source = await SourcesService.pickFileAndProcess(report.id);
              if (source != null) _addSource(report, source);
            },
            child: const Row(
              children: [
                Icon(Icons.file_upload, color: Colors.blue),
                SizedBox(width: 12),
                Text('Upload File (PDF, CSV)', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showPasteTextDialog(report);
            },
            child: const Row(
              children: [
                Icon(Icons.content_paste, color: Colors.teal),
                SizedBox(width: 12),
                Text('Paste Text', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              // Mock URL input
              final source = await SourcesService.addWebSource(report.id, "https://example.com/market-trends");
              _addSource(report, source);
            },
            child: const Row(
              children: [
                Icon(Icons.link, color: Colors.green),
                SizedBox(width: 12),
                Text('Web Source', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              final source = await SourcesService.addConnectorSource(report.id, "BigQuery: Client_Data_Q1");
              _addSource(report, source);
            },
            child: const Row(
              children: [
                Icon(FontAwesomeIcons.database, color: Colors.orange, size: 18),
                SizedBox(width: 12),
                Text('Data Connector (BigQuery)', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showConnectedAccountsDialog(report);
            },
            child: const Row(
              children: [
                Icon(Icons.hub, color: Colors.purpleAccent),
                SizedBox(width: 12),
                Text('From Connected Account', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showConnectedAccountsDialog(report); // Reuse pick, or filter for analytics only
            },
            child: const Row(
              children: [
                Icon(Icons.insights, color: Colors.orangeAccent),
                SizedBox(width: 12),
                Text('Analytics (GA4/GSC)', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConnectedAccountsDialog(Report report) async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Connect Platform", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.surface,
        children: [
          _buildPlatformConnectOption(report, "Google Ads", AdPlatform.googleAds),
          _buildPlatformConnectOption(report, "Meta Ads", AdPlatform.metaAds),
          _buildPlatformConnectOption(report, "TikTok Ads", AdPlatform.tiktokAds), // Will use Generic (Stub for now)
          _buildPlatformConnectOption(report, "Google Analytics 4", AdPlatform.googleAnalytics),
        ],
      ),
    );
  }

  Widget _buildPlatformConnectOption(Report report, String name, AdPlatform platform) {
    return SimpleDialogOption(
      onPressed: () async {
        Navigator.pop(context); // Close dialog selection
        
        final integrationService = ref.read(integrationServiceProvider);
        
        // Show loading
        _showLoadingDialog("Connecting to $name...");
        
        try {
          // 1. Initiate OAuth Flow
          final account = await integrationService.initiateConnection(platform, report.clientId);
          
          if (mounted) Navigator.pop(context); // Close loading dialog
          
          if (account != null) {
             // 2. Fetch Data & Add Source
             if (mounted) _showLoadingDialog("Fetching data from $name...");
             
             try {
                final source = await SourcesService.fetchAndAddConnectedSource(report.id, account, integrationService);
                if (mounted) Navigator.pop(context); // Close fetching dialog
                _addSource(report, source);
             } catch (e) {
                if (mounted) {
                   Navigator.pop(context);
                   _showErrorDialog("Failed to fetch data: $e");
                }
             }
          } else {
             // Null account usually means user cancelled or auth failed silently
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text("Connection cancelled or failed for $name"), backgroundColor: Colors.orange),
               );
             }
          }
        } catch (e) {
          if (mounted) Navigator.pop(context);
          if (mounted) _showErrorDialog("Connection Error: $e");
        }
      },
      child: Row(
        children: [
          Icon(_getIconForPlatform(name), color: Colors.blueAccent, size: 18),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  AdPlatform _getPlatformEnum(String name) {
    if (name.contains("Google Ads")) return AdPlatform.googleAds;
    if (name.contains("Meta")) return AdPlatform.metaAds;
    if (name.contains("TikTok")) return AdPlatform.tiktokAds;
    return AdPlatform.other;
  }

  IconData _getIconForPlatform(String platform) {
    if (platform.contains("Google")) return FontAwesomeIcons.google;
    if (platform.contains("Meta")) return FontAwesomeIcons.meta;
    if (platform.contains("TikTok")) return FontAwesomeIcons.tiktok;
    if (platform.contains("GA4")) return Icons.analytics;
    return Icons.account_circle;
  }

  Future<void> _showPasteTextDialog(Report report) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Paste Text Source", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: "Title (e.g. Email from Client)",
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Paste content here...",
                hintStyle: TextStyle(color: Colors.white30),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (contentController.text.isNotEmpty) {
                 Navigator.pop(context);
                 final source = await SourcesService.addTextSource(
                   report.id, 
                   contentController.text, 
                   titleController.text
                 );
                 _addSource(report, source);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAudioGeneration(Report report, {bool isPreview = true}) async {
    _showLoadingDialog(isPreview ? "Generating Audio Preview (LiteRT)..." : "Synthesizing Final Audio...");
    try {
      final url = await ReportsLMService.generateAudioOverview(report, ref, isPreview: isPreview);
      if (mounted) Navigator.pop(context); 
      if (mounted) {
        if (isPreview) {
          _showPreviewDialog(
            "Audio Script Preview", 
            "The generated script is ready. Preview audio is a placeholder.", 
            onGenerateFinal: () => _handleAudioGeneration(report, isPreview: false)
          );
        } else {
          _showResultDialog("Audio Overview Ready", "Podcast script generated and audio synthesized.", url: url, isAudio: true);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); 
      if (mounted) _showErrorDialog(e.toString());
    }
  }

  Future<void> _handleMindMapGeneration(Report report, {bool isPreview = true}) async {
      _showLoadingDialog(isPreview ? "Generating Mind Map Preview (LiteRT)..." : "Generating Final Mind Map...");
      try {
        final json = await ReportsLMService.generateMindMap(report, ref, isPreview: isPreview);
        if (mounted) Navigator.pop(context);
        if (mounted) {
           if (isPreview) {
             _showPreviewDialog(
               "Mind Map Preview", 
               "JSON Structure:\n$json", 
               onGenerateFinal: () => _handleMindMapGeneration(report, isPreview: false)
             );
           } else {
             _showResultDialog("Final Mind Map", json); 
           }
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        if (mounted) _showErrorDialog(e.toString());
      }
  }

  Future<void> _handleInfographicGeneration(Report report, {bool isPreview = true}) async {
      _showLoadingDialog(isPreview ? "Generating Infographic Concept (LiteRT)..." : "Designing Final Infographic...");
      try {
        final text = await ReportsLMService.generateInfographic(report, ref, isPreview: isPreview);
        if (mounted) Navigator.pop(context);
        if (mounted) {
            if (isPreview) {
              _showPreviewDialog(
                "Infographic Concept Preview", 
                text, 
                onGenerateFinal: () => _handleInfographicGeneration(report, isPreview: false)
              );
            } else {
              _showResultDialog("Infographic Design", text);
            }
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        if (mounted) _showErrorDialog(e.toString());
      }
  }

  Future<void> _handleSlideDeckGeneration(Report report, {bool isPreview = true}) async {
      _showLoadingDialog(isPreview ? "Drafting Slide Deck (LiteRT)..." : "Building Final Deck...");
      try {
        final text = await ReportsLMService.generateSlideDeck(report, ref, isPreview: isPreview);
        if (mounted) Navigator.pop(context);
        if (mounted) {
            if (isPreview) {
              _showPreviewDialog(
                "Deck Outline Preview", 
                text, 
                onGenerateFinal: () => _handleSlideDeckGeneration(report, isPreview: false)
              );
            } else {
              _showResultDialog("Final Slide Deck", text);
            }
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
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
    double progress = 0.0;
    String status = isFinal ? "Rendering Final (HQ)..." : "Generating fast preview (LiteRT)...";
    if (includeSubtitles) status += " (With Subtitles)";
    
    // To allow setDialogState to be called from the async task, we need a way to capture it.
    final progressNotifier = ValueNotifier<double>(0.0);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<double>(
        valueListenable: progressNotifier,
        builder: (context, val, _) {
          return Dialog(
            backgroundColor: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const CircularProgressIndicator(color: AppTheme.primary),
                   const SizedBox(height: 24),
                   Text(status, style: const TextStyle(color: Colors.white)),
                   const SizedBox(height: 8),
                   LinearProgressIndicator(value: val, backgroundColor: Colors.white10),
                   const SizedBox(height: 4),
                   Text("${(val * 100).toInt()}%", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
          );
        }
      ),
    );

    try {
      final url = await ReportsLMService.generateVideoOverview(
        report, 
        ref, 
        isFinal: isFinal,
        includeSubtitles: includeSubtitles,
        onProgress: (p) {
          progressNotifier.value = p;
        }
      );
      if (mounted) Navigator.pop(context); // Close loading
      
      if (mounted) {
        _showVideoResultDialog(report, url, isFinal: isFinal);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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

  void _showResultDialog(String title, String content, {String? url, bool isVideo = false, bool isAudio = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content, style: const TextStyle(color: Colors.white70), maxLines: 10, overflow: TextOverflow.ellipsis),
            if (url != null) ...[
                const SizedBox(height: 16),
                Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                   child: Row(
                     children: [
                       Icon(isVideo ? Icons.video_library : (isAudio ? Icons.audiotrack : Icons.link), color: Colors.white),
                       const SizedBox(width: 8),
                       Expanded(child: Text(url, style: const TextStyle(color: Colors.blueAccent))),
                     ],
                   ),
                )
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          if (isVideo || isAudio)
             ElevatedButton(
               onPressed: () {
                 // In real app, launch player
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Launching Media Player...")));
               }, 
               style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
               child: const Text("Play")
             ),
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => context.go('/reports'),
        ),
        title: reportAsync.when(
            data: (report) => Text(report?.title ?? "Report Not Found", style: const TextStyle(color: Colors.white)),
            loading: () => const Text("Loading...", style: TextStyle(color: Colors.white)),
            error: (_, __) => const Text("Error", style: TextStyle(color: Colors.red))
        ),
        actions: [
           IconButton(
             icon: const Icon(Icons.share, color: Colors.white70),
             onPressed: () {},
           ),
           const SizedBox(width: 16),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (err, stack) => Center(child: Text("Error loading report: $err", style: const TextStyle(color: Colors.red))),
        data: (report) {
          if (report == null) {
            return const Center(child: Text("Report not found.", style: TextStyle(color: Colors.white)));
          }
          return Row(
            children: [
              // PANE 1: SOURCES
              Expanded(
                flex: 2,
                child: Container(
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
                ),
              ),
              
              const VerticalDivider(width: 1, color: Colors.white10),

              // PANE 2: CHAT
              Expanded(
                flex: 4,
                child: Container(
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
                               Text("Explore ${report.title}", style: const TextStyle(color: Colors.white, fontSize: 20)),
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
                                 child: SelectableText( // Allow copying text
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
                ),
              ),

              const VerticalDivider(width: 1, color: Colors.white10),

              // PANE 3: STUDIO
              Expanded(
                flex: 4,
                child: Container(
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
                       
                       Expanded(
                         child: Padding(
                           padding: const EdgeInsets.all(16.0),
                           child: GridView.count(
                             crossAxisCount: 2,
                             mainAxisSpacing: 12,
                             crossAxisSpacing: 12,
                             childAspectRatio: 2.5,
                             children: [
                               _buildStudioCard("Audio Overview", FontAwesomeIcons.headphones, Colors.blue, onTap: () => _handleAudioGeneration(report)),
                               _buildStudioCard("Video Overview", FontAwesomeIcons.video, Colors.green, onTap: () => _handleVideoGeneration(report)),
                               _buildStudioCard("Mind Map", FontAwesomeIcons.diagramProject, Colors.purple, onTap: () => _handleMindMapGeneration(report)),
                               _buildStudioCard("Reports", FontAwesomeIcons.fileLines, Colors.orange),
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
