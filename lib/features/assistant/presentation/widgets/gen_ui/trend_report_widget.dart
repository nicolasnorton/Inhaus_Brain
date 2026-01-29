import 'package:flutter/material.dart';

class TrendReportWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const TrendReportWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Market Trend Report';
    final summary = data['summary'] ?? '';
    // Support both new 'sections' and legacy 'trends' list
    final sections = data['sections'] as List?;
    final legacyTrends = data['trends'] as List?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up, color: Colors.purpleAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              summary,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
            ),
          ],
          
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),

          // Dynamic Sections
          if (sections != null && sections.isNotEmpty)
            ...sections.map((section) => _buildSection(section)).toList()
          else if (legacyTrends != null && legacyTrends.isNotEmpty)
            ...legacyTrends.map((trend) => _buildTrendItem(Map<String, dynamic>.from(trend))).toList()
          else
            const Center(child: Text("No data available.", style: TextStyle(color: Colors.white38))),
            
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
               onPressed: () {}, // Interactive placeholder
               icon: const Icon(Icons.download_rounded, size: 16),
               label: const Text("Export Full PDF"),
               style: TextButton.styleFrom(
                 foregroundColor: Colors.blueAccent,
                 textStyle: const TextStyle(fontSize: 12),
               ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection(dynamic sectionData) {
    if (sectionData is! Map) return const SizedBox.shrink();
    final type = sectionData['type'];

    switch (type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            sectionData['content'] ?? '',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
        );
      case 'stat_card':
        return _buildStatGrid(sectionData); // Handle single or list logic inside
      case 'chart':
        return _buildSimpleBarChart(sectionData);
      case 'trend_list':
         // Nested trends list
         final trends = sectionData['items'] as List? ?? [];
         return Column(
           children: trends.map((t) => _buildTrendItem(Map<String, dynamic>.from(t))).toList(),
         );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatGrid(Map sectionData) {
    // If it's a single stat or a list
    final items = sectionData['items'] as List?;
    if (items != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) => _buildSingleStat(item)).toList(),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _buildSingleStat(sectionData),
    );
  }

  Widget _buildSingleStat(dynamic data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data['label'] ?? 'Stat',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            data['value']?.toString() ?? '-',
            style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart(Map sectionData) {
    final title = sectionData['title'] as String?;
    final dataMap = sectionData['data'] as Map?;
    
    if (dataMap == null || dataMap.isEmpty) return const SizedBox.shrink();

    // Find max value for normalization
    double maxVal = 0;
    dataMap.forEach((k, v) {
       final val = (v is num) ? v.toDouble() : 0.0;
       if (val > maxVal) maxVal = val;
    });
    if (maxVal == 0) maxVal = 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
         color: Colors.black26,
         borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
             Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
             const SizedBox(height: 12),
          ],
          ...dataMap.entries.map((e) {
             final label = e.key.toString();
             final val = (e.value is num) ? e.value.toDouble() : 0.0;
             final pct = (val / maxVal).clamp(0.0, 1.0);
             
             return Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               child: Row(
                 children: [
                   SizedBox(
                     width: 80,
                     child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12), overflow: TextOverflow.ellipsis),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Stack(
                       children: [
                         Container(height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                         FractionallySizedBox(
                           widthFactor: pct,
                           child: Container(
                             height: 8, 
                             decoration: BoxDecoration(
                               color: Colors.purpleAccent, 
                               borderRadius: BorderRadius.circular(4)
                             )
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(width: 8),
                   Text(val.toStringAsFixed(0), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                 ],
               ),
             );
          }).toList()
        ],
      ),
    );
  }

  Widget _buildTrendItem(Map<String, dynamic> trend) {
    final name = trend['name'] ?? 'Unknown Trend';
    final growth = trend['growth'] ?? 0;
    final description = trend['description'] ?? '';
    final impact = (trend['impact_score'] as num?)?.toDouble() ?? 0.0; // 0.0 to 1.0

    // Determining color based on growth
    final isPositive = growth >= 0;
    final growthColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 15, 
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: growthColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: growthColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${growth.abs()}%',
                      style: TextStyle(
                        color: growthColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Impact Meter
          Row(
            children: [
              Text('Impact', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: impact,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
