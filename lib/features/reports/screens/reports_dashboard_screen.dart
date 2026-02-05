import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/report_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/reports_provider.dart';
import '../../knowledge/providers/knowledge_provider.dart';

class ReportsDashboardScreen extends ConsumerWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverPadding(
            padding: const EdgeInsets.all(32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Reports",
                            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Create and manage your analysis reports.",
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width < 600 ? double.infinity : 400,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            icon: Icon(Icons.search, color: Colors.white24, size: 20),
                            hintText: "Search reports...",
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                         _FilterChip(label: "All Reports", isSelected: true),
                         SizedBox(width: 8),
                         _FilterChip(label: "Recent"),
                         SizedBox(width: 8),
                         _FilterChip(label: "Pinned"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Grid
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 32),
            sliver: reportsAsync.when(
              data: (reports) => SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: MediaQuery.of(context).size.width < 600 ? 200 : 300,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: MediaQuery.of(context).size.width < 600 ? 1.0 : 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                       return _buildCreateNewCard(context, ref);
                    }
                    final report = reports[index - 1];
                    return _buildReportCard(context, report);
                  },
                  childCount: reports.length + 1,
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateNewCard(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24, style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: () async {
          // 1. Create Knowledge Base for this report
          final api = ref.read(knowledgeApiServiceProvider);
          final kb = await api.createKnowledgeBase(
            name: 'Analysis: New Report',
            description: 'Source library for agentic analysis',
          );

          // 2. Create new report with dataset link
          final newReport = Report.create(
            title: 'New Analysis', 
            clientId: 'client_1',
            datasetId: kb.id,
          );
          
          await ref.read(reportsServiceProvider).createReport(newReport);
          
          if (context.mounted) {
             context.go('/reports/${newReport.id}');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white10,
              child: Icon(Icons.add, color: AppTheme.primary, size: 32),
            ),
            SizedBox(height: 16),
            Text("New Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Report report) {
    return Card(
      color: AppTheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.go('/reports/${report.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header / Icon layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(color: _getColorForId(report.id), borderRadius: BorderRadius.circular(8)),
                     child: const Icon(FontAwesomeIcons.bookOpen, color: Colors.white, size: 16),
                  ),
                  const Icon(Icons.more_horiz, color: Colors.white30),
                ],
              ),
              const Spacer(),
              Text(
                report.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                "${report.sources.length} sources",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                "Edited ${_formatDate(report.updatedAt)}",
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getColorForId(String id) {
     final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.teal];
     return colors[id.hashCode % colors.length];
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppTheme.primary : Colors.white10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primary : Colors.white54,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
