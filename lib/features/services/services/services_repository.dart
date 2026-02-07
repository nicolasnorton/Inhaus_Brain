import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';
import '../models/service_enums.dart';
import 'package:uuid/uuid.dart';

class ServicesRepository {
  final FirebaseFirestore _firestore;

  ServicesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _services => _firestore.collection('services');

  Stream<List<Service>> streamServices() {
    return _services.where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromJson(doc.data())).toList();
    });
  }

  Future<void> createService(Service service) async {
    await _services.doc(service.id).set(service.toJson());
  }

  Future<void> updateService(Service service) async {
    await _services.doc(service.id).update(service.toJson());
  }

  Future<void> deleteService(String id) async {
    await _services.doc(id).update({'isActive': false});
  }

  Future<List<Service>> getServicesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _services.where(FieldPath.documentId, whereIn: ids).get();
    return snapshot.docs.map((doc) => Service.fromJson(doc.data())).toList();
  }

  Future<void> seedInitialData() async {
    final existing = await _services.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final now = DateTime.now();
    final services = [
      // RRSS Bundles
      Service(
        id: 'bundle-rrss-entrepreneur',
        name: 'Paquete Emprendedor RRSS',
        nameEs: 'Paquete Emprendedor RRSS',
        type: ServiceType.bundle,
        basePrice: 1000.0,
        deliveryCost: 650.0,
        targetMargin: 35.0,
        execution: 'Monthly management of FB/IG including ad management.',
        team: ['Social Media Manager', 'Graphic Designer'],
        deliverables: ['20 pieces monthly', '1 Reel', '2 Carousels', '4 Statics', '9 Stories', 'Monthly Report'],
        includes: ['Community Management', 'Monthly Meeting'],
        excludes: ['Ad Spend', 'Custom content production (if not hired separately)'],
        billingCycle: BillingCycle.monthly,
        createdAt: now,
        updatedAt: now,
      ),
      Service(
        id: 'bundle-rrss-starter',
        name: 'Paquete Starter RRSS',
        nameEs: 'Paquete Starter RRSS',
        type: ServiceType.bundle,
        basePrice: 1500.0,
        deliveryCost: 900.0,
        targetMargin: 40.0,
        execution: 'Standard management of FB/IG with increased content.',
        team: ['Social Media Manager', 'Senior Designer', 'Content Creator'],
        deliverables: ['30 pieces monthly', '2 Reels', '3 Carousels', '3 Statics', '16 Stories', 'Monthly Report'],
        includes: ['Community Management', 'Performance Reports'],
        excludes: ['Ad Spend'],
        billingCycle: BillingCycle.monthly,
        createdAt: now,
        updatedAt: now,
      ),
      Service(
        id: 'bundle-rrss-corporate',
        name: 'Paquete Corporativo RRSS',
        nameEs: 'Paquete Corporativo RRSS',
        type: ServiceType.bundle,
        basePrice: 2000.0,
        deliveryCost: 1100.0,
        targetMargin: 45.0,
        execution: 'Advanced management of FB/IG for corporate clients.',
        team: ['Senior SMM', 'Creative Director', 'Senior Designer'],
        deliverables: ['40 pieces monthly', '3 Reels', '3 Carousels', '5 Statics', '20 Stories', 'Bi-weekly Meetings'],
        includes: ['Strategic Planning', 'Advanced Reporting'],
        excludes: ['Ad Spend'],
        billingCycle: BillingCycle.monthly,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Individual Services
      Service(
        id: 'service-web-refresh',
        name: 'Refresh Look & Feel Web',
        nameEs: 'Refresh Look & Feel Web',
        type: ServiceType.individual,
        basePrice: 1700.0,
        deliveryCost: 1000.0,
        targetMargin: 40.0,
        execution: 'Digital renewal on existing CMS.',
        team: ['Web Designer', 'Frontend Dev'],
        deliverables: ['Redesign HOME/About/Contact', 'SEO Initial', 'Favicon', 'Newsletter Basic'],
        includes: ['CMS Training', 'Google Tools Setup'],
        excludes: ['Hosting/Domain', 'Maintenance'],
        billingCycle: BillingCycle.project,
        createdAt: now,
        updatedAt: now,
      ),
      Service(
        id: 'service-tiktok',
        name: 'Paquete TikTok',
        nameEs: 'Paquete TikTok',
        type: ServiceType.individual,
        basePrice: 900.0,
        deliveryCost: 550.0,
        targetMargin: 35.0,
        execution: 'TikTok production and management.',
        team: ['Content Creator', 'Video Editor'],
        deliverables: ['4 Reels/month', 'Props included up to \$100'],
        includes: ['Full equipment', 'Editing'],
        excludes: ['Models', 'Travel expenses'],
        billingCycle: BillingCycle.monthly,
        createdAt: now,
        updatedAt: now,
      ),
      Service(
        id: 'service-branding-logo',
        name: 'Rebranding Logo',
        nameEs: 'Rebranding Logo',
        type: ServiceType.individual,
        basePrice: 1200.0,
        deliveryCost: 600.0,
        targetMargin: 50.0,
        execution: 'Logo refresh and one-page manual.',
        team: ['Senior Designer'],
        deliverables: ['New Logo', 'Basic Manual', 'Social Media Avatars'],
        includes: ['Two revisions'],
        excludes: ['Stationery', 'Complex brand manual'],
        billingCycle: BillingCycle.project,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final service in services) {
      await createService(service);
    }
  }
}

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository();
});

final servicesProvider = StreamProvider<List<Service>>((ref) {
  return ref.watch(servicesRepositoryProvider).streamServices();
});
