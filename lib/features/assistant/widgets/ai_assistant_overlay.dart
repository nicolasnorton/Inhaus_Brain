// import 'dart:io' show File, Directory; // Removed to avoid web crashes 

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/assistant_provider.dart';
import '../services/assistant_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../settings/providers/user_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'artifact_renderer.dart';
import '../../chat/models/chat_models.dart'; // For Artifact model (if needed explicitly)

class AiAssistantOverlay extends ConsumerStatefulWidget {
  const AiAssistantOverlay({super.key});

  @override
  ConsumerState<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends ConsumerState<AiAssistantOverlay> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  Uint8List? _selectedImage;
  String? _selectedImageName;
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _originalTextBeforeDictation = '';
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecordingAudio = false;
  String? _audioPath;
  bool _isFullWidth = false;
  final FlutterTts _flutterTts = FlutterTts();
  bool _autoRead = false;
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _speak(String text) async {
    await _flutterTts.stop();
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _flutterTts.stop();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImage = result.files.first.bytes;
          _selectedImageName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageName = null;
    });
  }

  Future<void> _startListening() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (errorNotification) => debugPrint('Speech error: $errorNotification'),
    );

    if (available) {
      if (mounted) {
        setState(() {
          _isListening = true;
          _autoRead = true; // Auto-enable voice response when user speaks
          _originalTextBeforeDictation = _controller.text; // Store current text
        });
        
        final userParams = ref.read(userPreferencesProvider);
        final localeId = userParams.effectiveVoiceLanguage;

        _speechToText.listen(
          onResult: (result) {
            String newText;
            if (_originalTextBeforeDictation.isEmpty) {
              newText = result.recognizedWords;
            } else {
              newText = "$_originalTextBeforeDictation ${result.recognizedWords}";
            }
            
            _controller.text = newText;
            
            // Move cursor to end
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          },
          localeId: localeId,
          listenOptions: SpeechListenOptions(
            cancelOnError: true,
            partialResults: true,
          ),
        );
      }
    } else {
      debugPrint("The user has denied the use of speech recognition.");
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      await _startListening();
    }
  }

  Future<void> _toggleAudioRecording() async {
    if (_isRecordingAudio) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecordingAudio = false);
      if (path != null) {
        _audioPath = path;
        _sendMessage();
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/assistant_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecordingAudio = true;
          _autoRead = true; // Auto-enable voice response
          _audioPath = path;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null && _audioPath == null) return;

    _controller.clear();
    final imageToSend = _selectedImage;
    final audioFileToSend = _audioPath;
    _removeImage(); 
    _audioPath = null;

    setState(() => _isTyping = true);

    try {
      List<int>? audioBytes;
      if (audioFileToSend != null && !kIsWeb) {
        // Logic to read file bytes on mobile/desktop without dart:io at compile time for web
        // This is tricky. Usually we use a service. 
        // For now, let's just bypass if it's causing issues or use a helper.
        debugPrint('Audio attachment on non-web: $audioFileToSend');
      }

      await ref.read(assistantChatProvider.notifier).sendMessage(
        text, 
        attachment: imageToSend?.toList(),
        audioAttachment: audioBytes,
      );
      // Wait a frame for the list to update
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = ref.watch(isAssistantOpenProvider);
    final messages = ref.watch(assistantChatProvider);
    
    // Listen to external send trigger (from FAB)
    ref.listen(assistantSendTriggerProvider, (previous, next) {
      if (next > 0) {
        _sendMessage();
      }
    });

    // Listen for new messages to trigger TTS
    ref.listen(assistantChatProvider, (prev, next) {
      if (next.isNotEmpty && (prev?.length ?? 0) < next.length) {
        final lastMessage = next.last;
        if (!lastMessage.isUser && isOpen) {
          // It's a new AI response (and overlay is open)
          String textToSpeak = lastMessage.text;
          
          // Enhanced TTS for generated assets
          if (lastMessage.generatedAssetPath != null) {
            String assetType = lastMessage.generatedAssetType == 'video' ? 'video' : 'image';
            // Speak the description found in the text, or a generic intro if text is brief
            if (textToSpeak.length < 50) {
               textToSpeak = "I've generated this $assetType for you. ${lastMessage.text}";
            }
          }
           // Filter out complex markdown (checking for code blocks or huge tables could be good, but simple for now)
           // Remove URLs and heavy markdown symbols for cleaner speech
           textToSpeak = textToSpeak.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '') // Remove images
                                    .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '') // Remove links
                                    .replaceAll('```', '')
                                    .replaceAll('#', '');
          
          if (_autoRead) {
            _speak(textToSpeak);
          }
        }
      }
    });

    if (!isOpen) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    // Layout parameters
    double? top, right, bottom, left, width;
    double borderRadius;

    if (_isFullWidth) {
      top = 0; right = 0; bottom = 0; left = 0;
      width = null;
      borderRadius = 0;
    } else if (isSmallScreen) {
      top = 5; right = 5; bottom = 5; left = 5;
      width = null;
      borderRadius = 16;
    } else {
      top = 20; right = 20; bottom = 20; left = null;
      width = 520;
      borderRadius = 16;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      width: width,
      child: Material(
        elevation: 16,
        borderRadius: BorderRadius.circular(borderRadius),
        color: const Color(0xFF1C2128), // Dark workspace background
        child: Consumer(
          builder: (context, ref, child) {
            final isOpen = ref.watch(isAssistantOpenProvider);
            return Visibility(
              visible: isOpen,
              maintainState: false, // Force re-layout/focus evaluation only when visible
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.smart_toy, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Assistant',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(_autoRead ? Icons.volume_up : Icons.volume_off, size: 20, color: _autoRead ? Colors.blueAccent : Colors.white54),
                          onPressed: () => setState(() => _autoRead = !_autoRead),
                          tooltip: _autoRead ? 'Mute Voice' : 'Enable Voice Response',
                        ),
                        // Mode Switcher
                        Consumer(
                          builder: (context, ref, _) {
                             final mode = ref.watch(assistantModeProvider);
                             return PopupMenuButton<AssistantMode>(
                               initialValue: mode,
                               tooltip: 'Assistant Mode',
                               icon: Icon(
                                 mode == AssistantMode.planning ? Icons.architecture : Icons.flash_on, 
                                 color: mode == AssistantMode.planning ? Colors.purpleAccent : Colors.amber,
                                 size: 20
                               ),
                               onSelected: (newMode) => ref.read(assistantModeProvider.notifier).state = newMode,
                               itemBuilder: (context) => [
                                 const PopupMenuItem(
                                   value: AssistantMode.fast,
                                    child: Row(children: [Icon(Icons.flash_on, size: 16, color: Colors.amber), SizedBox(width: 8), Text('Fast Mode', style: TextStyle(color: Colors.white))]),
                                 ),
                                 const PopupMenuItem(
                                   value: AssistantMode.planning,
                                    child: Row(children: [Icon(Icons.architecture, size: 16, color: Colors.purpleAccent), SizedBox(width: 8), Text('Planning Mode', style: TextStyle(color: Colors.white))]),
                                 ),
                               ],
                               color: const Color(0xFF2D333B),
                             );
                          }
                        ),
                        if (!isSmallScreen)
                          IconButton(
                            icon: Icon(_isFullWidth ? Icons.fullscreen_exit : Icons.fullscreen, size: 20, color: Colors.white54),
                            onPressed: () => setState(() => _isFullWidth = !_isFullWidth),
                            tooltip: _isFullWidth ? 'Collapse' : 'Expand Full Width',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white54),
                          onPressed: () => ref.read(assistantChatProvider.notifier).clearChat(),
                          tooltip: 'Clear Chat',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                          onPressed: () => ref.read(isAssistantOpenProvider.notifier).state = false,
                        ),
                      ],
                    ),
                  ),
                  
                  // Message List
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      primary: false,
                      itemCount: messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                           return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(messages[index]);
                      },
                    ),
                  ),

                  // Input Area
                  Column(
                    children: [
                      if (_selectedImage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: const Color(0xFF0F1116),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _selectedImage!,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedImageName ?? 'Image',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                                onPressed: _removeImage,
                                tooltip: 'Remove image',
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1116),
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(bottom: 8, right: 4),
                              icon: Icon(Icons.add_circle_outline, color: _selectedImage != null ? Colors.blueAccent : Colors.white54, size: 22),
                              onPressed: _pickImage,
                              tooltip: 'Add attachment',
                            ),
                            GestureDetector(
                              onTap: _toggleListening,
                              onLongPress: _toggleAudioRecording,
                              onLongPressUp: _toggleAudioRecording,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: Icon(
                                  _isRecordingAudio 
                                      ? Icons.fiber_manual_record 
                                      : (_isListening ? Icons.mic : Icons.mic_none), 
                                  color: (_isListening || _isRecordingAudio) ? Colors.redAccent : Colors.white54,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: KeyboardListener(
                                focusNode: _keyboardFocusNode,
                                onKeyEvent: (event) {
                                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter && !HardwareKeyboard.instance.isShiftPressed) {
                                    _sendMessage();
                                  }
                                },
                                child: TextField(
                                  controller: _controller,
                                  style: const TextStyle(color: Colors.white),
                                  minLines: 1,
                                  maxLines: 5,
                                  textInputAction: TextInputAction.newline,
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: TextStyle(color: Colors.white38),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AssistantMessage message) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20).copyWith(bottomRight: Radius.zero),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.attachment != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            Uint8List.fromList(message.attachment!),
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (message.audioAttachment != null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.audiotrack, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text("Voice Message", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: const TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white10,
                child: Icon(Icons.smart_toy, size: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branding / Name
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Powered by INHAUS BRAIN',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Message Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16).copyWith(topLeft: Radius.zero),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.6),
                            h1: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            h2: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            code: TextStyle(
                              backgroundColor: Colors.black.withValues(alpha: 0.3),
                              color: Colors.cyanAccent,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            tableBody: const TextStyle(color: Colors.white70, fontSize: 12),
                            tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            tableBorder: TableBorder.all(color: Colors.white10),
                          ),
                        ),
                        if (message.artifacts != null && message.artifacts!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: ArtifactRenderer(artifacts: message.artifacts!),
                          ),
                        if (message.generatedAssetPath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: _buildGeneratedAsset(message.generatedAssetPath!, message.generatedAssetType),
                          ),
                      ],
                    ),
                  ),

                  // Actions & Metadata
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sources button (if available)
                        if (message.sources != null && message.sources!.isNotEmpty)
                           Padding(
                             padding: const EdgeInsets.only(bottom: 8),
                             child: OutlinedButton.icon(
                               onPressed: () {}, // Expansion logic could go here
                               icon: const Icon(Icons.link, size: 12),
                               label: const Text('Sources', style: TextStyle(fontSize: 10)),
                               style: OutlinedButton.styleFrom(
                                 visualDensity: VisualDensity.compact,
                                 foregroundColor: Colors.white54,
                                 side: const BorderSide(color: Colors.white12),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                               ),
                             ),
                           ),
                           
                        Row(
                          children: [
                            // Model & Latency
                            Expanded(
                              child: Text(
                                'Powered by INHAUS BRAIN • ${message.modelName ?? 'DeepMind'} • ${message.processingTime != null ? '${(message.processingTime!.inMilliseconds / 1000).toStringAsFixed(1)}s' : 'Instant'}',
                                style: const TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 0.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            // Action Buttons
                            _buildActionButton(
                              _likedMessages.contains(message.id) ? Icons.thumb_up : Icons.thumb_up_outlined, 
                              () => _toggleLike(message.id),
                              color: _likedMessages.contains(message.id) ? Colors.blueAccent : null
                            ),
                            _buildActionButton(
                              _dislikedMessages.contains(message.id) ? Icons.thumb_down : Icons.thumb_down_outlined, 
                              () => _toggleDislike(message.id),
                              color: _dislikedMessages.contains(message.id) ? Colors.redAccent : null
                            ),
                            _buildActionButton(Icons.ios_share, () {
                              Share.share('${message.text}\n\nGenerated by INHAUS AI');
                            }),
                            _buildActionButton(Icons.copy, () {
                              Clipboard.setData(ClipboardData(text: message.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                              );
                            }),
                            if (message.generatedAssetPath != null && message.generatedAssetType == 'image')
                              _buildActionButton(Icons.download, () {
                                _downloadImage(message.generatedAssetPath!);
                              }),
                            _buildMenuButton(message),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  final Set<String> _likedMessages = {};
  final Set<String> _dislikedMessages = {};

  void _toggleLike(String id) {
    setState(() {
      if (_likedMessages.contains(id)) {
        _likedMessages.remove(id);
      } else {
        _likedMessages.add(id);
        _dislikedMessages.remove(id);
      }
    });
  }

  void _toggleDislike(String id) {
    setState(() {
      if (_dislikedMessages.contains(id)) {
        _dislikedMessages.remove(id);
      } else {
        _dislikedMessages.add(id);
        _likedMessages.remove(id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_dislikedMessages.contains(id) ? 'Feedback sent' : 'Feedback removed'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
      ),
    );
  }

  void _downloadImage(String url) {
    if (kIsWeb) {
      // In Flutter Web, we can use a simpler approach by launching the URL directly
      // as a download if the headers support it, or just opening it in a new tab.
      debugPrint('Downloading image: $url');
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download not implemented for this platform')),
      );
    }
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, {Color? color}) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      icon: Icon(icon, size: 14, color: color ?? Colors.white38),
      onPressed: onPressed,
      hoverColor: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildMenuButton(AssistantMessage message) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 14, color: Colors.white38),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      color: const Color(0xFF2D333B),
      offset: const Offset(0, 20),
      onSelected: (value) async {
        if (value == 'export_to_docs') {
          final url = Uri.parse('https://docs.new');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        } else if (value == 'draft_in_gmail') {
          final Uri emailLaunchUri = Uri(
            scheme: 'mailto',
            path: '',
            query: 'subject=INHAUS AI Draft&body=${Uri.encodeComponent(message.text)}',
          );
          if (await canLaunchUrl(emailLaunchUri)) {
            await launchUrl(emailLaunchUri);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Action Selected: $value'), duration: const Duration(seconds: 1)),
          );
        }
      },
      itemBuilder: (context) => [
        _buildMenuItem('Export to Docs', Icons.description_outlined),
        _buildMenuItem('Draft in Gmail', Icons.mail_outline),
        _buildMenuItem('Report legal issue', Icons.flag_outlined),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String label, IconData icon) {
    return PopupMenuItem<String>(
      value: label.toLowerCase().replaceAll(' ', '_'),
      height: 32,
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildGeneratedAsset(String path, String? type) {
    if (type == 'image') {
      return ExcludeSemantics(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: path.startsWith('http') 
                      ? Image.network(
                          path, 
                          fit: BoxFit.cover, 
                          width: 300,
                          height: 300,
                          semanticLabel: 'Generated Image',
                          errorBuilder: (c,e,s) {
                            debugPrint('Image Load Error for $path: $e');
                            return const Center(child: Icon(Icons.error, color: Colors.red));
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                        )
                      : (path.startsWith('assets') 
                          ? Image.asset(path, fit: BoxFit.cover, width: 300, height: 300) 
                          : (!kIsWeb 
                              // Use dynamic to avoid compile-time dart:io dependency on web
                              ? Image.memory(Uint8List.fromList([]), fit: BoxFit.cover, width: 300, height: 300) // Placeholder or better logic needed
                              : const Center(child: Icon(Icons.broken_image, color: Colors.white24)))),
                ),
              ),
              // Watermark Overlay (Asset Based)
              Positioned(
                bottom: 12,
                right: 12,
                child: Image.asset(
                  'assets/images/watermark.png',
                  height: 28, // Slightly larger for better prominence
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.auto_awesome, size: 12, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (type == 'video') {
       return Container(
        width: 300,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
             // Placeholder gradient or thumbnail
             Container(
               decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.withValues(alpha: 0.2), Colors.blue.withValues(alpha: 0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
               ),
             ),
             Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.play_circle_fill, size: 48, color: Colors.white70),
                 const SizedBox(height: 8),
                 Text(
                   'Generated Video',
                   style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                 ),
                 Text(
                   path.startsWith('http') ? 'Stream ready' : 'Local file ready',
                   style: const TextStyle(color: Colors.white54, fontSize: 10),
                 ),
               ],
             ),
             Positioned(
               bottom: 8,
               right: 8,
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                 child: const Text("VEO-2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
               ),
             )
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white10,
            child: Icon(Icons.smart_toy, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20).copyWith(topLeft: Radius.zero),
            ),
            child: const SizedBox(
              width: 24,
              height: 12,
              child: Center(
                child: Text(
                  '...', 
                  style: TextStyle(color: Colors.white54, letterSpacing: 2, height: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
