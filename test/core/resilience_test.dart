import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/utils/resilience_utils.dart';

void main() {
  group('CircuitBreaker Tests', () {
    test('starts in CLOSED state', () {
      final cb = CircuitBreaker(name: 'test', failureThreshold: 2);
      expect(cb.state, CircuitState.closed);
    });

    test('trips to OPEN after threshold reached', () async {
      final cb = CircuitBreaker(name: 'test', failureThreshold: 2);
      
      // First failure
      try {
        await cb.execute(() => throw Exception('fail 1'));
      } catch (_) {}
      expect(cb.state, CircuitState.closed);
      
      // Second failure
      try {
        await cb.execute(() => throw Exception('fail 2'));
      } catch (_) {}
      expect(cb.state, CircuitState.open);
    });

    test('blocks calls when OPEN', () async {
      final cb = CircuitBreaker(name: 'test', failureThreshold: 1);
      
      try {
        await cb.execute(() => throw Exception('fail'));
      } catch (_) {}
      
      expect(cb.state, CircuitState.open);
      
      expect(
        () => cb.execute(() async => 'success'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('OPEN'))),
      );
    });

    test('resets to HALF-OPEN after timeout', () async {
      final cb = CircuitBreaker(
        name: 'test', 
        failureThreshold: 1, 
        resetTimeout: const Duration(milliseconds: 100),
      );
      
      try {
        await cb.execute(() => throw Exception('fail'));
      } catch (_) {}
      
      expect(cb.state, CircuitState.open);
      
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Next call should be allowed and move to HALF-OPEN
      final result = await cb.execute(() async => 'recovered');
      expect(result, 'recovered');
      expect(cb.state, CircuitState.closed); // Success in half-open closes it
    });
  });
}
