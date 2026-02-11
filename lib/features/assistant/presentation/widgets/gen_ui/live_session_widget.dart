import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:record/record.dart';
import 'package:inhaus_brain/core/services/live_api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LiveMultimodalSessionWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const LiveMultimodalSessionWidget({super.key, required this.data});

  @override
  ConsumerState<LiveMultimodalSessionWidget> createState() => _LiveMultimodalSessionWidgetState();
}

class _LiveMultimodalSessionWidgetState extends ConsumerState<LiveMultimodalSessionWidget> {
  final _recorder = AudioRecorder();
  StreamSubscription? _recorderSubscription;
  StreamSubscription? _apiSubscription;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _statusMessage;
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _statusMessage = "Ready to connect...";
  }

  @override
  void dispose() {
    _recorderSubscription?.cancel();
    _apiSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = "Connecting to Multimodal Live API...";
      _logs.add("Initializing connection...");
    });

    try {
      final liveService = ref.read(liveApiServiceProvider);
      
      // Listen for API events
      _apiSubscription = liveService.events.listen((event) {
        _handleApiEvent(event);
      }, onError: (err) {
        _addLog("API Error: $err");
      });

      await liveService.connect(
        systemInstruction: "You are Brian, the Inhaus Brain assistant. You are in a Live Multimodal Session with the user. Help them with their objective: ${widget.data['objective'] ?? 'Research and Strategy'}.",
      );

      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _statusMessage = "Live API Connected";
      });
      _addLog("Connected to Gemini 2.0 Flash (Live)");

      // Start Audio Streaming
      await _startAudioStreaming();

    } catch (e) {
      setState(() {
        _isConnecting = false;
        _statusMessage = "Connection failed: $e";
      });
      _addLog("Error: $e");
    }
  }

  Future<void> _startAudioStreaming() async {
    if (await _recorder.hasPermission()) {
      _addLog("Starting audio stream (PCM 16k)...");
      
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      final stream = await _recorder.startStream(config);
      final liveService = ref.read(liveApiServiceProvider);

      _recorderSubscription = stream.listen((data) {
        liveService.sendAudio(data);
      });
    }
  }

  void _handleApiEvent(Map<String, dynamic> event) {
    if (event.containsKey('server_content')) {
      final content = event['server_content'];
      if (content.containsKey('model_turn')) {
        final parts = content['model_turn']['parts'] as List?;
        if (parts != null) {
          for (var part in parts) {
            if (part.containsKey('text')) {
              _addLog("Brian: ${part['text']}");
            }
            if (part.containsKey('inline_data')) {
              // Binary audio data received
              // TODO: Playback logic
              _addLog("[Audio Received: ${part['inline_data']['data'].length} bytes]");
            }
          }
        }
      }
    } else if (event.containsKey('setup_complete')) {
      _addLog("Setup verified. Voice-driven interaction active.");
    }
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _logs.add(message);
    });
    // Auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isConnected ? _buildSessionView() : _buildConnectView(),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.boltLightning,
            color: _isConnected ? Colors.greenAccent : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 12),
          Text(
            "Live Multimodal API Session",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const Spacer(),
          if (_isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                   CircleAvatar(radius: 3, backgroundColor: Colors.redAccent),
                   SizedBox(width: 6),
                   Text("LIVE", style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat()).fadeOut(duration: 800.ms).fadeIn(duration: 800.ms),
        ],
      ),
    );
  }

  Widget _buildConnectView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(FontAwesomeIcons.headset, size: 40, color: Colors.blueAccent),
          ),
          const SizedBox(height: 24),
          const Text(
            "Push the Pulse to Connect",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Start a real-time, bidirectional voice and audio session with Gemini 2.0 Flash.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isConnecting ? null : _startSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _isConnecting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("INITIALIZE SESSION", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ).animate().scale(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildSessionView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              final isModel = log.startsWith("Brian:");
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isModel ? Colors.blueAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log,
                  style: TextStyle(
                    color: isModel ? Colors.blueAccent : Colors.white70,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        ),
        _buildWaveform(),
      ],
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(15, (i) {
             return Container(
               width: 3,
               height: 10 + (i % 3 == 0 ? 20 : 10),
               margin: const EdgeInsets.symmetric(horizontal: 2),
               decoration: BoxDecoration(
                 color: Colors.blueAccent,
                 borderRadius: BorderRadius.circular(2),
               ),
             ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(
                begin: 0.5, 
                end: 1.5, 
                duration: (500 + (i * 100)).ms,
                curve: Curves.easeInOut,
             );
          }),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _statusMessage ?? "Ready",
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
            ),
          ),
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent, size: 20),
              onPressed: () {
                ref.read(liveApiServiceProvider).disconnect();
                setState(() => _isConnected = false);
              },
            ),
        ],
      ),
    );
  }
}
