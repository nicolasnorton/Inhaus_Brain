import '../../core/tokens/llm_provider.dart';

class VoiceCommandProcessor {
  static VoiceIntent? process(String text, String locale) {
    final lowerText = text.toLowerCase();
    
    // English Patterns
    if (locale.startsWith('en')) {
      if (lowerText.contains('switch to') || lowerText.contains('change to')) {
        if (lowerText.contains('creative')) return VoiceIntent(type: VoiceIntentType.switchAgent, data: AIModelConfig.geminiFlash);
        if (lowerText.contains('research')) return VoiceIntent(type: VoiceIntentType.switchAgent, data: AIModelConfig.geminiFlash); // Map to specific models
      }
      if (lowerText.contains('clear chat') || lowerText.contains('new conversation')) {
        return VoiceIntent(type: VoiceIntentType.clearChat);
      }
    }
    
    // Spanish Patterns
    if (locale.startsWith('es')) {
      if (lowerText.contains('cambiar a') || lowerText.contains('pasa a')) {
        if (lowerText.contains('creativo')) return VoiceIntent(type: VoiceIntentType.switchAgent, data: AIModelConfig.geminiFlash);
      }
      if (lowerText.contains('limpiar chat') || lowerText.contains('nueva conversación')) {
        return VoiceIntent(type: VoiceIntentType.clearChat);
      }
    }

    return null;
  }
}

enum VoiceIntentType { switchAgent, clearChat, sendText }

class VoiceIntent {
  final VoiceIntentType type;
  final dynamic data;

  VoiceIntent({required this.type, this.data});
}
