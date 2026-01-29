import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pipeline_template.dart';
import 'pipeline_orchestrator.dart';

class PipelineSelectionScreen extends ConsumerStatefulWidget {
  const PipelineSelectionScreen({super.key});

  @override
  ConsumerState<PipelineSelectionScreen> createState() => _PipelineSelectionScreenState();
}

class _PipelineSelectionScreenState extends ConsumerState<PipelineSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGrid([
                    _buildBlankCard(),
                    ...PipelineTemplate.builtInTemplates.map((t) => _buildTemplateCard(t)),
                  ]),
                  const SizedBox(height: 48),
                  _buildSectionHeader('CUSTOMIZED'),
                  _buildGrid([
                    _buildCustomTemplateCard('Financial Report Assistant', 'Analyzes financial statements, quarterly reports, and market data.'),
                    _buildCustomTemplateCard('Language Learning Hub', 'Comprehensive language learning resource containing grammar guides.'),
                    _buildCustomTemplateCard('Customer Support Chatbot', 'Instant help desk powered by product documentation.'),
                  ]),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_back, color: Colors.white60),
          ),
          const SizedBox(width: 8),
          const Text(
            'Blank Knowledge Pipeline',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: children,
    );
  }

  Widget _buildBlankCard() {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const KnowledgePipelineOrchestrator()));
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white60, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Blank knowledge pipeline',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Create a custom pipeline from scratch with full control over data processing and structure.',
              style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(PipelineTemplate template) {
    return InkWell(
      onTap: () => _showTemplateDetails(template),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: template.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(template.icon, color: template.color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        template.tags.first,
                        style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              template.description,
              style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTemplateCard(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description, color: Colors.orangeAccent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Text(
                      'GENERAL',
                      style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: const Text('Import from a DSL File'),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _showTemplateDetails(PipelineTemplate template) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 1000,
          height: 700,
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              // Visual Structure Preview
              Expanded(
                child: Container(
                  color: const Color(0xFF0F1116),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_tree_outlined, size: 64, color: Colors.white10),
                        const SizedBox(height: 16),
                        const Text('Visual Pipeline Preview', style: TextStyle(color: Colors.white24)),
                        const SizedBox(height: 24),
                        // Mock node flow
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMockNode('Source', Icons.source),
                            _buildMockConnector(),
                            _buildMockNode('Process', Icons.settings),
                            _buildMockConnector(),
                            _buildMockNode('Store', Icons.storage),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              
              const VerticalDivider(width: 1, color: Colors.white10),
              
              // Details Panel
              Container(
                width: 350,
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: template.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(template.icon, color: template.color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(template.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              const Text('BY INHAUS', style: TextStyle(color: Colors.white24, fontSize: 10)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white38)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(template.description, style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const KnowledgePipelineOrchestrator()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleType.rounded(12),
                      ),
                      child: const Text('Use this Knowledge Pipeline'),
                    ),
                    const SizedBox(height: 48),
                    const Text('STRUCTURE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildStructureItem(template.chunkStructure.name.toUpperCase(), 'Chunking mode used in this pipeline'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockNode(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMockConnector() {
    return Container(width: 20, height: 1, color: Colors.white10);
  }

  Widget _buildStructureItem(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.list_alt, size: 16, color: Colors.blueAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

extension RoundedRectangleType on RoundedRectangleBorder {
  static RoundedRectangleBorder rounded(double radius) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
}
