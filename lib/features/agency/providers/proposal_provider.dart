import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../agency/models/proposal_model.dart';
import '../../agency/services/proposal_service.dart';

// Service Provider
final proposalServiceProvider = Provider<ProposalService>((ref) {
  return ProposalService();
});

// Mock Storage for now (In-Memory)
class ProposalNotifier extends StateNotifier<List<Proposal>> {
  ProposalNotifier() : super(_getMockProposals());

  // CRUD Operations
  void addProposal(Proposal proposal) {
    state = [...state, proposal];
  }

  void updateProposal(Proposal proposal) {
    state = [
      for (final p in state)
        if (p.id == proposal.id) proposal else p
    ];
  }

  void deleteProposal(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  Proposal? getProposal(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Proposal> _getMockProposals() {
    return [
      Proposal(
        id: '1',
        title: 'Café Del Sol - Rebranding',
        clientId: '1',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        sources: [
          ProposalSource(
            id: 's1',
            proposalId: '1',
            type: ProposalSourceType.pastedText,
            name: 'Meeting Notes',
            content: 'Client wants a fresh, modern look. Target audience: Gen Z and Millennials. Budget: \$15k.',
            addedAt: DateTime.now(),
          )
        ],
      ),
       Proposal(
        id: '2',
        title: 'TechSolutions - SEO Campaign',
        clientId: '2',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        sources: [],
      ),
    ];
  }
}

final proposalsProvider = StateNotifierProvider<ProposalNotifier, List<Proposal>>((ref) {
  return ProposalNotifier();
});

// Single Proposal Provider
final proposalDetailProvider = Provider.family<Proposal?, String>((ref, id) {
  final proposals = ref.watch(proposalsProvider);
  try {
    return proposals.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});
