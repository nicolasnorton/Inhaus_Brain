import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../lib/features/agency/models/agency_service_model.dart';
import '../lib/firebase_options.dart';

/// Utility script to upload the new service catalog from JSON to Firestore
/// Run with: dart run scripts/upload_service_catalog.dart
void main() async {
  print('🚀 Starting service catalog upload to Firestore...');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('✅ Firebase initialized');
  
  // Load JSON file
  final file = File('assets/data/service_catalog.json');
  if (!file.existsSync()) {
    print('❌ Error: service_catalog.json not found at assets/data/');
    exit(1);
  }
  
  final jsonString = await file.readAsString();
  final catalogJson = json.decode(jsonString) as Map<String, dynamic>;
  
  print('✅ Loaded catalog JSON with ${(catalogJson['services'] as List).length} services');
  
  // Parse into ServiceCatalog model
  final catalog = ServiceCatalog.fromJson(catalogJson);
  
  print('✅ Parsed catalog: ${catalog.name}');
  print('   - Version: ${catalog.version}');
  print('   - Services: ${catalog.services.length}');
  print('   - Packages: ${catalog.services.where((s) => s.type == ServiceType.bundle).length}');
  print('   - Individual: ${catalog.services.where((s) => s.type == ServiceType.individual).length}');
  
  // Upload to Firestore
  final firestore = FirebaseFirestore.instance;
  final catalogRef = firestore
      .collection('knowledge')
      .doc('agency_services')
      .collection('data')
      .doc('catalog');
  
  print('📤 Uploading to Firestore...');
  
  await catalogRef.set(catalog.toJson(), SetOptions(merge: false));
  
  print('✅ Successfully uploaded catalog to Firestore!');
  print('   Path: /knowledge/agency_services/data/catalog');
  print('');
  print('🎉 Done! The new INHAUS catalog is now live.');
  
  exit(0);
}
