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

  Future<void> _editMemory(MemoryItem item) async {
    final controller = TextEditingController(text: item.value);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: Text('Edit Memory: ${item.key}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          maxLines: null,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter corrected value...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Update')),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        await ref.read(memoryServiceProvider).updateSuperAdminMemory(item.copyWith(value: result.trim()));
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memory updated')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteMemory(MemoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text('Delete Memory?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${item.key}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(memoryServiceProvider).deleteSuperAdminMemory(item);
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memory deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: AppBar(
        title: const Text('Super Copilot (Global Brain)'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(item.category.toUpperCase(), style: const TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.key, 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white24),
                      onPressed: () => _editMemory(item),
                      tooltip: 'Edit Memory',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 16, color: Colors.redAccent.withOpacity(0.5)),
                      onPressed: () => _deleteMemory(item),
                      tooltip: 'Delete Memory',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.value, 
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (item.userId != null) 
                      Text('origin: ${item.userId!.substring(0, 8)}...', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                    const Spacer(),
                    Text(
                      'Last updated: ${item.createdAt.toIso8601String().split('T').first}', 
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
