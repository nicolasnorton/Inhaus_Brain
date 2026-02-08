import 'dart:convert';
import 'package:flutter/foundation.dart';

class JsonParserService {
  /// Extracts and parses JSON from a raw LLM response string.
  /// Handles:
  /// - Markdown code blocks (```json ... ```)
  /// - Python print() wrappers
  /// - Text prefixes/suffixes
  /// - Malformed/partial JSON candidates
  static Map<String, dynamic>? parseJson(String rawText) {
    if (rawText.isEmpty) return null;

    String cleanText = rawText.trim();

    // 1. Strip Markdown Code Blocks
    final codeBlockRegex = RegExp(r'```(?:json)?\s*(.*?)\s*```', dotAll: true);
    final match = codeBlockRegex.firstMatch(cleanText);
    if (match != null) {
      cleanText = match.group(1)!.trim();
    }

    // 2. Strip Python print() wrapper (Common Gemini artifact)
    if (cleanText.startsWith('print(') && cleanText.endsWith(')')) {
      cleanText = cleanText.substring(6, cleanText.length - 1).trim();
      // Remove surrounding quotes if present
      if ((cleanText.startsWith('"') && cleanText.endsWith('"')) ||
          (cleanText.startsWith("'") && cleanText.endsWith("'"))) {
        cleanText = cleanText.substring(1, cleanText.length - 1);
        // Unescape generic escaped quotes
        cleanText = cleanText.replaceAll(r'\"', '"');
      }
    }

    // 3. Find JSON Object using Brace Counting
    int startIndex = 0;
    while (true) {
      int jsonStart = cleanText.indexOf('{', startIndex);
      if (jsonStart == -1) break;

      int braceCount = 0;
      int jsonEnd = -1;

      for (int i = jsonStart; i < cleanText.length; i++) {
        if (cleanText[i] == '{') {
          braceCount++;
        } else if (cleanText[i] == '}') {
          braceCount--;
          if (braceCount == 0) {
            jsonEnd = i;
            break;
          }
        }
      }

      if (jsonEnd != -1) {
        String candidate = cleanText.substring(jsonStart, jsonEnd + 1);
        
        // Sanitize newlines within strings
        candidate = candidate.replaceAllMapped(RegExp(r'(?<=: ")(.*?)(?=")', dotAll: true), (m) {
          return m.group(0)?.replaceAll('\n', '\\n') ?? '';
        });

        try {
          final dynamic parsed = jsonDecode(candidate);
          if (parsed is Map<String, dynamic>) {
            return parsed;
          } else if (parsed is Map) {
             return Map<String, dynamic>.from(parsed);
          }
        } catch (e) {
          debugPrint('JsonParserService: Skipped invalid JSON candidate: $e');
        }
        // Move past this block to find next candidate
        startIndex = jsonEnd + 1;
      } else {
        // Unclosed brace, stop searching
        break;
      }
    }

    return null;
  }
}
