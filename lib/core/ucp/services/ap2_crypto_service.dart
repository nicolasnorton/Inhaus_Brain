import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ap2_models.dart';

class AP2CryptoService {
  final _storage = const FlutterSecureStorage();
  
  // To simulate secure enclave, we use FlutterSecureStorage to keep a private key.
  // In a full biometric implementation, this would use local_auth to unlock the key.

  Future<String> _getOrGeneratePrivateKey() async {
    String? key = await _storage.read(key: 'ap2_private_key');
    if (key == null) {
      // Very basic simulation of key generation
      key = base64UrlEncode(List<int>.generate(32, (i) => DateTime.now().millisecond % 255));
      await _storage.write(key: 'ap2_private_key', value: key);
    }
    return key;
  }

  Future<IntentMandate> signIntentMandate(String userId, List<String> scopes) async {
    final privateKey = await _getOrGeneratePrivateKey();
    
    final validFrom = DateTime.now();
    final validUntil = validFrom.add(const Duration(hours: 1));
    final mandateId = 'mandate-${DateTime.now().millisecondsSinceEpoch}';
    
    final payload = {
      'id': mandateId,
      'userId': userId,
      'scopes': scopes,
      'exp': validUntil.millisecondsSinceEpoch,
    };
    
    // Create a HMAC SHA-256 signature using the simulated private key
    final hmac = Hmac(sha256, utf8.encode(privateKey));
    final digest = hmac.convert(utf8.encode(jsonEncode(payload)));
    final signature = base64UrlEncode(digest.bytes);

    return IntentMandate(
      id: mandateId,
      userId: userId,
      validFrom: validFrom,
      validUntil: validUntil,
      authorizedScopes: scopes,
      signature: signature,
    );
  }
}
