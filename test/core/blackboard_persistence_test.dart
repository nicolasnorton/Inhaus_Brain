import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/core/architecture/blackboard.dart';

void main() {
  group('BlackboardState Persistence Tests', () {
    test('BlackboardState should initialize with default assistant_global sessionId', () {
      final state = BlackboardState();
      expect(state.sessionId, 'assistant_global');
    });

    test('BlackboardState should serialize to JSON with sessionId', () {
      final state = BlackboardState(sessionId: 'test_session_123');
      final json = state.toJson();
      
      expect(json['sessionId'], 'test_session_123');
    });

    test('BlackboardState should deserialize from JSON with sessionId', () {
      final json = {
        'facts': {'key': 'value'},
        'sessionId': 'restored_session_456',
        'phase': 'strategy',
      };
      
      final state = BlackboardState.fromJson(json);
      
      expect(state.sessionId, 'restored_session_456');
      expect(state.facts['key'], 'value');
      expect(state.phase, BlackboardPhase.strategy);
    });

    test('BlackboardNotifier.initialize should set correct sessionId', () {
      final notifier = BlackboardNotifier();
      notifier.initialize('new_session_id');
      
      expect(notifier.state.sessionId, 'new_session_id');
      expect(notifier.state.facts, isEmpty);
    });

    test('BlackboardNotifier.clear should preserve existing sessionId if not provided', () {
      final notifier = BlackboardNotifier();
      notifier.initialize('persistent_id');
      notifier.postFact('temp', 'data');
      
      notifier.clear();
      
      expect(notifier.state.sessionId, 'persistent_id');
      expect(notifier.state.facts, isEmpty);
    });
    
    test('BlackboardNotifier.clear should update sessionId if provided', () {
      final notifier = BlackboardNotifier();
      notifier.initialize('old_id');
      
      notifier.clear(sessionId: 'new_id');
      
      expect(notifier.state.sessionId, 'new_id');
    });
  });
}
