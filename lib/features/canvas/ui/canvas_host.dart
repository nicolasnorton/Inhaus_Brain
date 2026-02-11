import 'package:flutter/material.dart';

class CanvasHost extends StatefulWidget {
  const CanvasHost({super.key});

  @override
  State<CanvasHost> createState() => _CanvasHostState();
}

class _CanvasHostState extends State<CanvasHost> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E), // Dark background for canvas
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.draw_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              "Canvas Empty",
              style: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }
}
