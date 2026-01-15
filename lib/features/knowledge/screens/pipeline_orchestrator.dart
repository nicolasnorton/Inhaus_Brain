import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class KnowledgePipelineOrchestrator extends ConsumerStatefulWidget {
  const KnowledgePipelineOrchestrator({super.key});

  @override
  ConsumerState<KnowledgePipelineOrchestrator> createState() => _KnowledgePipelineOrchestratorState();
}

class _KnowledgePipelineOrchestratorState extends ConsumerState<KnowledgePipelineOrchestrator> {
  final double _zoomLevel = 1.0;
  final bool _isPublished = false;
  String? _selectedNode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      body: Stack(
        children: [
          // Main Canvas
          _buildCanvas(),
          
          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // Left Floating Toolbar
          Positioned(
            left: 16,
            top: MediaQuery.of(context).size.height * 0.3,
            child: _buildFloatingLeftToolbar(),
          ),

          // Bottom Variable Inspect
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildVariableInspectFooter(),
          ),

          // Zoom Controls (Bottom Right)
          Positioned(
            bottom: 40,
            right: _selectedNode != null ? 336 : 16,
            child: _buildZoomControls(),
          ),

          // Properties Panel (Right)
          if (_selectedNode != null)
            Positioned(
              top: 56,
              right: 0,
              bottom: 32,
              child: _buildPropertiesPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1116).withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Text(
            'Auto-Saved 23:36:38 - ${_isPublished ? 'Published' : 'Unpublished'}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const Spacer(),
          _buildTopBarButton('Input Field', Icons.input_outlined),
          const SizedBox(width: 8),
          _buildTopBarIcon(Icons.history_outlined),
          const SizedBox(width: 12),
          _buildTopBarButton('Test Run', Icons.play_arrow_outlined, color: Colors.blueAccent),
          const SizedBox(width: 8),
          _buildTopBarIcon(Icons.checklist_outlined),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _showPublishDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Publish', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          _buildTopBarIcon(Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _buildTopBarButton(String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          if (color != null) Icon(icon, size: 16, color: color) else Icon(icon, size: 16, color: Colors.white60),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTopBarIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Icon(icon, size: 18, color: Colors.white60),
    );
  }

  Widget _buildFloatingLeftToolbar() {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolbarTool(Icons.add, active: false),
          const Divider(color: Colors.white10, height: 16),
          _buildToolbarTool(Icons.near_me_outlined, active: false),
          _buildToolbarTool(Icons.pan_tool_outlined, active: true),
          _buildToolbarTool(Icons.grid_view_outlined, active: false),
          _buildToolbarTool(Icons.layers_outlined, active: false),
          _buildToolbarTool(Icons.image_outlined, active: false),
        ],
      ),
    );
  }

  Widget _buildToolbarTool(IconData icon, {bool active = false}) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 18, color: active ? Colors.blueAccent : Colors.white60),
    );
  }

  Widget _buildVariableInspectFooter() {
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Center(
        child: Text(
          'VARIABLE INSPECT',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildZoomIcon(Icons.search_outlined),
          const SizedBox(width: 8),
          Text(
            '${(_zoomLevel * 100).toInt()}%',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(width: 8),
          _buildZoomIcon(Icons.unfold_more_outlined),
        ],
      ),
    );
  }

  Widget _buildZoomIcon(IconData icon) {
    return Icon(icon, size: 14, color: Colors.white38);
  }

  Widget _buildPropertiesPanel() {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(left: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedNode ?? 'Node Settings',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedNode = null),
                  icon: const Icon(Icons.close, size: 20, color: Colors.white38),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_selectedNode == 'DATA SOURCE') ...[
                  const Text('SOURCE SETTINGS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildPropertyLabel('Data Source Type'),
                  _buildPropertyDropdown('File Upload'),
                  const SizedBox(height: 24),
                  _buildPropertyLabel('Authorization'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Not Authorized', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Connect'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_selectedNode == 'IF/ELSE') ...[
                  const Text('LOGIC SETTINGS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildConditionEditor(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    );
  }

  Widget _buildPropertyDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const Icon(Icons.expand_more, color: Colors.white38, size: 18),
        ],
      ),
    );
  }

  Widget _buildConditionEditor() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: const Column(
            children: [
              Row(
                children: [
                  Text('Variable', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Spacer(),
                  Text('Operator', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Spacer(),
                  Text('Value', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              Divider(color: Colors.white10),
              // Mock items
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Condition'),
          style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
        ),
      ],
    );
  }

  void _showPublishDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C2128),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Publish',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Important reminder: Once published, the chunk structure cannot be modified.',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'This will publish the knowledge pipeline to make it available for document ingestion.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
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
                      Navigator.pop(context);
                      _showPublishSuccess();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Confirm & Publish'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPublishSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F1116),
        insetPadding: const EdgeInsets.all(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Publish Complete',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your knowledge pipeline has been successfully published.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: _buildSuccessOption(
                      'Go to add documents',
                      'Jump to the data source selection to upload documents.',
                      Icons.add_box_outlined,
                      Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildSuccessOption(
                      'Access API Reference',
                      'Get API calling methods and instructions.',
                      Icons.api_outlined,
                      Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSuccessOption(
                'Publish as a Knowledge Pipeline',
                'Save it as a reusable template for future use.',
                Icons.account_tree_outlined,
                Colors.purpleAccent,
                fullWidth: true,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOption(String title, String desc, IconData icon, Color color, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Stack(
      children: [
        // Grid Background
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(),
          ),
        ),
        
        // Nodes Container
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: SizedBox(
              width: 2500,
              height: 1500,
              child: Stack(
                children: [
                  // Connections (Background Layer)
                  CustomPaint(
                    size: const Size(2500, 1500),
                    painter: ConnectorPainter(),
                  ),

                  // Annotations
                  Positioned(
                    left: 400,
                    top: 200,
                    child: _buildNoteNode(
                      'A Knowledge Pipeline starts with Data Source as the starting node and ends with the knowledge base node. The general steps are: import documents from the data source -> use extractor to extract document content -> split and clean content into structured chunks -> store in the knowledge base.',
                      width: 400,
                    ),
                  ),
                  Positioned(
                    left: 140,
                    top: 450,
                    child: _buildNoteNode(
                      'Currently we support 5 types of Data Sources: File Upload, Text Input, Online Drive, Online Doc, and Web Crawler. Different types of Data Sources have different input and output types. The output of File Upload and Online Drive are files, while the output of Online Doc and WebCrawler are pages.',
                      width: 320,
                    ),
                  ),

                  // Data Source Node
                  Positioned(
                    left: 500,
                    top: 450,
                    child: InkWell(
                      onTap: () => setState(() => _selectedNode = 'DATA SOURCE'),
                      child: _buildDataSourceNode(),
                    ),
                  ),

                  // IF/ELSE Node
                  Positioned(
                    left: 720,
                    top: 440,
                    child: InkWell(
                      onTap: () => setState(() => _selectedNode = 'IF/ELSE'),
                      child: _buildIfElseNode(),
                    ),
                  ),

                  // Extractor Nodes
                  Positioned(
                    left: 980,
                    top: 420,
                    child: InkWell(
                      onTap: () => setState(() => _selectedNode = 'INHAUS EXTRACTOR'),
                      child: _buildProcessNode('INHAUS EXTRACTOR', Colors.greenAccent),
                    ),
                  ),
                  Positioned(
                    left: 980,
                    top: 520,
                    child: InkWell(
                      onTap: () => setState(() => _selectedNode = 'DOC EXTRACTOR'),
                      child: _buildProcessNode('DOC EXTRACTOR', Colors.blueAccent, showVariable: true),
                    ),
                  ),

                  // Chunker Node
                  Positioned(
                    left: 1250,
                    top: 480,
                    child: InkWell(
                      onTap: () => setState(() => _selectedNode = 'GENERAL CHUNKER'),
                      child: _buildProcessNode('GENERAL CHUNKER', Colors.purpleAccent, isChunker: true),
                    ),
                  ),

                  // Knowledge Base (Target) Node
                  Positioned(
                    left: 1520,
                    top: 460,
                    child: InkWell(
                      onTap: () => setState(() => _selectedNode = 'KNOWLEDGE BASE'),
                      child: _buildKnowledgeBaseNode(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteNode(String text, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.05),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
      ),
    );
  }

  Widget _buildDataSourceNode() {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DATA SOURCE', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('+ Add data source', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          _buildNodeItem('FILE UPLOAD', FontAwesomeIcons.fileLines),
          _buildNodeItem('NOTION', FontAwesomeIcons.notion),
          _buildNodeItem('FIRECAWL', FontAwesomeIcons.fire),
          _buildNodeItem('JINA READER', Icons.auto_awesome),
        ],
      ),
    );
  }

  Widget _buildIfElseNode() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildNodeHeader('IF/ELSE', Colors.blueAccent),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildConditionRow('File Up...', 'is type', '.xls'),
                _buildConditionRow('File Up...', 'is type', '.xlsx'),
                _buildConditionRow('File Up...', 'is type', '.md'),
                _buildConditionRow('File Up...', 'is type', '.txt'),
                _buildConditionRow('File Up...', 'is docx', '.docx'),
                _buildConditionRow('File Up...', 'is csv', '.csv'),
                _buildConditionRow('Jina Re...', 'is content', 'URL'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionRow(String label, String op, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9))),
          Text(op, style: const TextStyle(color: Colors.blueAccent, fontSize: 9)),
          const SizedBox(width: 6),
          Text(val, style: const TextStyle(color: Colors.white70, fontSize: 9)),
          const SizedBox(width: 8),
          const Text('IF', style: TextStyle(color: Colors.white30, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildProcessNode(String title, Color color, {bool showVariable = false, bool isChunker = false}) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildNodeHeader(title, color),
          if (showVariable)
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INPUT VARIABLE', style: TextStyle(color: Colors.white38, fontSize: 8)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: Colors.blueAccent),
                        SizedBox(width: 4),
                        Text('File Up...', style: TextStyle(color: Colors.white70, fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (isChunker)
             Container(
              padding: const EdgeInsets.all(12),
              child: const Text(
                'General Mode divides content into chunks and retrieves the most relevant ones based on the user\'s query...',
                style: TextStyle(color: Colors.white38, fontSize: 9, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeBaseNode() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildNodeHeader('KNOWLEDGE BASE', Colors.orangeAccent, icon: Icons.storage),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('INDEX METHOD', 'Economical'),
                const SizedBox(height: 8),
                _buildInfoRow('RETRIEVAL SETTING', ''),
                const SizedBox(height: 12),
                const Text(
                  'The knowledge base provides two indexing methods: High-Quality and Economical...',
                  style: TextStyle(color: Colors.white24, fontSize: 9, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeHeader(String title, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 14, color: color)
          else Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNodeItem(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white38),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const Spacer(),
          const Icon(Icons.circle, size: 6, color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8)),
        if (value.isNotEmpty)
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Example connections based on the layout
    _drawCurvedLine(path, const Offset(680, 520), const Offset(720, 550)); // DS -> IF/ELSE
    _drawCurvedLine(path, const Offset(940, 520), const Offset(980, 480)); // IF/ELSE -> Inhaus Ext
    _drawCurvedLine(path, const Offset(940, 580), const Offset(980, 580)); // IF/ELSE -> Doc Ext

    canvas.drawPath(path, paint);
  }

  void _drawCurvedLine(Path path, Offset start, Offset end) {
    final controlPoint1 = Offset(start.dx + (end.dx - start.dx) / 2, start.dy);
    final controlPoint2 = Offset(start.dx + (end.dx - start.dx) / 2, end.dy);
    path.moveTo(start.dx, start.dy);
    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, end.dx, end.dy);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
