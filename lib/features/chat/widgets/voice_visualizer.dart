import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceVisualizer extends StatefulWidget {
  final double soundLevel;
  final bool isActive;

  const VoiceVisualizer({super.key, required this.soundLevel, required this.isActive});

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (index) {
              final level = widget.soundLevel.clamp(0.0, 10.0) / 10.0;
              final wave = math.sin((_controller.value * 2 * math.pi) + (index * 0.5));
              final height = 4.0 + (level * 20.0) + (wave.abs() * 10.0);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.6 + (wave.abs() * 0.4)),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
