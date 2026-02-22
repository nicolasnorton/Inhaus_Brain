import 'package:flutter/material.dart';
import '../widgets/composer_sidebar.dart';

class ComposerShellScreen extends StatelessWidget {
  final Widget child;
  const ComposerShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const ComposerSidebar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
