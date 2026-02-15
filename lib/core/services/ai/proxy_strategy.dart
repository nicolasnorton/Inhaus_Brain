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
import '../../tokens/llm_provider.dart';

class ProxyStrategy extends AIStrategy {
  static final _logger = Logger();

  @override
  String get name => 'proxy';

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

    // Parse proxy response
    String text = 'No proxy content.';
    final candidates = proxyRes['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates.first['content'];
      final parts = content?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        final buffer = StringBuffer();
        for (var part in parts) {
          if (part is Map) {
            if (part.containsKey('thought')) {
              buffer.writeln('> *Thinking: ${part['thought']}* \n');
            }
            if (part.containsKey('text')) {
              buffer.write(part['text']);
            }
            if (part.containsKey('executable_adunit')) {
              buffer.write(jsonEncode(part));
            }
            if (part.containsKey('inlineData')) {
              // Handle Nano Banana inline images
              final mime = part['inlineData']['mimeType'];
              final data = part['inlineData']['data'];
              buffer.writeln('\n![Generated Image](data:$mime;base64,$data)\n');
            }
          }
        }
        text = buffer.toString();
        if (text.isEmpty && parts.isNotEmpty) {
           // Fallback if parts didn't match known keys but content exists
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
        final buffer = StringBuffer();
        for (var output in outputs) {
          if (output is Map) {
            if (output['type'] == 'thought') {
              final thought = output['thought'] ?? '';
              final summary = output['summary'] ?? '';
              if (thought.isNotEmpty || summary.isNotEmpty) {
                 buffer.writeln('> *Thinking: ${summary.isNotEmpty ? summary : thought}* \n');
              }
            } else if (output['type'] == 'text') {
              buffer.write(output['text'] ?? '');
            } else if (output['type'] == 'function_call') {
              buffer.writeln('\n`[Tool Call: ${output['call']?['function_name']}]`');
            }
          }
        }
        text = buffer.toString();
      }
    } else if (proxyRes['error'] != null) {
      text = 'Proxy Error: ${proxyRes['error']}';
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
    );
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
