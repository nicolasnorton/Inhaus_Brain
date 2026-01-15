import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/services/memory_service.dart';
import '../../chat/models/memory_models.dart';

class SuperCopilotScreen extends ConsumerStatefulWidget {
  const SuperCopilotScreen({super.key});

  @override
  ConsumerState<SuperCopilotScreen> createState() => _SuperCopilotScreenState();
}

class _SuperCopilotScreenState extends ConsumerState<SuperCopilotScreen> {
  bool _isLoading = true;
  List<MemoryItem> _memories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final memories = await ref.read(memoryServiceProvider).getSuperAdminMemories();
      setState(() {
        _memories = memories;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading system memory: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: AppBar(
        title: const Text('Super Copilot Brain'),
        backgroundColor: const Color(0xFF0F1116),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _memories.isEmpty 
              ? _buildEmptyState()
              : _buildMemoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.brain, size: 60, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No system memories found.', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          const Text(
            'Agents execute actions to populate this view.',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
             onPressed: _loadData,
             child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _memories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _memories[index];
        return Card(
          color: const Color(0xFF1C2128),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Badge(
                      label: Text(item.category),
                      backgroundColor: Colors.blueAccent.withOpacity(0.2),
                      textColor: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.key, 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                    ),
                    Icon(
                      item.scope == MemoryScope.private ? Icons.lock : Icons.public,
                      size: 14,
                      color: Colors.white24,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.value, 
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (item.userId != null) 
                      Text('User: ${item.userId!.substring(0, 5)}...', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                    const Spacer(),
                    Text(
                      item.createdAt.toIso8601String().split('T').first, 
                      style: const TextStyle(color: Colors.white24, fontSize: 10),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
