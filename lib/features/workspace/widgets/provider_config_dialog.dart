import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/model_provider_models.dart';
import '../services/model_provider_service.dart';
import '../providers/model_providers_provider.dart';

/// Dialog for configuring a model provider
class ProviderConfigDialog extends ConsumerStatefulWidget {
  final ProviderConfig config;

  const ProviderConfigDialog({
    super.key,
    required this.config,
  });

  @override
  ConsumerState<ProviderConfigDialog> createState() => _ProviderConfigDialogState();
}

class _ProviderConfigDialogState extends ConsumerState<ProviderConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _service = ModelProviderService();
  
  bool _obscureApiKey = true;
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;
  List<ModelConfig> _availableModels = [];
  ModelConfig? _selectedDefaultModel;

  @override
  void initState() {
    super.initState();
    if (widget.config.credentials != null) {
      _apiKeyController.text = widget.config.credentials!.apiKey;
      _baseUrlController.text = widget.config.credentials!.baseUrl ?? '';
    }
    _availableModels = widget.config.availableModels;
    _selectedDefaultModel = widget.config.defaultModel;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    final result = await _service.testConnection(
      widget.config.provider,
      _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim().isEmpty
          ? null
          : _baseUrlController.text.trim(),
    );

    setState(() {
      _isTesting = false;
      _testMessage = result.message;
      _testSuccess = result.success;
      if (result.success && result.models.isNotEmpty) {
        _availableModels = result.models;
        _selectedDefaultModel ??= result.models.first;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final credentials = ProviderCredentials(
      provider: widget.config.provider,
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim().isEmpty
          ? null
          : _baseUrlController.text.trim(),
      createdAt: widget.config.credentials?.createdAt ?? DateTime.now(),
    );

    final updatedConfig = widget.config.copyWith(
      credentials: credentials,
      availableModels: _availableModels,
      defaultModel: _selectedDefaultModel,
      status: _testSuccess == true
          ? ProviderStatus.connected
          : ProviderStatus.disconnected,
    );

    ref.read(modelProvidersProvider.notifier).configureProvider(updatedConfig);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: theme.colorScheme.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        widget.config.provider.logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          FontAwesomeIcons.microchip,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configure ${widget.config.provider.displayName}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // API Key field
              TextFormField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your API key',
                  prefixIcon: const Icon(FontAwesomeIcons.key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureApiKey
                          ? FontAwesomeIcons.eye
                          : FontAwesomeIcons.eyeSlash,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'API key is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Base URL field (optional)
              if (widget.config.provider == ModelProvider.custom ||
                  widget.config.provider == ModelProvider.ollama)
                TextFormField(
                  controller: _baseUrlController,
                  decoration: InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.example.com',
                    prefixIcon: const Icon(FontAwesomeIcons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (widget.config.provider == ModelProvider.custom &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Base URL is required for custom providers';
                    }
                    return null;
                  },
                ),
              if (widget.config.provider == ModelProvider.custom ||
                  widget.config.provider == ModelProvider.ollama)
                const SizedBox(height: 16),
              // Test connection button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(FontAwesomeIcons.vial),
                  label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              // Test result message
              if (_testMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testSuccess == true
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testSuccess == true ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess == true
                            ? FontAwesomeIcons.circleCheck
                            : FontAwesomeIcons.circleXmark,
                        color: _testSuccess == true ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _testMessage!,
                          style: TextStyle(
                            color: _testSuccess == true ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Default model selector
              if (_availableModels.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Default Model',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ModelConfig>(
                  initialValue: _selectedDefaultModel,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(FontAwesomeIcons.microchip),
                  ),
                  items: _availableModels.map((model) {
                    return DropdownMenuItem(
                      value: model,
                      child: Text(model.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDefaultModel = value;
                    });
                  },
                ),
              ],
              const Spacer(),
              const Divider(),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
