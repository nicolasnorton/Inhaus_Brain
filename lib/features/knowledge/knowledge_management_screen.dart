import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'widgets/knowledge_library_widget.dart';
import 'screens/quick_create_flow.dart';
import 'screens/pipeline_selection_screen.dart';
import 'screens/retrieval_sandbox_screen.dart';
import 'screens/knowledge_settings_screen.dart';
import 'screens/external_knowledge_screen.dart';
import 'screens/pipeline_orchestrator.dart';
import 'widgets/knowledge_tour_overlay.dart';

class KnowledgeManagementScreen extends ConsumerStatefulWidget {
  const KnowledgeManagementScreen({super.key});

  @override
  ConsumerState<KnowledgeManagementScreen> createState() => _KnowledgeManagementScreenState();
}

class _KnowledgeManagementScreenState extends ConsumerState<KnowledgeManagementScreen> {
  String _currentView = 'overview';
  String? _selectedKB;
  bool _showTour = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0F1116),
          body: Row(
            children: [
              // Sub-sidebar for Knowledge Module
              _selectedKB != null ? _buildKBSubSidebar() : _buildMainSubSidebar(),
              
              const VerticalDivider(width: 1, thickness: 1, color: Colors.white10),
              
              // Content Area
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
        if (_showTour)
          Positioned.fill(
            child: KnowledgeTourOverlay(
              onDismiss: () => setState(() => _showTour = false),
            ),
          ),
      ],
    );
  }

  Widget _buildMainSubSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF161B22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Text(
              AppLocalizations.of(context)!.knowledgeModule,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarSection(AppLocalizations.of(context)!.createKnowledge, [
                  _buildSubSidebarItem(AppLocalizations.of(context)!.quickCreate, 'quick-create', icon: Icons.bolt),
                  _buildSubSidebarItem(AppLocalizations.of(context)!.knowledgePipeline, 'pipeline', icon: Icons.account_tree_outlined),
                  _buildSubSidebarItem(AppLocalizations.of(context)!.authorizeDataSource, 'data-source', icon: Icons.key_outlined),
                ]),
                _buildSidebarSection(AppLocalizations.of(context)!.connectToExternal, [
                  _buildSubSidebarItem(AppLocalizations.of(context)!.externalBase, 'external-base', icon: Icons.cloud_outlined),
                  _buildSubSidebarItem(AppLocalizations.of(context)!.apiReference, 'api', icon: Icons.api_outlined),
                ]),
                _buildSidebarSection(AppLocalizations.of(context)!.manageKnowledge, [
                  _buildSubSidebarItem(AppLocalizations.of(context)!.contentLabel, 'content', icon: Icons.description_outlined),
                  _buildSubSidebarItem(AppLocalizations.of(context)!.navSettings, 'settings', icon: Icons.settings_outlined),
                  _buildSubSidebarItem(AppLocalizations.of(context)!.metadataLabel, 'metadata', icon: Icons.label_important_outline),
                ]),
                _buildSidebarItem(AppLocalizations.of(context)!.testRetrieval, 'test-retrieval', icon: Icons.plumbing_outlined),
                _buildSidebarItem(AppLocalizations.of(context)!.integrateApps, 'integrate', icon: Icons.extension_outlined),
              ],
            ),
          ),
          _buildUsageInfo(),
        ],
      ),
    );
  }

  Widget _buildKBSubSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF161B22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: TextButton.icon(
              onPressed: () => setState(() {
                _selectedKB = null;
                _currentView = 'content';
              }),
              icon: const Icon(Icons.chevron_left, size: 18),
              label: Text(AppLocalizations.of(context)!.backLabel, style: const TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.white38),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.storage, color: Colors.orangeAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedKB ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildKBSidebarItem(AppLocalizations.of(context)!.kbDocuments, 'kb-documents', icon: Icons.description_outlined),
                _buildKBSidebarItem(AppLocalizations.of(context)!.knowledgePipeline, 'kb-pipeline', icon: Icons.account_tree_outlined),
                _buildKBSidebarItem(AppLocalizations.of(context)!.kbRetrievalTest, 'kb-retrieval', icon: Icons.science_outlined),
                _buildKBSidebarItem(AppLocalizations.of(context)!.navSettings, 'kb-settings', icon: Icons.settings_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKBSidebarItem(String title, String viewId, {required IconData icon}) {
    final isSelected = _currentView == viewId;
    return InkWell(
      onTap: () => setState(() => _currentView = viewId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.blueAccent : Colors.white38),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSidebarItem(String title, String viewId, {required IconData icon}) {
    final isSelected = _currentView == viewId;
    return InkWell(
      onTap: () => setState(() => _currentView = viewId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.blueAccent : Colors.white60),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSidebarItem(String title, String viewId, {required IconData icon}) {
    final isSelected = _currentView == viewId || _currentView.startsWith('$viewId-');
    return InkWell(
      onTap: () => setState(() => _currentView = viewId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.blueAccent : Colors.white38),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.knowledgeUsage, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)),
                child: Text(AppLocalizations.of(context)!.kbCloud, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            value: 0.45,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.kbUsedMsg('4.5GB', '10GB'), style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Override content for KB-specific views
    if (_selectedKB != null) {
      switch (_currentView) {
        case 'kb-pipeline':
          return KnowledgePipelineOrchestrator();
        case 'kb-documents':
          return const KnowledgeLibraryWidget();
        case 'kb-retrieval':
          return const RetrievalSandboxScreen();
        case 'kb-settings':
          return const KnowledgeSettingsScreen();
      }
    }

    switch (_currentView) {
      case 'content':
        return KnowledgeLibraryWidget(
          onSelectKB: (kbName) {
            setState(() {
              _selectedKB = kbName;
              _currentView = 'kb-documents';
            });
          },
        );
      case 'quick-create':
        return const QuickCreateFlow();
      case 'pipeline':
        return const PipelineSelectionScreen();
      case 'test-retrieval':
        return const RetrievalSandboxScreen();
      case 'settings':
      case 'metadata':
        return const KnowledgeSettingsScreen();
      case 'external-base':
      case 'api':
        return const ExternalKnowledgeScreen();
      default:
        return _buildPlaceholder(_currentView.toUpperCase().replaceAll('-', ' '));
    }
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_outlined, size: 64, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(color: Colors.white24, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Implementation in progress...',
            style: TextStyle(color: Colors.white12, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
