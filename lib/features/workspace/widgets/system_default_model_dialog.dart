import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/model_provider_models.dart';
import '../providers/model_providers_provider.dart';

/// Dialog for setting system-wide default models
class SystemDefaultModelDialog extends ConsumerWidget {
  const SystemDefaultModelDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final defaultModels = ref.watch(defaultModelsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(FontAwesomeIcons.gears, color: theme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'System Model Defaults',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Set global preference for primary AI models across your workspace.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: 24),
            // Default Model Pickers
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: ModelProviderType.values.map((type) {
                    return _buildTypeSection(context, ref, type, defaultModels[type]);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection(
    BuildContext context,
    WidgetRef ref,
    ModelProviderType type,
    ModelConfig? currentDefault,
  ) {
    final theme = Theme.of(context);
    final availableModels = ref.watch(availableModelsProvider(type));

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getTypeIcon(type, theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                type.displayName,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ModelConfig>(
            initialValue: availableModels.any((m) => m.id == currentDefault?.id) 
                ? availableModels.firstWhere((m) => m.id == currentDefault?.id)
                : null,
            hint: const Text('Select default model...'),
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            items: availableModels.map((model) {
              return DropdownMenuItem(
                value: model,
                child: Row(
                  children: [
                    Text(model.name),
                    const SizedBox(width: 8),
                    Text(
                      '(${model.provider.displayName})',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final currentDefaults = ref.read(defaultModelsProvider);
                ref.read(defaultModelsProvider.notifier).state = {
                  ...currentDefaults,
                  type: value,
                };
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _getTypeIcon(ModelProviderType type, Color color) {
    IconData icon;
    switch (type) {
      case ModelProviderType.llm:
        icon = FontAwesomeIcons.brain;
        break;
      case ModelProviderType.embedding:
        icon = FontAwesomeIcons.database;
        break;
      case ModelProviderType.rerank:
        icon = FontAwesomeIcons.arrowDownShortWide;
        break;
      case ModelProviderType.tts:
        icon = FontAwesomeIcons.commentDots;
        break;
      case ModelProviderType.stt:
        icon = FontAwesomeIcons.microphone;
        break;
      case ModelProviderType.image:
        icon = FontAwesomeIcons.image;
        break;
    }
    return Icon(icon, color: color, size: 14);
  }
}
