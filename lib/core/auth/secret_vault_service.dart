import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  static const String _elevenLabsKey = 'eleven_labs_api_key';
  static const String _vertexKey = 'vertex_api_key';
  static const String _difyKey = 'dify_api_key';
  static const String _notionKey = 'notion_api_key';
  static const String _slackToken = 'slack_token';
  static const String _ghlKey = 'ghl_api_key';
  static const String _ghlLocationId = 'ghl_location_id';

  /// Generic secret retrieval
  Future<String?> getSecret(String key) async {
    // 1. Environment
    final envVal = dotenv.maybeGet(key);
    if (envVal != null && envVal.isNotEmpty) return envVal;
    
    // 2. Build-time constants
    // Note: String.fromEnvironment must be const to work, so we can't use dynamic keys here.
    // Use explicit getters like getGeminiKey() for build-time keys.

    // 3. Storage
    return await _storage.read(key: key.toLowerCase());
  }

  Future<void> saveGeminiKey(String key) async => await _storage.write(key: _geminiKey, value: key);
  
  Future<String?> getGeminiKey() async {
    // Priority 1: Environment Variable (Production/CI)
    final envKey = dotenv.maybeGet('GEMINI_API_KEY');
    if (envKey != null && envKey.isNotEmpty) return envKey;

    // Priority 1.5: Build-time Constants (--dart-define)
    const buildKey = String.fromEnvironment('GEMINI_API_KEY');
    if (buildKey.isNotEmpty) return buildKey;

    // Priority 2: Secure Storage (User BYOK)
    return await _storage.read(key: _geminiKey);
  }

  Future<void> saveVeoKey(String key) async => await _storage.write(key: _veoKey, value: key);
  
  Future<String?> getVeoKey() async {
    // Priority 1: Environment Variable
    final envKey = dotenv.maybeGet('VEO_API_KEY');
    if (envKey != null && envKey.isNotEmpty) return envKey;

    // Priority 1.5: Build-time Constant
    const buildKey = String.fromEnvironment('VEO_API_KEY');
    if (buildKey.isNotEmpty) return buildKey;

    // Priority 2: Secure Storage
    return await _storage.read(key: _veoKey);
  }

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
  
  Future<String?> getOpenAIKey() async {
    final envKey = dotenv.maybeGet('OPENAI_API_KEY');
    if (envKey != null && envKey.isNotEmpty) return envKey;
    return await _storage.read(key: _openaiKey);
  }

  Future<void> saveAnthropicKey(String key) async => await _storage.write(key: _anthropicKey, value: key);
  
  Future<String?> getAnthropicKey() async {
    final envKey = dotenv.maybeGet('ANTHROPIC_API_KEY');
    if (envKey != null && envKey.isNotEmpty) return envKey;
    return await _storage.read(key: _anthropicKey);
  }

  Future<void> saveXAIKey(String key) async => await _storage.write(key: _xaiKey, value: key);
  Future<String?> getXAIKey() async => await _storage.read(key: _xaiKey);

  Future<void> saveMidjourneyKey(String key) async => await _storage.write(key: _midjourneyKey, value: key);
  Future<String?> getMidjourneyKey() async => await _storage.read(key: _midjourneyKey);

  Future<void> saveRunwayKey(String key) async => await _storage.write(key: _runwayKey, value: key);
  Future<String?> getRunwayKey() async => await _storage.read(key: _runwayKey);

  Future<void> saveElevenLabsKey(String key) async => await _storage.write(key: _elevenLabsKey, value: key);
  Future<String?> getElevenLabsKey() async => await _storage.read(key: _elevenLabsKey);

  Future<void> saveVertexKey(String key) async => await _storage.write(key: _vertexKey, value: key);
  Future<String?> getVertexKey() async {
    final envKey = dotenv.maybeGet('VERTEX_API_KEY');
    if (envKey != null && envKey.isNotEmpty) return envKey;
    
    // Priority 1.5: Build-time Constant (--dart-define)
    // WARNING: Do not use --dart-define for keys in production builds, as they can be extracted from the binary.
    const buildKey = String.fromEnvironment('VERTEX_API_KEY');
    // Prefer Firebase Auth / App Check for Vertex in prod
    if (buildKey.isNotEmpty) return buildKey;
    return await _storage.read(key: _vertexKey);
  }

  Future<void> saveDifyKey(String key) async => await _storage.write(key: _difyKey, value: key);
  
  Future<String?> getDifyKey() async {
    final envKey = dotenv.maybeGet('DIFY_API_KEY');
    if (envKey != null && envKey.isNotEmpty) return envKey;
    
    const buildKey = String.fromEnvironment('DIFY_API_KEY');
    if (buildKey.isNotEmpty) return buildKey;
    return await _storage.read(key: _difyKey);
  }
  
  Future<void> saveNotionKey(String key) async => await _storage.write(key: _notionKey, value: key);
  Future<String?> getNotionKey() async => await _storage.read(key: _notionKey);

  Future<void> saveSlackToken(String token) async => await _storage.write(key: _slackToken, value: token);
  Future<String?> getSlackToken() async => await _storage.read(key: _slackToken);

  Future<void> saveGHLKey(String key) async => await _storage.write(key: _ghlKey, value: key);
  Future<String?> getGHLKey() async => await _storage.read(key: _ghlKey);

  Future<void> saveGHLLocationId(String id) async => await _storage.write(key: _ghlLocationId, value: id);
  Future<String?> getGHLLocationId() async => await _storage.read(key: _ghlLocationId);

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
    await _storage.delete(key: _elevenLabsKey);
    await _storage.delete(key: _vertexKey);
    await _storage.delete(key: _difyKey);
  }
}

class AIKeys {
  final String? gemini;
  final String? veo;
  final String? imagen;
  final String? lyria;
  final String? banana;
  final String? openai;
  final String? anthropic;
  final String? xai;
  final String? midjourney;
  final String? runway;
  final String? vertex;
  final String? dify;

  AIKeys({
    this.gemini,
    this.veo,
    this.imagen,
    this.lyria,
    this.banana,
    this.openai,
    this.anthropic,
    this.xai,
    this.midjourney,
    this.runway,
    this.vertex,
    this.dify,
  });
}

final aiKeysProvider = FutureProvider<AIKeys>((ref) async {
  final vault = ref.read(secretVaultProvider);
  return AIKeys(
    gemini: await vault.getGeminiKey(),
    veo: await vault.getVeoKey(),
    imagen: await vault.getImagenKey(),
    lyria: await vault.getLyriaKey(),
    banana: await vault.getBananaKey(),
    openai: await vault.getOpenAIKey(),
    anthropic: await vault.getAnthropicKey(),
    xai: await vault.getXAIKey(),
    midjourney: await vault.getMidjourneyKey(),
    runway: await vault.getRunwayKey(),
    vertex: await vault.getVertexKey(),
    dify: await vault.getDifyKey(),
  );
});

final secretVaultProvider = Provider<SecretVaultService>((ref) => SecretVaultService());
