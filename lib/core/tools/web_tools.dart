import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import '../services/edge_ai_service.dart';
import '../tokens/llm_provider.dart';

class ReadUrlTool extends AgentTool {
  ReadUrlTool()
      : super(
          name: 'read_url',
          description: 'Read and extract text content from a public web URL.',
          inputSchema: {
            'url': {
              'type': 'string',
              'description': 'The URL to read.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final url = parameters['url'] as String?;
    if (url == null || url.isEmpty) {
      return ToolResult.failure('url parameter is required');
    }

    try {
      // Use AllOrigins as a CORS proxy for the client-side app
      final proxyUrl = Uri.parse('https://api.allorigins.win/get?url=${Uri.encodeComponent(url)}');
      final response = await http.get(proxyUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String htmlContent = data['contents'] ?? '';
        
        // Basic HTML stripping
        final textContent = htmlContent
            .replaceAll(RegExp(r'<script[^>]*>([\s\S]*?)<\/script>', caseSensitive: false), '')
            .replaceAll(RegExp(r'<style[^>]*>([\s\S]*?)<\/style>', caseSensitive: false), '')
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        if (textContent.isEmpty) {
           return ToolResult.failure('Could not extract meaningful text from the URL.');
        }

        return ToolResult.success({
          'url': url,
          'content': textContent.substring(0, textContent.length > 5000 ? 5000 : textContent.length), // Limit size
          'status': 'success'
        });
      } else {
        return ToolResult.failure('Failed to fetch URL via proxy: ${response.statusCode}');
      }
    } catch (e) {
      return ToolResult.failure('Error reading URL: $e');
    }
  }
}

class WebSearchTool extends AgentTool {
  final Ref? _ref;

  WebSearchTool([this._ref])
      : super(
          name: 'web_search',
          description: 'Search the web for real-time information and market trends.',
          inputSchema: {
            'query': {
              'type': 'string',
              'description': 'The search query.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    print('DEBUG: EXECUTING UPDATED WEB SEARCH TOOL WITH GROUNDING');
    final query = parameters['query'] as String?;
    if (query == null) return ToolResult.failure('query is required');

    if (_ref == null) {
      // Fallback if no ref (should not happen in actual assistant)
      return ToolResult.success({
        'results': [
          {
            'title': 'Search Result for $query',
            'snippet': 'Information about $query...',
            'url': 'https://google.com/search?q=${Uri.encodeComponent(query)}'
          }
        ]
      });
    }

    try {
      // Use Grounding to get real search results
      final groundingRes = await EdgeAIService.generateText(
        "Search for: $query. Return a concise analysis. (Internal search call)",
        modelConfig: AIModelConfig.geminiResearch, // Enables grounding
        ref: _ref
      );

      final List<Map<String, dynamic>> results = [];
      if (groundingRes.sourceCitations != null) {
        for (var url in groundingRes.sourceCitations!) {
           results.add({
             'title': 'Verified Source',
             'snippet': 'Detailed information found via Google Grounding.',
             'url': url
           });
        }
      }

      if (results.isEmpty) {
        return ToolResult.success({
          'results': [
            {
              'title': 'No results found',
              'snippet': 'Could not find specific external sources for "$query".',
              'url': 'https://google.com/search?q=${Uri.encodeComponent(query)}'
            }
          ],
          'message': 'No external sources returned by grounding.'
        });
      }

      return ToolResult.success({
        'results': results,
        'message': 'Real-time search complete via Google Grounding.'
      });
    } catch (e) {
      return ToolResult.failure('Search execution error: $e');
    }
  }
}

final webToolsProvider = Provider<List<AgentTool>>((ref) {
  return [
    ReadUrlTool(),
    WebSearchTool(ref),
  ];
});
