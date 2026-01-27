import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_models.dart';

class ThinkingIndicator extends StatefulWidget {
  final ChatMessage message;

  const ThinkingIndicator({super.key, required this.message});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator> {
  late Timer _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _updateDuration());
  }

  void _updateDuration() {
    if (mounted) {
      setState(() {
        _duration = DateTime.now().difference(widget.message.createdAt);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent.withValues(alpha: 0.8)),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.message.content, 
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${_duration.inSeconds}.${(_duration.inMilliseconds % 1000 ~/ 100)}s",
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blueAccent,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
