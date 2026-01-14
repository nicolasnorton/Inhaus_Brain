import 'ucp_types.dart';

/// Represents a verifiable user intent in AP2.
/// Signed by the Credential Provider.
class IntentMandate {
  final String id;
  final String userId;
  final DateTime validFrom;
  final DateTime validUntil;
  final List<String> authorizedScopes; // e.g., ["payment", "shipping"]
  final String signature; 

  IntentMandate({
    required this.id,
    required this.userId,
    required this.validFrom,
    required this.validUntil,
    required this.authorizedScopes,
    required this.signature,
  });
}

/// Represents a locked cart configuration in AP2.
/// Signed by the Business/Merchant.
class CartMandate {
  final String cartId;
  final double totalAmount;
  final String currency;
  final List<String> itemIds;
  final DateTime expiration;
  final String merchantSignature;

  CartMandate({
    required this.cartId,
    required this.totalAmount,
    required this.currency,
    required this.itemIds,
    required this.expiration,
    required this.merchantSignature,
  });
}

/// A2A Discovery Object (The "Business Card" for Agents)
class AgentCard {
  final String agentId;
  final String name;
  final String description;
  final List<UCPBinding> supportedBindings;
  final List<String> supportedCapabilities; // IDs of capabilities
  final String publicKeyId;
  final String signature; // Self-signed or signed by a CA

  AgentCard({
    required this.agentId,
    required this.name,
    required this.description,
    required this.supportedBindings,
    required this.supportedCapabilities,
    required this.publicKeyId,
    required this.signature,
  });
}
