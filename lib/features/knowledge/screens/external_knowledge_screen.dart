import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExternalKnowledgeScreen extends ConsumerStatefulWidget {
  const ExternalKnowledgeScreen({super.key});

  @override
  ConsumerState<ExternalKnowledgeScreen> createState() => _ExternalKnowledgeScreenState();
}

class _ExternalKnowledgeScreenState extends ConsumerState<ExternalKnowledgeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
              _buildAPIConnectionItem(
                'Enterprise SharePoint API',
                'https://sharepoint.corp.example.com/v1',
                'Active',
                Colors.greenAccent,
                lastSync: '2 hours ago',
              ),
              const SizedBox(height: 16),
              _buildAPIConnectionItem(
                'AWS Bedrock Knowledge Base',
                'https://bedrock-runtime.us-east-1.amazonaws.com',
                'Active',
                Colors.greenAccent,
                lastSync: '5 minutes ago',
              ),
              const SizedBox(height: 16),
              _buildAPIConnectionItem(
                'Legacy Internal Wiki',
                'https://wiki.internal.example.com/api/v2',
                'Error',
                Colors.redAccent,
                lastSync: 'Failed',
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildAPIConnectionItem(String name, String url, String status, Color statusColor, {String? lastSync}) {
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
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(url, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                if (lastSync != null) ...[
                  const SizedBox(height: 4),
                  Text('Last sync: $lastSync', style: const TextStyle(color: Colors.white24, fontSize: 11)),
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
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.refresh, color: Colors.white38, size: 18),
            tooltip: 'Test Connection',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.white38, size: 18),
            tooltip: 'Configure',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
            tooltip: 'Remove',
          ),
        ],
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
              _buildDialogField('Connection Name', 'e.g., My Knowledge Base'),
              const SizedBox(height: 16),
              _buildDialogField('API Endpoint', 'https://api.example.com/v1/retrieve'),
              const SizedBox(height: 16),
              _buildDialogField('API Key', 'sk-...', isPassword: true),
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
                    onPressed: () => Navigator.pop(context),
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

  Widget _buildDialogField(String label, String hint, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
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
