import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';

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
  WebSearchTool()
      : super(
          name: 'web_search',
          description: 'Search the web for information.',
          inputSchema: {
            'query': {
              'type': 'string',
              'description': 'The search query.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final query = parameters['query'] as String?;
    if (query == null) return ToolResult.failure('query is required');

    // Without a backend or paid API, client-side search is limited.
    // However, the Assistant System Prompt should prefer built-in "Grounding" where available.
    return ToolResult.success({
      'results': [
        {
          'title': 'Limited Web Search Access',
          'snippet': 'I do not have direct independent internet access for broad searches. For fact-checking, please enable "Grounding" if available, or provide specific URLs I can read with the "read_url" tool.',
          'url': 'https://google.com/search?q=${Uri.encodeComponent(query)}'
        }
      ],
      'message': 'Web search is limited. Try to rely on my internal knowledge or provide specific URLs for me to read.'
    });
  }
}

final webToolsProvider = Provider<List<AgentTool>>((ref) {
  return [
    ReadUrlTool(),
    WebSearchTool(),
  ];
});
