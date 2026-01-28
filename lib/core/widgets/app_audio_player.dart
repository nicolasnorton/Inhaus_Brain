import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

class AppAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final bool autoPlay;

  const AppAudioPlayer({
    super.key,
    required this.audioUrl,
    this.autoPlay = false,
  });

  @override
  State<AppAudioPlayer> createState() => _AppAudioPlayerState();
}

class _AppAudioPlayerState extends State<AppAudioPlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Listen to states
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });

    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      if (widget.audioUrl.isNotEmpty) {
          await _audioPlayer.setSourceUrl(widget.audioUrl);
          if (widget.autoPlay) {
              await _audioPlayer.resume();
          }
      }
    } catch (e) {
      print("Audio Init Error: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _downloadAudio() async {
    final Uri url = Uri.parse(widget.audioUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
       // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
            child: IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              color: Colors.blueAccent,
              onPressed: () async {
                if (_isPlaying) {
                  await _audioPlayer.pause();
                } else {
                  await _audioPlayer.resume();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisSize: MainAxisSize.min,
               children: [
                 SliderTheme(
                   data: SliderTheme.of(context).copyWith(
                     thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                     trackHeight: 2,
                     overlayShape: SliderComponentShape.noOverlay,
                   ),
                   child: Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble(),
                      value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.white24,
                      onChanged: (value) async {
                        final position = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(position);
                      },
                   ),
                 ),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 4),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(_formatDuration(_position), style: const TextStyle(fontSize: 10, color: Colors.white54)),
                       Text(_formatDuration(_duration), style: const TextStyle(fontSize: 10, color: Colors.white54)),
                     ],
                   ),
                 )
               ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 20, color: Colors.white54),
            tooltip: 'Download Audio',
            onPressed: _downloadAudio,
          ),
        ],
      ),
    );
  }
}
