import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../models/package.dart';
import '../models/proforma_style.dart';
import '../services/proposals_repository.dart';

// ---------------------------------------------------------------------------
// Repository Provider
// ---------------------------------------------------------------------------
final proposalsRepositoryProvider = Provider<ProposalsRepository>((ref) {
  return ProposalsRepository();
});

// ---------------------------------------------------------------------------
// Quotes
// ---------------------------------------------------------------------------
final cotizadorQuotesProvider = FutureProvider<List<Quote>>((ref) async {
  final repo = ref.read(proposalsRepositoryProvider);
  return repo.getQuotes();
});

// ---------------------------------------------------------------------------
// Packages
// ---------------------------------------------------------------------------
final cotizadorPackagesProvider = FutureProvider<List<Package>>((ref) async {
  final repo = ref.read(proposalsRepositoryProvider);
  return repo.getPackages();
});

final cotizadorDeletedPackagesProvider = FutureProvider<List<Package>>((ref) async {
  final repo = ref.read(proposalsRepositoryProvider);
  return repo.getDeletedPackages();
});

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------
final cotizadorStylesProvider = FutureProvider<List<ProformaStyle>>((ref) async {
  final repo = ref.read(proposalsRepositoryProvider);
  return repo.getStyles();
});
