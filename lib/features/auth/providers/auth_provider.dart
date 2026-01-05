import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/features/auth/models/user_model.dart';

class AuthNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  void login(UserRole role) {
    state = AppUser(
      id: 'mock-id',
      email: 'user@inhausbrain.com',
      role: role,
    );
  }

  void logout() {
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);
