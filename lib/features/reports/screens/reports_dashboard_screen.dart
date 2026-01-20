import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/report_model.dart';
import '../../../../l10n/app_localizations.dart';

class ReportsDashboardScreen extends ConsumerWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const Text(
                    "Reports",
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Create and manage your analysis reports.",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          // Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // First item: "New Notebook"
                  if (index == 0) {
                     return _buildCreateNewCard(context);
                  }
                  final report = mockReports[index - 1];
                  return _buildReportCard(context, report);
                },
                childCount: mockReports.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateNewCard(BuildContext context) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24, style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: () {
          // In real app, create logic
          context.go('/reports/1'); 
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
            Text("New Notebook", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
