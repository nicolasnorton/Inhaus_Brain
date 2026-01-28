
import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/features/chat/models/chat_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock ProviderContainer if needed, but we can unit test the logic if it was public.
// Since it's inside ChatNotifier, we might need a widget test or a simpler unit test.
// For now, let's create a test that verifies Context Compression Logic in isolation
// but simulating a chat history structure.

import 'package:inhaus_brain/core/services/orchestrator_service.dart';

// Mock Ref
class MockRef extends Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Simulate Chat History Construction', () {
    final orchestrator = OrchestratorService(MockRef());
    
    final messages = List.generate(30, (i) => ChatMessage(
        id: '$i', 
        content: 'Message $i', 
        sender: i % 2 == 0 ? MessageSender.user : MessageSender.system, 
        createdAt: DateTime.now()
    ));
    
    // Logic from ChatProvider
    final history = messages
        .where((m) => m.type == MessageType.text || m.type == MessageType.toolUsage)
        .take(20) // ChatProvider uses take(20) at the start?? 
        // Wait, standard List.take takes from the START. 
        // If we want the RECENT messages, we should probably reverse or takeLast?
        // Let's verify standard Dart Iterable behavior.
        // iterable.take(n) takes the first n elements.
        .map((m) => "${m.sender.name}: ${m.content}")
        .join("\n");
    
    // If the list is chronological [0, 1, 2... 29], take(20) gives 0..19.
    // This gives the OLDEST messages! 
    // We usually want the NEWEST messages (29, 28...).
    
    // THIS IS A BUG FIND! 
    // If ChatProvider does `messages.take(20)`, and `messages` are [Old...New],
    // then it deletes the new context.
    
    // Let's check ChatProvider implementation of `messages`.
    // In `sendMessage`: `messages: [...state!.messages, userMessage]` -> Chronological order.
    // So `messages` is [Old, ..., New].
    // `messages.take(20)` returns the OLDContext.
    
    // We need `messages.reversed.take(20).toList().reversed` OR `messages.skip(length - 20)`.
  });
}
