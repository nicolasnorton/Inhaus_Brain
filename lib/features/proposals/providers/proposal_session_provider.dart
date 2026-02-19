import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proposal_model.dart';
import '../../agency/models/agency_service_model.dart';
import '../../agency/providers/service_catalog_riverpod_provider.dart';
import 'proposals_provider.dart';

/// State for the active proposal session
class ProposalSessionState {
  final Proposal proposal;
  final List<AgencyService> selectedServices;
  final bool isLoading;
  final String? error;

  ProposalSessionState({
    required this.proposal,
    this.selectedServices = const [],
    this.isLoading = false,
    this.error,
  });

  double get subtotal => selectedServices.fold(0, (sum, item) => sum + item.basePrice);
  double get discountAmount => subtotal * (proposal.discount / 100);
  double get baseAmount => subtotal - discountAmount;
  double get ivaAmount => proposal.applyIva ? baseAmount * 0.15 : 0;
  double get total => baseAmount + ivaAmount;

  ProposalSessionState copyWith({
    Proposal? proposal,
    List<AgencyService>? selectedServices,
    bool? isLoading,
    String? error,
  }) {
    return ProposalSessionState(
      proposal: proposal ?? this.proposal,
      selectedServices: selectedServices ?? this.selectedServices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing the proposal session
class ProposalSessionNotifier extends StateNotifier<ProposalSessionState?> {
  final Ref _ref;

  ProposalSessionNotifier(this._ref) : super(null);

  /// Load a proposal session
  Future<void> loadProposal(Proposal proposal) async {
    state = ProposalSessionState(proposal: proposal, isLoading: true);
    
    try {
      // Resolve service IDs to actual services from the catalog
      final catalog = await _ref.read(serviceCatalogProvider.future);
      List<AgencyService> services = [];
      if (catalog != null) {
        services = proposal.serviceIds
            .map((id) {
              try {
                return catalog.services.firstWhere((s) => s.id == id);
              } catch (_) {
                return null;
              }
            })
            .whereType<AgencyService>()
            .toList();
      }
      
      state = state?.copyWith(
        selectedServices: services,
        isLoading: false,
      );
    } catch (e) {
      state = state?.copyWith(
        isLoading: false,
        error: "Failed to load services: $e",
      );
    }
  }

  /// Set the client name
  void setClientName(String name) {
    if (state == null) return;
    state = state!.copyWith(
      proposal: state!.proposal.copyWith(clientName: name),
    );
  }

  /// Add a service to the session
  void addService(AgencyService service) {
    if (state == null) return;
    
    if (state!.selectedServices.any((s) => s.id == service.id)) return;
    
    final newServices = [...state!.selectedServices, service];
    final newServiceIds = newServices.map((s) => s.id).toList();
    
    state = state!.copyWith(
      selectedServices: newServices,
      proposal: state!.proposal.copyWith(serviceIds: newServiceIds),
    );
  }

  /// Remove a service from the session
  void removeService(String serviceId) {
    if (state == null) return;
    
    final newServices = state!.selectedServices.where((s) => s.id != serviceId).toList();
    final newServiceIds = newServices.map((s) => s.id).toList();
    
    state = state!.copyWith(
      selectedServices: newServices,
      proposal: state!.proposal.copyWith(serviceIds: newServiceIds),
    );
  }

  /// Set discount percentage
  void setDiscount(double discount) {
    if (state == null) return;
    state = state!.copyWith(
      proposal: state!.proposal.copyWith(discount: discount),
    );
  }

  /// Toggle IVA
  void setIva(bool applyIva) {
    if (state == null) return;
    state = state!.copyWith(
      proposal: state!.proposal.copyWith(applyIva: applyIva),
    );
  }

  /// Save the session to Firestore
  Future<void> saveSession() async {
    if (state == null) return;
    
    state = state!.copyWith(isLoading: true);
    try {
      await _ref.read(proposalsServiceProvider).updateProposal(state!.proposal);
      state = state!.copyWith(isLoading: false);
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: "Failed to save: $e",
      );
    }
  }

  /// Clear the session
  void clear() {
    state = null;
  }
}

/// Provider for the active proposal session
final proposalSessionProvider = StateNotifierProvider<ProposalSessionNotifier, ProposalSessionState?>((ref) {
  return ProposalSessionNotifier(ref);
});
