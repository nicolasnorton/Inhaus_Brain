import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          const Text(
            'Knowledge Settings',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your knowledge base configuration, metadata, and indexing settings.',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 48),
          
          _buildSettingsSection(
            'BASIC INFORMATION',
            [
              _buildSettingItem('Knowledge Name', 'Inhaus Corporate Knowledge Base'),
              _buildSettingItem('Description', 'Internal documentation, brand guidelines, and case studies.'),
            ],
          ),
          
          const SizedBox(height: 48),
          _buildSettingsSection(
            'INDEXING & RETRIEVAL',
            [
              _buildSettingDropdown('Embedding Model', 'text-embedding-3-large', Icons.psychology),
              _buildSettingDropdown('Rerank Model', 'rerank-english-v3.0', Icons.layers),
              _buildSettingToggle('Enable Hybrid Search', true),
              _buildSettingSlider('Top K', 3, 1, 10),
            ],
          ),
          
          const SizedBox(height: 48),
          _buildSettingsSection(
            'METADATA CONFIGURATION',
            [
              _buildSettingToggle('Auto-extract author', true),
              _buildSettingToggle('Auto-extract publish date', true),
              _buildSettingToggle('Index tables as text', false),
            ],
          ),
          
          const SizedBox(height: 48),
          _buildSettingsSection(
            'DANGER ZONE',
            [
              _buildDangerItem('Delete Knowledge Base', 'Permanently delete this knowledge base and all associated data.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
