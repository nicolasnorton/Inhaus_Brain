import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          const Text(
            'Connect to External Knowledge Base',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Integrate with external knowledge bases through API services or official plugins.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
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
              tabs: const [
                Tab(text: 'API Connections'),
                Tab(text: 'Plugin Marketplace'),
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
            const Expanded(
              child: Text(
                'Configure custom API endpoints to connect to your self-hosted or third-party knowledge bases.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
            const SizedBox(width: 24),
            ElevatedButton.icon(
              onPressed: _showAddAPIDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add API Connection'),
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
          child: ListView(
            children: [
              if (connections.isEmpty)
                _buildEmptyConnectionsState()
              else
                ...connections.map((conn) => Column(
                  children: [
                    _buildAPIConnectionItem(conn),
                    const SizedBox(height: 16),
                  ],
                )),
              
              const SizedBox(height: 24),
              if (connections.isNotEmpty) _buildRetrievalSandbox(),
            ],
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
          const Text(
            'Retrieval Sandbox',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Test your retrieval settings and view raw chunks returned by the API.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Connection', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                          hint: const Text('Choose a connection', style: TextStyle(color: Colors.white24, fontSize: 14)),
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
                    const Text('Query', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'Enter search query...',
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
                  child: const Text('Search'),
                ),
              ),
            ],
          ),
          
          if (results != null) ...[
            const SizedBox(height: 32),
            const Text(
              'Retrieval Results',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
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
                          'Score: ${record.score.toStringAsFixed(3)}',
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
          const Text(
            'No connections configured',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showAddAPIDialog,
            child: const Text('Add your first connection'),
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
        const Text(
          'Official plugins provide seamless integration with popular knowledge base services.',
          style: TextStyle(color: Colors.white38, fontSize: 13),
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
                  Text('Last sync: $lastSyncText', style: const TextStyle(color: Colors.white24, fontSize: 11)),
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
            tooltip: 'Test Connection',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.white38, size: 18),
            tooltip: 'Configure',
          ),
          IconButton(
            onPressed: () => ref.read(externalConnectionsProvider.notifier).removeConnection(connection.id),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
            tooltip: 'Remove',
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
        return 'Active';
      case ConnectionStatus.error:
        return 'Error';
      case ConnectionStatus.pending:
        return 'Testing...';
      default:
        return 'Disconnected';
    }
  }

  String? _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return null;
    final diff = DateTime.now().difference(lastSync);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _testConnection(String id) async {
    final success = await ref.read(externalConnectionsProvider.notifier).testConnection(ref, id);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Connection successful!' : 'Connection failed. Check your settings.'),
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
                  child: const Text('INSTALLED', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
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
              child: Text(isInstalled ? 'Configure' : 'Install', style: const TextStyle(fontSize: 12)),
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
              const Text('Add API Connection', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildDialogField('Connection Name', 'e.g., My Knowledge Base', controller: _nameController),
              const SizedBox(height: 16),
              _buildDialogField('API Endpoint', 'https://api.example.com/v1/retrieve', controller: _endpointController),
              const SizedBox(height: 16),
              _buildDialogField('Knowledge ID (Optional)', 'Internal reference ID', controller: _knowledgeIdController),
              const SizedBox(height: 16),
              _buildDialogField('API Key', 'sk-...', isPassword: true, controller: _apiKeyController),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blueAccent, size: 16),
                        SizedBox(width: 8),
                        Text('API Requirements', style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your API must accept POST requests with a query parameter and return results in JSON format with text content.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
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
                    child: const Text('Test & Save'),
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
              const Row(
                children: [
                  Icon(Icons.extension, color: Colors.blueAccent, size: 24),
                  SizedBox(width: 12),
                  Text('Configure LlamaCloud', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              _buildDialogField('LlamaCloud API Key', 'llx-...', isPassword: true),
              const SizedBox(height: 16),
              _buildDialogField('Pipeline ID', 'Optional: Specify a pipeline ID'),
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
                          const Text('Need an API key?', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              'Visit cloud.llamaindex.ai to create one',
                              style: TextStyle(color: Colors.blueAccent, fontSize: 11, decoration: TextDecoration.underline),
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
                    child: const Text('Save Configuration'),
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
