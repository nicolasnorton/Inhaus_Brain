import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/secret_vault_service.dart';
import 'knowledge_connector.dart';
import 'meta_social_connector.dart';
import 'linkedin_social_connector.dart';
import 'google_ads_connector.dart';

/// Registry to manage and access all active knowledge connectors.
class ConnectorRegistry {
  final SecretVaultService _vault;
  final List<KnowledgeConnector> _connectors;

  ConnectorRegistry(this._vault) : _connectors = [
    MetaSocialConnector(_vault),
    LinkedInSocialConnector(_vault),
    GoogleAdsConnector(_vault),
  ];

  /// Returns all available connectors.
  List<KnowledgeConnector> getAllConnectors() => _connectors;

  /// Gets a specific connector by its ID.
  KnowledgeConnector? getConnector(String id) {
    try {
      return _connectors.firstWhere((c) => c.connectorId == id);
    } catch (_) {
      return null;
    }
  }

  /// Refreshes all active connectors (fetches and ingests data).
  Future<void> syncAll() async {
    for (final connector in _connectors) {
      try {
        final updates = await connector.fetchRecentUpdates();
        // Integration with KnowledgeIngestionService would happen here
        // for each doc in updates -> ingestSocialData or ingestPaidMediaData
      } catch (_) {}
    }
  }
}

final connectorRegistryProvider = Provider<ConnectorRegistry>((ref) {
  final vault = ref.watch(secretVaultProvider);
  return ConnectorRegistry(vault);
});
