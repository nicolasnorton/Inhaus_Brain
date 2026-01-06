import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemPromptsService {
  final _storage = const FlutterSecureStorage();

  static const String _researchPromptKey = 'research_prompt';
  static const String _creativePromptKey = 'creative_prompt';
  static const String _copywriterPromptKey = 'copywriter_prompt';
  static const String _developerPromptKey = 'developer_prompt';
  static const String _orchestratorPromptKey = 'orchestrator_prompt'; 

  // --- Original (Default) Master Prompts ---
  static const String originalResearchPrompt = """
You are the Inhaus Brain Research Agent. 
Your goal is to perform deep market analysis, competitor scraping, and trend forecasting.
Be analytical, precise, and provide data-driven insights. 
Always look for the 'winning patterns' in the data.
""";

  static const String originalCreativePrompt = """
You are the Inhaus Brain Creative Agent.
Your goal is to generate visual concepts, moodboards, and art direction for campaigns.
Be visionary, aesthetic-focused, and translate business goals into stunning visuals.
Focus on 'premium branding' and 'dynamic storytelling'.
""";

  static const String originalCopywriterPrompt = """
You are the Inhaus Brain Copywriting Agent.
Your goal is to write high-converting copy for social media, ads, and landing pages.
Use a tone that is professional yet engaging.
Focus on clear calls-to-action and emotional resonance.
""";

  static const String originalDeveloperPrompt = """
You are the Inhaus Brain Developer Agent.
Your goal is to help with technical implementation, Flutter code generation, and Gen UI concepts.
Provide clean, idiomatic code and follow modern design principles.
""";

  static const String originalOrchestratorPrompt = """
You are the Inhaus Brain Orchestrator.
Your goal is to review and audit the outputs of all other agents.
Ensure brand consistency, strategic alignment, and quality control before human review.
""";

  Future<void> saveResearchPrompt(String prompt) async => await _storage.write(key: _researchPromptKey, value: prompt);
  Future<String> getResearchPrompt() async {
    final stored = await _storage.read(key: _researchPromptKey);
    if (stored != null) return stored;
    try {
      return await rootBundle.loadString('assets/prompts/research.md');
    } catch (_) {
      return originalResearchPrompt;
    }
  }

  Future<void> saveCreativePrompt(String prompt) async => await _storage.write(key: _creativePromptKey, value: prompt);
  Future<String> getCreativePrompt() async {
    final stored = await _storage.read(key: _creativePromptKey);
    if (stored != null) return stored;
    try {
      return await rootBundle.loadString('assets/prompts/creative.md');
    } catch (_) {
      return originalCreativePrompt;
    }
  }

  Future<void> saveCopywriterPrompt(String prompt) async => await _storage.write(key: _copywriterPromptKey, value: prompt);
  Future<String> getCopywriterPrompt() async {
    final stored = await _storage.read(key: _copywriterPromptKey);
    if (stored != null) return stored;
    try {
      return await rootBundle.loadString('assets/prompts/copywriter.md');
    } catch (_) {
      return originalCopywriterPrompt;
    }
  }

  Future<void> saveDeveloperPrompt(String prompt) async => await _storage.write(key: _developerPromptKey, value: prompt);
  Future<String> getDeveloperPrompt() async {
    final stored = await _storage.read(key: _developerPromptKey);
    if (stored != null) return stored;
    try {
      return await rootBundle.loadString('assets/prompts/developer.md');
    } catch (_) {
      return originalDeveloperPrompt;
    }
  }

  Future<void> saveOrchestratorPrompt(String prompt) async => await _storage.write(key: _orchestratorPromptKey, value: prompt);
  Future<String> getOrchestratorPrompt() async {
    final stored = await _storage.read(key: _orchestratorPromptKey);
    if (stored != null) return stored;
    try {
      return await rootBundle.loadString('assets/prompts/orchestrator.md');
    } catch (_) {
      return originalOrchestratorPrompt;
    }
  }
}

final systemPromptsProvider = Provider<SystemPromptsService>((ref) => SystemPromptsService());
