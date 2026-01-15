import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';

class KnowledgeSettingsScreen extends ConsumerStatefulWidget {
  const KnowledgeSettingsScreen({super.key});

  @override
  ConsumerState<KnowledgeSettingsScreen> createState() => _KnowledgeSettingsScreenState();
}

class _KnowledgeSettingsScreenState extends ConsumerState<KnowledgeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.knowledgeSettings,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.knowledgeSettingsSub,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 48),
          
          _buildSettingsSection(
            AppLocalizations.of(context)!.basicInfo,
            [
              _buildSettingItem(AppLocalizations.of(context)!.knowledgeNameLabel, 'Inhaus Corporate Knowledge Base'),
              _buildSettingItem(AppLocalizations.of(context)!.descriptionLabel, 'Internal documentation, brand guidelines, and case studies.'),
            ],
          ),
          
          const SizedBox(height: 48),
          _buildSettingsSection(
            AppLocalizations.of(context)!.indexRetrievalTitle.toUpperCase(),
            [
              _buildSettingDropdown(AppLocalizations.of(context)!.embeddingModel.toLowerCase().replaceFirst(AppLocalizations.of(context)!.embeddingModel[0].toLowerCase(), AppLocalizations.of(context)!.embeddingModel[0].toUpperCase()), 'text-embedding-3-large', Icons.psychology), // Manual capitalization if needed or just use key
              _buildSettingDropdown(AppLocalizations.of(context)!.rerankModel, 'rerank-english-v3.0', Icons.layers),
              _buildSettingToggle(AppLocalizations.of(context)!.enableHybridSearch, true),
              _buildSettingSlider(AppLocalizations.of(context)!.topK, 3, 1, 10),
            ],
          ),
          
          const SizedBox(height: 48),
          _buildSettingsSection(
            AppLocalizations.of(context)!.metadataConfig,
            [
              _buildSettingToggle(AppLocalizations.of(context)!.autoExtractAuthor, true),
              _buildSettingToggle(AppLocalizations.of(context)!.autoExtractDate, true),
              _buildSettingToggle(AppLocalizations.of(context)!.indexTablesAsText, false),
            ],
          ),
          
          const SizedBox(height: 48),
          _buildSettingsSection(
            AppLocalizations.of(context)!.dangerZone,
            [
              _buildDangerItem(AppLocalizations.of(context)!.deleteKnowledgeBase, AppLocalizations.of(context)!.deleteKnowledgeBaseSub),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.edit_outlined, size: 16, color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildSettingDropdown(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(icon, size: 16, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.white24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(String label, bool value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13))),
          Transform.scale(
            scale: 0.8,
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

  Widget _buildSettingSlider(String label, double value, double min, double max) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: (max - min).toInt(),
                    activeColor: Colors.blueAccent,
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 12),
                Text(value.toInt().toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerItem(String label, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 0.5),
              foregroundColor: Colors.redAccent,
            ),
            child: Text(AppLocalizations.of(context)!.deleteLabel),
          ),
        ],
      ),
    );
  }
}
