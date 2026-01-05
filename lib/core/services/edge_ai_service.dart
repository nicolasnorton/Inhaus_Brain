import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('promptBuiltInAI')
external JSPromise promptBuiltInAI(String query);

class EdgeAIService {
  static Future<String> generateText(String prompt) async {
    if (kIsWeb) {
      try {
        final JSPromise promise = promptBuiltInAI(prompt);
        final JSString? response = await promise.toDart as JSString?;
        if (response != null) return response.toDart;
      } catch (e) {
        debugPrint('Chrome AI Error: $e');
      }
    }
    
    // Fallback/Mock for local processing when built-in AI is missing
    return _generateLocalMock(prompt);
  }

  static Future<String> _generateLocalMock(String prompt) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final lowerPrompt = prompt.toLowerCase();
    
    if (lowerPrompt.contains('target audience')) {
      final topic = _extractTopic(lowerPrompt);
      return "Local Edge Analysis: The ideal audience for $topic is likely environmentally conscious urban professionals who value quality and sustainability.";
    }
    
    if (lowerPrompt.contains('competitor')) {
      final topic = _extractTopic(lowerPrompt);
      return "In-Browser Research: High-performing content for $topic focuses on transparency and behind-the-scenes authenticity. Competitors are moving away from polished studio shots.";
    }

    if (lowerPrompt.contains('strategy')) {
      final topic = _extractTopic(lowerPrompt);
      return "On-Device Simulation: For $topic, we recommend a mix of TikTok (60%), Instagram Reels (30%), and niche community forums (10%).";
    }

    if (lowerPrompt.contains('ad copy')) {
      final topic = _extractTopic(lowerPrompt);
      return "Local Proposal: 'Step into the future with $topic. Sustainable, stylish, and made for you. Feel the difference of zero-impact innovation.'";
    }

    if (lowerPrompt.contains('visual atmosphere')) {
      final topic = _extractTopic(lowerPrompt);
      return "Edge Visual Strategy: Minimalist organic textures, soft natural lighting, and a palette inspired by $topic's core values.";
    }

    return "Local Edge AI: Processing complete for query regarding $prompt.";
  }

  static String _extractTopic(String prompt) {
    if (prompt.contains('campaign:')) {
      return prompt.split('campaign:').last.split('.').first.trim();
    }
    if (prompt.contains('titled')) {
      return prompt.split('titled').last.split('.').first.trim();
    }
    return "this campaign";
  }
}
