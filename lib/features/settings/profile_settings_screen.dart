import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_service.dart';
import 'secret_vault_service.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _geminiController = TextEditingController();
  final _veoController = TextEditingController();
  final _bananaController = TextEditingController();
  bool _isLoadingKeys = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final vault = ref.read(secretVaultProvider);
    _geminiController.text = await vault.getGeminiKey() ?? '';
    _veoController.text = await vault.getVeoKey() ?? '';
    _bananaController.text = await vault.getBananaKey() ?? '';
    setState(() => _isLoadingKeys = false);
  }

  Future<void> _saveKeys() async {
    final vault = ref.read(secretVaultProvider);
    await vault.saveGeminiKey(_geminiController.text);
    await vault.saveVeoKey(_veoController.text);
    await vault.saveBananaKey(_bananaController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keys securely saved to Vault.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Assuming dark theme
      appBar: AppBar(
        title: const Text('Settings & Vault'),
        backgroundColor: Colors.transparent,
      ),
      body: authState.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Profile Section
              _buildUserProfile(user),
              const SizedBox(height: 32),
              const Divider(color: Colors.white24),
              const SizedBox(height: 32),
              
              // 2. Secrets Vault Section
              const Text(
                'SECRETS VAULT (BYO-KEYS)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your keys are stored securely on your device. Inhaus Brain uses them for high-tier agent actions.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoadingKeys)
                      const CircularProgressIndicator()
                    else
                      Column(
                        children: [
                          _buildKeyField('Gemini Pro / Flash API Key', _geminiController, FontAwesomeIcons.google),
                          const SizedBox(height: 16),
                          _buildKeyField('Veo Video Gen Key', _veoController, FontAwesomeIcons.video),
                          const SizedBox(height: 16),
                          _buildKeyField('Banana Dev Key (Llama/Mistral)', _bananaController, FontAwesomeIcons.code),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saveKeys,
                              icon: const Icon(Icons.lock_outline, size: 16),
                              label: const Text('Save to Vault'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildUserProfile(User? user) {
    if (user == null) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () => ref.read(authServiceProvider).signInWithGoogle(),
          icon: const FaIcon(FontAwesomeIcons.google, size: 16),
          label: const Text('Sign in with Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null ? const Icon(Icons.person, size: 32) : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? 'Display Name',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                user.email ?? 'email@example.com',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => ref.read(authServiceProvider).signOut(),
          icon: const Icon(Icons.logout, color: Colors.white38),
          tooltip: 'Sign Out',
        ),
      ],
    );
  }

  Widget _buildKeyField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 16, color: Colors.white38),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
