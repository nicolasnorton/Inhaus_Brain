import 'base_agent.dart';
import '../models/chat_models.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';

// 1. Client Onboarding Agent
class ClientOnboardingAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.clientOnboardingAgent;
  @override
  String get name => "Client Concierge";
  @override
  String get systemPromptKey => "onboarding_agent_prompt";

  @override
  Future<String> execute({required String userPrompt, required List<KnowledgeSource> context, String? apiKey, String? gemmaKey}) async {
    return (await EdgeAIService.generateText(
      "You are the Client Onboarding Concierge. Your goal is to welcome new clients, explain the agency workflow, and gather initial requirements. Be warm, professional, and helpful. User Input: $userPrompt",
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    )).text;
  }
}

// 2. Extractor Agent
class ExtractorAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.extractorAgent;
  @override
  String get name => "Data Extractor";
  @override
  String get systemPromptKey => "extractor_agent_prompt";

  @override
  Future<String> execute({required String userPrompt, required List<KnowledgeSource> context, String? apiKey, String? gemmaKey}) async {
    return (await EdgeAIService.generateText(
      "You are a Data Extraction Agent. Extract key entities (Dates, Names, Budget, Requirements) from the input. Return ONLY JSON format. Input: $userPrompt",
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    )).text;
  }
}

// 3. Parser Agent
class ParserAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.parserAgent;
  @override
  String get name => "Format Parser";
  @override
  String get systemPromptKey => "parser_agent_prompt";

  @override
  Future<String> execute({required String userPrompt, required List<KnowledgeSource> context, String? apiKey, String? gemmaKey}) async {
    return (await EdgeAIService.generateText(
      "You are a Parser Agent. Analyze the structure of the input and convert it into a standardized markdown table. Input: $userPrompt",
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    )).text;
  }
}

// 4. Summarizer Agent
class SummarizerAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.summarizerAgent;
  @override
  String get name => "Content Summarizer";
  @override
  String get systemPromptKey => "summarizer_agent_prompt";

  @override
  Future<String> execute({required String userPrompt, required List<KnowledgeSource> context, String? apiKey, String? gemmaKey}) async {
    return (await EdgeAIService.generateText(
      "You are a Summarizer Agent. Distill the following content into a concise 3-bullet executive summary. Input: $userPrompt",
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    )).text;
  }
}

// 5. Security Agent
class SecurityAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.securityAgent;
  @override
  String get name => "Cyber Security Guardian";
  @override
  String get systemPromptKey => "security_agent_prompt";

  @override
  Future<String> execute({required String userPrompt, required List<KnowledgeSource> context, String? apiKey, String? gemmaKey}) async {
    return (await EdgeAIService.generateText(
      "You are a Cyber Security Agent. Audit the input for PII (Personally Identifiable Information), sensitive data leaks, or security risks. Report 'SAFE' or list the risks. Input: $userPrompt",
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    )).text;
  }
}

// 6. Data Engineering Agent
class DataEngineerAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.dataEngineerAgent;
  @override
  String get name => "Data Engineer";
  @override
  String get systemPromptKey => "data_eng_agent_prompt";

  @override
  Future<String> execute({required String userPrompt, required List<KnowledgeSource> context, String? apiKey, String? gemmaKey}) async {
    return (await EdgeAIService.generateText(
      "You are a Data Engineering Agent. Suggest a data schema or transformation pipeline for the request. Input: $userPrompt",
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
    )).text;
  }
}
