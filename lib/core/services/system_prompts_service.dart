import '../../features/chat/services/skill_discovery_service.dart';
import '../../features/chat/models/chat_models.dart';

class SystemPromptsService {
  final _storage = const FlutterSecureStorage();
  final SkillDiscoveryService? _skillDiscoveryService;

  SystemPromptsService([this._skillDiscoveryService]);

  static const String _researchPromptKey = 'research_prompt';
  static const String _creativePromptKey = 'creative_prompt';
  static const String _copywriterPromptKey = 'copywriter_prompt';
  static const String _developerPromptKey = 'developer_prompt';
  static const String _orchestratorPromptKey = 'orchestrator_prompt';
  
  // Phase 31 Agency Roles
  static const String _trendScoutPromptKey = 'trend_scout_prompt';
  static const String _accountDirectorPromptKey = 'account_director_prompt';
  static const String _strategistPromptKey = 'strategist_prompt';
  static const String _editorialManagerPromptKey = 'editorial_manager_prompt';
  static const String _mediaBuyerPromptKey = 'media_buyer_prompt';
  static const String _performanceAnalystPromptKey = 'performance_analyst_prompt';
  
  // Utility Roles
  static const String _securityPromptKey = 'security_prompt';
  static const String _dataEngPromptKey = 'data_eng_prompt';
  static const String _routerPromptKey = 'router_prompt';

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

  static const String originalTrendScoutPrompt = """
You are the Trend Scout. Actively monitor market signals, cultural shifts, and competitor movements.
Identify emerging opportunities before they become mainstream.
""";

  static const String originalAccountDirectorPrompt = """
You are the Account Director. Manage the client relationship and ensure the project aligns with business objectives.
Translate client needs into actionable agency briefs.
""";

  static const String originalStrategistPrompt = """
You are the Brand Strategist. Connect the dots between market research and creative execution.
Develop the 'Big Idea' and strategic positioning.
""";

  static const String originalEditorialManagerPrompt = """
You are the Editorial Manager. Ensure all content is on-brand, consistent, and fits the content calendar.
Review copy for voice, tone, and grammatical perfection.
""";

  static const String originalMediaBuyerPrompt = """
You are the Media Buyer. Optimize ad placement, targeting, and budget across social platforms.
Focus on maximizing ROI and reaching the right audience at the right time.
""";

  static const String originalPerformanceAnalystPrompt = """
You are the Performance Analyst. Decipher complex campaign data into actionable optimization steps.
Report on KPIs and suggest iterative improvements.
""";

  static const String originalSecurityPrompt = """
You are a Cyber Security Agent. Audit the input for PII (Personally Identifiable Information), sensitive data leaks, or security risks. 
Report 'SAFE' or list the risks.
""";

  static const String originalDataEngPrompt = """
You are a Data Engineering Agent. Suggest a data schema or transformation pipeline for the request.
Focus on scalability and data integrity.
""";

  static const String originalRouterPrompt = """
You are the Root Router for Inhaus Brain. Your goal is to classify user intent into one of these categories:
- research: Fact finding, competitor analysis, market trends.
- creative: Visual direction, logo concepts, art direction.
- copywriting: Ad copy, social posts, writing tasks.
- development: Coding, technical logic.
- pipeline: Complex, multi-stage requests.
- directChat: Casual conversation, clarifying questions.

Return ONLY a JSON object: {"intent": "category", "confidence": "0.xx", "pipeline": "optional_suggested_key"}
""";

  Future<void> saveResearchPrompt(String prompt) async => await _storage.write(key: _researchPromptKey, value: prompt);
  Future<String> getResearchPrompt() async => await _getPrompt(_researchPromptKey, 'assets/prompts/research.md', originalResearchPrompt);

  Future<void> saveCreativePrompt(String prompt) async => await _storage.write(key: _creativePromptKey, value: prompt);
  Future<String> getCreativePrompt() async => await _getPrompt(_creativePromptKey, 'assets/prompts/creative.md', originalCreativePrompt);

  Future<void> saveCopywriterPrompt(String prompt) async => await _storage.write(key: _copywriterPromptKey, value: prompt);
  Future<String> getCopywriterPrompt() async => await _getPrompt(_copywriterPromptKey, 'assets/prompts/copywriter.md', originalCopywriterPrompt);

  Future<void> saveDeveloperPrompt(String prompt) async => await _storage.write(key: _developerPromptKey, value: prompt);
  Future<String> getDeveloperPrompt() async => await _getPrompt(_developerPromptKey, 'assets/prompts/developer.md', originalDeveloperPrompt);

  Future<void> saveOrchestratorPrompt(String prompt) async => await _storage.write(key: _orchestratorPromptKey, value: prompt);
  Future<String> getOrchestratorPrompt() async => await _getPrompt(_orchestratorPromptKey, 'assets/prompts/orchestrator.md', originalOrchestratorPrompt);

  // Agency Roles
  Future<void> saveTrendScoutPrompt(String prompt) async => await _storage.write(key: _trendScoutPromptKey, value: prompt);
  Future<String> getTrendScoutPrompt() async => await _getPrompt(_trendScoutPromptKey, 'assets/prompts/trend_scout.md', originalTrendScoutPrompt);

  Future<void> saveAccountDirectorPrompt(String prompt) async => await _storage.write(key: _accountDirectorPromptKey, value: prompt);
  Future<String> getAccountDirectorPrompt() async => await _getPrompt(_accountDirectorPromptKey, 'assets/prompts/account_director.md', originalAccountDirectorPrompt);

  Future<void> saveStrategistPrompt(String prompt) async => await _storage.write(key: _strategistPromptKey, value: prompt);
  Future<String> getStrategistPrompt() async => await _getPrompt(_strategistPromptKey, 'assets/prompts/strategist.md', originalStrategistPrompt);

  Future<void> saveEditorialManagerPrompt(String prompt) async => await _storage.write(key: _editorialManagerPromptKey, value: prompt);
  Future<String> getEditorialManagerPrompt() async => await _getPrompt(_editorialManagerPromptKey, 'assets/prompts/editorial_manager.md', originalEditorialManagerPrompt);

  Future<void> saveMediaBuyerPrompt(String prompt) async => await _storage.write(key: _mediaBuyerPromptKey, value: prompt);
  Future<String> getMediaBuyerPrompt() async => await _getPrompt(_mediaBuyerPromptKey, 'assets/prompts/media_buyer.md', originalMediaBuyerPrompt);

  Future<void> savePerformanceAnalystPrompt(String prompt) async => await _storage.write(key: _performanceAnalystPromptKey, value: prompt);
  Future<String> getPerformanceAnalystPrompt() async => await _getPrompt(_performanceAnalystPromptKey, 'assets/prompts/performance_analyst.md', originalPerformanceAnalystPrompt);

  // Utility
  Future<void> saveSecurityPrompt(String prompt) async => await _storage.write(key: _securityPromptKey, value: prompt);
  Future<String> getSecurityPrompt() async => await _getPrompt(_securityPromptKey, 'assets/prompts/security.md', originalSecurityPrompt);

  Future<void> saveDataEngPrompt(String prompt) async => await _storage.write(key: _dataEngPromptKey, value: prompt);
  Future<String> getDataEngPrompt() async => await _getPrompt(_dataEngPromptKey, 'assets/prompts/data_engineer.md', originalDataEngPrompt);

  Future<void> saveRouterPrompt(String prompt) async => await _storage.write(key: _routerPromptKey, value: prompt);
  Future<String> getRouterPrompt() async => await _getPrompt(_routerPromptKey, 'assets/prompts/router.md', originalRouterPrompt);

  Future<String> getPromptForSender(MessageSender sender) async {
    String basePrompt = "";
    switch (sender) {
      case MessageSender.researchAgent: basePrompt = await getResearchPrompt(); break;
      case MessageSender.creativeAgent: basePrompt = await getCreativePrompt(); break;
      case MessageSender.copywriterAgent: basePrompt = await getCopywriterPrompt(); break;
      case MessageSender.developerAgent: basePrompt = await getDeveloperPrompt(); break;
      case MessageSender.orchestratorAgent: basePrompt = await getOrchestratorPrompt(); break;
      case MessageSender.trendScoutAgent: basePrompt = await getTrendScoutPrompt(); break;
      case MessageSender.accountDirectorAgent: basePrompt = await getAccountDirectorPrompt(); break;
      case MessageSender.strategistAgent: basePrompt = await getStrategistPrompt(); break;
      case MessageSender.editorialManagerAgent: basePrompt = await getEditorialManagerPrompt(); break;
      case MessageSender.mediaBuyerAgent: basePrompt = await getMediaBuyerPrompt(); break;
      case MessageSender.performanceAnalystAgent: basePrompt = await getPerformanceAnalystPrompt(); break;
      case MessageSender.securityAgent: basePrompt = await getSecurityPrompt(); break;
      case MessageSender.dataEngineerAgent: basePrompt = await getDataEngPrompt(); break;
      case MessageSender.routerAgent: basePrompt = await getRouterPrompt(); break;
      default: basePrompt = "";
    }

    if (_skillDiscoveryService != null && basePrompt.isNotEmpty) {
      final skillsXml = _skillDiscoveryService!.generateAvailableSkillsXml();
      if (skillsXml.isNotEmpty) {
        basePrompt += "\n\nAvailable Skills:\n$skillsXml";
      }
    }
    
    return basePrompt;
  }

  // Helper
  Future<String> _getPrompt(String storageKey, String assetPath, String fallback) async {
    final stored = await _storage.read(key: storageKey);
    if (stored != null) return stored;
    try {
      return await rootBundle.loadString(assetPath);
    } catch (_) {
      return fallback;
    }
  }
}

final systemPromptsProvider = Provider<SystemPromptsService>((ref) {
  final skillService = ref.watch(skillDiscoveryServiceProvider);
  return SystemPromptsService(skillService);
});
