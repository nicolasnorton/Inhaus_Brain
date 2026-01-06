import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecretVaultService {
  final _storage = const FlutterSecureStorage();

  static const String _geminiKey = 'gemini_api_key';
  static const String _veoKey = 'veo_api_key';
  static const String _imagenKey = 'imagen_api_key';
  static const String _lyriaKey = 'lyria_api_key';
  static const String _gemmaKey = 'gemma_api_key';
  static const String _bananaKey = 'banana_api_key';

  Future<void> saveGeminiKey(String key) async => await _storage.write(key: _geminiKey, value: key);
  Future<String?> getGeminiKey() async => await _storage.read(key: _geminiKey);

  Future<void> saveVeoKey(String key) async => await _storage.write(key: _veoKey, value: key);
  Future<String?> getVeoKey() async => await _storage.read(key: _veoKey);

  Future<void> saveBananaKey(String key) async => await _storage.write(key: _bananaKey, value: key);
  Future<String?> getBananaKey() async => await _storage.read(key: _bananaKey);

  Future<void> saveImagenKey(String key) async => await _storage.write(key: _imagenKey, value: key);
  Future<String?> getImagenKey() async => await _storage.read(key: _imagenKey);

  Future<void> saveLyriaKey(String key) async => await _storage.write(key: _lyriaKey, value: key);
  Future<String?> getLyriaKey() async => await _storage.read(key: _lyriaKey);

  Future<void> saveGemmaKey(String key) async => await _storage.write(key: _gemmaKey, value: key);
  Future<String?> getGemmaKey() async => await _storage.read(key: _gemmaKey);

  Future<void> clearAllKeys() async {
    await _storage.delete(key: _geminiKey);
    await _storage.delete(key: _veoKey);
    await _storage.delete(key: _bananaKey);
    await _storage.delete(key: _imagenKey);
    await _storage.delete(key: _lyriaKey);
    await _storage.delete(key: _gemmaKey);
  }
}

final secretVaultProvider = Provider<SecretVaultService>((ref) => SecretVaultService());
