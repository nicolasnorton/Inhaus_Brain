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
        if (isOpen) {
          // Trigger send in the overlay
          ref.read(assistantSendTriggerProvider.notifier).state++;
        } else {
          ref.read(isAssistantOpenProvider.notifier).state = true;
        }
      },
      backgroundColor: Colors.blueAccent,
      child: Icon(isOpen ? Icons.send : Icons.smart_toy_outlined),
      tooltip: isOpen ? 'Send Message' : 'AI Assistant',
    );
  }
}
