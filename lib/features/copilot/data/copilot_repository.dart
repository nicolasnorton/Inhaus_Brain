import 'dart:convert';
import 'package:ag_ui/ag_ui.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CopilotRepository {
  final String _endpoint;

  CopilotRepository({required String endpoint}) : _endpoint = endpoint;

  Stream<BaseEvent> sendMessage(String text, {List<Message> history = const [], SystemMessage? systemMessage}) async* {
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
        'flatten': true, // Required for v1.x single-route requests
      });

      final streamedResponse = await client.send(request);
      
      if (streamedResponse.statusCode == 200) {
        String? currentMessageId;
        await for (final chunk in streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (chunk.startsWith('data: ')) {
            final dataStr = chunk.substring(6).trim();
            if (dataStr == '[DONE]') break;
            
            try {
              final data = jsonDecode(dataStr);
              // CopilotKit protocol: content chunks
              if (data['type'] == 'content' || data['content'] != null || data['delta'] != null) {
                final delta = data['content'] ?? data['delta'] ?? '';
                currentMessageId ??= data['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
                yield TextMessageContentEvent(
                  delta: delta,
                  messageId: currentMessageId!,
                );
              }
            } catch (_) {
              // Ignore non-json data
            }
          }
        }
      } else {
        final body = await streamedResponse.stream.bytesToString();
        yield RunErrorEvent(code: streamedResponse.statusCode.toString(), message: 'Server error: $body');
      }
    } catch (e) {
      yield RunErrorEvent(code: 'error', message: e.toString());
    }
  }
}

// Global provider for CopilotRepository
final copilotRepositoryProvider = Provider((ref) {
  return CopilotRepository(
      endpoint: 'https://us-central1-inhausbrain.cloudfunctions.net/copilotRuntime');
});
