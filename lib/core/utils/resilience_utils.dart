import 'dart:async';
import 'package:flutter/foundation.dart';

enum CircuitState { closed, open, halfOpen }

/// Circuit Breaker (Inhaus Brain v2.0 Production)
/// 
/// Prevents cascading failures by stopping calls to a failing service.
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration resetTimeout;
  
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 3,
    this.resetTimeout = const Duration(seconds: 30),
  });

  CircuitState get state => _state;

  Future<T> execute<T>(Future<T> Function() action) async {
    _maybeReset();

    if (_state == CircuitState.open) {
      debugPrint('CircuitBreaker [$name]: Blocked request (State: OPEN)');
      throw Exception('Circuit Breaker [$name] is OPEN. Service unavailable.');
    }

    try {
      final result = await action();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure(e);
      rethrow;
    }
  }

  void _maybeReset() {
    if (_state == CircuitState.open && _lastFailureTime != null) {
      if (DateTime.now().difference(_lastFailureTime!) > resetTimeout) {
        debugPrint('CircuitBreaker [$name]: Switching to HALF-OPEN');
        _state = CircuitState.halfOpen;
      }
    }
  }

  void _onSuccess() {
    if (_state == CircuitState.halfOpen || _state == CircuitState.closed) {
      _state = CircuitState.closed;
      _failureCount = 0;
    }
  }

  void _onFailure(Object error) {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    debugPrint('CircuitBreaker [$name]: Failure count: $_failureCount');

    if (_failureCount >= failureThreshold) {
      debugPrint('CircuitBreaker [$name]: TRIP! State: OPEN');
      _state = CircuitState.open;
    }
  }
}
