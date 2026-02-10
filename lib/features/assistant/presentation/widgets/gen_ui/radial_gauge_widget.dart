import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class RadialGaugeWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const RadialGaugeWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'KPI';
    final double value = (data['value'] ?? 0).toDouble();
    final double min = (data['min'] ?? 0).toDouble();
    final double max = (data['max'] ?? 100).toDouble();
    final List<dynamic> ranges = data['ranges'] ?? [];
    final String? annotation = data['annotation'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: min,
                  maximum: max,
                  showLabels: true,
                  showTicks: true,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.2,
                    cornerStyle: CornerStyle.bothCurve,
                    color: Color(0xFF2D333B),
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    NeedlePointer(
                      value: value,
                      needleColor: Colors.blueAccent,
                      tailStyle: const TailStyle(length: 0.18, width: 8, color: Colors.blueAccent),
                      knobStyle: const KnobStyle(knobRadius: 0.07, color: Colors.white),
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                     GaugeAnnotation(
                       widget: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                            Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            if (annotation != null)
                              Text(
                                annotation,
                                style: const TextStyle(fontSize: 14, color: Colors.white70),
                              ),
                         ],
                       ),
                       angle: 90,
                       positionFactor: 0.5,
                     )
                  ],
                  ranges: ranges.map<GaugeRange>((r) {
                    return GaugeRange(
                      startValue: (r['start'] ?? 0).toDouble(),
                      endValue: (r['end'] ?? 100).toDouble(),
                      color: _parseColor(r['color']),
                      startWidth: 0.2,
                      endWidth: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return Colors.blueAccent;
    final lower = colorStr.toLowerCase();
    switch (lower) {
      case 'red': return Colors.redAccent;
      case 'green': return Colors.greenAccent;
      case 'yellow': return Colors.amberAccent;
      case 'orange': return Colors.orangeAccent;
      case 'blue': return Colors.blueAccent;
      case 'purple': return Colors.purpleAccent;
    }
    if (colorStr.startsWith('#')) {
      try {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {}
    }
    return Colors.blueAccent;
  }
}
