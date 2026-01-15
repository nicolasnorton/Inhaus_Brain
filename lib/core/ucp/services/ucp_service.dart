import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/participant_model.dart';
import '../models/capability_model.dart';
import '../models/ucp_types.dart';
import '../models/payment_handler.dart';
import '../models/ap2_models.dart';

class UCPService {
  Future<List<Business>> discoverBusinesses(String query) async {
    // Mock discovery
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Business(
        id: 'biz-1',
        name: 'TechStore Global',
        merchantId: 'merch_123',
        capabilities: [
          CheckoutCapability(id: 'cap-checkout-1', allowsGuestCheckout: true),
          OrderCapability(id: 'cap-order-1'),
        ],
      ),
      Business(
        id: 'biz-2',
        name: 'Fashion Hub',
        merchantId: 'merch_456',
        capabilities: [
          CheckoutCapability(id: 'cap-checkout-2'),
        ],
      ),
    ];
  }

  Future<Map<String, dynamic>> initiateCheckout(Business business, List<String> itemIds) async {
    // Mock checkout initiation
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'status': UCPTransactionStatus.pending.toString(),
      'checkoutUrl': 'https://ucp.dev/checkout/mock/${business.id}',
    };
  }

  Future<UCPTransactionStatus> checkTransactionStatus(String transactionId) async {
    return UCPTransactionStatus.authorized;
  }

  Future<UCPTokenizationResponse> tokenizePayment(UCPTokenizationRequest request) async {
    // Mock tokenization
    await Future.delayed(const Duration(milliseconds: 600));
    return UCPTokenizationResponse(
      token: 'tok_${DateTime.now().millisecondsSinceEpoch}',
      last4: request.pan.substring(request.pan.length - 4),
      cardBrand: 'Visa', // Mock
    );
  }

  // --- AP2 & A2A Mock Operations ---

  Future<IntentMandate> signIntentMandate(String userId, List<String> scopes) async {
    // Mock signature creation (AP2)
    return IntentMandate(
      id: 'mandate-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      validFrom: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(hours: 1)),
      authorizedScopes: scopes,
      signature: 'mock_signature_bytes_base64',
    );
  }

  Future<bool> verifyAgentCard(AgentCard card) async {
    // Mock Agent Identity Verification (A2A)
    // In reality, this would check the signature against a registry or PKI
    await Future.delayed(const Duration(milliseconds: 300));
    return card.signature.isNotEmpty;
  }

  Future<List<UCPParticipant>> getParticipants() async {
    // Return a mix of participants for demonstration
    return [
       Business(id: 'biz-1', name: 'TechStore Global', merchantId: 'merch_123'),
       Business(id: 'biz-2', name: 'Fashion Hub', merchantId: 'merch_456'),
       PlatformAgent(id: 'agt-1', name: 'Inhaus Core Agent', version: '1.0.0'),
    ];
  }
}

final ucpServiceProvider = Provider<UCPService>((ref) => UCPService());
