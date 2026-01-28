import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/report_model.dart';
import '../widgets/reports_notebook_view.dart';
import '../widgets/slide_deck_config_dialog.dart';
import '../models/slide_deck_model.dart'; // For types

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  // Mock finding report
  late Report _report;

  @override
  void initState() {
    super.initState();
    try {
      _report = mockReports.firstWhere((r) => r.id == widget.reportId);
    } catch (e) {
      // Fallback for direct nav or new
      _report = mockReports.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => context.go('/reports'),
        ),
        title: Text(_report.title, style: const TextStyle(color: Colors.white)),
        actions: [
           IconButton(
             icon: const Icon(Icons.share, color: Colors.white70),
             onPressed: () {},
           ),
           const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // PANE 1: SOURCES (Left, 20%)
          Expanded(
            flex: 2,
            child: Container(
              color: AppTheme.background, // Slightly darker
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sources", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 16),
                  // Add Source Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text("+ Add Source", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _report.sources.length,
                      itemBuilder: (context, index) {
                        return _buildSourceItem(_report.sources[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const VerticalDivider(width: 1, color: Colors.white10),

          // PANE 2: CHAT / REASONING (Center, 40%)
          Expanded(
            flex: 4,
            child: Container(
              color: AppTheme.background,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                       // Placeholder for the Chat Interface linked to ReportsAgent
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 48),
                           const SizedBox(height: 16),
                           Text("Explore ${_report.title}", style: const TextStyle(color: Colors.white, fontSize: 20)),
                           const SizedBox(height: 8),
                           const Text("Ask questions based on your sources.", style: TextStyle(color: Colors.white54)),
                         ],
                       ),
                    ),
                  ),
                  // Input Area
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
                          child: IconButton(icon: const Icon(Icons.arrow_upward, color: Colors.white), onPressed: () {}),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1, color: Colors.white10),

          // PANE 3: STUDIO / NOTES (Right, 40%)
          Expanded(
            flex: 4,
            child: Container(
              color: AppTheme.surface, // Slightly lighter
              child: Column(
                children: [
                  // Studio Header
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
                   
                   // Studio Grid
                   Expanded(
                     child: Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: GridView.count(
                         crossAxisCount: 2,
                         mainAxisSpacing: 12,
                         crossAxisSpacing: 12,
                         childAspectRatio: 2.5,
                         children: [
                           _buildStudioCard("Audio Overview", FontAwesomeIcons.headphones, Colors.blue),
                           _buildStudioCard("Video Overview", FontAwesomeIcons.video, Colors.green),
                           _buildStudioCard("Mind Map", FontAwesomeIcons.diagramProject, Colors.purple),
                           _buildStudioCard("Reports", FontAwesomeIcons.fileLines, Colors.orange),
                           _buildStudioCard("Infographic", FontAwesomeIcons.chartPie, Colors.pink),
                           _buildStudioCard(
                             "Slide Deck", 
                             FontAwesomeIcons.layerGroup, 
                             Colors.amber,
                             onTap: () {
                               showDialog(
                                 context: context,
                                 builder: (context) => SlideDeckConfigDialog(
                                   onGenerate: (format, lang, length, prompt) {
                                     // Mock generation trigger
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                         content: Text("Generating $length ${format.name} deck in $lang..."),
                                         backgroundColor: AppTheme.primary,
                                       ),
                                     );
                                   },
                                 ),
                               );
                             },
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

  Widget _buildSourceItem(String name) {
    IconData icon = Icons.insert_drive_file;
    if (name.contains("BigQuery")) icon = FontAwesomeIcons.database;
    if (name.contains("Drive")) icon = FontAwesomeIcons.googleDrive;
    if (name.contains("Web")) icon = FontAwesomeIcons.globe;
    
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
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
