import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import '../models/external_knowledge_models.dart';
import '../providers/external_knowledge_provider.dart';

class ExternalKnowledgeScreen extends ConsumerStatefulWidget {
  const ExternalKnowledgeScreen({super.key});

  @override
  ConsumerState<ExternalKnowledgeScreen> createState() => _ExternalKnowledgeScreenState();
}

class _ExternalKnowledgeScreenState extends ConsumerState<ExternalKnowledgeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _knowledgeIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    _nameController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    _knowledgeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.externalKnowledgeTitle,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.externalKnowledgeSub,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: AppLocalizations.of(context)!.apiConnections),
                Tab(text: AppLocalizations.of(context)!.pluginMarketplace),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAPIConnectionsTab(),
                _buildPluginMarketplaceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAPIConnectionsTab() {
    final connections = ref.watch(externalConnectionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.apiConnectionsSub,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
            const SizedBox(width: 24),
            ElevatedButton.icon(
              onPressed: _showAddAPIDialog,
              icon: const Icon(Icons.add, size: 16),
              label: Text(AppLocalizations.of(context)!.addApiConnection),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        Expanded(
          child: connections.isEmpty
              ? _buildEmptyConnectionsState()
              : ListView.builder(
                  itemCount: connections.length + (connections.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < connections.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildAPIConnectionItem(connections[index]),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        child: _buildRetrievalSandbox(),
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRetrievalSandbox() {
    final selectedConnId = ref.watch(selectedConnectionProvider);
    final results = ref.watch(queryResultsProvider);
    final connections = ref.watch(externalConnectionsProvider);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.retrievalSandbox,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.retrievalSandboxSub,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.selectConnection, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedConnId,
                          hint: Text(AppLocalizations.of(context)!.chooseConnectionHint, style: const TextStyle(color: Colors.white24, fontSize: 14)),
                          dropdownColor: const Color(0xFF1C2128),
                          isExpanded: true,
                          items: connections.map((conn) => DropdownMenuItem(
                            value: conn.id,
                            child: Text(conn.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          )).toList(),
                          onChanged: (val) => ref.read(selectedConnectionProvider.notifier).state = val,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.queryLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchQueryHint,
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed: (selectedConnId != null && _queryController.text.isNotEmpty)
                      ? () => ref.read(externalConnectionsProvider.notifier).queryKnowledge(ref, selectedConnId, _queryController.text)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                  child: Text(AppLocalizations.of(context)!.searchLabel),
                ),
              ),
            ],
          ),
          
          if (results != null) ...[
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.retrievalResults,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...results.records.map((record) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.01),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.scoreLabel(record.score.toStringAsFixed(3)),
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.content,
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (record.metadata?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: record.metadata!.entries.map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${e.key}: ${e.value}', style: const TextStyle(color: Colors.white24, fontSize: 9)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyConnectionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.api_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noConnectionsConfigured,
            style: const TextStyle(color: Colors.white38, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showAddAPIDialog,
            child: Text(AppLocalizations.of(context)!.addFirstConnection),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginMarketplaceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.externalKnowledgeSub, // Reusing key for marketplace sub
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(height: 32),
        
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 2.5,
            children: [
              _buildPluginCard(
                'LlamaCloud',
                'Official LlamaIndex cloud service integration',
                'llamaindex.png',
                isInstalled: true,
              ),
              _buildPluginCard(
                'Pinecone',
                'Vector database for semantic search',
                'pinecone.png',
                isInstalled: false,
              ),
              _buildPluginCard(
                'Weaviate',
                'Open-source vector search engine',
                'weaviate.png',
                isInstalled: false,
              ),
              _buildPluginCard(
                'Qdrant',
                'High-performance vector similarity search',
                'qdrant.png',
                isInstalled: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAPIConnectionItem(ExternalConnection connection) {
    final statusColor = _getStatusColor(connection.status);
    final statusText = _getStatusText(connection.status);
    final lastSyncText = _formatLastSync(connection.lastSync);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.api, color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(connection.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(connection.endpoint, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                if (lastSyncText != null) ...[
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)!.lastSyncLabel(lastSyncText), style: const TextStyle(color: Colors.white24, fontSize: 11)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.5),
            ),
            child: connection.status == ConnectionStatus.pending
                ? const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                  )
                : Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => _testConnection(connection.id),
            icon: const Icon(Icons.refresh, color: Colors.white38, size: 18),
            tooltip: AppLocalizations.of(context)!.testingStatus.replaceAll('...', ''),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.white38, size: 18),
            tooltip: AppLocalizations.of(context)!.configureLabel,
          ),
          IconButton(
            onPressed: () => ref.read(externalConnectionsProvider.notifier).removeConnection(connection.id),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
            tooltip: AppLocalizations.of(context)!.deleteLabel,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.active:
        return Colors.greenAccent;
      case ConnectionStatus.error:
        return Colors.redAccent;
      case ConnectionStatus.pending:
        return Colors.blueAccent;
      default:
        return Colors.white38;
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.active:
        return AppLocalizations.of(context)!.statusActive;
      case ConnectionStatus.error:
        return AppLocalizations.of(context)!.statusError;
      case ConnectionStatus.pending:
        return AppLocalizations.of(context)!.testingStatus;
      default:
        return AppLocalizations.of(context)!.disconnectedStatus;
    }
  }

  String? _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return null;
    final diff = DateTime.now().difference(lastSync);
    if (diff.inMinutes < 1) return AppLocalizations.of(context)!.justNow;
    if (diff.inMinutes < 60) return AppLocalizations.of(context)!.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return AppLocalizations.of(context)!.hoursAgo(diff.inHours);
    return AppLocalizations.of(context)!.daysAgo(diff.inDays);
  }

  Future<void> _testConnection(String id) async {
    final success = await ref.read(externalConnectionsProvider.notifier).testConnection(ref, id);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? AppLocalizations.of(context)!.connectionSuccessful : AppLocalizations.of(context)!.connectionFailed),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildPluginCard(String name, String description, String iconPath, {bool isInstalled = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isInstalled ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.extension, color: Colors.blueAccent, size: 20),
              ),
              const Spacer(),
              if (isInstalled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(AppLocalizations.of(context)!.installedLabel, style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isInstalled ? _showPluginConfigDialog : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isInstalled ? Colors.white.withValues(alpha: 0.05) : Colors.blueAccent,
                foregroundColor: isInstalled ? Colors.white70 : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isInstalled ? AppLocalizations.of(context)!.configureLabel : AppLocalizations.of(context)!.installLabel, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAPIDialog() {
    _nameController.clear();
    _endpointController.clear();
    _apiKeyController.clear();
    _knowledgeIdController.clear();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C2128),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.addApiConnection, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildDialogField(AppLocalizations.of(context)!.connectionNameLabel, AppLocalizations.of(context)!.connectionNameHint, controller: _nameController),
              const SizedBox(height: 16),
              _buildDialogField(AppLocalizations.of(context)!.apiEndpointLabel, 'https://api.example.com/v1/retrieve', controller: _endpointController),
              const SizedBox(height: 16),
              _buildDialogField(AppLocalizations.of(context)!.knowledgeIdOptional, AppLocalizations.of(context)!.internalRefId, controller: _knowledgeIdController),
              const SizedBox(height: 16),
              _buildDialogField(AppLocalizations.of(context)!.apiKeyLabel, 'sk-...', isPassword: true, controller: _apiKeyController),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.apiRequirements, style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.apiRequirementsSub,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.isEmpty || _endpointController.text.isEmpty) {
                        return;
                      }
                      
                      final conn = ref.read(externalConnectionsProvider.notifier).createCustomConnection(
                        name: _nameController.text,
                        endpoint: _endpointController.text,
                        apiKey: _apiKeyController.text,
                        knowledgeId: _knowledgeIdController.text,
                      );
                      
                      ref.read(externalConnectionsProvider.notifier).addConnection(conn);
                      Navigator.pop(context);
                      _testConnection(conn.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(AppLocalizations.of(context)!.testSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPluginConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C2128),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.extension, color: Colors.blueAccent, size: 24),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.configurePlugin('LlamaCloud'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              _buildDialogField(AppLocalizations.of(context)!.apiKeyLabel, 'llx-...', isPassword: true),
              const SizedBox(height: 16),
              _buildDialogField('Pipeline ID', AppLocalizations.of(context)!.apiKeyOptionalHint('pipeline ID')),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.needApiKey, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              AppLocalizations.of(context)!.visitPluginHub('cloud.llamaindex.ai'),
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 11, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(AppLocalizations.of(context)!.saveConfiguration),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, String hint, {bool isPassword = false, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
