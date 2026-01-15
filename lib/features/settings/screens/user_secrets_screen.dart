import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/secrets_service.dart';

class UserSecretsScreen extends ConsumerStatefulWidget {
  const UserSecretsScreen({super.key});

  @override
  ConsumerState<UserSecretsScreen> createState() => _UserSecretsScreenState();
}

class _UserSecretsScreenState extends ConsumerState<UserSecretsScreen> {
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
      final secrets = await ref.read(secretsServiceProvider).getUserSecrets();
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
      await ref.read(secretsServiceProvider).saveUserSecrets(_controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your secrets saved successfully'), backgroundColor: Colors.green),
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
        title: const Text('My Secrets (secrets.md)'),
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
                      color: theme.primaryColor.withOpacity(0.1),
                      border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.lock, color: theme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'These secrets are encrypted at rest and only accessible by you. Use them in your workflows via {{secrets.KEY}}.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColor),
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
                        hintText: 'NOTION_KEY=secret_...\nSLACK_TOKEN=xoxb-...',
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
