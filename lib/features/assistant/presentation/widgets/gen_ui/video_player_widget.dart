import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_video_player.dart';

class VideoPlayerWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const VideoPlayerWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Extract data with safe fallbacks
    final String url = data['url'] ?? '';
    final String caption = data['caption'] ?? '';
    final bool autoPlay = data['autoplay'] == true;
    final String title = data['title'] ?? 'Generated Video';

    if (url.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, color: Colors.white24, size: 48),
              SizedBox(height: 8),
              Text('No video URL provided', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Optional, if title is distinct from generic)
          if (title.isNotEmpty && title != 'Generated Video')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.movie_creation_outlined, size: 18, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Video Player
          AspectRatio(
            aspectRatio: 16 / 9, // Default aspect ratio, player might adjust
            child: AppVideoPlayer(
              videoUrl: url,
              autoPlay: autoPlay,
            ),
          ),

          // Footer / Caption
          if (caption.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF252525),
              child: Text(
                caption,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
