import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_model.dart';
import '../../../core/services/error_service.dart';

class ClientRepository {
  final FirebaseFirestore _firestore;

  ClientRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _clients => _firestore.collection('clients');

  /// Create a new client
  Future<void> createClient(Client client) async {
    try {
      await _clients.doc(client.id).set(client.toJson());
    } catch (e, stack) {
      ErrorService.logError(e, stack, context: 'ClientRepository.createClient');
      rethrow;
    }
  }

  /// Update an existing client
  Future<void> updateClient(Client client) async {
    try {
      await _clients.doc(client.id).update(client.toJson());
    } catch (e, stack) {
      ErrorService.logError(e, stack, context: 'ClientRepository.updateClient');
      rethrow;
    }
  }

  /// Delete a client (soft delete or hard delete?)
  /// Ideally, we'd just archive, but for now hard delete or status update is fine.
  Future<void> deleteClient(String clientId) async {
    try {
      await _clients.doc(clientId).delete();
    } catch (e, stack) {
      ErrorService.logError(e, stack, context: 'ClientRepository.deleteClient');
      rethrow;
    }
  }

  /// Fetch a single client by ID
  Future<Client?> getClient(String clientId) async {
    try {
      final doc = await _clients.doc(clientId).get();
      if (!doc.exists) return null;
      return Client.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e, stack) {
      ErrorService.logError(e, stack, context: 'ClientRepository.getClient');
      rethrow;
    }
  }

  /// Stream a single client
  Stream<Client?> streamClient(String clientId) {
    return _clients.doc(clientId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Client.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  /// Fetch all clients (real-time stream)
  Stream<List<Client>> streamClients() {
    return _clients.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Client.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}
