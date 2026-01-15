import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';

class QuickCreateFlow extends ConsumerStatefulWidget {
  const QuickCreateFlow({super.key});

  @override
  ConsumerState<QuickCreateFlow> createState() => _QuickCreateFlowState();
}

class _QuickCreateFlowState extends ConsumerState<QuickCreateFlow> {
  int _currentStep = 1;
  String? _selectedSourceType;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress Header
        _buildHeader(),
        
        const Divider(height: 1, color: Colors.white10),
        
        // Step Content
        Expanded(
          child: _buildStepContent(),
        ),
        
        // Footer Actions
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {}, // Close flow?
            icon: const Icon(Icons.close, color: Colors.white38),
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.createKnowledge.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
          ),
          const Spacer(),
          _buildStepIndicator(1, AppLocalizations.of(context)!.dataSourceStep, _currentStep >= 1),
          _buildStepConnector(_currentStep > 1),
          _buildStepIndicator(2, AppLocalizations.of(context)!.processingStep, _currentStep >= 2),
          _buildStepConnector(_currentStep > 2),
          _buildStepIndicator(3, AppLocalizations.of(context)!.executeFinishStep, _currentStep >= 3, isBlue: true),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive, {bool isBlue = false}) {
    final color = isActive ? (isBlue ? Colors.blueAccent : Colors.white) : Colors.white24;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBlue && isActive ? Colors.blueAccent : (isActive ? Colors.white38 : Colors.transparent),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(color: isBlue && isActive ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 40,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: isActive ? Colors.blueAccent : Colors.white10,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildDataSourceStep();
      case 2:
        return _buildProcessingStep();
      case 3:
        return _buildFinishStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDataSourceStep() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.selectDataSource,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.dataSourceChangeWarning,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildSourceCard(AppLocalizations.of(context)!.importFromFile, 'local-file', FontAwesomeIcons.fileLines, Colors.orangeAccent),
              const SizedBox(width: 16),
              _buildSourceCard(AppLocalizations.of(context)!.syncFromNotion, 'notion', FontAwesomeIcons.notion, Colors.black),
              const SizedBox(width: 16),
              _buildSourceCard(AppLocalizations.of(context)!.syncFromWebsite, 'website', FontAwesomeIcons.globe, Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(String title, String type, IconData icon, Color color) {
    final isSelected = _selectedSourceType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSourceType = type),
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 32, color: color == Colors.black ? Colors.white : color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.chunkSettings,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.chunkSettingsSub,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Settings Panel
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(AppLocalizations.of(context)!.chunkingMode),
                    Row(
                      children: [
                        _buildChoiceChip(AppLocalizations.of(context)!.automatic, true),
                        const SizedBox(width: 8),
                        _buildChoiceChip(AppLocalizations.of(context)!.custom, false),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader(AppLocalizations.of(context)!.chunkingRules),
                    _buildSettingField(AppLocalizations.of(context)!.separator, '\\n'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildSettingField(AppLocalizations.of(context)!.maxChunkLength, '500')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSettingField(AppLocalizations.of(context)!.chunkOverlap, '50')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader(AppLocalizations.of(context)!.cleaningRules),
                    _buildToggleRow(AppLocalizations.of(context)!.cleanSpacesRule, true),
                    _buildToggleRow(AppLocalizations.of(context)!.cleanUrlsRule, false),
                  ],
                ),
              ),
              
              const SizedBox(width: 48),
              
              // Preview Panel
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.chunksPreview, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(AppLocalizations.of(context)!.chunksIdentified(12), style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.7), fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildChunkPreviewItem(1, 'Introducing Hybrid Search and Rerank to Improve the Retrieval Accuracy of the RAG System. Hybrid search combines full-text search and vector search...'),
                      const SizedBox(height: 12),
                      _buildChunkPreviewItem(2, 'The basic idea of hybrid search is to leverage the strengths of both keyword matching and semantic understanding. While vector search is great...'),
                      const SizedBox(height: 12),
                      _buildChunkPreviewItem(3, 'Wait for the data processing to complete. Once finished, your knowledge base will be ready for integration into your AI applications...'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
      ),
      child: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white38, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSettingField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              onChanged: (_) {},
              activeThumbColor: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChunkPreviewItem(int index, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                child: Text('#$index', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              const Text('245 tokens', style: TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFinishStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.indexRetrievalTitle,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.indexRetrievalSub,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indexing Method Area
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(AppLocalizations.of(context)!.indexMethod),
                    _buildIndexMethodCard(
                      AppLocalizations.of(context)!.highQuality,
                      AppLocalizations.of(context)!.highQualitySub,
                      true,
                    ),
                    const SizedBox(height: 12),
                    _buildIndexMethodCard(
                      AppLocalizations.of(context)!.economical,
                      AppLocalizations.of(context)!.economicalSub,
                      false,
                    ),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader(AppLocalizations.of(context)!.embeddingModel),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology, size: 18, color: Colors.blueAccent),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('text-embedding-3-large', style: TextStyle(color: Colors.white, fontSize: 13))),
                          const Icon(Icons.arrow_drop_down, color: Colors.white38),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 48),

              // Retrieval Settings Area
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(AppLocalizations.of(context)!.retrievalSettings),
                    _buildChoiceChipGroup(['Vector Search', 'Full-Text Search', 'Hybrid Search'], 'Hybrid Search'),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader(AppLocalizations.of(context)!.rerankSettings),
                    _buildToggleRow(AppLocalizations.of(context)!.rerankModel, true),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.layers_outlined, size: 18, color: Colors.purpleAccent),
                          SizedBox(width: 12),
                          Expanded(child: Text('rerank-english-v3.0', style: TextStyle(color: Colors.white, fontSize: 13))),
                          Icon(Icons.arrow_drop_down, color: Colors.white38),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildSettingField(AppLocalizations.of(context)!.topK, '3')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSettingField(AppLocalizations.of(context)!.scoreThreshold, '0.5')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndexMethodCard(String title, String subtitle, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: isSelected ? Colors.blueAccent : Colors.white38),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChipGroup(List<String> options, String selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) => _buildChoiceChip(opt, opt == selected)).toList(),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentStep > 1)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              child: Text(AppLocalizations.of(context)!.backLabel),
            ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _selectedSourceType == null ? null : () {
               if (_currentStep < 3) setState(() => _currentStep++);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(_currentStep == 3 ? AppLocalizations.of(context)!.finishLabel : AppLocalizations.of(context)!.nextLabel),
          ),
        ],
      ),
    );
  }
}
