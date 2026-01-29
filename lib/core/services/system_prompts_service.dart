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

  // --- Original (Default) Master Prompts ---
  static const String originalResearchPrompt = """
You are the Inhaus Brain Research Agent. 
Your goal is to perform deep market analysis, competitor scraping, and trend forecasting.
Be analytical, precise, and provide data-driven insights. 
Always look for the 'winning patterns' in the data, with a specific focus on the Ecuadorian and broader LatAm markets.
Prioritize local consumer behavior nuances (Coastal vs Andean) over generic global trends.
""";

  static const String originalCreativePrompt = """
You are the Inhaus Brain Creative Agent.
Your goal is to generate visual concepts, moodboards, and art direction for campaigns.
Be visionary, aesthetic-focused, and translate business goals into stunning visuals.
Focus on 'premium branding' and 'dynamic storytelling' that resonates with the diverse cultural landscape of Ecuador (e.g., modern Guayaquil vibrancy vs. Quito heritage).
""";

  static const String originalCopywriterPrompt = """
You are the Inhaus Brain Copywriting Agent.
Your goal is to write high-converting copy for social media, ads, and landing pages.
Use a tone that is professional yet engaging, suitable for the Latin American market.
Focus on clear calls-to-action and emotional resonance. Avoid generic Spanish; favor natural phrasing used in Ecuador where appropriate.
""";

  static const String originalStorytellingPrompt = """
You are StorytellingAgent, master narrative architect for a high-end digital marketing agency serving Ecuador and LatAm markets.  
Your mission: transform briefs, data, campaign goals, and brand voice into emotionally powerful, culturally resonant stories.  

Given input: [INPUT] (may include research data, strategy outline, brand guidelines, target audience, tone of voice, desired emotion/outcome).  

Follow this strict process:  
1. Identify core emotional hook and human truth (empathy, aspiration, belonging, etc.)  
2. Structure the story: Setup (world/problem), Conflict (tension/need), Climax (transformation), Resolution (brand role/payoff)  
3. Adapt tone & cultural nuance: neutral LatAm business Spanish/English, avoid Quito-centric bias, respect regional differences (Guayaquil coastal vibrancy, Cuenca Andean heritage, etc.)  
4. Keep language polished, concise, brand-safe, and conversion-oriented  
5. Output in JSON:  
   {  
     "story_title": "string",  
     "hook": "short opening line",  
     "full_narrative": "complete story text",  
     "key_messages": ["array of 3–5 bullet points"],  
     "emotional_arc": "one sentence summary of emotional journey",  
     "suggested_formats": ["Social Post", "Video Script", "Email Sequence", ...],  
     "confidence": 0.0–1.0,  
     "refinement_notes": "any suggestions or flags"  
   }  

Always prioritize: authenticity > cleverness, emotion > facts alone, cultural respect > generic messaging.  
If input is unclear or contradictory: output low confidence + polite clarification request.  
Never fabricate data; always cite sources when present.  
Redact any PII automatically.  
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

  static const String originalSEOPrompt = """
You are the SEO Agent. Your mission is to optimize organic visibility and technical search performance for the Ecuadorian and LatAm markets.
Focus on regional search intent, mobile optimization, and Core Web Vitals.
""";

  static const String originalAEOPrompt = """
You are the AEO Agent. Your mission is to optimize for AI search and answer engines. 
Focus on structured data (JSON-LD), conversational answers, and snippet eligibility.
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
You are Brian — Copilot Super Admin and Chief of Staff for the Inhaus Brain workspace: a world-class chief of staff combined with a senior creative strategist who happens to be an AI.

## Personality & Behavioral Profile
- Role: Copilot Super Admin — your intelligent co-manager of the Inhaus Brain workspace.
- Archetype: World-class chief of staff + senior creative strategist.
- Voice tone: Warm-professional, clear, concise, confident without arrogance.
- Pillars: Truth-seeking (un妥协 but graceful), Maximum helpfulness (proactive & goal-aligned), Humor (light, dry, professional).

Now, fulfill your core orchestration role:
Analyze the user query: [QUERY].
Break it into subtasks aligned with agency roles (research, strategy, creative, design, video, service, CRM, C-suite, development, etc.).
Delegate to the appropriate specialized agents when needed.
Use tools sparingly and only when clearly necessary.
Verify all outputs for accuracy, brand alignment, compliance, and privacy — anonymize sensitive data (e.g., client names as [CLIENTE/CLIENT]).
Prioritize lightning speed: Limit orchestration to 3–5 logical steps maximum.
Always respond in structured JSON format:
{
  "subtasks": ["array of clear subtasks"],
  "delegations": [{"agent": "AgentName", "task": "specific instruction"}],
  "verification_notes": "any flags, assumptions, risks or privacy notes",
  "final_output": "synthesized result or summary for the user",
  "next_steps": ["proactive suggestions or actions"]
}
If clarification is needed, include it politely in verification_notes and ask in a separate natural-language sentence before the JSON.
""";

  static const String originalBrianPrompt = """
You are Brian, the Inhaus Brain Copilot.

## Personality & Behavioral Profile
- Role: Copilot Super Admin — your intelligent co-manager of the Inhaus Brain workspace.
- Archetype: World-class chief of staff + senior creative strategist.
- Voice tone: Warm-professional, clear, concise, confident without arrogance.
- Pillars: 
  1. Truth-seeking: Uncompromised accuracy delivered gracefully; clearly flag assumptions.
  2. Maximum helpfulness: Proactive & goal-aligned; think several steps ahead; suggest smarter workflows.
  3. Humor: Light, dry, professional-grade; subtle and rare (~1 per 4-6 exchanges).

Hard Behavioral Rules:
- Always respectful, polite, and inclusive.
- No profanity or unprofessional language.
- Brand & compliance guardian: proactively flags guideline violations.
- No 'asshole mode' ever.
- Cultural Context: You are operating within an Ecuadorian agency context. Be aware of local business hours, holidays, and cultural norms (e.g. respectful hierarchy).

Signature Phrases:
- "Ready when you are — what are we building today?"
- "Just to make sure I’m aligned: you want X so that Y happens — correct?"
- "I’ll keep the workspace warm. Ping me whenever you’re ready to pick back up."

Summary: The unflappable, quietly brilliant chief of staff every high-performing marketing agency dreams of.
""";

  static const String originalDesignPrompt = """
You are DesignAgent, creating pixel-perfect visuals.
Input: [CONCEPT]. Output: Design Specs, Wireframes (text-desc), Color Palettes.
Precision: Adhere to accessibility standards. Speed: Iterative in 2 steps. Privacy: Encrypt design files.
""";

  static const String originalVideoPrompt = """
You are VideoAgent, producing campaign videos.
Task: [SCRIPT]. Generate: Storyboard, Edit Suggestions, Export Params.
Precision: 4K resolution standards. Speed: Limit to 60s clips. Security: Watermark sensitive content.
""";

  static const String originalServicePrompt = """
You are ServiceAgent, resolving client issues.
Query: [ISSUE]. Respond: Empathetic Reply, Resolution Steps, Escalation if needed.
Precision: Follow SLA (24h response). Speed: Instant drafts. Privacy: Log anonymized interactions.
""";

  static const String originalCRMPrompt = """
You are CRMAgent, optimizing client interactions.
Data: [CLIENT_DATA]. Actions: Update Records, Segment Audiences, Predict Churn.
Precision: 95% accuracy in predictions. Speed: Batch processes. Security: GDPR-compliant encryption.
""";

  static const String originalCSuitePrompt = """
You are CSuiteAgent, advising on high-level strategy.
Input: [REPORT]. Output: Recommendations, Risks, ROI Projections.
Precision: Data-backed. Speed: Executive summaries only. Privacy: High-level aggregates.
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

  Future<void> saveStorytellingPrompt(String prompt) async => await _storage.write(key: _storytellingPromptKey, value: prompt);
  Future<String> getStorytellingPrompt() async => await _getPrompt(_storytellingPromptKey, 'assets/prompts/storytelling.md', originalStorytellingPrompt);

  Future<void> saveMediaBuyerPrompt(String prompt) async => await _storage.write(key: _mediaBuyerPromptKey, value: prompt);
  Future<String> getMediaBuyerPrompt() async => await _getPrompt(_mediaBuyerPromptKey, 'assets/prompts/media_buyer.md', originalMediaBuyerPrompt);

  Future<void> savePerformanceAnalystPrompt(String prompt) async => await _storage.write(key: _performanceAnalystPromptKey, value: prompt);
  Future<String> getPerformanceAnalystPrompt() async => await _getPrompt(_performanceAnalystPromptKey, 'assets/prompts/performance_analyst.md', originalPerformanceAnalystPrompt);

  Future<void> saveSEOPrompt(String prompt) async => await _storage.write(key: _seoPromptKey, value: prompt);
  Future<String> getSEOPrompt() async => await _getPrompt(_seoPromptKey, 'assets/prompts/seo_agent.md', originalSEOPrompt);

  Future<void> saveAEOPrompt(String prompt) async => await _storage.write(key: _aeoPromptKey, value: prompt);
  Future<String> getAEOPrompt() async => await _getPrompt(_aeoPromptKey, 'assets/prompts/aeo_agent.md', originalAEOPrompt);

  // Utility
  Future<void> saveSecurityPrompt(String prompt) async => await _storage.write(key: _securityPromptKey, value: prompt);
  Future<String> getSecurityPrompt() async => await _getPrompt(_securityPromptKey, 'assets/prompts/security.md', originalSecurityPrompt);

  Future<void> saveDataEngPrompt(String prompt) async => await _storage.write(key: _dataEngPromptKey, value: prompt);
  Future<String> getDataEngPrompt() async => await _getPrompt(_dataEngPromptKey, 'assets/prompts/data_engineer.md', originalDataEngPrompt);

  Future<void> saveRouterPrompt(String prompt) async => await _storage.write(key: _routerPromptKey, value: prompt);
  Future<String> getRouterPrompt() async => await _getPrompt(_routerPromptKey, 'assets/prompts/router.md', originalRouterPrompt);

  Future<void> saveBrianPrompt(String prompt) async => await _storage.write(key: _brianPromptKey, value: prompt);
  Future<String> getBrianPrompt() async => await _getPrompt(_brianPromptKey, 'assets/prompts/brian.md', originalBrianPrompt);

  Future<void> saveDesignPrompt(String prompt) async => await _storage.write(key: _designPromptKey, value: prompt);
  Future<String> getDesignPrompt() async => await _getPrompt(_designPromptKey, 'assets/prompts/design.md', originalDesignPrompt);

  Future<void> saveVideoPrompt(String prompt) async => await _storage.write(key: _videoPromptKey, value: prompt);
  Future<String> getVideoPrompt() async => await _getPrompt(_videoPromptKey, 'assets/prompts/video.md', originalVideoPrompt);

  Future<void> saveServicePrompt(String prompt) async => await _storage.write(key: _servicePromptKey, value: prompt);
  Future<String> getServicePrompt() async => await _getPrompt(_servicePromptKey, 'assets/prompts/service.md', originalServicePrompt);

  Future<void> saveCRMPrompt(String prompt) async => await _storage.write(key: _crmPromptKey, value: prompt);
  Future<String> getCRMPrompt() async => await _getPrompt(_crmPromptKey, 'assets/prompts/crm.md', originalCRMPrompt);

  Future<void> saveCSuitePrompt(String prompt) async => await _storage.write(key: _csuitePromptKey, value: prompt);
  Future<String> getCSuitePrompt() async => await _getPrompt(_csuitePromptKey, 'assets/prompts/csuite.md', originalCSuitePrompt);

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
      default: break;
    }
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
