import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'ai_proxy_service.dart';

/// Service to handle real-time Multimodal Live API interactions via WebSockets.
/// Follows the Jan 2026 standards for low-latency AI communication.
class LiveApiService {
  final AIProxyService _proxyService;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  LiveApiService(this._proxyService);

  /// Stream of events received from the Live API (Audio, Tool Calls, etc.)
  Stream<Map<String, dynamic>> get events => _eventController.stream;
  
  bool get isConnected => _isConnected;

  /// Connect to the Multimodal Live API using a secure token from the backend.
  Future<void> connect({
    String model = 'gemini-3-flash-preview',
    String? systemInstruction,
  }) async {
    if (_isConnected) return;

    try {
      debugPrint('LiveApiService: Fetching secure access token...');
      final tokenData = await AIProxyService.getLiveToken();
      
      final token = tokenData['token'];
      final project = tokenData['projectId'];
      final location = tokenData['location'];

      // Vertex AI Multimodal Live WebSocket URL
      final url = 'wss://$location-aiplatform.googleapis.com/v1/projects/$project/locations/$location/publishers/google/models/$model:streamMultimodalCtx';

      debugPrint('LiveApiService: Connecting to WebSocket...');
      
      _channel = WebSocketChannel.connect(
        Uri.parse(url),
        // Pass the OAuth token in the Sec-WebSocket-Protocol header (standard for Google Cloud WS)
        protocols: ['access_token', token],
      );

      _channel!.stream.listen(
        (data) {
          _isConnected = true;
          try {
            final event = jsonDecode(data);
            _eventController.add(event);
          } catch (e) {
             debugPrint('LiveApiService: Failed to decode event: $e');
          }
        },
        onError: (err) {
          debugPrint('LiveApiService: WebSocket Error: $err');
          _isConnected = false;
          _eventController.addError(err);
        },
        onDone: () {
          debugPrint('LiveApiService: WebSocket Closed');
          _isConnected = false;
          _channel = null;
        },
      );

      // 1. Send Setup Event
      _sendSetup(
        project: project,
        location: location,
        model: model,
        systemInstruction: systemInstruction,
      );

    } catch (e) {
      debugPrint('LiveApiService: Connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }

  void _sendSetup({
    required String project,
    required String location,
    required String model,
    String? systemInstruction,
  }) {
    final setupEvent = {
      "setup": {
        "model": "projects/$project/locations/$location/publishers/google/models/$model",
        "generation_config": {
          "response_modalities": ["AUDIO"]
        },
        if (systemInstruction != null)
          "system_instruction": {
            "parts": [{"text": systemInstruction}]
          }
      }
    };
    
    _sendRawEvent(setupEvent);
  }

  /// Send a generic event to the API.
  void _sendRawEvent(Map<String, dynamic> event) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(event));
    } else {
      debugPrint('LiveApiService: Cannot send event - Not connected.');
    }
  }

  /// Send real-time audio data (PCM 16k 16-bit Mono).
  void sendAudio(List<int> audioData) {
    final audioEvent = {
      "realtime_input": {
        "media_chunks": [
          {
            "mime_type": "audio/pcm;rate=16000",
            "data": base64Encode(audioData)
          }
        ]
      }
    };
    _sendRawEvent(audioEvent);
  }

  /// Send a text prompt as part of the live interaction.
  void sendText(String text) {
     final textEvent = {
      "client_content": {
        "turns": [
          {
            "role": "user",
            "parts": [{"text": text}]
          }
        ],
        "turn_complete": true
      }
    };
    _sendRawEvent(textEvent);
  }

  /// Disconnect the active session.
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  /// Clean up resources.
  void dispose() {
    disconnect();
    _eventController.close();
  }
}

final liveApiServiceProvider = Provider((ref) {
  final proxyService = ref.watch(aiProxyServiceProvider);
  return LiveApiService(proxyService);
});
