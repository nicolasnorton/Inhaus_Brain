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
  
  // Phase 35: Multi-Model Keys
  static const String _openaiKey = 'openai_api_key';
  static const String _anthropicKey = 'anthropic_api_key';
  static const String _xaiKey = 'xai_api_key';
  static const String _midjourneyKey = 'midjourney_api_key';
  static const String _runwayKey = 'runway_api_key';

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

  // New Providers
  Future<void> saveOpenAIKey(String key) async => await _storage.write(key: _openaiKey, value: key);
  Future<String?> getOpenAIKey() async => await _storage.read(key: _openaiKey);

  Future<void> saveAnthropicKey(String key) async => await _storage.write(key: _anthropicKey, value: key);
  Future<String?> getAnthropicKey() async => await _storage.read(key: _anthropicKey);

  Future<void> saveXAIKey(String key) async => await _storage.write(key: _xaiKey, value: key);
  Future<String?> getXAIKey() async => await _storage.read(key: _xaiKey);

  Future<void> saveMidjourneyKey(String key) async => await _storage.write(key: _midjourneyKey, value: key);
  Future<String?> getMidjourneyKey() async => await _storage.read(key: _midjourneyKey);

  Future<void> saveRunwayKey(String key) async => await _storage.write(key: _runwayKey, value: key);
  Future<String?> getRunwayKey() async => await _storage.read(key: _runwayKey);

  Future<void> clearAllKeys() async {
    await _storage.delete(key: _geminiKey);
    await _storage.delete(key: _veoKey);
    await _storage.delete(key: _bananaKey);
    await _storage.delete(key: _imagenKey);
    await _storage.delete(key: _lyriaKey);
    await _storage.delete(key: _gemmaKey);
    await _storage.delete(key: _openaiKey);
    await _storage.delete(key: _anthropicKey);
    await _storage.delete(key: _xaiKey);
    await _storage.delete(key: _midjourneyKey);
    await _storage.delete(key: _runwayKey);
  }
}

final secretVaultProvider = Provider<SecretVaultService>((ref) => SecretVaultService());
