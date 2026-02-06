import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/proposal_model.dart';

/// Firestore proposals collection provider
final proposalsCollectionProvider = Provider<CollectionReference>((ref) {
  return FirebaseFirestore.instance.collection('proposals');
});

/// Proposals service provider
final proposalsServiceProvider = Provider<ProposalsService>((ref) {
  final collection = ref.watch(proposalsCollectionProvider);
  return ProposalsService(collection);
});

/// Service for managing proposals in Firestore
class ProposalsService {
  final CollectionReference _collection;

  ProposalsService(this._collection);

  /// Create a new proposal
  Future<void> createProposal(Proposal proposal) async {
    await _collection.doc(proposal.id).set(proposal.toJson());
  }

  /// Update an existing proposal
  Future<void> updateProposal(Proposal proposal) async {
    await _collection.doc(proposal.id).update(proposal.toJson());
  }

  /// Delete a proposal
  Future<void> deleteProposal(String proposalId) async {
    await _collection.doc(proposalId).delete();
  }

  /// Get a single proposal by ID
  Future<Proposal?> getProposal(String proposalId) async {
    final doc = await _collection.doc(proposalId).get();
    if (!doc.exists) return null;
    return Proposal.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Stream of all proposals for a client
  Stream<List<Proposal>> watchProposalsByClient(String clientId) {
    return _collection
        .where('clientId', isEqualTo: clientId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Proposal.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream of all proposals (for current user's workspace)
  Stream<List<Proposal>> watchAllProposals() {
    // TODO: Add workspace filtering when multi-tenancy is implemented
    return _collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Proposal.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }
}

/// Provider for a single proposal by ID
final proposalProvider = StreamProvider.family<Proposal?, String>((ref, proposalId) {
  final collection = ref.watch(proposalsCollectionProvider);
  return collection.doc(proposalId).snapshots().map((doc) {
    if (!doc.exists) return null;
    return Proposal.fromJson(doc.data() as Map<String, dynamic>);
  });
});

/// Provider for all proposals by client
final proposalsByClientProvider = StreamProvider.family<List<Proposal>, String>((ref, clientId) {
  final service = ref.watch(proposalsServiceProvider);
  return service.watchProposalsByClient(clientId);
});

/// Provider for all proposals
final allProposalsProvider = StreamProvider<List<Proposal>>((ref) {
  final service = ref.watch(proposalsServiceProvider);
  return service.watchAllProposals();
});

/// Selected client provider (for filtering proposals)
final selectedProposalClientProvider = StateProvider<String?>((ref) => null);
