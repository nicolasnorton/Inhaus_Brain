import 'package:flutter/material.dart';
import 'app_video_player.dart';

class VideoPreviewPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isFinal;
  final Function(bool includeSubtitles)? onRefine;
  final Function(bool includeSubtitles)? onRenderFinal;
  final String? progressMessage;
  final double? progress;

  const VideoPreviewPlayer({
    super.key,
    required this.videoUrl,
    this.isFinal = false,
    this.onRefine,
    this.onRenderFinal,
    this.progressMessage,
    this.progress,
  });

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  bool _includeSubtitles = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AppVideoPlayer(videoUrl: widget.videoUrl),
              ),
            ),
            if (!widget.isFinal)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PREVIEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (widget.progressMessage != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.progressMessage!,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  ],
                ),
              ),
              if (widget.progress != null) ...[
                const SizedBox(width: 12),
                Text(
                  '${(widget.progress! * 100).toInt()}%',
                  style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (!widget.isFinal) ...[
          SwitchListTile(
            value: _includeSubtitles,
            onChanged: (val) => setState(() => _includeSubtitles = val),
            title: const Text('Bilingual Subtitles (EN/ES)', style: TextStyle(color: Colors.white70, fontSize: 13)),
            dense: true,
            activeColor: Colors.blueAccent,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.onRefine != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onRefine!(_includeSubtitles),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refine'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
              if (widget.onRefine != null && widget.onRenderFinal != null) const SizedBox(width: 12),
              if (widget.onRenderFinal != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onRenderFinal!(_includeSubtitles),
                    icon: const Icon(Icons.movie_filter, size: 16),
                    label: const Text('Render Final (HQ)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
