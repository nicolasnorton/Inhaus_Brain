import 'package:flutter/material.dart';
import 'app_video_player.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

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

  void _downloadVideo(String url) {
    if (!kIsWeb) return;
    
    // Ensure we have a valid data URI or URL
    String downloadUrl = url;
    if (downloadUrl.startsWith('data:video/mp4;base64,')) {
      // It's already a data URI
    } else if (!downloadUrl.startsWith('http') && !downloadUrl.startsWith('gs://')) {
      // Assume it's raw base64 if not a URL
      downloadUrl = 'data:video/mp4;base64,$downloadUrl';
    }

    try {
      final anchor = html.AnchorElement(href: downloadUrl)
        ..setAttribute("download", "inhaus_video_${DateTime.now().millisecondsSinceEpoch}.mp4")
        ..click();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting download...')),
      );
    } catch (e) {
      debugPrint('Error downloading video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we are showing a fallback image (Storyboard) instead of a video
    // Use robust trimming and regex to handle potential whitespace or casing issues
    final cleanUrl = widget.videoUrl.trim();
    
    // RADICAL STRIP: Always remove prefixes (recursive) if present to avoid scheme errors
    // Regex matches one or more occurrences of "image:" or "video:" at the start
    String mediaUrl = cleanUrl.replaceAll(RegExp(r'^((image|video):\s*)+', caseSensitive: false), '').trim();
    if (mediaUrl.contains(':') && RegExp(r':\d+$').hasMatch(mediaUrl)) {
      print('DEBUG: VideoPreviewPlayer stripping trailing noise from $mediaUrl');
      mediaUrl = mediaUrl.replaceFirst(RegExp(r':\d+$'), '');
    }
    
    // DEBUG: Print detection logic
    print('DEBUG: VideoPreviewPlayer input: "$cleanUrl"');
    print('DEBUG: VideoPreviewPlayer target: "$mediaUrl"');
    
    bool isFallbackImage = cleanUrl.toUpperCase().startsWith('IMAGE:') || 
                           RegExp(r'^image:', caseSensitive: false).hasMatch(cleanUrl);

    // FAILSAFE: If it contains 'unsplash' or typical image extensions and isn't marked, force it
    if (!isFallbackImage && (mediaUrl.contains('unsplash.com') || mediaUrl.contains('pollinations.ai') || 
                             mediaUrl.toLowerCase().contains('.png') || mediaUrl.toLowerCase().contains('.jpg') || 
                             mediaUrl.toLowerCase().contains('.webp'))) {
       print('DEBUG: VideoPreviewPlayer detected image by content (failsafe)');
       isFallbackImage = true;
    }

    print('DEBUG: VideoPreviewPlayer isFallbackImage: $isFallbackImage');

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
                child: isFallbackImage
                   ? Stack(
                       fit: StackFit.expand,
                       children: [
                         Image.network(
                           mediaUrl, 
                           fit: BoxFit.cover,
                           loadingBuilder: (ctx, child, loadingProgress) {
                             if (loadingProgress == null) return child;
                             return const Center(child: CircularProgressIndicator());
                           },
                           errorBuilder: (ctx, err, stack) => Container(
                             color: Colors.grey[900],
                             child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                           ),
                         ),
                         Container(
                           color: Colors.black45,
                           child: Center(
                             child: Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Icon(Icons.image, color: Colors.white, size: 48),
                                 SizedBox(height: 8),
                                 Text(
                                   "Static Storyboard",
                                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                 ),
                                 Text(
                                   "(Preview generation timed out)",
                                   style: TextStyle(color: Colors.white70, fontSize: 12),
                                 ),
                                 if (widget.onRefine != null)
                                   Padding(
                                     padding: const EdgeInsets.only(top: 8.0),
                                     child: OutlinedButton.icon(
                                       onPressed: () => widget.onRefine!(false),
                                       icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                                       label: const Text('Retry Generation', style: TextStyle(color: Colors.white70)),
                                       style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                                     ),
                                   ),
                               ],
                             ),
                           ),
                         ),
                       ],
                     )
                   : AppVideoPlayer(videoUrl: mediaUrl),
              ),
            ),
            if (!widget.isFinal)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFallbackImage ? Colors.grey : Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isFallbackImage ? Icons.image : Icons.bolt, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isFallbackImage ? 'FALLBACK' : 'LITERT FAST',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                    label: const Text('Refine Preview'),
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
          if (!isFallbackImage && (widget.videoUrl.isNotEmpty)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _downloadVideo(mediaUrl),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download Original Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
