import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../settings/services/secrets_service.dart';

class SystemSecretsScreen extends ConsumerStatefulWidget {
  const SystemSecretsScreen({super.key});

  @override
  ConsumerState<SystemSecretsScreen> createState() => _SystemSecretsScreenState();
}

class _SystemSecretsScreenState extends ConsumerState<SystemSecretsScreen> {
  final _controller = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSecrets();
  }

  Future<void> _loadSecrets() async {
    try {
      final secrets = await ref.read(secretsServiceProvider).getSystemSecrets();
      if (mounted) {
        setState(() {
          _controller.text = secrets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading secrets: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSecrets() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(secretsServiceProvider).saveSystemSecrets(_controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System secrets saved successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving secrets: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('System Secrets (secrets.md)'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _isSaving ? null : _saveSecrets,
              icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const FaIcon(FontAwesomeIcons.floppyDisk),
              tooltip: 'Save Secrets',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.amber, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'CAUTION: API Keys and secrets stored here are used by server-side functions. Edits take effect immediately.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'OPENAI_API_KEY=sk-...\nDATABASE_URL=postgres://...',
                        fillColor: theme.cardColor,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
