import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/client_model.dart';

class ClientNotifier extends StateNotifier<List<Client>> {
  ClientNotifier() : super([]) {
    _loadMockClients();
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
  }

  void addClient(String name, String industry, {String? email}) {
    final newClient = Client(
      id: const Uuid().v4(),
      name: name,
      industry: industry,
      primaryContactEmail: email,
    );
    state = [...state, newClient];
  }

  void updateClient(Client updatedClient) {
    state = [
      for (final client in state)
        if (client.id == updatedClient.id) updatedClient else client
    ];
  }

  void addCampaignToClient(String clientId, String campaignId) {
    state = [
      for (final client in state)
        if (client.id == clientId)
          client.copyWith(campaignIds: [...client.campaignIds, campaignId])
        else
          client
    ];
  }

  Client? getClientForCampaign(String campaignId) {
    try {
      return state.firstWhere((client) => client.campaignIds.contains(campaignId));
    } catch (_) {
      return null;
    }
  }
}

final clientProvider = StateNotifierProvider<ClientNotifier, List<Client>>((ref) => ClientNotifier());
