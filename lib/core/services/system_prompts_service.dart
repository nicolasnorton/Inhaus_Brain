import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static const String _storytellingPromptKey = 'storytelling_prompt';
  static const String _seoPromptKey = 'seo_prompt';
  static const String _aeoPromptKey = 'aeo_prompt';
  
  // Utility Roles
  static const String _securityPromptKey = 'security_prompt';
  static const String _dataEngPromptKey = 'data_eng_prompt';
  static const String _routerPromptKey = 'router_prompt';
  static const String _brianPromptKey = 'brian_prompt';
  static const String _designPromptKey = 'design_prompt';
  static const String _videoPromptKey = 'video_prompt';
  static const String _servicePromptKey = 'service_prompt';
  static const String _crmPromptKey = 'crm_prompt';
  static const String _csuitePromptKey = 'csuite_prompt';
  static const String _proposalSpecialistPromptKey = 'proposal_specialist_prompt';
  static const String _dataAnalystPromptKey = 'data_analyst_agent_prompt';
  static const String _intentClassifierPromptKey = 'intent_classifier_prompt';
  static const String _assistantMainPromptKey = 'assistant_main_prompt';
  static const String _proposalChatPromptKey = 'proposal_chat_prompt';
  static const String _sreOrchestratorPromptKey = 'sre_orchestrator_prompt';
  static const String _postmortemPromptKey = 'postmortem_prompt';

  // --- Default Fallback ---
  static const String _defaultFallback = "You are Brian, the Lead Agency Orchestrator. Help the user achieve their creative and strategic goals.";

  Future<void> saveResearchPrompt(String prompt) async => await _storage.write(key: _researchPromptKey, value: prompt);
  Future<String> getResearchPrompt() async => await _getPrompt(_researchPromptKey, 'assets/prompts/research.md', _defaultFallback);

  Future<void> saveCreativePrompt(String prompt) async => await _storage.write(key: _creativePromptKey, value: prompt);
  Future<String> getCreativePrompt() async => await _getPrompt(_creativePromptKey, 'assets/prompts/creative.md', _defaultFallback);

  Future<void> saveCopywriterPrompt(String prompt) async => await _storage.write(key: _copywriterPromptKey, value: prompt);
  Future<String> getCopywriterPrompt() async => await _getPrompt(_copywriterPromptKey, 'assets/prompts/copywriter.md', _defaultFallback);

  Future<void> saveDeveloperPrompt(String prompt) async => await _storage.write(key: _developerPromptKey, value: prompt);
  Future<String> getDeveloperPrompt() async => await _getPrompt(_developerPromptKey, 'assets/prompts/developer.md', _defaultFallback);

  Future<void> saveOrchestratorPrompt(String prompt) async => await _storage.write(key: _orchestratorPromptKey, value: prompt);
  Future<String> getOrchestratorPrompt() async => await _getPrompt(_orchestratorPromptKey, 'assets/prompts/orchestrator.md', _defaultFallback);

  // Agency Roles
  Future<void> saveTrendScoutPrompt(String prompt) async => await _storage.write(key: _trendScoutPromptKey, value: prompt);
  Future<String> getTrendScoutPrompt() async => await _getPrompt(_trendScoutPromptKey, 'assets/prompts/trend_scout.md', _defaultFallback);

  Future<void> saveAccountDirectorPrompt(String prompt) async => await _storage.write(key: _accountDirectorPromptKey, value: prompt);
  Future<String> getAccountDirectorPrompt() async => await _getPrompt(_accountDirectorPromptKey, 'assets/prompts/account_director.md', _defaultFallback);

  Future<void> saveStrategistPrompt(String prompt) async => await _storage.write(key: _strategistPromptKey, value: prompt);
  Future<String> getStrategistPrompt() async => await _getPrompt(_strategistPromptKey, 'assets/prompts/strategist.md', _defaultFallback);

  Future<void> saveEditorialManagerPrompt(String prompt) async => await _storage.write(key: _editorialManagerPromptKey, value: prompt);
  Future<String> getEditorialManagerPrompt() async => await _getPrompt(_editorialManagerPromptKey, 'assets/prompts/editorial_manager.md', _defaultFallback);

  Future<void> saveStorytellingPrompt(String prompt) async => await _storage.write(key: _storytellingPromptKey, value: prompt);
  Future<String> getStorytellingPrompt() async => await _getPrompt(_storytellingPromptKey, 'assets/prompts/storytelling.md', _defaultFallback);

  Future<void> saveMediaBuyerPrompt(String prompt) async => await _storage.write(key: _mediaBuyerPromptKey, value: prompt);
  Future<String> getMediaBuyerPrompt() async => await _getPrompt(_mediaBuyerPromptKey, 'assets/prompts/media_buyer.md', _defaultFallback);

  Future<void> savePerformanceAnalystPrompt(String prompt) async => await _storage.write(key: _performanceAnalystPromptKey, value: prompt);
  Future<String> getPerformanceAnalystPrompt() async => await _getPrompt(_performanceAnalystPromptKey, 'assets/prompts/performance_analyst.md', _defaultFallback);

  Future<void> saveSEOPrompt(String prompt) async => await _storage.write(key: _seoPromptKey, value: prompt);
  Future<String> getSEOPrompt() async => await _getPrompt(_seoPromptKey, 'assets/prompts/seo_agent.md', _defaultFallback);

  Future<void> saveAEOPrompt(String prompt) async => await _storage.write(key: _aeoPromptKey, value: prompt);
  Future<String> getAEOPrompt() async => await _getPrompt(_aeoPromptKey, 'assets/prompts/aeo_agent.md', _defaultFallback);

  // Utility
  Future<void> saveSecurityPrompt(String prompt) async => await _storage.write(key: _securityPromptKey, value: prompt);
  Future<String> getSecurityPrompt() async => await _getPrompt(_securityPromptKey, 'assets/prompts/security.md', _defaultFallback);

  Future<void> saveDataEngPrompt(String prompt) async => await _storage.write(key: _dataEngPromptKey, value: prompt);
  Future<String> getDataEngPrompt() async => await _getPrompt(_dataEngPromptKey, 'assets/prompts/data_engineer.md', _defaultFallback);

  Future<void> saveRouterPrompt(String prompt) async => await _storage.write(key: _routerPromptKey, value: prompt);
  Future<String> getRouterPrompt() async => await _getPrompt(_routerPromptKey, 'assets/prompts/router.md', _defaultFallback);

  Future<void> saveBrianPrompt(String prompt) async => await _storage.write(key: _brianPromptKey, value: prompt);
  Future<String> getBrianPrompt() async => await _getPrompt(_brianPromptKey, 'assets/prompts/brian.md', _defaultFallback);

  Future<void> saveDesignPrompt(String prompt) async => await _storage.write(key: _designPromptKey, value: prompt);
  Future<String> getDesignPrompt() async => await _getPrompt(_designPromptKey, 'assets/prompts/design.md', _defaultFallback);

  Future<void> saveVideoPrompt(String prompt) async => await _storage.write(key: _videoPromptKey, value: prompt);
  Future<String> getVideoPrompt() async => await _getPrompt(_videoPromptKey, 'assets/prompts/video.md', _defaultFallback);

  Future<void> saveServicePrompt(String prompt) async => await _storage.write(key: _servicePromptKey, value: prompt);
  Future<String> getServicePrompt() async => await _getPrompt(_servicePromptKey, 'assets/prompts/service.md', _defaultFallback);

  Future<void> saveCRMPrompt(String prompt) async => await _storage.write(key: _crmPromptKey, value: prompt);
  Future<String> getCRMPrompt() async => await _getPrompt(_crmPromptKey, 'assets/prompts/crm.md', _defaultFallback);

  Future<void> saveCSuitePrompt(String prompt) async => await _storage.write(key: _csuitePromptKey, value: prompt);
  Future<String> getCSuitePrompt() async => await _getPrompt(_csuitePromptKey, 'assets/prompts/csuite.md', _defaultFallback);

  Future<void> saveProposalSpecialistPrompt(String prompt) async => await _storage.write(key: _proposalSpecialistPromptKey, value: prompt);
  Future<String> getProposalSpecialistPrompt() async => await _getPrompt(_proposalSpecialistPromptKey, 'assets/prompts/proposal_specialist.md', _defaultFallback);

  Future<void> saveProposalChatPrompt(String prompt) async => await _storage.write(key: _proposalChatPromptKey, value: prompt);
  Future<String> getProposalChatPrompt() async => await _getPrompt(_proposalChatPromptKey, 'assets/prompts/proposal_chat.md', _defaultFallback);

  Future<void> saveDataAnalystPrompt(String prompt) async => await _storage.write(key: _dataAnalystPromptKey, value: prompt);
  Future<String> getDataAnalystPrompt() async => await _getPrompt(_dataAnalystPromptKey, 'assets/prompts/data_analyst.md', _defaultFallback);

  Future<void> saveIntentClassifierPrompt(String prompt) async => await _storage.write(key: _intentClassifierPromptKey, value: prompt);
  Future<String> getIntentClassifierPrompt() async => await _getPrompt(_intentClassifierPromptKey, 'assets/prompts/intent_classifier.md', _defaultFallback);

  Future<void> saveAssistantMainPrompt(String prompt) async => await _storage.write(key: _assistantMainPromptKey, value: prompt);
  Future<String> getAssistantMainPrompt() async => await _getPrompt(_assistantMainPromptKey, 'assets/prompts/assistant_main.md', _defaultFallback);

  Future<void> saveSreOrchestratorPrompt(String prompt) async => await _storage.write(key: _sreOrchestratorPromptKey, value: prompt);
  Future<String> getSreOrchestratorPrompt() async => await _getPrompt(_sreOrchestratorPromptKey, 'assets/prompts/sre_orchestrator.md', _defaultFallback);

  Future<void> savePostmortemPrompt(String prompt) async => await _storage.write(key: _postmortemPromptKey, value: prompt);
  Future<String> getPostmortemPrompt() async => await _getPrompt(_postmortemPromptKey, 'assets/prompts/postmortem.md', _defaultFallback);

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
      case MessageSender.storytellingAgent: basePrompt = await getStorytellingPrompt(); break;
      case MessageSender.mediaBuyerAgent: basePrompt = await getMediaBuyerPrompt(); break;
      case MessageSender.performanceAnalystAgent: basePrompt = await getPerformanceAnalystPrompt(); break;
      case MessageSender.securityAgent: basePrompt = await getSecurityPrompt(); break;
      case MessageSender.dataEngineerAgent: basePrompt = await getDataEngPrompt(); break;
      case MessageSender.routerAgent: basePrompt = await getRouterPrompt(); break;
      case MessageSender.designAgent: basePrompt = await getDesignPrompt(); break;
      case MessageSender.videoProductionAgent: basePrompt = await getVideoPrompt(); break;
      case MessageSender.customerServiceAgent: basePrompt = await getServicePrompt(); break;
      case MessageSender.crmAgent: basePrompt = await getCRMPrompt(); break;
      case MessageSender.cSuiteAdvisorAgent: basePrompt = await getCSuitePrompt(); break;
      case MessageSender.seoAgent: basePrompt = await getSEOPrompt(); break;
      case MessageSender.aeoAgent: basePrompt = await getAEOPrompt(); break;
      case MessageSender.proposalSpecialistAgent: basePrompt = await getProposalSpecialistPrompt(); break;
      case MessageSender.reportsAgent: basePrompt = await getDataAnalystPrompt(); break;
      case MessageSender.sreOrchestratorAgent: basePrompt = await getSreOrchestratorPrompt(); break;
      case MessageSender.postmortemAgent: basePrompt = await getPostmortemPrompt(); break;
      case MessageSender.system: basePrompt = await getBrianPrompt(); break;
      default: basePrompt = "";
    }

    if (_skillDiscoveryService != null && basePrompt.isNotEmpty) {
      final skillsXml = _skillDiscoveryService.generateAvailableSkillsXml();
      if (skillsXml.isNotEmpty) {
        basePrompt += "\n\nAvailable Skills:\n$skillsXml";
      }
    }
    
    return basePrompt;
  }

  Future<void> savePromptForSender(MessageSender sender, String prompt) async {
    switch (sender) {
      case MessageSender.researchAgent: await saveResearchPrompt(prompt); break;
      case MessageSender.creativeAgent: await saveCreativePrompt(prompt); break;
      case MessageSender.copywriterAgent: await saveCopywriterPrompt(prompt); break;
      case MessageSender.developerAgent: await saveDeveloperPrompt(prompt); break;
      case MessageSender.orchestratorAgent: await saveOrchestratorPrompt(prompt); break;
      case MessageSender.trendScoutAgent: await saveTrendScoutPrompt(prompt); break;
      case MessageSender.accountDirectorAgent: await saveAccountDirectorPrompt(prompt); break;
      case MessageSender.strategistAgent: await saveStrategistPrompt(prompt); break;
      case MessageSender.editorialManagerAgent: await saveEditorialManagerPrompt(prompt); break;
      case MessageSender.storytellingAgent: await saveStorytellingPrompt(prompt); break;
      case MessageSender.mediaBuyerAgent: await saveMediaBuyerPrompt(prompt); break;
      case MessageSender.performanceAnalystAgent: await savePerformanceAnalystPrompt(prompt); break;
      case MessageSender.securityAgent: await saveSecurityPrompt(prompt); break;
      case MessageSender.dataEngineerAgent: await saveDataEngPrompt(prompt); break;
      case MessageSender.routerAgent: await saveRouterPrompt(prompt); break;
      case MessageSender.designAgent: await saveDesignPrompt(prompt); break;
      case MessageSender.videoProductionAgent: await saveVideoPrompt(prompt); break;
      case MessageSender.customerServiceAgent: await saveServicePrompt(prompt); break;
      case MessageSender.crmAgent: await saveCRMPrompt(prompt); break;
      case MessageSender.cSuiteAdvisorAgent: await saveCSuitePrompt(prompt); break;
      case MessageSender.seoAgent: await saveSEOPrompt(prompt); break;
      case MessageSender.aeoAgent: await saveAEOPrompt(prompt); break;
      case MessageSender.proposalSpecialistAgent: await saveProposalSpecialistPrompt(prompt); break;
      case MessageSender.reportsAgent: await saveDataAnalystPrompt(prompt); break;
      case MessageSender.sreOrchestratorAgent: await saveSreOrchestratorPrompt(prompt); break;
      case MessageSender.postmortemAgent: await savePostmortemPrompt(prompt); break;
      default: break;
    }
  }

  // Helper
  Future<String> _getPrompt(String storageKey, String assetPath, String fallback) async {
    final stored = await _storage.read(key: storageKey);
    
    // Bypass logic: If stored prompt contains maintenance keywords, ignore it and load from assets
    if (stored != null) {
      final lowers = stored.toLowerCase();
      if (lowers.contains('maintenance') || 
          lowers.contains('unavailable') || 
          lowers.contains('offline') || 
          lowers.contains('mantenimiento') || 
          lowers.contains('desactivado') || 
          lowers.contains('deshabilitado') || 
          lowers.contains('fuera de servicio')) {
        debugPrint('⚠️ SystemPromptsService: Stored prompt for $storageKey contains maintenance/offline guard. Bypassing storage.');
      } else {
        return stored;
      }
    }
    
    try {
      final content = await rootBundle.loadString(assetPath);
      // Safeguard against HTML fallback (index.html) served by hosting for missing assets
      if (content.trim().startsWith('<!DOCTYPE') || content.trim().startsWith('<html')) {
        debugPrint('⚠️ SystemPromptsService: Detected HTML content for asset $assetPath. Using fallback.');
        return fallback;
      }
      return content;
    } catch (e) {
      debugPrint('⚠️ SystemPromptsService: Failed to load asset $assetPath: $e. Using fallback.');
      return fallback;
    }
  }
}

final systemPromptsProvider = Provider<SystemPromptsService>((ref) {
  final skillService = ref.watch(skillDiscoveryServiceProvider);
  return SystemPromptsService(skillService);
});
