import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecretVaultService {
  final _storage = const FlutterSecureStorage();

  static const String _geminiKey = 'gemini_api_key';
  static const String _veoKey = 'veo_api_key';
  static const String _bananaKey = 'banana_api_key';

  Future<void> saveGeminiKey(String key) async => await _storage.write(key: _geminiKey, value: key);
  Future<String?> getGeminiKey() async => await _storage.read(key: _geminiKey);

  Future<void> saveVeoKey(String key) async => await _storage.write(key: _veoKey, value: key);
  Future<String?> getVeoKey() async => await _storage.read(key: _veoKey);

  Future<void> saveBananaKey(String key) async => await _storage.write(key: _bananaKey, value: key);
  Future<String?> getBananaKey() async => await _storage.read(key: _bananaKey);

  Future<void> clearAllKeys() async {
    await _storage.delete(key: _geminiKey);
    await _storage.delete(key: _veoKey);
    await _storage.delete(key: _bananaKey);
  }
}

final secretVaultProvider = Provider<SecretVaultService>((ref) => SecretVaultService());
