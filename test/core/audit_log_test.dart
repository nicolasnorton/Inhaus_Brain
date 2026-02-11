import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/core/services/audit_log_service.dart';

void main() {
  group('AuditLogService Tests', () {
    test('Service initializes correctly', () {
      final container = ProviderContainer();
      final service = container.read(auditLogServiceProvider);
      expect(service, isNotNull);
    });

    // Note: Integration tests would check actual Firestore writes.
    // Here we mainly ensure the logic flows without crashing.
    test('Logging generic action does not throw', () async {
      final container = ProviderContainer();
      final service = container.read(auditLogServiceProvider);
      
      await expectLater(
        service.log(action: 'test/action', metadata: {'foo': 'bar'}),
        completes,
      );
    });
  });
}
