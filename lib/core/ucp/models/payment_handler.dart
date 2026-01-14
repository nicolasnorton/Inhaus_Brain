import 'ucp_types.dart';

/// Request to tokenize a raw credential
class UCPTokenizationRequest {
  final String pan;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final String holderName;
  final String currency;

  UCPTokenizationRequest({
    required this.pan,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.holderName,
    required this.currency,
  });
}

/// Response from a tokenizer
class UCPTokenizationResponse {
  final String token;
  final String last4;
  final String cardBrand;
  final String? fingerprint;

  UCPTokenizationResponse({
    required this.token,
    required this.last4,
    required this.cardBrand,
    this.fingerprint,
  });
}

/// A credential that has been encrypted for transmission
class EncryptedCredential {
  final String encryptedData;
  final String keyId;
  final String version;

  EncryptedCredential({
    required this.encryptedData,
    required this.keyId,
    required this.version,
  });
}

abstract class UCPPaymentHandler {
  Future<UCPTokenizationResponse> tokenize(UCPTokenizationRequest request);
  Future<EncryptedCredential> encryptCredential(UCPTokenizationRequest request);
}
