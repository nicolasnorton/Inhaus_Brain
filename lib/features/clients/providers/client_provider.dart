import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../clients/models/client_model.dart';
import '../../clients/models/client_contact_model.dart';
import '../../clients/services/client_repository.dart';
import '../../../features/knowledge/providers/knowledge_service_providers.dart';

// State class to hold list of clients and the currently selected one
class ClientState {
  final List<Client> clients;
  final String? selectedClientId;
  final bool isLoading;
  final String? error;

  ClientState({
    this.clients = const [],
    this.selectedClientId,
    this.isLoading = false,
    this.error,
  });

  Client? get selectedClient {
    if (selectedClientId == null) return null;
    try {
      return clients.firstWhere((c) => c.id == selectedClientId);
    } catch (_) {
      return null;
    }
  }

  ClientState copyWith({
    List<Client>? clients,
    Object? selectedClientId = _undefined,
    bool? isLoading,
    String? error,
  }) {
    return ClientState(
      clients: clients ?? this.clients,
      selectedClientId: selectedClientId == _undefined ? this.selectedClientId : (selectedClientId as String?),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

const Object _undefined = Object();

class ClientNotifier extends StateNotifier<ClientState> {
  final ClientRepository _repository;
  final Ref _ref;

  ClientNotifier(this._repository, this._ref) : super(ClientState()) {
    _init();
  }

  void _init() {
    // Listen to real-time stream of clients from Firestore
    _repository.streamClients().listen((clients) {
      state = state.copyWith(clients: clients, isLoading: false);
    }, onError: (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    });
  }

  void selectClient(String? clientId) {
    state = state.copyWith(selectedClientId: clientId);
  }

  Future<void> addClient({
    required String name,
    required ClientType clientType,
    required String industry,
    String? email,
    String? website,
    String? address,
    String? fiscalAddress,
    String? size,
    String? description,
    String? legalName,
    String? taxId,
    String? profession,
    String? personalTaxId,
    String? portfolioUrl,
    String? linkedinUrl,
    DateTime? birthDate,
  }) async {
    final newClient = Client(
      id: const Uuid().v4(),
      name: name,
      clientType: clientType,
      industry: industry,
      primaryContactEmail: email,
      website: website,
      address: address,
      fiscalAddress: fiscalAddress,
      size: size,
      description: description,
      legalName: legalName,
      taxId: taxId,
      profession: profession,
      personalTaxId: personalTaxId,
      portfolioUrl: portfolioUrl,
      linkedinUrl: linkedinUrl,
      birthDate: birthDate,
    );
    
    // Optimistic update not strictly needed with stream, but good for responsiveness if stream is slow
    // state = state.copyWith(isLoading: true); 
    
    await _repository.createClient(newClient);
    _ref.read(knowledgeIngestionServiceProvider).ingestClient(newClient);
  }

  Future<void> updateClient(Client updatedClient) async {
    await _repository.updateClient(updatedClient);
  }
  
  Future<void> deleteClient(String clientId) async {
    await _repository.deleteClient(clientId);
    if (state.selectedClientId == clientId) {
      state = state.copyWith(selectedClientId: null); // Clear selection if deleted
    }
  }

  Future<void> addCampaignToClient(String clientId, String campaignId) async {
    final client = state.clients.firstWhere((c) => c.id == clientId);
    final updated = client.copyWith(campaignIds: [...client.campaignIds, campaignId]);
    await _repository.updateClient(updated);
  }

  Future<void> addClientContact(String clientId, String firstName, String lastName, String email, String role, {String accessLevel = 'viewer', String? phoneNumber}) async {
    final contact = ClientContact(
      id: const Uuid().v4(),
      clientId: clientId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: role,
      accessLevel: accessLevel,
      phoneNumber: phoneNumber,
    );
    
    final client = state.clients.firstWhere((c) => c.id == clientId);
    final updated = client.copyWith(contacts: [...client.contacts, contact]);
    await _repository.updateClient(updated);
  }

  Client? getClientForCampaign(String campaignId) {
    try {
      return state.clients.firstWhere((client) => client.campaignIds.contains(campaignId));
    } catch (_) {
      return null;
    }
  }
}

// Provider definition
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository();
});

final clientProvider = StateNotifierProvider<ClientNotifier, ClientState>((ref) {
  final repo = ref.watch(clientRepositoryProvider);
  return ClientNotifier(repo, ref);
});

// Helper provider for easier access to the selected client
final selectedClientProvider = Provider<Client?>((ref) {
  return ref.watch(clientProvider).selectedClient;
});
