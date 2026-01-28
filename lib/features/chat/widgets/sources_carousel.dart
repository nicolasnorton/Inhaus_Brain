import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SourcesCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> sources;

  const SourcesCarousel({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8, top: 12),
          child: Text(
            'SOURCES',
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold, 
              color: Colors.white54, 
              letterSpacing: 1.2
            ),
          ),
        ),
        SizedBox(
          height: 80, // Fixed height for the cards
          child: ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: sources.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final source = sources[index];
              return _buildSourceCard(context, source);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSourceCard(BuildContext context, Map<String, dynamic> source) {
    final title = source['title'] ?? 'Unknown Source';
    final url = source['url'] ?? '';
    final domain = _getDomain(url);

    return InkWell(
      onTap: () {
        if (url.isNotEmpty) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Favicon placeholder - in a real app, use a favicon fetcher
                Container(
                  width: 16, 
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    domain.isNotEmpty ? domain[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    domain,
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12, 
                color: Colors.white, 
                fontWeight: FontWeight.w500
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return 'web';
    }
  }
}
