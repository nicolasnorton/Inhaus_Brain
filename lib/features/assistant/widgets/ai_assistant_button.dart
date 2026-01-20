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
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white, width: 1.0),
      ),
      tooltip: isOpen ? 'Send Message' : 'Brian',
      child: isOpen 
        ? const Icon(Icons.send)
        : ClipOval(
            child: Image.asset(
              'assets/images/ihb_favicon.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.smart_toy_outlined),
            ),
          ),
    );
  }
}
