import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

final voiceServiceProvider = ChangeNotifierProvider((ref) => VoiceService());

class VoiceService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  bool get isListening => _isListening;
  
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  double _soundLevel = 0.0;
  double get soundLevel => _soundLevel;

  String _currentLocale = 'en-US';
  String get currentLocale => _currentLocale;

  void setLocale(String locale) {
    _currentLocale = locale;
    notifyListeners();
  }

  Future<bool> init() async {
    bool hasSpeech = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          _isListening = false;
          _soundLevel = 0.0;
          notifyListeners();
        }
      },
      onError: (error) {
        _isListening = false;
        _soundLevel = 0.0;
        notifyListeners();
      },
    );
    
    await _tts.setPitch(1.0);
    return hasSpeech;
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isListening) {
      _isListening = true;
      notifyListeners();
      await _speech.listen(
        localeId: _currentLocale,
        onSoundLevelChange: (level) {
          _soundLevel = level;
          notifyListeners();
        },
        onResult: (result) {
          if (result.finalResult) {
            _isListening = false;
            notifyListeners();
            onResult(result.recognizedWords);
          }
        },
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> speak(String text) async {
    _isSpeaking = true;
    notifyListeners();
    // Dynamically set language before speaking
    await _tts.setLanguage(_currentLocale);
    await _tts.speak(text);
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }
}

// State provider for UI status
final voiceStateProvider = StateProvider<VoiceState>((ref) => VoiceState.idle);

enum VoiceState { idle, listening, speaking }
