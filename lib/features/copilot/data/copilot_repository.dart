import 'dart:convert';
import 'package:ag_ui/ag_ui.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VertexChatRepository {
  final String _endpoint;

  VertexChatRepository({required String endpoint}) : _endpoint = endpoint;

  Stream<BaseEvent> sendMessage(
      String text, 
      {
        List<Message> history = const [], 
        SystemMessage? systemMessage,
      List<Map<String, dynamic>> tools = const [],
      bool thinking = true, // Default to true for better reasoning
      }) async* {
    final List<Map<String, dynamic>> messages = [];
    
    if (systemMessage != null) {
      messages.add({
        'id': systemMessage.id,
        'role': 'system',
        'content': systemMessage.content,
      });
    }
    
    for (final msg in history) {
      messages.add({
        'id': msg.id,
        'role': msg.role.toString().split('.').last.toLowerCase(),
        'content': msg.content,
      });
    }
    
    messages.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'role': 'user',
      'content': text,
    });

    try {
      final client = http.Client();
      final request = http.Request('POST', Uri.parse(_endpoint));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'messages': messages,
        'tools': tools,
        'thinking': thinking, // Control thinking models
        'model': thinking ? 'gemini-2.0-flash-thinking-exp-01-21' : 'gemini-2.5-flash',
      });

      final streamedResponse = await client.send(request);
      final body = await streamedResponse.stream.bytesToString();
      
      if (streamedResponse.statusCode == 200) {
        try {
          final data = jsonDecode(body);
          if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
             final candidate = data['candidates'][0];
             final parts = candidate['content']['parts'] as List;
             
             String fullText = '';
             for (var part in parts) {
               if (part['text'] != null) {
                 fullText += part['text'];
               } else if (part['thought'] != null) {
                  // If we want to show thoughts, we can. For now, maybe just append or ignore.
                  // The UI might not handle thoughts yet.
                  // Let's ignore thoughts for now to mimic standard chat unless specifically requested.
               }
             }
             
             yield TextMessageContentEvent(
               delta: fullText,
               messageId: DateTime.now().millisecondsSinceEpoch.toString(),
             );
          }
        } catch (e) {
          yield RunErrorEvent(code: 'parse_error', message: 'Failed to parse JSON: $e');
        }
      } else {
        yield RunErrorEvent(code: streamedResponse.statusCode.toString(), message: 'Server error: $body');
      }
    } catch (e) {
      yield RunErrorEvent(code: 'error', message: e.toString());
    }
  }
}

// Global provider for VertexChatRepository
final vertexChatRepositoryProvider = Provider((ref) {
  return VertexChatRepository(
      endpoint: 'https://us-central1-inhausbrain.cloudfunctions.net/generate_content');
});

// Legacy CopilotKit provider (deprecated - use vertexChatRepositoryProvider instead)
final copilotRepositoryProvider = Provider((ref) {
  return VertexChatRepository(
      endpoint: 'https://us-central1-inhausbrain.cloudfunctions.net/generate_content');
});
