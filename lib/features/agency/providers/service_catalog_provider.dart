import 'package:flutter/foundation.dart';
import '../models/agency_service_model.dart';
import '../services/service_catalog_repository.dart';

/// Provider for managing Agency Services Catalog state
class ServiceCatalogProvider with ChangeNotifier {
  final ServiceCatalogRepository _repository;

  ServiceCatalog? _catalog;
  bool _isLoading = false;
  String? _error;

  ServiceCatalogProvider({ServiceCatalogRepository? repository})
      : _repository = repository ?? ServiceCatalogRepository();

  ServiceCatalog? get catalog => _catalog;
  List<AgencyService> get services => _catalog?.services ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _catalog != null;

  /// Load the catalog from Firestore
  Future<void> loadCatalog() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _catalog = await _repository.getCatalog();
      _error = null;
    } catch (e) {
      _error = 'Failed to load catalog: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize catalog with default services if not exists
  Future<void> initializeCatalog() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.initializeDefaultCatalog();
      await loadCatalog();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize catalog: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new service
  Future<void> addService(AgencyService service) async {
    try {
      await _repository.addService(service);
      await loadCatalog(); // Reload to get updated state
    } catch (e) {
      _error = 'Failed to add service: $e';
      print(_error);
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing service
  Future<void> updateService(AgencyService service) async {
    try {
      await _repository.updateService(service);
      await loadCatalog();
    } catch (e) {
      _error = 'Failed to update service: $e';
      print(_error);
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a service
  Future<void> deleteService(String serviceId) async {
    try {
      await _repository.deleteService(serviceId);
      await loadCatalog();
    } catch (e) {
      _error = 'Failed to delete service: $e';
      print(_error);
      notifyListeners();
      rethrow;
    }
  }

  /// Search services
  Future<List<AgencyService>> searchServices(String query) async {
    try {
      return await _repository.searchServices(query);
    } catch (e) {
      _error = 'Failed to search services: $e';
      print(_error);
      return [];
    }
  }

  /// Get services by frequency
  List<AgencyService> getServicesByFrequency(String frequency) {
    return services.where((s) => s.frequency == frequency).toList();
  }

  /// Get recurring services
  List<AgencyService> get recurringServices {
    return services.where((s) => s.isRecurring).toList();
  }

  /// Get one-time services
  List<AgencyService> get oneTimeServices {
    return services.where((s) => !s.isRecurring).toList();
  }

  /// Merge new services from PDF extraction
  Future<void> mergeServices(List<AgencyService> newServices) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.mergeServices(newServices);
      await loadCatalog();
      _error = null;
    } catch (e) {
      _error = 'Failed to merge services: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get service by ID
  AgencyService? getServiceById(String serviceId) {
    try {
      return services.firstWhere((s) => s.id == serviceId);
    } catch (e) {
      return null;
    }
  }

  /// Get total catalog value (sum of all min prices)
  double get totalCatalogValue {
    return services.fold(0.0, (sum, service) => sum + service.getMinPrice());
  }

  /// Get services grouped by frequency
  Map<String, List<AgencyService>> get servicesByFrequency {
    final Map<String, List<AgencyService>> grouped = {};
    for (final service in services) {
      grouped.putIfAbsent(service.frequency, () => []).add(service);
    }
    return grouped;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
