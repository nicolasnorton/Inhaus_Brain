import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/model_provider_models.dart';
import '../providers/model_providers_provider.dart';
import '../widgets/provider_card.dart';
import '../widgets/provider_config_dialog.dart';
import '../widgets/system_default_model_dialog.dart';
import '../services/model_provider_service.dart';

/// Main screen for managing model providers
class ModelProvidersScreen extends ConsumerStatefulWidget {
  const ModelProvidersScreen({super.key});

  @override
  ConsumerState<ModelProvidersScreen> createState() => _ModelProvidersScreenState();
}

class _ModelProvidersScreenState extends ConsumerState<ModelProvidersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ModelProviderType? _selectedType;
  final _service = ModelProviderService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSystemDefaultsDialog() {
    showDialog(
      context: context,
      builder: (context) => const SystemDefaultModelDialog(),
    );
  }

  void _showConfigDialog(ProviderConfig config) {
    showDialog(
      context: context,
      builder: (context) => ProviderConfigDialog(config: config),
    );
  }

  Future<void> _testProvider(ProviderConfig config) async {
    if (config.credentials == null) {
      _showSnackBar('Please configure the provider first', isError: true);
      return;
    }

    // Update status to testing
    ref.read(modelProvidersProvider.notifier).updateStatus(
          config.provider,
          ProviderStatus.testing,
        );

    final result = await _service.testConnection(
      config.provider,
      config.credentials!.apiKey,
      baseUrl: config.credentials!.baseUrl,
    );

    ref.read(modelProvidersProvider.notifier).updateStatus(
          config.provider,
          result.success ? ProviderStatus.connected : ProviderStatus.error,
          errorMessage: result.success ? null : result.message,
        );

    if (result.success && result.models.isNotEmpty) {
      ref.read(modelProvidersProvider.notifier).updateAvailableModels(
            config.provider,
            result.models,
          );
    }

    _showSnackBar(
      result.message,
      isError: !result.success,
    );
  }

  void _toggleProvider(ProviderConfig config) {
    ref.read(modelProvidersProvider.notifier).toggleProvider(
          config.provider,
          !config.enabled,
        );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providers = ref.watch(modelProvidersProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.microchip,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Model Providers',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configure AI model access for your workspace',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: theme.primaryColor,
                  tabs: const [
                    Tab(text: 'Predefined Models'),
                    Tab(text: 'Custom Models'),
                  ],
                ),
              ],
            ),
          ),
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  'Filter by type:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                DropdownButton<ModelProviderType?>(
                  value: _selectedType,
                  hint: const Text('All Types'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...ModelProviderType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),
                const Spacer(),
                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.circleCheck,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${providers.where((p) => p.status == ProviderStatus.connected).length} Connected',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showSystemDefaultsDialog,
                  icon: const Icon(FontAwesomeIcons.gears, size: 14),
                  label: const Text('System Defaults'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Predefined Models Tab
                _buildProviderGrid(
                  providers.where((p) {
                    if (_selectedType != null) {
                      return p.availableModels
                          .any((m) => m.type == _selectedType);
                    }
                    return true;
                  }).toList(),
                ),
                // Custom Models Tab
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.cubes,
                        size: 64,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Custom Models',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coming soon',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderGrid(List<ProviderConfig> providers) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.magnifyingGlass,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              'No providers found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white60,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white38,
                  ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final config = providers[index];
        return ProviderCard(
          config: config,
          onConfigure: () => _showConfigDialog(config),
          onTest: () => _testProvider(config),
          onToggle: () => _toggleProvider(config),
        );
      },
    );
  }
}
