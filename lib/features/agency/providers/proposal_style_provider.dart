import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proposal_style.dart';
import '../services/proposal_style_repository.dart';

final proposalStyleRepositoryProvider = Provider<ProposalStyleRepository>((ref) {
  return ProposalStyleRepository();
});

final proposalStylesProvider = FutureProvider<List<ProposalStyle>>((ref) async {
  final repository = ref.watch(proposalStyleRepositoryProvider);
  return await repository.getStyles();
});

final proposalStyleByIdProvider = FutureProvider.family<ProposalStyle, String>((ref, id) async {
  final repository = ref.watch(proposalStyleRepositoryProvider);
  return await repository.getStyleById(id);
});

// A provider to hold the currently selected/active style for preview or editing
final selectedProposalStyleProvider = StateProvider<ProposalStyle?>((ref) => null);
