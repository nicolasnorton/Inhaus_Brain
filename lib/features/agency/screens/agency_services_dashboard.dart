import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/agency_service_model.dart';
import '../services/service_catalog_repository.dart';
import '../services/service_pdf_parser_service.dart';
import '../providers/service_catalog_riverpod_provider.dart';
import '../widgets/agency_service_card.dart';
import '../widgets/agency_service_form.dart';
import '../widgets/agency_profitability_dashboard.dart';

/// Consolidated dashboard for managing Agency Services (Catalog + Profitability)
class AgencyServicesDashboard extends ConsumerStatefulWidget {
  const AgencyServicesDashboard({super.key});

  @override
  ConsumerState<AgencyServicesDashboard> createState() => _AgencyServicesDashboardState();
}

class _AgencyServicesDashboardState extends ConsumerState<AgencyServicesDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterFrequency = 'all';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCatalog();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeCatalog() async {
    final repository = ref.read(serviceCatalogRepositoryProvider);
    final catalog = await repository.getCatalog();
    if (catalog == null) {
      await repository.initializeDefaultCatalog();
      ref.invalidate(serviceCatalogProvider);
    }
  }

  Future<void> _uploadPdfAndExtract() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        _showError('Failed to read file');
        return;
      }

      setState(() => _isUploading = true);

      final parser = ServicePdfParserService();
      final services = await parser.extractServicesFromPdf(
        file.bytes!,
        file.name,
      );

      if (services.isEmpty) {
        _showError('No services found in PDF');
        setState(() => _isUploading = false);
        return;
      }

      // Show preview dialog
      final confirmed = await _showServicesPreview(services);
      
      if (confirmed == true && mounted) {
        final repository = ref.read(serviceCatalogRepositoryProvider);
        await repository.mergeServices(services);
        ref.invalidate(serviceCatalogProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully merged ${services.length} services'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showError('Failed to extract services: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<bool?> _showServicesPreview(List<AgencyService> services) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Found ${services.length} Services', style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 600,
          height: 400,
          child: ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ListTile(
                title: Text(service.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(service.description, style: const TextStyle(color: Colors.white60)),
                trailing: Text(
                  '\$${service.price}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Merge into Catalog'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<AgencyService> _getFilteredServices(List<AgencyService> services) {
    var filtered = services;

    // Apply frequency filter
    if (_filterFrequency != 'all') {
      filtered = filtered.where((s) => s.frequency == _filterFrequency).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  void _showServiceForm(BuildContext context, {AgencyService? service}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          service == null ? "Create New Service" : "Edit Service",
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 600,
          child: AgencyServiceForm(
            service: service,
            onSave: (data) async {
              final repository = ref.read(serviceCatalogRepositoryProvider);
              if (service == null) {
                final newService = AgencyService.create(
                  name: data['name'],
                  description: data['description'],
                  type: ServiceType.values.byName(data['type']),
                  price: data['price'],
                  basePrice: data['basePrice'],
                  deliveryCost: data['deliveryCost'],
                  targetMargin: data['targetMargin'],
                  execution: data['execution'],
                  team: data['team'],
                  deliverables: data['deliverables'],
                  includes: data['includes'],
                  excludes: data['excludes'],
                  frequency: data['billingCycle'] == 'oneTime' ? 'one-time' : data['billingCycle'],
                  billingCycle: BillingCycle.values.byName(data['billingCycle']),
                );
                await repository.addService(newService);
              } else {
                final updated = service.copyWith(
                  name: data['name'],
                  description: data['description'],
                  type: ServiceType.values.byName(data['type']),
                  price: data['price'],
                  basePrice: data['basePrice'],
                  deliveryCost: data['deliveryCost'],
                  targetMargin: data['targetMargin'],
                  execution: data['execution'],
                  team: data['team'],
                  deliverables: data['deliverables'],
                  includes: data['includes'],
                  excludes: data['excludes'],
                  frequency: data['billingCycle'] == 'oneTime' ? 'one-time' : data['billingCycle'],
                  billingCycle: BillingCycle.values.byName(data['billingCycle']),
                  updatedAt: DateTime.now(),
                );
                await repository.updateService(updated);
              }
              ref.invalidate(serviceCatalogProvider);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AgencyService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Delete Service", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete \"${service.name}\"?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(serviceCatalogRepositoryProvider).deleteService(service.id);
              ref.invalidate(serviceCatalogProvider);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(serviceCatalogProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Agency Services Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              tooltip: 'Upload PDF to Extract Services',
              onPressed: _uploadPdfAndExtract,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload Catalog',
            onPressed: () => ref.invalidate(serviceCatalogProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: "Catalog"),
            Tab(text: "Profitability"),
          ],
        ),
      ),
      body: catalogAsync.when(
        data: (catalog) {
          if (catalog == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('Catalog not initialized', style: TextStyle(color: Colors.white70, fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeCatalog,
                    child: const Text('Initialize Catalog'),
                  ),
                ],
              ),
            );
          }

          final filteredServices = _getFilteredServices(catalog.services);

          return TabBarView(
            controller: _tabController,
            children: [
              // Catalog Tab
              Column(
                children: [
                  _buildFilterBar(),
                  _buildStatsBar(catalog, filteredServices),
                  Expanded(
                    child: filteredServices.isEmpty
                        ? const Center(child: Text('No services found', style: TextStyle(color: Colors.white38)))
                        : GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = filteredServices[index];
                              return AgencyServiceCard(
                                service: service,
                                onEdit: () => _showServiceForm(context, service: service),
                                onDelete: () => _showDeleteConfirmation(context, service),
                              );
                            },
                          ),
                  ),
                ],
              ),
              // Profitability Tab
              AgencyProfitabilityDashboard(services: catalog.services),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceForm(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search services...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primary)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 16),
          _buildFrequencyFilter(),
        ],
      ),
    );
  }

  Widget _buildFrequencyFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButton<String>(
        value: _filterFrequency,
        dropdownColor: AppTheme.surface,
        style: const TextStyle(color: Colors.white),
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All Frequencies')),
          DropdownMenuItem(value: 'one-time', child: Text('One-Time')),
          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
          DropdownMenuItem(value: 'bimonthly', child: Text('Bimonthly')),
          DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
          DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
        ],
        onChanged: (value) => setState(() => _filterFrequency = value ?? 'all'),
      ),
    );
  }

  Widget _buildStatsBar(ServiceCatalog catalog, List<AgencyService> filteredServices) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Total', catalog.services.length.toString()),
          _buildStat('Showing', filteredServices.length.toString()),
          _buildStat('Recurring', catalog.services.where((s) => s.isRecurring).length.toString()),
          _buildStat('One-Time', catalog.services.where((s) => !s.isRecurring).length.toString()),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
      ],
    );
  }
}
