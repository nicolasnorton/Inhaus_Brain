
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ghl_service.dart';
import '../models/agency_models.dart';
import 'sales_repository.dart';
import '../../../core/auth/secret_vault_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final salesServiceProvider = Provider<SalesService>((ref) {
  return SalesService(ref);
});

class SalesService {
  final Ref _ref;
  final SalesRepository _repository;
  // GHLService is instantiated on demand to get latest keys from vault
  // or we could inject it if we had a provider for it.
  
  SalesService(this._ref) : _repository = SalesRepository();

  Stream<List<SalesLead>> getLeads() {
    return _repository.getLeadsStream();
  }

  // Create Lead: Writes to GHL -> Webhook syncs to Firestore
  Future<void> createLead(SalesLead lead) async {
    final vault = _ref.read(secretVaultProvider);
    final apiKey = await vault.getGHLKey();
    final locationId = await vault.getGHLLocationId();
    
    final ghlService = GHLService(apiKey: apiKey, locationId: locationId);

    // Map SalesLead to GHL Contact format
    final contactData = {
      'name': lead.name,
      'email': lead.email,
      'phone': lead.phone,
      'companyName': lead.company,
      'tags': ['inhaus_brain_created'],
    };

    await ghlService.createContact(contactData);
    // No need to write to Firestore manually; webhook will handle it.
  }

  Future<void> updateLeadStatus(String leadId, LeadStatus status) async {
     final vault = _ref.read(secretVaultProvider);
    final apiKey = await vault.getGHLKey();
    final locationId = await vault.getGHLLocationId();
    
    final ghlService = GHLService(apiKey: apiKey, locationId: locationId);

    // Update in GHL (using tag for now, or could map to pipeline stage)
     await ghlService.addTag(leadId, 'status_${status.name}');
     
     // Update in Firestore
     await _repository.updateLeadStatus(leadId, status);
  }

  Future<void> convertLeadToClient(SalesLead lead) async {
    // 1. Create Client Object
    // Note: We need a ClientRepository or similar to save this. 
    // For now, we'll assume direct Firestore write for simplicity or use a provider if available.
    
    final clientData = {
      'name': lead.name,
      'company': lead.company,
      'email': lead.email,
      'phone': lead.phone,
      'notes': lead.notes,
      'source': 'crm_conversion',
      'createdAt': FieldValue.serverTimestamp(),
      'ghlId': lead.id,
    };

    // 2. Save to 'clients' collection
    final clientRef = FirebaseFirestore.instance.collection('clients').doc();
    await clientRef.set(clientData);

    // 3. Mark Lead as Won
    await updateLeadStatus(lead.id, LeadStatus.closedWon);
    
    // 4. Update GHL
     final vault = _ref.read(secretVaultProvider);
    final apiKey = await vault.getGHLKey();
    final locationId = await vault.getGHLLocationId();
    final ghlService = GHLService(apiKey: apiKey, locationId: locationId);
    
    await ghlService.addTag(lead.id, 'converted_to_client');
    await ghlService.addNote(lead.id, 'Converted to Inhaus Client on ${DateTime.now()}');
  }
}
