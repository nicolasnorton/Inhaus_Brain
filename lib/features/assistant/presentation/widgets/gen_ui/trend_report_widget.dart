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
          // Header with gradient accent
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purpleAccent.withOpacity(0.3), Colors.blueAccent.withOpacity(0.2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.purpleAccent, size: 24),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Market Intelligence',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.5),
          ),
        );
      case 'heading':
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
          child: Text(
            sectionData['title'] ?? sectionData['content'] ?? 'Section',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      case 'check_list':
        final items = sectionData['items'] as List? ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.toString(), style: const TextStyle(color: Colors.white70, fontSize: 13))),
                ],
              ),
            )).toList(),
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
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items.map((item) => _buildSingleStat(item)).toList(),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: _buildSingleStat(sectionData),
    );
  }

  Widget _buildSingleStat(dynamic data) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minWidth: 140),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (data['label'] ?? 'Stat').toString().toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5), 
              fontSize: 11, 
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['value']?.toString() ?? '-',
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          if (data['change'] != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data['change'].toString(),
                style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ]
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
         color: Colors.black.withOpacity(0.3),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
             Text(
               title.toUpperCase(), 
               style: TextStyle(
                 color: Colors.white.withOpacity(0.9), 
                 fontWeight: FontWeight.bold, 
                 fontSize: 13,
                 letterSpacing: 0.8,
               )
             ),
             const SizedBox(height: 16),
          ],
          ...dataMap.entries.map((e) {
             final label = e.key.toString();
             final val = (e.value is num) ? e.value.toDouble() : 0.0;
             final pct = (val / maxVal).clamp(0.0, 1.0);
             
             return Padding(
               padding: const EdgeInsets.only(bottom: 12.0),
               child: Row(
                 children: [
                   SizedBox(
                     width: 90,
                     child: Text(
                       label, 
                       style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500), 
                       overflow: TextOverflow.ellipsis
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Stack(
                       children: [
                         Container(
                           height: 10, 
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.05), 
                             borderRadius: BorderRadius.circular(5)
                           )
                         ),
                         FractionallySizedBox(
                           widthFactor: pct,
                           child: Container(
                             height: 10, 
                             decoration: BoxDecoration(
                               gradient: LinearGradient(
                                 colors: [Colors.blueAccent, Colors.purpleAccent],
                                 begin: Alignment.centerLeft,
                                 end: Alignment.centerRight,
                               ),
                               borderRadius: BorderRadius.circular(5),
                               boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                               ]
                             )
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(width: 12),
                   SizedBox(
                     width: 40,
                     child: Text(
                       val.toStringAsFixed(0), 
                       style: const TextStyle(
                         color: Colors.white, 
                         fontSize: 13, 
                         fontWeight: FontWeight.bold
                       ),
                       textAlign: TextAlign.end,
                     ),
                   ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                    fontSize: 16, 
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: growthColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: growthColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: growthColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${growth.abs()}%',
                      style: TextStyle(
                        color: growthColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
            style: TextStyle(
              color: Colors.white.withOpacity(0.7), 
              fontSize: 14, 
              height: 1.4
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          
          // Impact Meter
          Row(
            children: [
              Text('IMPACT', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: impact,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      impact > 0.7 ? Colors.deepPurpleAccent : (impact > 0.4 ? Colors.purpleAccent : Colors.blueAccent)
                    ),
                    minHeight: 6,
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
