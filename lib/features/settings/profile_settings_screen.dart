import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/secret_vault_service.dart';
import '../../core/services/system_prompts_service.dart';
import '../auth/auth_screen.dart';
import '../auth/models/user_model.dart';
import '../clients/models/client_model.dart';
import '../clients/providers/client_provider.dart';

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
  
  // Phase 35: Multi-Model Keys
  final _openaiController = TextEditingController();
  final _anthropicController = TextEditingController();
  final _xaiController = TextEditingController();
  final _midjourneyController = TextEditingController();
  final _runwayController = TextEditingController();

  final _researchPromptController = TextEditingController();
  final _creativePromptController = TextEditingController();
  final _copyPromptController = TextEditingController();
  final _devPromptController = TextEditingController();
  
  // Phase 31 Agency Roles
  final _trendScoutPromptController = TextEditingController();
  final _accountDirectorPromptController = TextEditingController();
  final _strategistPromptController = TextEditingController();
  final _editorialManagerPromptController = TextEditingController();
  final _mediaBuyerPromptController = TextEditingController();
  final _performanceAnalystPromptController = TextEditingController();
  
  // Utility
  final _securityPromptController = TextEditingController();
  final _dataEngPromptController = TextEditingController();

  final _displayNameController = TextEditingController();
  final _emailEditController = TextEditingController();

  bool _isLoadingKeys = true;
  bool _isEditingProfile = false;
  
  UserRole? _selectedRole;
  List<String> _selectedClientIds = [];

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
    
    // Phase 35
    _openaiController.text = await vault.getOpenAIKey() ?? '';
    _anthropicController.text = await vault.getAnthropicKey() ?? '';
    _xaiController.text = await vault.getXAIKey() ?? '';
    _midjourneyController.text = await vault.getMidjourneyKey() ?? '';
    _runwayController.text = await vault.getRunwayKey() ?? '';

    _researchPromptController.text = await prompts.getResearchPrompt();
    _creativePromptController.text = await prompts.getCreativePrompt();
    _copyPromptController.text = await prompts.getCopywriterPrompt();
    _devPromptController.text = await prompts.getDeveloperPrompt();
    
    // Agency Roles
    _trendScoutPromptController.text = await prompts.getTrendScoutPrompt();
    _accountDirectorPromptController.text = await prompts.getAccountDirectorPrompt();
    _strategistPromptController.text = await prompts.getStrategistPrompt();
    _editorialManagerPromptController.text = await prompts.getEditorialManagerPrompt();
    _mediaBuyerPromptController.text = await prompts.getMediaBuyerPrompt();
    _performanceAnalystPromptController.text = await prompts.getPerformanceAnalystPrompt();
    
    // Utility
    _securityPromptController.text = await prompts.getSecurityPrompt();
    _dataEngPromptController.text = await prompts.getDataEngPrompt();

    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _emailEditController.text = user.email ?? '';
      
      final profile = ref.read(authServiceProvider).getAppUser(user);
      _selectedRole = profile.role;
      _selectedClientIds = List.from(profile.assignedClientIds);
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
    
    // Phase 35
    await vault.saveOpenAIKey(_openaiController.text);
    await vault.saveAnthropicKey(_anthropicController.text);
    await vault.saveXAIKey(_xaiController.text);
    await vault.saveMidjourneyKey(_midjourneyController.text);
    await vault.saveRunwayKey(_runwayController.text);
    
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
    
    // Agency Roles
    await prompts.saveTrendScoutPrompt(_trendScoutPromptController.text);
    await prompts.saveAccountDirectorPrompt(_accountDirectorPromptController.text);
    await prompts.saveStrategistPrompt(_strategistPromptController.text);
    await prompts.saveEditorialManagerPrompt(_editorialManagerPromptController.text);
    await prompts.saveMediaBuyerPrompt(_mediaBuyerPromptController.text);
    await prompts.savePerformanceAnalystPrompt(_performanceAnalystPromptController.text);
    
    // Utility
    await prompts.saveSecurityPrompt(_securityPromptController.text);
    await prompts.saveDataEngPrompt(_dataEngPromptController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Master Prompts updated.')),
      );
    }
  }

  Future<void> _updateProfile() async {
    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (user != null) {
      await auth.updateDisplayName(_displayNameController.text);
      
      final profile = auth.getAppUser(user);
      final updatedProfile = profile.copyWith(
        displayName: _displayNameController.text,
        role: _selectedRole,
        assignedClientIds: _selectedClientIds,
      );
      await auth.updateAppUser(updatedProfile);
    }
    
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
              if (user != null) ...[
                _buildUserProfile(user),
                const SizedBox(height: 32),
                
                // 1.5 Role & Assignment Section
                _buildRoleAndClientManagement(user),
                const SizedBox(height: 32),
              ],

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
                          const SizedBox(height: 16),
                          _buildKeyField('Nano Banana 🍌 (Image Edit Key)', _bananaController, FontAwesomeIcons.wandMagicSparkles),
                          
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Divider(color: Colors.white24),
                          ),
                          const Text('MULTI-MODEL PROVIDERS (PHASE 35)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10)),
                          const SizedBox(height: 16),
                          
                          _buildKeyField('OpenAI API Key (GPT-4o)', _openaiController, FontAwesomeIcons.microchip),
                          const SizedBox(height: 16),
                          _buildKeyField('Anthropic API Key (Claude 3.5)', _anthropicController, FontAwesomeIcons.brain),
                          const SizedBox(height: 16),
                          _buildKeyField('xAI API Key (Grok)', _xaiController, FontAwesomeIcons.xTwitter),
                          
                           const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Divider(color: Colors.white24),
                          ),
                          const Text('CREATIVE GENERATION', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10)),
                          const SizedBox(height: 16),
                          _buildKeyField('Midjourney API Key (Proxy)', _midjourneyController, FontAwesomeIcons.paintRoller),
                          const SizedBox(height: 16),
                          _buildKeyField('Runway API Key (Gen-2)', _runwayController, FontAwesomeIcons.film),
                          
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
                          const SizedBox(height: 16),
                          
                          const Divider(color: Colors.white10),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'AGENCY PIPELINE ROLES',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.1),
                            ),
                          ),
                          
                          _buildPromptField('Trend Scout Prompt', _trendScoutPromptController, FontAwesomeIcons.bolt, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 16),
                          _buildPromptField('Account Director Prompt', _accountDirectorPromptController, FontAwesomeIcons.userTie, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 16),
                          _buildPromptField('Strategist Prompt', _strategistPromptController, FontAwesomeIcons.compass, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 16),
                          _buildPromptField('Editorial Manager Prompt', _editorialManagerPromptController, FontAwesomeIcons.calendarCheck, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 16),
                          _buildPromptField('Media Buyer Prompt', _mediaBuyerPromptController, FontAwesomeIcons.bullhorn, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 16),
                          _buildPromptField('Performance Analyst Prompt', _performanceAnalystPromptController, FontAwesomeIcons.chartLine, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 24),
                          
                          const Divider(color: Colors.white10),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'SECURITY & UTILITY',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.1),
                            ),
                          ),
                          
                          _buildPromptField('Cyber Security Prompt', _securityPromptController, FontAwesomeIcons.shieldHalved, readOnly: !ref.read(authServiceProvider).isAdmin),
                          const SizedBox(height: 16),
                          _buildPromptField('Data Engineer Prompt', _dataEngPromptController, FontAwesomeIcons.database, readOnly: !ref.read(authServiceProvider).isAdmin),
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
              onBackgroundImageError: user.photoURL != null 
                ? (exception, stackTrace) {
                    debugPrint('Avatar Load Error: $exception');
                  }
                : null,
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

  Widget _buildRoleAndClientManagement(User user) {
    final isAdmin = ref.read(authServiceProvider).isAdmin;
    final allClients = ref.watch(clientProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ROLE & ASSIGNMENTS',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role Selector
              const Text('User Role', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              if (_isEditingProfile && isAdmin)
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRole = val),
                )
              else
                Text(
                  _selectedRole?.name.toUpperCase() ?? 'NONE',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              
              const SizedBox(height: 24),
              
              // Assigned Clients
              const Text('Assigned Clients', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              if (_isEditingProfile && isAdmin)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allClients.map((client) {
                    final isSelected = _selectedClientIds.contains(client.id);
                    return FilterChip(
                      label: Text(client.name, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                      checkmarkColor: Colors.blueAccent,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedClientIds.add(client.id);
                          } else {
                            _selectedClientIds.remove(client.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedClientIds.isEmpty 
                    ? [const Text('No clients assigned', style: TextStyle(color: Colors.white24, fontSize: 12))]
                    : _selectedClientIds.map((id) {
                        final clientName = allClients.firstWhere((c) => c.id == id, orElse: () => Client(id: id, name: 'Unknown', industry: '')).name;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(clientName, style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
