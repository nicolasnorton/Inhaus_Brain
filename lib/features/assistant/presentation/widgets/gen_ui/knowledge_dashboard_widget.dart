import 'package:flutter/material.dart';
import 'package:ag_ui/ag_ui.dart';

class KnowledgeDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const KnowledgeDashboardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final sources = data['sources'] as List? ?? [];
    final stats = data['stats'] as Map? ?? {};
    final recentSyncs = data['recent_syncs'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Knowledge Intelligence Dashboard',
                    style: AgFonts.h2.copyWith(color: Colors.white),
                  ),
                  Text(
                    'Real-time data synchronization & semantic indexing',
                    style: AgFonts.body2.copyWith(color: Colors.white54),
                  ),
                ],
              ),
              _buildStatusBadge('Live'),
            ],
          ),
          const SizedBox(height: 32),
          
          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard('Sources', '${stats['total_sources'] ?? 0}', Icons.hub_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Documents', '${stats['total_docs'] ?? 0}', Icons.description_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Embeddings', '${stats['total_vectors'] ?? 0}', Icons.auto_awesome_outlined)),
            ],
          ),
          
          const SizedBox(height: 32),
          Text('Connected Platforms', style: AgFonts.h3.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          
          // Source Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: sources.map((s) => _buildPlatformChip(s)).toList(),
          ),
          
          const SizedBox(height: 32),
          Text('Recent Synchornizations', style: AgFonts.h3.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          
          // Activity List
          ...recentSyncs.take(3).map((s) => _buildActivityItem(s)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7B61FF), size: 24),
          const SizedBox(height: 12),
          Text(value, style: AgFonts.h1.copyWith(color: Colors.white)),
          Text(label, style: AgFonts.body2.copyWith(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildPlatformChip(dynamic source) {
    final name = source['name'] ?? 'Unknown';
    final type = source['type'] ?? 'general';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1423),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7B61FF).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getIconForType(type),
          const SizedBox(width: 8),
          Text(name, style: AgFonts.body1.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['message'] ?? 'Successfully synced', style: AgFonts.body1.copyWith(color: Colors.white)),
                Text(activity['time'] ?? 'Just now', style: AgFonts.body2.copyWith(color: Colors.white38)),
              ],
            ),
          ),
          Text(
            '+${activity['new_items'] ?? 0} items',
            style: AgFonts.body2.copyWith(color: const Color(0xFF7B61FF), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text, style: AgFonts.body2.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'meta': return const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 18);
      case 'linkedin': return const Icon(Icons.link, color: Color(0xFF0A66C2), size: 18);
      case 'google_ads': return const Icon(Icons.ads_click, color: Color(0xFF4285F4), size: 18);
      default: return const Icon(Icons.cloud_queue, color: Colors.white54, size: 18);
    }
  }

  static const _agFonts = _AgFontsMock();
}

class _AgFontsMock {
  const _AgFontsMock();
  TextStyle get h1 => const TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
  TextStyle get h2 => const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  TextStyle get h3 => const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  TextStyle get body1 => const TextStyle(fontSize: 16);
  TextStyle get body2 => const TextStyle(fontSize: 14);
}

const AgFonts = _AgFontsMock();
