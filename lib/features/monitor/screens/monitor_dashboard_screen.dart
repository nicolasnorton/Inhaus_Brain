import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../models/monitor_models.dart';
import '../providers/monitor_provider.dart';

class MonitorDashboardScreen extends ConsumerWidget {
  final String appId;

  const MonitorDashboardScreen({super.key, required this.appId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(appMetricsProvider(appId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(FontAwesomeIcons.gaugeHigh, color: Colors.blueAccent, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Monitor Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 24),
                _buildTracingButton(context),
                const Spacer(),
                _buildTimeRangeSelector(),
              ],
            ),
            const SizedBox(height: 32),
            
            metricsAsync.when(
              data: (metrics) => _buildMetricsGrid(context, metrics),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
            ),
            
            const SizedBox(height: 48),
            const Text(
              'Statistics',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildChartsGrid(context),
            
            const SizedBox(height: 48),
            Row(
              children: [
                const Text(
                  'Quick Logs',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    context.go('/monitor/logs?appId=$appId');
                  },
                  child: const Text('View All Logs'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildQuickLogsList(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Text('Last 7 Days', style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(width: 8),
          Icon(Icons.expand_more, color: Colors.white38, size: 16),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, MetricSummary metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.0,
          children: [
            _buildMetricCard(
              'Total Messages',
              metrics.totalMessages.toString(),
              'Conversation volume',
              Icons.forum_outlined,
              Colors.blueAccent,
            ),
            _buildMetricCard(
              'Active Users',
              metrics.activeUsers.toString(),
              '>1 meaningful exchange',
              Icons.people_outline,
              Colors.greenAccent,
            ),
            _buildMetricCard(
              'Avg. Interactions',
              '${metrics.avgInteractions.toStringAsFixed(1)}',
              'Engagement depth',
              Icons.insights_outlined,
              Colors.orangeAccent,
            ),
            _buildMetricCard(
              'Token Usage',
              '${(metrics.totalTokens / 1000).toStringAsFixed(1)}K',
              'Resource consumption',
              Icons.token_outlined,
              Colors.purpleAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTracingButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C2128),
            title: const Text('Tracing Integration', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 const Text('Connect external tracing providers to monitor agent performance.', style: TextStyle(color: Colors.white70)),
                 const SizedBox(height: 16),
                 _buildProviderButton(context, 'LangSmith', Icons.hub),
                 const SizedBox(height: 8),
                 _buildProviderButton(context, 'Langfuse', Icons.auto_graph),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      },
      icon: const Icon(Icons.analytics_outlined, size: 16),
      label: const Text('Tracing app performance'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blueAccent,
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildProviderButton(BuildContext context, String name, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected to $name (Mock)')));
            }, 
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String subValue, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subValue, style: TextStyle(color: subValue.contains('+') ? Colors.greenAccent : (subValue.contains('-') ? Colors.greenAccent : Colors.white24), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                'Total Messages',
                const [0.2, 0.4, 0.3, 0.6, 0.5, 0.8, 0.7, 0.9],
                Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                'Active Users',
                const [0.1, 0.2, 0.5, 0.4, 0.7, 0.6, 0.8, 0.85],
                Colors.greenAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                'Avg. User Interactions',
                const [0.8, 0.7, 0.9, 0.5, 0.6, 0.4, 0.5, 0.3],
                Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                'Token Usage',
                const [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.7, 0.95],
                Colors.purpleAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard(String label, List<double> data, Color color) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const Spacer(),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: SparklinePainter(data, color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogsList(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(appLogsProvider(appId));

    return logsAsync.when(
      data: (logs) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C2128),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              leading: Icon(Icons.circle, color: log.level.color, size: 8),
              title: Text(log.message, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              subtitle: Text(log.traceId ?? '', style: const TextStyle(color: Colors.white24, fontSize: 11)),
              trailing: Text(
                '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final xStep = size.width / (data.length - 1);
    
    path.moveTo(0, size.height * (1 - data[0]));
    
    for (var i = 1; i < data.length; i++) {
      path.lineTo(i * xStep, size.height * (1 - data[i]));
    }

    canvas.drawPath(path, paint);

    // Fill area under line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
