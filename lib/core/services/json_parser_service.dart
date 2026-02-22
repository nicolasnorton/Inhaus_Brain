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

    // 1.5 Strip <tool_code> tags (Gemini Code Execution artifact)
    final toolCodeRegex = RegExp(r'<tool_code>\s*(.*?)\s*</tool_code>', dotAll: true);
    final toolCodeMatch = toolCodeRegex.firstMatch(cleanText);
    if (toolCodeMatch != null) {
      cleanText = toolCodeMatch.group(1)!.trim();
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

    // 3. Fallback: Detect function-call syntax: tool_name(key='value', data={...})
    final functionMatch = RegExp(r'^([a-zA-Z0-9_]+)\s*\((.*)\)$', dotAll: true).firstMatch(cleanText);
    if (functionMatch != null) {
      final toolName = functionMatch.group(1);
      final argsString = functionMatch.group(2) ?? '';
      
      final params = <String, dynamic>{};
      
      // Heuristic 1: Extract key=value pairs
      final kvRegex = RegExp(r"([a-zA-Z0-9_]+)\s*=\s*(['\x22]{1})(.*?)\2", dotAll: true);
      for (final kvMatch in kvRegex.allMatches(argsString)) {
        params[kvMatch.group(1)!] = kvMatch.group(3);
      }
      
      // Heuristic 2: Try to extract a JSON-like object from inside
      final innerJson = parseJson(argsString);
      if (innerJson != null) {
        params.addAll(innerJson);
      }
      
      if (params.isNotEmpty) {
        return {'name': toolName, 'args': params};
      }
    }

    // 4. Find JSON Object using Brace Counting
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

        // TRY 1: Standard JSON
        try {
          final dynamic parsed = jsonDecode(candidate);
          if (parsed is Map<String, dynamic>) return parsed;
          if (parsed is Map) return Map<String, dynamic>.from(parsed);
        } catch (_) {
          // TRY 2: Handle single quotes (Common in LLM Python-like output)
          try {
             // Replace single quotes with double quotes, but ONLY for keys and string values
             // This is a naive but often effective fix for LLM 'JSON'
             String fixed = candidate
                .replaceAll("'", '"') // Extreme fallback
                .replaceAll('None', 'null')
                .replaceAll('True', 'true')
                .replaceAll('False', 'false');
             
             final dynamic parsed = jsonDecode(fixed);
             if (parsed is Map<String, dynamic>) return parsed;
             if (parsed is Map) return Map<String, dynamic>.from(parsed);
          } catch (e2) {
            debugPrint('JsonParserService: Skipped invalid JSON candidate: $e2');
          }
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
