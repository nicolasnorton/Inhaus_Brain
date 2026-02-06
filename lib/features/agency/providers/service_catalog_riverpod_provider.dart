import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agency_service_model.dart';
import '../services/service_catalog_repository.dart';

/// Provider for the ServiceCatalogRepository
final serviceCatalogRepositoryProvider = Provider<ServiceCatalogRepository>((ref) {
  return ServiceCatalogRepository();
});

/// Provider for the service catalog state
final serviceCatalogProvider = FutureProvider<ServiceCatalog?>((ref) async {
  final repository = ref.watch(serviceCatalogRepositoryProvider);
  return await repository.getCatalog();
});

/// Provider for services list
final servicesListProvider = FutureProvider<List<AgencyService>>((ref) async {
  final catalog = await ref.watch(serviceCatalogProvider.future);
  return catalog?.services ?? [];
});

/// Provider for recurring services
final recurringServicesProvider = FutureProvider<List<AgencyService>>((ref) async {
  final services = await ref.watch(servicesListProvider.future);
  return services.where((s) => s.isRecurring).toList();
});

/// Provider for one-time services
final oneTimeServicesProvider = FutureProvider<List<AgencyService>>((ref) async {
  final services = await ref.watch(servicesListProvider.future);
  return services.where((s) => !s.isRecurring).toList();
});

/// Provider for searching services
final serviceSearchProvider = FutureProvider.family<List<AgencyService>, String>((ref, query) async {
  final repository = ref.watch(serviceCatalogRepositoryProvider);
  return await repository.searchServices(query);
});

/// Provider for getting a service by ID
final serviceByIdProvider = FutureProvider.family<AgencyService?, String>((ref, serviceId) async {
  final repository = ref.watch(serviceCatalogRepositoryProvider);
  return await repository.getServiceById(serviceId);
});
