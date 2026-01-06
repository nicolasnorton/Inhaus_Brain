import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/secret_vault_service.dart';
import '../../core/services/system_prompts_service.dart';
import '../auth/auth_screen.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _geminiController = TextEditingController();
  final _veoController = TextEditingController();
  final _bananaController = TextEditingController(); // Nano Banana
  final _imagenController = TextEditingController();
  final _lyriaController = TextEditingController();
  final _gemmaController = TextEditingController();

  final _researchPromptController = TextEditingController();
  final _creativePromptController = TextEditingController();
  final _copyPromptController = TextEditingController();
  final _devPromptController = TextEditingController();

  final _displayNameController = TextEditingController();
  final _emailEditController = TextEditingController();

  bool _isLoadingKeys = true;
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadKeysAndPrompts();
  }

  Future<void> _loadKeysAndPrompts() async {
    final vault = ref.read(secretVaultProvider);
    final prompts = ref.read(systemPromptsProvider);

    _geminiController.text = await vault.getGeminiKey() ?? '';
    _veoController.text = await vault.getVeoKey() ?? '';
    _bananaController.text = await vault.getBananaKey() ?? '';
    _imagenController.text = await vault.getImagenKey() ?? '';
    _lyriaController.text = await vault.getLyriaKey() ?? '';
    _gemmaController.text = await vault.getGemmaKey() ?? '';

    _researchPromptController.text = await prompts.getResearchPrompt() ?? '';
    _creativePromptController.text = await prompts.getCreativePrompt() ?? '';
    _copyPromptController.text = await prompts.getCopywriterPrompt() ?? '';
    _devPromptController.text = await prompts.getDeveloperPrompt() ?? '';

    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _emailEditController.text = user.email ?? '';
    }

    setState(() => _isLoadingKeys = false);
  }

  Future<void> _saveKeys() async {
    final vault = ref.read(secretVaultProvider);
    await vault.saveGeminiKey(_geminiController.text);
    await vault.saveVeoKey(_veoController.text);
    await vault.saveBananaKey(_bananaController.text);
    await vault.saveImagenKey(_imagenController.text);
    await vault.saveLyriaKey(_lyriaController.text);
    await vault.saveGemmaKey(_gemmaController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keys securely saved to Vault.')),
      );
    }
  }

  Future<void> _savePrompts() async {
    final prompts = ref.read(systemPromptsProvider);
    await prompts.saveResearchPrompt(_researchPromptController.text);
    await prompts.saveCreativePrompt(_creativePromptController.text);
    await prompts.saveCopywriterPrompt(_copyPromptController.text);
    await prompts.saveDeveloperPrompt(_devPromptController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Master Prompts updated.')),
      );
    }
  }

  Future<void> _updateProfile() async {
    final auth = ref.read(authServiceProvider);
    await auth.updateDisplayName(_displayNameController.text);
    // In a real app, email update is more complex (verification etc.)
    setState(() => _isEditingProfile = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
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
                          _buildKeyField('Gemma Model Key (Vertex/Local)', _gemmaController, FontAwesomeIcons.dna),
                          const SizedBox(height: 16),
                          _buildKeyField('Imagen 3 Generation Key', _imagenController, FontAwesomeIcons.image),
                          const SizedBox(height: 16),
                          _buildKeyField('Veo Video Gen Key', _veoController, FontAwesomeIcons.video),
                          const SizedBox(height: 16),
                          _buildKeyField('Lyria Music Gen Key', _lyriaController, FontAwesomeIcons.music),
                          const SizedBox(height: 16),
                          _buildKeyField('Nano Banana 🍌 (Image Edit Key)', _bananaController, FontAwesomeIcons.wandMagicSparkles),
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

              const SizedBox(height: 32),
              
              // 3. Agent Brain Section (Master Prompts)
              const Text(
                'AGENT BRAIN (MASTER PROMPTS)',
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
                      'Define the system instructions for each agent. These master prompts guide their behavior and persona.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoadingKeys) 
                      const CircularProgressIndicator()
                    else
                      Column(
                        children: [
                          _buildPromptField('Research Agent Prompt', _researchPromptController, FontAwesomeIcons.magnifyingGlass, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 16),
                          _buildPromptField('Creative Agent Prompt', _creativePromptController, FontAwesomeIcons.palette, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 16),
                          _buildPromptField('Copywriter Agent Prompt', _copyPromptController, FontAwesomeIcons.penNib, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 16),
                          _buildPromptField('Developer Agent Prompt', _devPromptController, FontAwesomeIcons.code, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 24),
                          if (ref.read(authServiceProvider).isAdmin)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _savePrompts,
                                icon: const Icon(FontAwesomeIcons.brain, size: 16),
                                label: const Text('Update Agent Brains'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purpleAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Original prompts are protected. Only system admins can modify the Agent Brain.',
                                style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildPromptField(String label, TextEditingController controller, IconData icon, {bool readOnly = false}) {
    return TextField(
      controller: controller,
      maxLines: 3,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.white38 : Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 48), // Align top
          child: Icon(icon, size: 16, color: readOnly ? Colors.white12 : Colors.white38),
        ),
        filled: true,
        fillColor: readOnly ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildUserProfile(User? user) {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.account_circle_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Sign in to sync your agents and vault across devices',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Login / Sign Up'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(authServiceProvider).signInWithGoogle(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text('Google'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Avatar Load Error: $exception');
              },
              child: user.photoURL == null 
                ? Text(
                    (user.displayName ?? user.email ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ) 
                : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Brain User',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email ?? 'not.logged@in.com',
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
        ),
        const SizedBox(height: 24),
        if (!_isEditingProfile)
          TextButton.icon(
            onPressed: () => setState(() => _isEditingProfile = true),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Edit Profile Details'),
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildPromptField('Display Name', _displayNameController, Icons.person_outline),
                const SizedBox(height: 12),
                _buildPromptField('Email Address', _emailEditController, Icons.email_outlined),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isEditingProfile = false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text('Update Profile'),
                    ),
                  ],
                ),
              ],
            ),
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
