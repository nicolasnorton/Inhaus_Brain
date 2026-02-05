import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/secret_vault_service.dart';
import '../../core/services/system_prompts_service.dart';
import '../auth/models/user_model.dart';
import '../clients/providers/client_provider.dart';
import 'screens/agent_config_screen.dart';

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
      
      final profile = await ref.read(authServiceProvider).getAppUser(user);
      _selectedRole = profile.role;
      _selectedClientIds = List.from(profile.assignedClientIds);
    }

    setState(() {});
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
        SnackBar(content: Text(AppLocalizations.of(context)!.keysSavedMsg)),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.promptsUpdatedMsg)),
      );
    }
  }

  Future<void> _updateProfile() async {
    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(_displayNameController.text);
      
      final profile = await auth.getAppUser(user);
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
        SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdatedMsg)),
      );
    }
  }

  int _selectedIndex = 0;

  List<(String, IconData)> _getSections(BuildContext context) => [
    (AppLocalizations.of(context)!.secGeneral, Icons.person_outline),
    (AppLocalizations.of(context)!.secAgentBrain, FontAwesomeIcons.brain),
    (AppLocalizations.of(context)!.secAIModels, FontAwesomeIcons.microchip),
    (AppLocalizations.of(context)!.secConnectors, FontAwesomeIcons.plug),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.operationsCenter),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          // 1. Internal Settings Sidebar
          Container(
            width: 200,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: ListView.builder(
              itemCount: _getSections(context).length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                final sections = _getSections(context);
                return ListTile(
                  leading: Icon(sections[index].$2, size: 18, color: isSelected ? Colors.blueAccent : Colors.white54),
                  title: Text(
                    sections[index].$1,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.blueAccent.withValues(alpha: 0.1),
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          
          // 2. Content Area
          Expanded(
            child: Container(
              color: const Color(0xFF0F0F0F),
              child: RefreshedWebLayout( // Helper for consistent padding
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: _buildSectionContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    final user = ref.watch(authStateProvider).value;
    switch (_selectedIndex) {
      case 0: return _buildGeneralSection(user);
      case 1: return _buildBrainSection();
      case 2: return _buildAIModelsSection();
      case 3: return _buildConnectorsSection();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildGeneralSection(User? user) {
    if (user == null) return _buildLoginPrompt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(AppLocalizations.of(context)!.profileAccount, AppLocalizations.of(context)!.profileAccountSub),
        const SizedBox(height: 32),
        _buildUserProfile(user),
        const SizedBox(height: 32),
        _buildRoleAndClientManagement(user),
      ],
    );
  }

  Widget _buildBrainSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(AppLocalizations.of(context)!.agentBrainTitle, AppLocalizations.of(context)!.agentBrainSub),
        const SizedBox(height: 32),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(FontAwesomeIcons.robot, size: 48, color: Colors.purpleAccent),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.agentStudioTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.agentStudioSub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings_suggest, size: 18),
                label: Text(AppLocalizations.of(context)!.launchAgentStudio),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AgentConfigScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIModelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(AppLocalizations.of(context)!.aiModelVaultTitle, AppLocalizations.of(context)!.aiModelVaultSub),
        const SizedBox(height: 32),
        Container(
           padding: const EdgeInsets.all(24),
           decoration: BoxDecoration(
             color: Colors.white.withValues(alpha: 0.05),
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
           ),
           child: Column(
             children: [
                _buildKeyField('Gemini Pro / Flash API Key', _geminiController, FontAwesomeIcons.google),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveKeys, child: const Text('Save Keys')))
             ],
           ),
        ),
      ],
    );
  }

  Widget _buildConnectorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(AppLocalizations.of(context)!.toolConnectorsTitle, AppLocalizations.of(context)!.toolConnectorsSub),
        const SizedBox(height: 32),
        _buildConnectorCard('Google Search', FontAwesomeIcons.google, true, 'Active'),
        const SizedBox(height: 16),
        _buildConnectorCard('Gmail', FontAwesomeIcons.envelope, false, 'Coming Soon'),
        const SizedBox(height: 16),
        _buildConnectorCard('Slack', FontAwesomeIcons.slack, false, 'Coming Soon'),
        const SizedBox(height: 16),
        _buildConnectorCard('Notion', FontAwesomeIcons.n, false, 'Coming Soon'),
        const SizedBox(height: 16),
        _buildConnectorCard('Otter.ai', FontAwesomeIcons.earListen, false, 'Coming Soon'),
        const SizedBox(height: 16),
        _buildConnectorCard('HubSpot', FontAwesomeIcons.hubspot, false, 'Coming Soon'),
        const SizedBox(height: 16),
        _buildConnectorCard('GoHighLevel', FontAwesomeIcons.rocket, false, AppLocalizations.of(context)!.comingSoon),
        const SizedBox(height: 16),
        _buildConnectorCard('Google Drive', FontAwesomeIcons.googleDrive, false, AppLocalizations.of(context)!.comingSoon),
      ],
    );
  }

  Widget _buildConnectorCard(String name, IconData icon, bool isConnected, String status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isConnected ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(status, style: TextStyle(color: isConnected ? Colors.greenAccent : Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          Switch(value: isConnected, onChanged: (val) {}, activeThumbColor: Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
         const SizedBox(height: 8),
         Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
       ], 
     );
  }

  Widget _buildLoginPrompt() {
    return Center(child: Text(AppLocalizations.of(context)!.pleaseLoginManage));
  }

  Widget _buildPromptField(String label, TextEditingController controller, IconData icon, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 5,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
            hintText: AppLocalizations.of(context)!.enterAgentInstructions,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
            hintText: AppLocalizations.of(context)!.enterApiKey,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile(User user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                child: Text(user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : '?', 
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isEditingProfile 
                      ? TextField(controller: _displayNameController, style: const TextStyle(color: Colors.white))
                      : Text(user.displayName ?? AppLocalizations.of(context)!.unnamedUser, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user.email ?? '', style: const TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_isEditingProfile ? Icons.check : Icons.edit, color: Colors.blueAccent),
                onPressed: () {
                  if (_isEditingProfile) {
                    _updateProfile();
                  } else {
                    setState(() => _isEditingProfile = true);
                  }
                },
              ),
            ],
          ),
          if (_isEditingProfile) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => setState(() => _isEditingProfile = false),
              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white38)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleAndClientManagement(User user) {
    final appUser = ref.watch(appUserProvider).value;
    final isAdmin = appUser?.role == UserRole.admin || appUser?.role == UserRole.superAdmin;
    if (!isAdmin) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.teamAccessRoles, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1)),
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
              Text(AppLocalizations.of(context)!.systemRole, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: UserRole.values.map((role) {
                  final isSelected = _selectedRole == role;
                  return ChoiceChip(
                    label: Text(role.name.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white)),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent,
                    backgroundColor: Colors.white10,
                    onSelected: (val) {
                      if (val) setState(() => _selectedRole = role);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context)!.assignedClients, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, child) {
                  final clientState = ref.watch(clientProvider);
                  if (clientState.clients.isEmpty) return Text(AppLocalizations.of(context)!.noClientsFound, style: const TextStyle(color: Colors.white24, fontSize: 12));
                  
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: clientState.clients.map((client) {
                      final isSelected = _selectedClientIds.contains(client.id);
                      return FilterChip(
                        label: Text(client.name, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white)),
                        selected: isSelected,
                        selectedColor: Colors.greenAccent,
                        backgroundColor: Colors.white10,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedClientIds.add(client.id);
                            } else {
                              _selectedClientIds.remove(client.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.black),
                  child: Text(AppLocalizations.of(context)!.saveAccessLevels),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RefreshedWebLayout extends StatelessWidget {
  final Widget child;
  const RefreshedWebLayout({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: child));
  }
}
