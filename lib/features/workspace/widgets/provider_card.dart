import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/model_provider_models.dart';

/// Card widget for displaying model provider information
class ProviderCard extends ConsumerWidget {
  final ProviderConfig config;
  final VoidCallback onConfigure;
  final VoidCallback onTest;
  final VoidCallback? onToggle;

  const ProviderCard({
    super.key,
    required this.config,
    required this.onConfigure,
    required this.onTest,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isConfigured = config.credentials != null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor.withValues(alpha: 0.9),
              theme.cardColor.withValues(alpha: 0.7),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with logo and status
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Provider logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        config.provider.logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          FontAwesomeIcons.microchip,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Provider name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.provider.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusIndicator(context),
                            const SizedBox(width: 8),
                            Text(
                              config.status.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Enable/disable toggle
                  if (onToggle != null)
                    Switch(
                      value: config.enabled,
                      onChanged: (_) => onToggle?.call(),
                      activeColor: theme.primaryColor,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Model count and info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isConfigured) ...[
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.cubes,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${config.availableModels.length} models available',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (config.defaultModel != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.star,
                              size: 10,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Default: ${config.defaultModel!.name}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCapabilityIcons(context, config.defaultModel!),
                    ],
                  ] else
                    Text(
                      'Not configured',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (config.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.triangleExclamation,
                          size: 14,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            config.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (config.quota != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildUsageQuotas(context, config.quota!),
              ),
            ],
            const Divider(height: 1),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isConfigured)
                    TextButton.icon(
                      onPressed: config.enabled ? onTest : null,
                      icon: const Icon(FontAwesomeIcons.vial, size: 14),
                      label: const Text('Test'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onConfigure,
                    icon: Icon(
                      isConfigured ? FontAwesomeIcons.gear : FontAwesomeIcons.plus,
                      size: 14,
                    ),
                    label: Text(isConfigured ? 'Configure' : 'Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageQuotas(BuildContext context, UsageQuota quota) {
    final theme = Theme.of(context);
    final isNearLimit = quota.isNearLimit;

    return Column(
      children: [
        _buildQuotaRow(
          context,
          'Requests',
          quota.requestsUsed,
          quota.requestsLimit,
          quota.requestsPercentage,
          isNearLimit,
        ),
        const SizedBox(height: 8),
        _buildQuotaRow(
          context,
          'Tokens',
          quota.tokensUsed,
          quota.tokensLimit,
          quota.tokensPercentage,
          isNearLimit,
        ),
      ],
    );
  }

  Widget _buildQuotaRow(
    BuildContext context,
    String label,
    int used,
    int limit,
    double percentage,
    bool isWarning,
  ) {
    final theme = Theme.of(context);
    final color = isWarning ? Colors.orange : theme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
            Text(
              '$used / $limit',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isWarning ? Colors.orange : Colors.white60,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getStatusColor(context),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(context).withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityIcons(BuildContext context, ModelConfig model) {
    return Row(
      children: [
        if (model.supportsVision)
          _buildCapabilityIcon(context, FontAwesomeIcons.eye, 'Vision'),
        if (model.supportsFunctionCalling)
          _buildCapabilityIcon(context, FontAwesomeIcons.code, 'Tools'),
        if (model.supportsStreaming)
          _buildCapabilityIcon(context, FontAwesomeIcons.bolt, 'Stream'),
      ],
    );
  }

  Widget _buildCapabilityIcon(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: label,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 10, color: Colors.white38),
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    if (!config.enabled) return Colors.grey;
    
    switch (config.status) {
      case ProviderStatus.connected:
        return Colors.green;
      case ProviderStatus.disconnected:
        return Colors.orange;
      case ProviderStatus.error:
        return Colors.red;
      case ProviderStatus.testing:
        return Colors.blue;
    }
  }
}
