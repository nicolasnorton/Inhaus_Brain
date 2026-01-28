
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/services/local_persistence_service.dart';

class OnboardingNotifier extends StateNotifier<bool> {
  final LocalPersistenceService _persistence;

  OnboardingNotifier(this._persistence) : super(false) {
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final completed = await _persistence.getOnboardingCompleted();
    state = completed;
  }

  Future<void> completeOnboarding() async {
    await _persistence.setOnboardingCompleted(true);
    state = true;
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref.watch(persistenceServiceProvider));
});
