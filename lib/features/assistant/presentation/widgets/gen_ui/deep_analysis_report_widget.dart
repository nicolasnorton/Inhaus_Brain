import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../reports/services/report_pdf_service.dart';

class DeepAnalysisReportWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const DeepAnalysisReportWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Research Report';
    final execSummary = data['executive_summary'] as String? ?? '';
    final keyInsights = List<String>.from(data['key_insights'] ?? []);
    final recommendations = List<String>.from(data['strategic_recommendations'] ?? []);
    final detailedAnalysis = data['detailed_analysis'] as String? ?? '';
    final metrics = List<Map<String, dynamic>>.from(data['metrics'] ?? []);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header with Gradient Badge and Download Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigoAccent.withOpacity(0.3), Colors.cyanAccent.withOpacity(0.2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigoAccent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.science_outlined, color: Colors.cyanAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deep Research Analysis • Gemini 3.0 Pro',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white54),
                tooltip: 'Download PDF Report',
                onPressed: () async {
                   try {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...'), duration: Duration(milliseconds: 1000)));
                     
                     final pdfBytes = await ReportPdfService.generateReportPdfFromData(data);
                     await ReportPdfService.saveAndOpenPdf(pdfBytes, 'inhaus_research_report_${DateTime.now().millisecond}.pdf');
                   } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.redAccent));
                   }
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 24),

          // 2. Executive Summary (Highlight Card)
          if (execSummary.isNotEmpty) ...[
            Text('EXECUTIVE SUMMARY', style: _sectionHeaderStyle),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                execSummary,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // 3. Metrics Grid
          if (metrics.isNotEmpty) ...[
            Text('KEY METRICS', style: _sectionHeaderStyle),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: metrics.map((m) => _buildMetricCard(m)).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // 4. Key Insights & Recommendations (Two Columns on Desktop, Stacked on Mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Insights
                  if (keyInsights.isNotEmpty)
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('KEY INSIGHTS', style: _sectionHeaderStyle),
                          const SizedBox(height: 12),
                          ...keyInsights.map((insight) => _buildBulletItem(insight, Icons.lightbulb_outline, Colors.amberAccent)),
                        ],
                      ),
                    ),
                  
                  if (isWide && keyInsights.isNotEmpty && recommendations.isNotEmpty)
                     const SizedBox(width: 32), // Spacer
                  if (!isWide && keyInsights.isNotEmpty && recommendations.isNotEmpty)
                     const SizedBox(height: 32),

                  // Recommendations
                  if (recommendations.isNotEmpty)
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STRATEGIC RECOMMENDATIONS', style: _sectionHeaderStyle),
                          const SizedBox(height: 12),
                          ...recommendations.map((rec) => _buildBulletItem(rec, Icons.verified_outlined, Colors.greenAccent)),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          
          if (detailedAnalysis.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(color: Colors.white10),
            const SizedBox(height: 32),
            Text('DETAILED ANALYSIS', style: _sectionHeaderStyle),
            const SizedBox(height: 16),
            MarkdownBody(
              data: detailedAnalysis,
               styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, height: 1.6),
                  h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  h3: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(color: Colors.white54),
                  blockquote: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                  blockquoteDecoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                    border: Border(left: BorderSide(color: Colors.blueAccent.withOpacity(0.5), width: 4)),
                  ),
                ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(Map<String, dynamic> metric) {
    // "metrics": [{"name": "string", "value": "string", "trend": "up|down|flat"}]
    final name = metric['name'] ?? 'Metric';
    final value = metric['value'] ?? '-';
    final trend = metric['trend']?.toString().toLowerCase();
    
    IconData trendIcon = Icons.remove;
    Color trendColor = Colors.grey;
    
    if (trend == 'up') {
      trendIcon = Icons.trending_up;
      trendColor = Colors.greenAccent;
    } else if (trend == 'down') {
      trendIcon = Icons.trending_down;
      trendColor = Colors.redAccent;
    }

    return Container(
      width: 150, // Fixed width for grid alignment
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 4),
              Text(
                trend?.toUpperCase() ?? 'FLAT',
                style: TextStyle(
                  color: trendColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _sectionHeaderStyle => TextStyle(
    color: Colors.white.withOpacity(0.4),
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );
}
