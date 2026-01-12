import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/assistant_provider.dart';

class AiAssistantButton extends ConsumerWidget {
  const AiAssistantButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(isAssistantOpenProvider);

    return FloatingActionButton(
      onPressed: () {
        ref.read(isAssistantOpenProvider.notifier).state = !isOpen;
      },
      backgroundColor: isOpen ? Colors.redAccent : Colors.blueAccent,
      child: Icon(isOpen ? Icons.close : Icons.smart_toy_outlined),
      tooltip: isOpen ? 'Close Assistant' : 'AI Assistant',
    );
  }
}
