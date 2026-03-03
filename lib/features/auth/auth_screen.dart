import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'google_signin_button.dart'
    if (dart.library.js_interop) 'google_signin_button_web.dart'
    if (dart.library.io) 'google_signin_button_mobile.dart';
import '../../core/auth/auth_service.dart';
import '../../core/router/app_router.dart';
import '../../core/providers/demo_provider.dart';
import '../../features/knowledge/providers/knowledge_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final auth = ref.read(authServiceProvider);
    
    try {
      if (_isLogin) {
        await auth.signInWithEmail(_emailController.text, _passwordController.text);
      } else {
        await auth.signUpWithEmail(
          _emailController.text, 
          _passwordController.text, 
          _nameController.text
        );
      }
      // If we are at the /login route, the app_router's redirect will handle the transition.
      // If we were pushed manually (e.g. from Settings), we need to pop.
      if (mounted) {
        final router = ref.read(routerProvider);
        final currentPath = router.routerDelegate.currentConfiguration.last.matchedLocation;
        if (currentPath == '/login') {
          // GoRouter will redirect us automatically due to auth state change.
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 44,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),
                Image.asset(
                  'assets/images/brain_icon.png',
                  height: 80, // Slightly larger for better visibility
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'INHAUS BRAIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6.0,
                      ),
                    ),
                  ),
                ),
                const Text(
                  'v1.1.22',
                  style: TextStyle(color: Colors.white24, fontSize: 8),
                ),
                const SizedBox(height: 54),
                Text(
                  _isLogin ? AppLocalizations.of(context)!.welcomeBackAuth : AppLocalizations.of(context)!.createAccountAuth,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? AppLocalizations.of(context)!.signInAccessConsole : AppLocalizations.of(context)!.joinEcosystem,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 48),
                
                // Form
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      if (!_isLogin) ...[
                        _buildTextField(AppLocalizations.of(context)!.fullNameLabel, _nameController, Icons.person_outline),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField(AppLocalizations.of(context)!.emailAddressLabel, _emailController, Icons.email_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(AppLocalizations.of(context)!.passwordLabel, _passwordController, Icons.lock_outline, obscureText: true),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(_isLogin ? AppLocalizations.of(context)!.signInLabel : AppLocalizations.of(context)!.registerLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                // Toggle
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin ? AppLocalizations.of(context)!.newAccountLabel : AppLocalizations.of(context)!.existingUserLogin,
                    style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.orLabel, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                const SizedBox(height: 16),
                
                const SizedBox(height: 32),
                const SizedBox(height: 16),
                _buildGoogleSignInButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return buildGoogleSignInButton(
      context: context,
      isLoading: _isLoading,
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          await ref.read(authServiceProvider).signInWithGoogle();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Google Sign-In Error: $e'), backgroundColor: Colors.redAccent),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white30, fontSize: 12),
        prefixIcon: Icon(icon, size: 18, color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
