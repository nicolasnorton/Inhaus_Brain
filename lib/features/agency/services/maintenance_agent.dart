import 'dart:typed_data';
import '../models/agency_service_model.dart';
import 'service_catalog_repository.dart';
import 'service_pdf_parser_service.dart';

/// Maintenance Agent for identifying and updating agency products/services
class MaintenanceAgent {
  final ServiceCatalogRepository _repository;
  final ServicePdfParserService _parser;

  MaintenanceAgent({
    ServiceCatalogRepository? repository,
    ServicePdfParserService? parser,
  })  : _repository = repository ?? ServiceCatalogRepository(),
        _parser = parser ?? ServicePdfParserService();

  /// Orchestrates extraction and merging from a PDF file
  Future<List<AgencyService>> updateServicesFromPdf(Uint8List pdfBytes, String filename) async {
    try {
      // 1. Extract services using Gemini
      final extractedServices = await _parser.extractServicesFromPdf(pdfBytes, filename);
      
      if (extractedServices.isEmpty) {
        return [];
      }

      // 2. Persist/Merge into Firestore catalog
      await _repository.mergeServices(extractedServices);

      return extractedServices;
    } catch (e) {
      print('MaintenanceAgent Error: $e');
      rethrow;
    }
  }

  /// Orchestrates extraction and merging from text
  Future<List<AgencyService>> updateServicesFromText(String text) async {
    try {
      final extractedServices = await _parser.extractServicesFromText(text);
      
      if (extractedServices.isNotEmpty) {
        await _repository.mergeServices(extractedServices);
      }

      return extractedServices;
    } catch (e) {
      print('MaintenanceAgent Error: $e');
      rethrow;
    }
  }

  /// Validates the current catalog against a standard (optional)
  Future<void> runHealthCheck() async {
    final catalog = await _repository.getCatalog();
    if (catalog == null || catalog.services.isEmpty) {
      print('MaintenanceAgent: Catalog is empty or missing. Initializing default...');
      await _repository.initializeDefaultCatalog();
    } else {
      print('MaintenanceAgent: Catalog OK with ${catalog.services.length} services.');
    }
  }
}
