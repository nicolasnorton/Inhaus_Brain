import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../settings/services/secrets_service.dart';

class SystemSecretsScreen extends ConsumerStatefulWidget {
  const SystemSecretsScreen({super.key});

  @override
  ConsumerState<SystemSecretsScreen> createState() => _SystemSecretsScreenState();
}

class _SystemSecretsScreenState extends ConsumerState<SystemSecretsScreen> {
  final List<TextEditingController> _keyControllers = [];
  final List<TextEditingController> _valueControllers = [];
  final List<bool> _isMasked = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSecrets();
  }

  Future<void> _loadSecrets() async {
    try {
      final content = await ref.read(secretsServiceProvider).getSystemSecrets();
      _parseSecrets(content);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  void _parseSecrets(String content) {
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty || !line.contains('=')) continue;
      final parts = line.split('=');
      final key = parts[0].trim();
      final value = parts.sublist(1).join('=').trim();
      
      _keyControllers.add(TextEditingController(text: key));
      _valueControllers.add(TextEditingController(text: value));
      _isMasked.add(true);
    }
    // Add one empty field if list is empty
    if (_keyControllers.isEmpty) _addField();
  }

  void _addField() {
    setState(() {
      _keyControllers.add(TextEditingController());
      _valueControllers.add(TextEditingController());
      _isMasked.add(false);
    });
  }

  void _removeField(int index) {
    setState(() {
      _keyControllers.removeAt(index);
      _valueControllers.removeAt(index);
      _isMasked.removeAt(index);
    });
  }

  Future<void> _saveSecrets() async {
    setState(() => _isSaving = true);
    try {
      final content = _keyControllers.asMap().entries.map((e) {
        final key = e.value.text.trim();
        final value = _valueControllers[e.key].text.trim();
        if (key.isEmpty) return null;
        return '$key=$value';
      }).where((e) => e != null).join('\n');

      await ref.read(secretsServiceProvider).saveSystemSecrets(content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secrets saved successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: AppBar(
        title: const Text('System Secrets Management'),
        backgroundColor: const Color(0xFF0F1116),
        actions: [
          IconButton(
            onPressed: _addField,
            icon: const Icon(Icons.add_box_outlined, color: Colors.blueAccent),
            tooltip: 'Add Secret',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSaving ? null : _saveSecrets,
            icon: _isSaving 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const FaIcon(FontAwesomeIcons.floppyDisk, size: 18),
            tooltip: 'Save All Changes',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _keyControllers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildSecretRow(index),
            ),
    );
  }

  Widget _buildSecretRow(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _keyControllers[index],
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'KEY_NAME',
                hintStyle: TextStyle(color: Colors.white12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: TextField(
              controller: _valueControllers[index],
              obscureText: _isMasked[index],
              style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'value',
                hintStyle: TextStyle(color: Colors.white12),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(_isMasked[index] ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.white24),
            onPressed: () => setState(() => _isMasked[index] = !_isMasked[index]),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: Colors.white24),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _valueControllers[index].text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
            onPressed: () => _removeField(index),
          ),
        ],
      ),
    );
  }
}
