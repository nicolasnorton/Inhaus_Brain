import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:inhaus_brain/features/clients/models/client_model.dart';
import 'package:inhaus_brain/core/services/local_persistence_service.dart';

class ClientNotifier extends StateNotifier<List<Client>> {
  final LocalPersistenceService _persistenceService;
  
  ClientNotifier(this._persistenceService) : super([]) {
    _loadClients();
  }

  Future<void> _loadClients() async {
    final clients = await _persistenceService.getClients();
    if (clients.isEmpty) {
      _loadMockClients();
    } else {
      state = clients;
    }
  }

  void _loadMockClients() {
    state = [
      Client(
        id: 'client-1',
        name: 'Inhaus Studios',
        industry: 'Creative Agency',
        primaryContactEmail: 'studio@inhaus.ai',
        campaignIds: ['camp-1', 'camp-2'],
      ),
      Client(
        id: 'client-2',
        name: 'Global Tech Corp',
        industry: 'Technology',
        primaryContactEmail: 'marketing@globaltech.com',
        campaignIds: ['camp-3'],
      ),
    ];
    _persistenceService.saveClients(state);
  }

  Future<void> addClient(String name, String industry, {String? email}) async {
    final newClient = Client(
      id: const Uuid().v4(),
      name: name,
      industry: industry,
      primaryContactEmail: email,
    );
    state = [...state, newClient];
    await _persistenceService.saveClients(state);
  }

  Future<void> updateClient(Client updatedClient) async {
    state = [
      for (final client in state)
        if (client.id == updatedClient.id) updatedClient else client
    ];
    await _persistenceService.saveClients(state);
  }
  
  Future<void> deleteClient(String clientId) async {
    state = state.where((client) => client.id != clientId).toList();
    await _persistenceService.saveClients(state);
  }

  Future<void> addCampaignToClient(String clientId, String campaignId) async {
    state = [
      for (final client in state)
        if (client.id == clientId)
          client.copyWith(campaignIds: [...client.campaignIds, campaignId])
        else
          client
    ];
    await _persistenceService.saveClients(state);
  }

  Client? getClientForCampaign(String campaignId) {
    try {
      return state.firstWhere((client) => client.campaignIds.contains(campaignId));
    } catch (_) {
      return null;
    }
  }
}

final clientProvider = StateNotifierProvider<ClientNotifier, List<Client>>((ref) {
  final persistence = ref.watch(persistenceServiceProvider);
  return ClientNotifier(persistence);
});
