import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/providers/bigquery_provider.dart';

class BigQueryAiPerformanceChart extends ConsumerWidget {
  final int days;

  const BigQueryAiPerformanceChart({super.key, this.days = 7});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(aiPerformanceMetricsProvider(days));

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: metricsAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(child: Text('No telemetry data available', style: TextStyle(color: Colors.white38)));
          }

          // Group by model_id
          final Map<String, List<ChartData>> chartData = {};
          for (final row in data) {
            final model = row['model_id'] as String? ?? 'unknown';
            final date = row['date'] as String? ?? '';
            final latency = (row['avg_latency'] as num?)?.toDouble() ?? 0.0;
            
            chartData.putIfAbsent(model, () => []);
            chartData[model]!.add(ChartData(DateTime.parse(date), latency));
          }

          return SfCartesianChart(
            title: ChartTitle(text: 'AI Latency by Model (ms)', textStyle: const TextStyle(color: Colors.white70, fontSize: 12)),
            legend: Legend(isVisible: true, textStyle: const TextStyle(color: Colors.white60)),
            primaryXAxis: DateTimeAxis(
              labelStyle: const TextStyle(color: Colors.white38),
              majorGridLines: const MajorGridLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              labelStyle: const TextStyle(color: Colors.white38),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
            ),
            series: chartData.entries.map((entry) {
              return LineSeries<ChartData, DateTime>(
                name: entry.key.split('/').last,
                dataSource: entry.value,
                xValueMapper: (ChartData d, _) => d.time,
                yValueMapper: (ChartData d, _) => d.value,
                markerSettings: const MarkerSettings(isVisible: true),
              );
            }).toList(),
            tooltipBehavior: TooltipBehavior(enable: true),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }
}

class BigQueryUsageChart extends ConsumerWidget {
  final int days;

  const BigQueryUsageChart({super.key, this.days = 7});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(usageMetricsProvider(days));

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: usageAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(child: Text('No usage data available', style: TextStyle(color: Colors.white38)));
          }

          final List<ChartData> messages = [];
          final List<ChartData> users = [];

          for (final row in data) {
            final date = DateTime.parse(row['date'] as String);
            messages.add(ChartData(date, (row['message_count'] as num?)?.toDouble() ?? 0.0));
            users.add(ChartData(date, (row['active_users'] as num?)?.toDouble() ?? 0.0));
          }

          return SfCartesianChart(
            title: ChartTitle(text: 'Agency Message Volume', textStyle: const TextStyle(color: Colors.white70, fontSize: 12)),
            legend: Legend(isVisible: true, position: LegendPosition.bottom, textStyle: const TextStyle(color: Colors.white60)),
            primaryXAxis: DateTimeAxis(labelStyle: const TextStyle(color: Colors.white38)),
            series: [
              ColumnSeries<ChartData, DateTime>(
                name: 'Messages',
                dataSource: messages,
                xValueMapper: (ChartData d, _) => d.time,
                yValueMapper: (ChartData d, _) => d.value,
                color: Colors.blueAccent,
              ),
              LineSeries<ChartData, DateTime>(
                name: 'Active Users',
                dataSource: users,
                xValueMapper: (ChartData d, _) => d.time,
                yValueMapper: (ChartData d, _) => d.value,
                color: Colors.greenAccent,
                yAxisName: 'users',
              ),
            ],
            axes: <ChartAxis>[
              NumericAxis(
                name: 'users',
                opposedPosition: true,
                labelStyle: const TextStyle(color: Colors.greenAccent),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }
}

class ChartData {
  final DateTime time;
  final double value;
  ChartData(this.time, this.value);
}
