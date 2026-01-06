import 'dart:typed_data';
import '../../knowledge/models/knowledge_source.dart';
import '../models/chat_models.dart';

abstract class BaseAgent {
  MessageSender get type;
  String get name;
  String get systemPromptKey; // Key to fetch from SystemPromptsService if needed, or hardcoded default

  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
  });
}
