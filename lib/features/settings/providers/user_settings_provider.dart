import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserSettingsState {
  final String displayLanguage; // 'en' or 'es'
  final String voiceLanguage;   // 'en-US' or 'es-EC'

  const UserSettingsState({
    required this.displayLanguage,
    required this.voiceLanguage,
  });

  UserSettingsState copyWith({
    String? displayLanguage,
    String? voiceLanguage,
  }) {
    return UserSettingsState(
      displayLanguage: displayLanguage ?? this.displayLanguage,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
    );
  }
}

class UserSettingsNotifier extends StateNotifier<UserSettingsState> {
  UserSettingsNotifier() : super(const UserSettingsState(displayLanguage: 'en', voiceLanguage: 'en-US'));

  void setDisplayLanguage(String lang) {
    // Auto-sync voice language option
    String voiceLang = lang == 'es' ? 'es-EC' : 'en-US';
    state = state.copyWith(displayLanguage: lang, voiceLanguage: voiceLang);
  }

  void setVoiceLanguage(String lang) {
    state = state.copyWith(voiceLanguage: lang);
  }
}

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettingsState>((ref) {
  return UserSettingsNotifier();
});
