import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientIntegrationState {
  final bool isGmailConnected;
  final bool isSlackConnected;
  final bool isNotionConnected;
  final bool isGHLConnected;

  ClientIntegrationState({
    this.isGmailConnected = false,
    this.isSlackConnected = false,
    this.isNotionConnected = false,
    this.isGHLConnected = false,
  });

  ClientIntegrationState copyWith({
    bool? isGmailConnected,
    bool? isSlackConnected,
    bool? isNotionConnected,
    bool? isGHLConnected,
  }) {
    return ClientIntegrationState(
      isGmailConnected: isGmailConnected ?? this.isGmailConnected,
      isSlackConnected: isSlackConnected ?? this.isSlackConnected,
      isNotionConnected: isNotionConnected ?? this.isNotionConnected,
      isGHLConnected: isGHLConnected ?? this.isGHLConnected,
    );
  }
}

class ClientIntegrationsNotifier extends StateNotifier<Map<String, ClientIntegrationState>> {
  ClientIntegrationsNotifier() : super({});

  void toggleIntegration(String clientId, String provider, bool status) {
    final current = state[clientId] ?? ClientIntegrationState();
    final updated = switch (provider) {
      'Gmail' => current.copyWith(isGmailConnected: status),
      'Slack' => current.copyWith(isSlackConnected: status),
      'Notion' => current.copyWith(isNotionConnected: status),
      'GoHighLevel' => current.copyWith(isGHLConnected: status),
      _ => current,
    };

    state = {
      ...state,
      clientId: updated,
    };
  }

  ClientIntegrationState getIntegrationsForClient(String clientId) {
    return state[clientId] ?? ClientIntegrationState();
  }
}

final clientIntegrationsProvider = StateNotifierProvider<ClientIntegrationsNotifier, Map<String, ClientIntegrationState>>((ref) => ClientIntegrationsNotifier());
