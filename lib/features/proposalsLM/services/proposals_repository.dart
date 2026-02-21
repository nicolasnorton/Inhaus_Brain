import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/quote.dart';
import '../models/package.dart';
import '../models/proforma_style.dart';

/// Native Firestore repository replacing the HTTP-based ProposalsService.
///
/// Collections:
///   - `cotizadorQuotes`   → Quote documents
///   - `cotizadorPackages` → Package documents
///   - `proformaStyles`    → ProformaStyle documents
class ProposalsRepository {
  final FirebaseFirestore _db;

  ProposalsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Quotes
  // ---------------------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> get _quotesCol =>
      _db.collection('cotizadorQuotes');

  Future<List<Quote>> getQuotes() async {
    final snap = await _quotesCol.orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Quote.fromJson(data);
    }).toList();
  }

  Future<Quote> createQuote(Quote quote) async {
    final docRef = await _quotesCol.add(quote.toJson());
    return quote.copyWith(id: docRef.id);
  }

  Future<void> updateQuote(Quote quote) async {
    await _quotesCol.doc(quote.id).update(quote.toJson());
  }

  Future<void> deleteQuote(String id) async {
    await _quotesCol.doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // Packages
  // ---------------------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> get _packagesCol =>
      _db.collection('cotizadorPackages');

  Future<List<Package>> getPackages() async {
    final snap = await _packagesCol
        .where('deletedAt', isNull: true)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Package.fromJson(data);
    }).toList();
  }

  Future<Package> createPackage(Package pkg) async {
    final docRef = await _packagesCol.add(pkg.toJson());
    return pkg.copyWith(id: docRef.id);
  }

  Future<void> updatePackage(Package pkg) async {
    await _packagesCol.doc(pkg.id).update(pkg.toJson());
  }

  /// Soft-delete: sets `deletedAt` + `deletedBy` without removing the document.
  Future<void> softDeletePackage(String id, String deletedBy) async {
    await _packagesCol.doc(id).update({
      'deletedAt': DateTime.now().toIso8601String(),
      'deletedBy': deletedBy,
    });
  }

  Future<List<Package>> getDeletedPackages() async {
    final snap = await _packagesCol
        .where('deletedAt', isNull: false)
        .orderBy('deletedAt', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Package.fromJson(data);
    }).toList();
  }

  Future<void> restorePackage(String id) async {
    await _packagesCol.doc(id).update({
      'deletedAt': null,
      'deletedBy': null,
    });
  }

  // ---------------------------------------------------------------------------
  // Styles
  // ---------------------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> get _stylesCol =>
      _db.collection('proformaStyles');

  Future<List<ProformaStyle>> getStyles() async {
    final snap = await _stylesCol.orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ProformaStyle.fromJson(data);
    }).toList();
  }

  Future<ProformaStyle> createStyle(ProformaStyle style) async {
    final docRef = await _stylesCol.add(style.toJson());
    return style.copyWith(id: docRef.id);
  }

  Future<void> updateStyle(ProformaStyle style) async {
    await _stylesCol.doc(style.id).update(style.toJson());
  }

  Future<void> deleteStyle(dynamic id) async {
    await _stylesCol.doc(id.toString()).delete();
  }

  // ---------------------------------------------------------------------------
  // Bridge methods — match the old ProposalsService API surface
  // so the generated views compile without rewriting.
  // ---------------------------------------------------------------------------

  /// Old API: `deletePackage(slug, masterKey, deletedBy)`
  /// We ignore the masterKey (Firestore rules handle auth) and soft-delete by doc ID.
  Future<void> deletePackage(String slugOrId, String masterKey, String deletedBy) async {
    // Try to find by slug first, fall back to direct ID
    final snap = await _packagesCol.where('slug', isEqualTo: slugOrId).limit(1).get();
    final docId = snap.docs.isNotEmpty ? snap.docs.first.id : slugOrId;
    await softDeletePackage(docId, deletedBy);
  }

  /// Old API: `createStyle(Map<String, dynamic> data)`
  Future<void> createStyleFromMap(Map<String, dynamic> data) async {
    final style = ProformaStyle(
      id: '',
      name: data['name'] as String? ?? '',
      colors: StyleColors.fromJson(data['colors'] as Map<String, dynamic>? ?? {}),
      referenceImages: (data['referenceImages'] as List<dynamic>?)?.cast<String>() ?? [],
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: DateTime.now(),
    );
    await createStyle(style);
  }

  /// Old API: `updateStyle(int id, Map<String, dynamic> data)`
  Future<void> updateStyleById(dynamic id, Map<String, dynamic> data) async {
    await _stylesCol.doc(id.toString()).update(data);
  }

  /// Old API: `tuneProforma(String text)` → AI text-to-quote.
  /// Calls the Python Cloud Function `tune_proforma`.
  Future<Map<String, dynamic>> tuneProforma(String text) async {
    final callable = FirebaseFunctions.instance.httpsCallable('tune_proforma');
    final result = await callable.call({'text': text});
    final Map<String, dynamic> data = Map<String, dynamic>.from(result.data as Map);
    
    // Ensure lists inside are properly cast
    if (data['items'] != null) {
      data['items'] = (data['items'] as List).cast<Map<String, dynamic>>();
    } else {
      data['items'] = <Map<String, dynamic>>[];
    }
    
    return data;
  }

  /// Old API: `importPackages(String text)` → AI text → packages.
  /// Calls the Python Cloud Function `import_packages`.
  Future<List<Map<String, dynamic>>> importPackages(String text) async {
    final callable = FirebaseFunctions.instance.httpsCallable('import_packages');
    final result = await callable.call({'text': text});
    final Map<String, dynamic> data = Map<String, dynamic>.from(result.data as Map);
    
    if (data['packages'] != null) {
      return (data['packages'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
