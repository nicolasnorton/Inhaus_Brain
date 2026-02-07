import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

import '../models/service_model.dart';
import '../models/service_enums.dart';
import '../services/services_repository.dart';
import '../widgets/service_card.dart';
import '../widgets/service_form.dart';
import '../widgets/profitability_dashboard.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _innerTabController;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: TabBar(
            controller: _innerTabController,
            indicatorColor: AppTheme.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: "Service Catalog"),
              Tab(text: "Profitability Analysis"),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _innerTabController,
        children: [
          _buildCatalogTab(servicesAsync),
          _buildProfitabilityTab(servicesAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showServiceDialog(BuildContext context, {Service? service}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          service == null ? "Create New Service" : "Edit Service",
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 500,
          child: ServiceForm(
            service: service,
            onSave: (data) async {
              final now = DateTime.now();
              if (service == null) {
                final newService = Service(
                  id: DateTime.now().millisecondsSinceEpoch.toString(), // Simplified ID for now
                  name: data['name'],
                  nameEs: data['nameEs'],
                  type: ServiceType.values.byName(data['type']),
                  basePrice: data['basePrice'],
                  deliveryCost: data['deliveryCost'],
                  targetMargin: data['targetMargin'],
                  execution: data['execution'],
                  billingCycle: BillingCycle.values.byName(data['billingCycle']),
                  createdAt: now,
                  updatedAt: now,
                );
                await ref.read(servicesRepositoryProvider).createService(newService);
              } else {
                final updated = service.copyWith(
                  name: data['name'],
                  nameEs: data['nameEs'],
                  type: ServiceType.values.byName(data['type']),
                  basePrice: data['basePrice'],
                  deliveryCost: data['deliveryCost'],
                  targetMargin: data['targetMargin'],
                  execution: data['execution'],
                  billingCycle: BillingCycle.values.byName(data['billingCycle']),
                  updatedAt: now,
                );
                await ref.read(servicesRepositoryProvider).updateService(updated);
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogTab(AsyncValue<List<Service>> servicesAsync) {
    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                const Text("Catalog is Empty", style: TextStyle(color: Colors.white54, fontSize: 20)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(servicesRepositoryProvider).seedInitialData(),
                  child: const Text("Seed Demo Data"),
                ),
              ],
            ),
          );
        }

        final bundles = services.where((s) => s.type == ServiceType.bundle).toList();
        final individuals = services.where((s) => s.type == ServiceType.individual).toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (bundles.isNotEmpty) ...[
              const Text("SERVICE BUNDLES", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _buildServiceGrid(bundles),
              const SizedBox(height: 32),
            ],
            if (individuals.isNotEmpty) ...[
              const Text("INDIVIDUAL SERVICES", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _buildServiceGrid(individuals),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildServiceGrid(List<Service> services) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.5,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return ServiceCard(
          service: service,
          onEdit: () => _showServiceDialog(context, service: service),
          onDelete: () => _showDeleteConfirmation(context, service),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Service service) {
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
              await ref.read(servicesRepositoryProvider).deleteService(service.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitabilityTab(AsyncValue<List<Service>> servicesAsync) {
    return servicesAsync.when(
      data: (services) => ProfitabilityDashboard(services: services),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
    );
  }
}
