import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/features/clients/tools/client_tools.dart';
import 'package:inhaus_brain/features/chat/agents/base_agent.dart';
import 'package:inhaus_brain/features/chat/models/chat_models.dart';
import 'package:inhaus_brain/features/knowledge/models/knowledge_source.dart';
import 'package:inhaus_brain/core/services/edge_ai_service.dart';
import 'package:inhaus_brain/core/adk/services/adk_event_bus.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import 'package:inhaus_brain/features/campaigns/tools/campaign_tools.dart';
import 'package:inhaus_brain/features/adk/tools/adk_tools.dart';
import 'package:inhaus_brain/features/knowledge/tools/knowledge_tools.dart';
import 'package:inhaus_brain/features/chat/services/skill_discovery_service.dart';
import 'package:inhaus_brain/features/admin/tools/admin_tools.dart';
import 'package:inhaus_brain/core/ucp/services/ucp_mcp_tool.dart';
import 'package:inhaus_brain/core/mcp/tools/multimodal_tools.dart';
import 'package:inhaus_brain/features/chat/agents/agent_tool_adapter.dart';
import 'package:inhaus_brain/features/chat/agents/agency_agents.dart';

class ManagementAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.managementAgent;
  @override
  String get name => "Management Agent";
  @override
  String get systemPromptKey => "management_agent_prompt";

  @override
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
    Function(AdkEvent)? onEvent,
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    
    final finalSystemPrompt = systemPrompt ?? """
You are the Management Agent (Copilot). You have access to tools to MANAGE the entire application platform.
You can Create, Read (List), Update, and Delete the following resources:

1. **Clients**: Brand-level accounts.
2. **Projects & Tasks**: Deliverables within a client.
3. **Campaigns**: Marketing initiatives with status and assets.
4. **Apps**: Specialized AI Workflows (Pipelines).
5. **Knowledge Sources**: Data used by the brain.

### YOUR TOOLS:

#### Client Management
- list_clients()
- create_client(name, industry, email)
- update_client(clientId, name, industry, email)
- delete_client(clientId)

#### Project & Task Management
- create_project(clientId, name, description)
- update_project(projectId, name, description)
- delete_project(projectId)
- create_task(projectId, title, description)
- update_task(taskId, title, description)
- delete_task(taskId)

#### Campaign Management
- list_campaigns()
- create_campaign(title, description, clientId)
- update_campaign(campaignId, title, description, status)
- delete_campaign(campaignId)

#### App (Workflow) Management
- list_apps()
- create_app(name, description)
- update_app(appId, name, description)
- delete_app(appId)

#### Knowledge Management
- list_knowledge_sources()
- add_knowledge_source(title, content, type)
- delete_knowledge_source(sourceId)

#### Skill Management (Portable Expertise)
- activate_skill(skillName): Load full instructions for an available skill when a task matches it. Available skills are listed in the "Available Skills" section of your system prompt.
- load_skill_resource(skillName, resourcePath): Load a specific document (e.g., "references/FORMS.md") or script from an activated skill.

#### Super Admin Tools (Memory & Logs)
- read_global_memory(limit, category): Read system-wide memories from ALL agents and users. Use this to find context that other agents have saved.
- read_system_logs(limit, level): Read kernel execution logs. Use this to diagnose errors or monitor performance.

#### Universal Commerce Protocol (UCP)
- ucp_discover_businesses(query): Search for businesses and services.
- ucp_initiate_checkout(businessId, itemIds): Start a transaction.
- ucp_list_categories(): Browse commerce categories.
- ucp_list_participants(): See who is active in the network.

#### Multimodal Asset Generation
- image_generation(prompt, style): Create production-grade images.
- video_generation(prompt, duration): Generate video content.
- audio_generation(prompt, duration): Compose music or audio.
- notion_tool(action, query, pageId, parentId): Manage Notion pages and searches.
- slack_tool(action, channel, text, limit): Interact with Slack channels and messages.
- ghl_tool(action, contactData, limit): Manage Go High Level contacts and opportunities.
- gmail_tool(query): Search recent emails for client communications.
- drive_tool(fileId, query): Read content from Google Drive files or search for them.
- proposal_specialist_agent(query): Specialized agent for generating bilingual client proposals. Input should be the details of what to include in the proposal.
- generate_client_proposal(clientName, campaignId, proposalJson): Generates a professional PDF proposal for a client based on structured JSON data.

If the user request is a direct command to perform one of these actions, return a JSON object representing the tool call.
Use this EXACT format:
```json
{
  "tool": "tool_name",
  "parameters": {
     "param1": "value1"
  }
}
```
### CRITICAL RULES:
- Use "parameters" key for arguments.
- Return ONLY the JSON block for tool calls.
- If listing data, use list_clients(), list_campaigns(), etc.
- If the request is ambiguous, ask for clarification.
""";

    // 2. LLM Decision
    final result = await EdgeAIService.generateText(
      "$finalSystemPrompt\nUser Request: $userPrompt",
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
    );
    
    final text = result.text.trim();
    
    // 3. Parse and Execute Tool
    final lowerText = text.toLowerCase();
    if (lowerText.contains('```json') || lowerText.contains('{')) {
       return await _processToolCall(text, ref);
    }
    
    // If no tool call, return text
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return text;
  }
  
  Future<String> _processToolCall(String text, dynamic ref) async {
    if (ref == null) return "Error: No context provided for tool execution.";
    
    try {
      // Robust JSON extraction: Find the first { and the last }
      String jsonStr;
      if (text.contains('{') && text.contains('}')) {
        jsonStr = text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1);
      } else {
        jsonStr = text;
      }

      final Map<String, dynamic> toolCall = json.decode(jsonStr);
      final toolName = toolCall['tool'];
      
      // Support both 'parameters' and 'args' for resilience, or use root object
      final Map<String, dynamic> parameters = Map<String, dynamic>.from(
          toolCall['parameters'] ?? toolCall['args'] ?? Map<String, dynamic>.from(toolCall)..remove('tool'));
      
      final tools = await ref.read(allManagementToolsProvider.future);
      final tool = tools.firstWhere(
        (t) => t.name == toolName,
        orElse: () => throw Exception("Tool '$toolName' not found."),
      );
      
      final result = await tool.execute(parameters, ref: ref);
      
      if (result.isSuccess) {
        // If it's a list tool, we might want to format it nicely, but returning raw string/json is OK for now.
        // The LLM (if called recursively) would format it, but here we just return the output.
        // For lists, the result data usually has the list.
        if (result.data.containsKey('clients')) {
           final clients = result.data['clients'] as List;
           if (clients.isEmpty) return "No clients found.";
           return "Clients:\n${clients.map((c) => "- ${c['name']} (${c['industry']}) [ID: ${c['id']}]").join("\n")}";
        }
        
        if (result.data.containsKey('campaigns')) {
           final items = result.data['campaigns'] as List;
           if (items.isEmpty) return "No campaigns found.";
           return "Campaigns:\n${items.map((c) => "- ${c['title']} (${c['status']}) [ID: ${c['id']}]").join("\n")}";
        }

        if (result.data.containsKey('apps')) {
           final items = result.data['apps'] as List;
           if (items.isEmpty) return "No apps found.";
           return "Apps/Workflows:\n${items.map((c) => "- ${c['name']} [ID: ${c['id']}]").join("\n")}";
        }
        
        if (result.data.containsKey('sources')) {
           final items = result.data['sources'] as List;
           if (items.isEmpty) return "No knowledge sources found.";
           return "Knowledge Sources:\n${items.map((c) => "- ${c['title']} (${c['type']}) [ID: ${c['id']}]").join("\n")}";
        }
        return result.data['message'] ?? result.data.toString();
      } else {
        return "Tool Error: ${result.errorMessage}";
      }
      
    } catch (e) {
      debugPrint('ManagementAgent Tool Error: $e');
      return "Failed to process tool call '$text': $e";
    }
  }
}

final allManagementToolsProvider = FutureProvider<List<AgentTool>>((ref) async {
  final multimodal = await ref.watch(multimodalToolsProvider.future);
  
  return [
    ...ref.watch(clientToolsProvider),
    ...ref.watch(campaignToolsProvider),
    ...ref.watch(adkToolsProvider),
    ...ref.watch(knowledgeToolsProvider),
    ...ref.watch(skillToolsProvider),
    ...ref.watch(adminToolsProvider),
    ...ref.watch(ucpToolsProvider),
    ...multimodal,
    AgentToolAdapter(agent: ProposalSpecialistAgent()),
  ];
});
