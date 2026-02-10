import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MediaCarouselWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const MediaCarouselWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Review Assets';
    final List<dynamic> items = data['items'] ?? [];
    final double aspectRatio = (data['aspect_ratio'] is num) ? data['aspect_ratio'].toDouble() : 16/9;

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
        ],
        CarouselSlider(
          options: CarouselOptions(
            height: 250.0,
            aspectRatio: aspectRatio,
            enlargeCenterPage: true,
            autoPlay: false,
            viewportFraction: 0.85,
          ),
          items: items.map<Widget>((item) {
            final type = item['type'] ?? 'image';
            final url = item['url'] ?? '';
            final caption = item['caption'] ?? '';

            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D333B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: type == 'video' 
                          ? Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white70)) // Simplified Video Placeholder
                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (c,e,s) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
                            ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                            ),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          ),
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            caption,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
