import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/features/auth/models/user_model.dart';
import 'package:inhaus_brain/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  Color(0xFF1A1F3C),
                  Color(0xFF0A0E17),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.psychology, size: 80, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Inhaus Brain',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your role to continue',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 32),
                  ...UserRole.values.map((role) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          ref.read(authProvider.notifier).login(role);
                        },
                        child: Text(
                          _roleToString(role),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Admin';
      case UserRole.accountManager: return 'Account Manager';
      case UserRole.designer: return 'Designer';
      case UserRole.socialMediaManager: return 'Social Media Manager';
      case UserRole.adManager: return 'Ad Manager';
    }
  }
}
