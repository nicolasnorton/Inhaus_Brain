import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class AppVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  const AppVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
  });

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (kIsWeb) {
         // On Web, we might need to handle CORS or specific encoding
         _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
         _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      }

      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });

      if (widget.autoPlay) {
        await _controller.play();
        setState(() {
          _isPlaying = true;
        });
      }

      _controller.addListener(() {
        final isPlaying = _controller.value.isPlaying;
        if (isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
        if (_controller.value.hasError) {
           setState(() {
             _errorMessage = _controller.value.errorDescription;
           });
        }
      });

    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to load video: $e';
            });
          }
        });
      }
      print('Video Initialization Error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo() async {
    final Uri url = Uri.parse(widget.videoUrl);
    
    if (kIsWeb) {
      // On Web, we can try to force a download by using a specific launch mode 
      // or by interacting with the DOM (though we avoid dart:html here).
      // A common way without extra packages is to use launchUrl with external application,
      // but for "download", many browsers need the 'download' attribute.
      
      // For now, let's just make it more robust.
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
         _showError('Could not download video');
      }
    } else {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showError('Could not launch/download video');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message: ${widget.videoUrl}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Video Error',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                ),
                Text(
                  'Tap to download directly', 
                  style: Theme.of(context).textTheme.bodySmall
                ),
                TextButton(
                  onPressed: _downloadVideo,
                  child: const Text('Download'),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          _ControlsOverlay(
            controller: _controller,
            isPlaying: _isPlaying,
            onDownload: _downloadVideo,
          ),
          VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.blueAccent)),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isPlaying;
  final VoidCallback onDownload;

  const _ControlsOverlay({
    required this.controller,
    required this.isPlaying,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: Center(
                    child: IconButton(
                      onPressed: () {
                        controller.play();
                      },
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 64.0,
                      ),
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28), // Larger icon
              tooltip: 'Download Video',
              onPressed: onDownload,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
                padding: const EdgeInsets.all(12), // Larger touch target
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 25,
          right: 8,
          child: IconButton(
            icon: Icon(
              controller.value.volume == 0 ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
              size: 20
            ),
            onPressed: () {
               controller.setVolume(controller.value.volume == 0 ? 1.0 : 0.0);
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black45,
            ),
          )
        )
      ],
    );
  }
}
