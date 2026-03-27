/// Proxy strategy — web-first cloud generation via Python proxy.
///
/// Routes through the AIProxyService to bypass CORS and App Check
/// issues on web. This is the primary path for web clients.
library;

import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_strategy.dart';
import 'ai_generation_request.dart';
import '../ai_proxy_service.dart';

class ProxyStrategy extends AIStrategy {
  static final _logger = Logger();

  @override
  String get name => 'proxy';

  @override
  bool get supportsStreaming => true;

  @override
  Future<AIGenerationResult> generate(AIGenerationRequest request, {dynamic ref}) async {
    final stopwatch = Stopwatch()..start();
    final config = request.config;
    final prompt = request.effectivePrompt;

    _logger.d('Proxy: Generating via proxy for ${config.modelId}');

    // Build multimodal prompt for proxy if needed
    dynamic proxyPrompt = prompt;
    if (request.isMultimodal) {
      final parts = <Map<String, dynamic>>[{'text': prompt}];
      if (request.imageBytes != null) {
        parts.add({
          'inlineData': {
            'data': base64Encode(request.imageBytes!),
            'mimeType': request.imageMimeType ?? 'image/jpeg',
          }
        });
      }
      if (request.audioBytes != null) {
        parts.add({
          'inlineData': {
            'data': base64Encode(request.audioBytes!),
            'mimeType': request.audioMimeType ?? 'audio/mp3',
          }
        });
      }
      if (request.videoBytes != null) {
        parts.add({
          'inlineData': {
            'data': base64Encode(request.videoBytes!),
            'mimeType': request.videoMimeType ?? 'video/mp4',
          }
        });
      }
      if (request.pdfBytes != null) {
        parts.add({
          'inlineData': {
            'data': base64Encode(request.pdfBytes!),
            'mimeType': request.pdfMimeType ?? 'application/pdf',
          }
        });
      }
      proxyPrompt = parts;
    }

    final proxyRes = await AIProxyService.generateContent(
      prompt: proxyPrompt,
      config: config,
      systemInstruction: request.systemInstruction,
      tools: request.tools,
      thinking: config.modelId.contains('thinking') ||
          config.thinkingLevel != null ||
          prompt.toLowerCase().contains('deep research'),
      audio: config.modelId.contains('lyra'),
      previousInteractionId: request.previousInteractionId,
      ref: ref is Ref ? ref : null,
    );

    stopwatch.stop();

    // Parse proxy response — extract text, function calls, and thinking separately
    String text = '';
    final functionCalls = <FunctionCallRequest>[];
    final thinkingBuffer = StringBuffer();

    final candidates = proxyRes['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates.first['content'];
      final parts = content?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        final textBuffer = StringBuffer();
        for (var part in parts) {
          if (part is Map) {
            if (part.containsKey('thought')) {
              // Capture thinking for debugging — NOT rendered to user
              thinkingBuffer.write(part['thought']);
              _logger.d('Proxy: [Thought] ${(part['thought'] as String).length} chars');
            }
            if (part.containsKey('text')) {
              textBuffer.write(part['text']);
            }
            if (part.containsKey('functionCall')) {
              // Native Gemini function call — extract as structured data
              final fc = part['functionCall'] as Map<String, dynamic>;
              functionCalls.add(FunctionCallRequest.fromJson(fc));
              _logger.d('Proxy: Extracted functionCall: ${fc['name']}');
            }
            if (part.containsKey('call')) {
              // Python proxy format function call
              final fc = part['call'] as Map<String, dynamic>;
              functionCalls.add(FunctionCallRequest.fromJson(fc));
              _logger.d('Proxy: Extracted call: ${fc['function_name'] ?? fc['name']}');
            }
            if (part.containsKey('executable_adunit')) {
              textBuffer.write(jsonEncode(part));
            }
            if (part.containsKey('executable_code')) {
              final code = part['executable_code'];
              if (code is Map) {
                textBuffer.writeln('\n```${code['language'] ?? ''}\n${code['code'] ?? ''}\n```\n');
              }
            }
            if (part.containsKey('inlineData')) {
              final mime = part['inlineData']['mimeType'];
              final data = part['inlineData']['data'];
              textBuffer.writeln('\n![Generated Image](data:$mime;base64,$data)\n');
            }
          }
        }
        text = textBuffer.toString();
        if (text.isEmpty && functionCalls.isEmpty && parts.isNotEmpty) {
           if (parts.first is Map && parts.first.containsKey('inlineData')) {
              final mime = parts.first['inlineData']['mimeType'];
              final data = parts.first['inlineData']['data'];
              text = '![Generated Image](data:$mime;base64,$data)';
           } else {
              text = jsonEncode(parts.first);
           }
        }
      }
    } else if (proxyRes['custom_type'] == 'interaction_result') {
      final outputs = proxyRes['outputs'] as List?;
      if (outputs != null && outputs.isNotEmpty) {
        final textBuffer = StringBuffer();
        for (var output in outputs) {
          if (output is Map) {
            if (output['type'] == 'thought') {
              final thought = output['thought'] ?? '';
              final summary = output['summary'] ?? '';
              thinkingBuffer.write('$thought\n$summary');
            } else if (output['type'] == 'text') {
              textBuffer.write(output['text'] ?? '');
            } else if (output['type'] == 'function_call') {
              final call = output['call'] as Map<String, dynamic>?;
              if (call != null) {
                functionCalls.add(FunctionCallRequest.fromJson(call));
              }
            }
          }
        }
        text = textBuffer.toString();
      }
    } else if (proxyRes['error'] != null) {
      text = 'Proxy Error: ${proxyRes['error']}';
    }

    // If no text AND no function calls, dump raw response for debugging
    if (text.isEmpty && functionCalls.isEmpty) {
      _logger.w('Proxy: No parseable content. Raw response: $proxyRes');
      text = jsonEncode(proxyRes);
    }

    // Strip markdown wrapper from JSON responses
    if (request.outputMode == 'json') {
      text = _stripMarkdown(text);
    }

    return AIGenerationResult(
      text: text,
      modelUsed: 'Proxy: ${config.modelId}',
      strategyUsed: name,
      latency: stopwatch.elapsed,
      confidence: 1.0,
      functionCalls: functionCalls,
      thinkingContent: thinkingBuffer.isEmpty ? null : thinkingBuffer.toString(),
    );
  }

  @override
  Stream<AIGenerationResult> generateStream(AIGenerationRequest request, {dynamic ref}) async* {
    _logger.d('Proxy: Simulating stream for ${request.config.modelId}');
    yield AIGenerationResult(
      text: 'Thinking...',
      modelUsed: 'Proxy: ${request.config.modelId}',
      strategyUsed: name,
      confidence: 0.5,
    );

    // Proxy API doesn't have true SSE endpoints yet, so we await the full response
    // and yield it to satisfy the chat UI's stream subscription.
    final result = await generate(request, ref: ref);

    if (result.text != 'No proxy content.' && !result.text.startsWith('Proxy Error:')) {
      // Clear the "Thinking..." text and yield the final payload
      yield result.copyWith(text: result.text);
    } else {
      yield result; // Yield the error
    }
  }

  static String _stripMarkdown(String text) {
    if (text.startsWith('```')) {
      final firstLineEnd = text.indexOf('\n');
      final lastBackticks = text.lastIndexOf('```');
      if (firstLineEnd != -1 && lastBackticks > firstLineEnd) {
        return text.substring(firstLineEnd + 1, lastBackticks).trim();
      }
    }
    return text.trim();
  }
}
