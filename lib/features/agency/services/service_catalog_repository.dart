import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agency_service_model.dart';

/// Repository for managing the Agency Services Catalog in Firestore
/// Path: /knowledge/agency_services/catalog
class ServiceCatalogRepository {
  final FirebaseFirestore _firestore;
  
  static const String _collectionPath = 'knowledge';
  static const String _servicesDoc = 'agency_services';
  static const String _catalogDoc = 'catalog';

  ServiceCatalogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the catalog document reference
  DocumentReference get _catalogRef => _firestore
      .collection(_collectionPath)
      .doc(_servicesDoc)
      .collection('data')
      .doc(_catalogDoc);

  /// Fetch the complete service catalog
  Future<ServiceCatalog?> getCatalog() async {
    try {
      final doc = await _catalogRef.get();
      if (!doc.exists) {
        return null;
      }
      return ServiceCatalog.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching service catalog: $e');
      return null;
    }
  }

  /// Save/update the entire catalog
  Future<void> saveCatalog(ServiceCatalog catalog) async {
    try {
      await _catalogRef.set(catalog.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving service catalog: $e');
      rethrow;
    }
  }

  /// Initialize catalog with default services (from the extracted PDF data)
  Future<void> initializeDefaultCatalog() async {
    final existing = await getCatalog();
    if (existing != null && existing.services.isNotEmpty) {
      print('Catalog already exists with ${existing.services.length} services');
      return;
    }

    final defaultServices = _getDefaultServices();
    final catalog = ServiceCatalog(
      id: 'catalog',
      name: 'Inhaus Agency Services Catalog',
      description: 'Complete catalog of agency products and services extracted from proposals',
      services: defaultServices,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: '1.0',
      metadata: {
        'source': 'COTIZACIONES INHAUS.pdf',
        'extractedAt': DateTime.now().toIso8601String(),
      },
    );

    await saveCatalog(catalog);
    print('Initialized catalog with ${defaultServices.length} services');
  }

  /// Add a new service to the catalog
  Future<void> addService(AgencyService service) async {
    final catalog = await getCatalog();
    if (catalog == null) {
      throw Exception('Catalog not initialized');
    }

    final updatedServices = [...catalog.services, service];
    final updatedCatalog = catalog.copyWith(
      services: updatedServices,
      updatedAt: DateTime.now(),
    );

    await saveCatalog(updatedCatalog);
  }

  /// Update an existing service
  Future<void> updateService(AgencyService service) async {
    final catalog = await getCatalog();
    if (catalog == null) {
      throw Exception('Catalog not initialized');
    }

    final updatedServices = catalog.services.map((s) {
      if (s.id == service.id) {
        return service.copyWith(updatedAt: DateTime.now());
      }
      return s;
    }).toList();

    final updatedCatalog = catalog.copyWith(
      services: updatedServices,
      updatedAt: DateTime.now(),
    );

    await saveCatalog(updatedCatalog);
  }

  /// Delete a service from the catalog
  Future<void> deleteService(String serviceId) async {
    final catalog = await getCatalog();
    if (catalog == null) {
      throw Exception('Catalog not initialized');
    }

    final updatedServices = catalog.services.where((s) => s.id != serviceId).toList();
    final updatedCatalog = catalog.copyWith(
      services: updatedServices,
      updatedAt: DateTime.now(),
    );

    await saveCatalog(updatedCatalog);
  }

  /// Get a specific service by ID
  Future<AgencyService?> getServiceById(String serviceId) async {
    final catalog = await getCatalog();
    if (catalog == null) return null;

    try {
      return catalog.services.firstWhere((s) => s.id == serviceId);
    } catch (e) {
      return null;
    }
  }

  /// Get multiple services by their IDs
  Future<List<AgencyService>> getServicesByIds(List<String> ids) async {
    final catalog = await getCatalog();
    if (catalog == null || ids.isEmpty) return [];

    return catalog.services.where((s) => ids.contains(s.id)).toList();
  }

  /// Search services by name or description
  Future<List<AgencyService>> searchServices(String query) async {
    final catalog = await getCatalog();
    if (catalog == null) return [];

    final lowerQuery = query.toLowerCase();
    return catalog.services.where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
          s.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get services by frequency (e.g., "monthly", "one-time")
  Future<List<AgencyService>> getServicesByFrequency(String frequency) async {
    final catalog = await getCatalog();
    if (catalog == null) return [];

    return catalog.services.where((s) => s.frequency == frequency).toList();
  }

  /// Merge new services from PDF extraction (deduplication by name)
  Future<void> mergeServices(List<AgencyService> newServices) async {
    final catalog = await getCatalog();
    if (catalog == null) {
      throw Exception('Catalog not initialized');
    }

    final existingMap = {for (var s in catalog.services) s.name.toLowerCase(): s};
    final merged = <AgencyService>[];

    // Keep existing services
    merged.addAll(catalog.services);

    // Add or update from new services
    for (final newService in newServices) {
      final key = newService.name.toLowerCase();
      if (existingMap.containsKey(key)) {
        // Update existing service (increment version)
        final existing = existingMap[key]!;
        final versionParts = existing.version.split('.');
        final majorVersion = int.tryParse(versionParts[0]) ?? 1;
        final minorVersion = int.tryParse(versionParts.length > 1 ? versionParts[1] : '0') ?? 0;
        final newVersion = '$majorVersion.${minorVersion + 1}';

        final updated = newService.copyWith(
          id: existing.id, // Keep same ID
          version: newVersion,
          updatedAt: DateTime.now(),
        );

        // Replace in merged list
        final index = merged.indexWhere((s) => s.id == existing.id);
        if (index != -1) {
          merged[index] = updated;
        }
      } else {
        // Add new service
        merged.add(newService);
      }
    }

    final updatedCatalog = catalog.copyWith(
      services: merged,
      updatedAt: DateTime.now(),
    );

    await saveCatalog(updatedCatalog);
  }

  /// Get default services from the extracted PDF data
  List<AgencyService> _getDefaultServices() {
    return [
      AgencyService.create(
        name: 'Refresh Look & Feel Web',
        description: 'Renovación digital en CMS existente (Ghost.org/Webflow) – rediseño clave sections, optimización visual, SEO inicial, Analytics.',
        details: [
          'Rediseño HOME/Quien somos/Donaciones/Contacto',
          'Navegación scroll down',
          'Favicon',
          'Optimización contenido existente',
          'Capacitación CMS',
          'Implementación back-end',
          'Integración newsletter básica',
          'SEO inicial + Google tools',
        ],
        excludes: ['Hosting/dominio', 'Mantenimiento post-entrega', 'Modificaciones posteriores', 'Campañas email'],
        price: '1700.00',
        frequency: 'one-time',
        timeEstimate: '1.5 months',
      ),
      AgencyService.create(
        name: 'Paquete Emprendedor RRSS',
        description: 'Manejo Facebook/Instagram básico con pauta.',
        details: [
          '20 piezas mensuales (1 Reel, 2 Carruseles, 4 Estáticos, 9 Stories)',
          'Respuestas, reunión/informe mensual',
          'Gestión pauta (15% comisión)',
        ],
        excludes: ['Valor pauta', 'Contenido personalizado si no contratado'],
        price: '1000.00',
        frequency: 'monthly',
      ),
      AgencyService.create(
        name: 'Paquete Starter RRSS',
        description: 'Manejo Facebook/Instagram estándar.',
        details: [
          '30 piezas mensuales (2 Reels, 3 Carruseles, 3 Estáticos, 16 Stories)',
          'Respuestas, reunión/informe',
          'Pauta 15% comisión',
        ],
        price: '1500.00',
        frequency: 'monthly',
      ),
      AgencyService.create(
        name: 'Paquete Corporativo RRSS',
        description: 'Manejo Facebook/Instagram avanzado.',
        details: [
          '40 piezas mensuales (3 Reels, 3 Carruseles, 5 Estáticos, 20 Stories)',
          'Respuestas, reunión/informe',
          'Pauta 15% comisión',
        ],
        price: '2000.00',
        frequency: 'monthly',
      ),
      AgencyService.create(
        name: 'Paquete TikTok',
        description: 'Manejo y producción TikTok.',
        details: ['4 Reels/mes', 'Producción 8h jornada', 'Props \$100'],
        includes: ['Producción audiovisual', 'Post/edición', 'Equipo completo'],
        excludes: ['Modelos/maquillaje', 'Viáticos', '>8h producción'],
        price: '900.00',
        frequency: 'monthly',
      ),
      AgencyService.create(
        name: 'Creación de Contenido Estándar',
        description: 'Sesión foto/video básica.',
        details: ['3 reels', '20 fotos', '4h jornada'],
        includes: ['Producción', 'Post/edición'],
        excludes: ['Modelos', 'Props', 'Viáticos', '>4h'],
        price: '800.00',
        frequency: 'one-time',
      ),
      AgencyService.create(
        name: 'Creación de Contenido Pro',
        description: 'Sesión foto/video profesional.',
        details: ['5 reels', '25 fotos', '8h jornada', 'Props \$100'],
        includes: ['Producción profesional', 'Post/edición'],
        excludes: ['Modelos/maquillaje/foodstyling', 'Viáticos', '>8h'],
        price: '1500.00',
        frequency: 'bimonthly',
      ),
      AgencyService.create(
        name: 'Paquete de Cobertura Evento',
        description: 'Documentación eventos.',
        details: ['Videos + fotos + stories en vivo', '4h jornada'],
        includes: ['Producción', 'Post/edición'],
        excludes: ['Viáticos', '>4h'],
        price: '800.00',
        frequency: 'one-time',
      ),
      AgencyService.create(
        name: 'Paquete Web Landing',
        description: 'Landing page Webflow.',
        details: ['Diseño + desarrollo single page', 'SEO', 'Analytics'],
        price: '1000.00-1500.00',
        frequency: 'one-time',
      ),
      AgencyService.create(
        name: 'Paquete Web Completo',
        description: 'Sitio web full hasta 20 páginas.',
        details: ['Home + internas', 'SEO', 'Analytics'],
        price: '2000.00-3000.00',
        frequency: 'one-time',
      ),
      AgencyService.create(
        name: 'Rebranding Logo',
        description: 'Logo + manual one page.',
        price: '1200.00',
        frequency: 'one-time',
      ),
      AgencyService.create(
        name: 'Branding Emprendedor',
        description: 'Logo + manual one pager + papelería.',
        price: '1500.00',
        frequency: 'one-time',
      ),
      AgencyService.create(
        name: 'Branding Starter',
        description: 'Logo + manual completo 20-30 páginas.',
        price: '5000.00',
        frequency: 'one-time',
      ),
      AgencyService.create(
        name: 'Branding Corporativo',
        description: 'Logo + manual completo 60-80 páginas.',
        price: '8000.00',
        frequency: 'one-time',
      ),
      AgencyService.create(
        name: 'Pauta Básico (Meta)',
        description: 'Gestión campañas Meta.',
        details: ['Hasta 3 objetivos', 'TEST', 'Informes'],
        excludes: ['Valor pauta'],
        price: '400.00',
        frequency: 'monthly',
        minAdSpend: '360.00',
      ),
      AgencyService.create(
        name: 'Pauta Medio (Meta + TikTok)',
        description: 'Gestión Meta + TikTok.',
        details: ['Hasta 3 objetivos/plataforma'],
        price: '750.00',
        frequency: 'monthly',
        minAdSpend: '720.00',
      ),
      AgencyService.create(
        name: 'Pauta Premium (Meta + TikTok + Google)',
        description: 'Gestión full plataformas.',
        details: ['Hasta 5 objetivos/plataforma'],
        price: '1600.00',
        frequency: 'monthly',
        minAdSpend: '1200.00',
      ),
      AgencyService.create(
        name: 'Manejo LinkedIn',
        description: '4 artículos mensuales profesionales.',
        price: '1500.00',
        frequency: 'monthly',
      ),
      AgencyService.create(
        name: 'Creación Brochure',
        description: 'Brochure corporativo 12-17 páginas + PowerPoint/PDF.',
        price: '1000.00',
        frequency: 'one-time',
      ),
    ];
  }
}
