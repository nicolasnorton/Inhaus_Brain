import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/core/widgets/app_video_player.dart';
import 'package:inhaus_brain/core/widgets/app_audio_player.dart';
import 'package:inhaus_brain/core/widgets/app_audio_player.dart';
import '../../core/services/voice_service.dart';
import '../../core/ui/split_pane_layout.dart';
import '../canvas/ui/canvas_host.dart';
import '../canvas/providers/canvas_provider.dart';
import 'providers/chat_provider.dart';
import 'models/chat_models.dart';
import '../campaigns/widgets/multi_modal_input_section.dart';
import '../campaigns/models/campaign.dart';
import '../knowledge/widgets/knowledge_library_widget.dart';
import '../settings/profile_settings_screen.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/app_environment.dart';
import '../../core/tokens/llm_provider.dart';
import '../../core/services/voice_command_processor.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/voice_visualizer.dart';
import 'widgets/watermarked_image.dart';
import 'widgets/thinking_indicator.dart';
import 'widgets/sources_carousel.dart';
import 'widgets/message_actions_row.dart';

import 'widgets/tool_selector_bar.dart';

class AgenticChatView extends ConsumerStatefulWidget {
  const AgenticChatView({super.key});

  @override
  ConsumerState<AgenticChatView> createState() => _AgenticChatViewState();
}

class _AgenticChatViewState extends ConsumerState<AgenticChatView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final FocusNode _chatFocusNode = FocusNode();
  List<Attachment> _pendingAttachments = [];
  AIModelConfig _selectedModelConfig = AIModelConfig.geminiFlash;
  bool _isAutoReadEnabled = false;
  ToolMode _toolMode = ToolMode.chat;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(voiceServiceProvider).init());
  }

  @override
  void dispose() {
    // Silence any active voice/listening on exit
    try {
      ref.read(voiceServiceProvider).stopSpeaking();
      ref.read(voiceServiceProvider).stopListening();
    } catch (_) {
      // ref might be disposed
    }
    _textController.dispose();
    _scrollController.dispose();
    _chatFocusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_textController.text.isEmpty && _pendingAttachments.isEmpty) return;
    
    ref.read(chatProvider.notifier).sendMessage(
      _textController.text,
      attachments: _pendingAttachments,
      modelConfig: _selectedModelConfig,
      toolMode: _toolMode,
    );
    
    _textController.clear();
    setState(() {
       _pendingAttachments = [];
       // Reset tool mode to chat after sending, or keep it sticky? 
       // Plan implies explicit control, so maybe sticky is better.
       // For now, let's keep it sticky as per "Tool Mode" concept.
    });
    
    // Scroll to bottom after message
    Future.delayed(const Duration(milliseconds: 100), () {
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
    final session = ref.watch(chatProvider);
    final canvasState = ref.watch(canvasProvider);

    // Auto-open logic
    ref.listen(chatProvider, (previous, next) {
      if (next != null && (previous == null || next.messages.length > previous.messages.length)) {
        final lastMsg = next.messages.last;
        if (lastMsg.sender != MessageSender.user) {
           // Auto-open attachments
           if (lastMsg.attachments.isNotEmpty) {
              final att = lastMsg.attachments.first;
              // Simple check for image/video/code types
              if (att.url.endsWith('.png') || att.url.endsWith('.jpg') || att.type.toString().contains('image')) {
                 ref.read(canvasProvider.notifier).showImage(att.url, title: att.name);
              }
           }
           // Auto-open GenUI if present in metadata
           if (lastMsg.metadata != null && lastMsg.metadata!['uiPayload'] != null) {
              ref.read(canvasProvider.notifier).showGenUI(
                Map<String, dynamic>.from(lastMsg.metadata!['uiPayload']), 
                title: lastMsg.metadata!['title'] ?? 'Generated Content'
              );
           }
        }
      }
    });

    // The existing chat UI (Right Pane)
    final chatUi = Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: session == null || session.messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: session.messages.length,
                      itemBuilder: (context, index) {
                        final message = session.messages[index];
                        // Auto-read logic
                        if (_isAutoReadEnabled && index == session.messages.length - 1 && message.sender != MessageSender.user) {
                           ref.read(voiceServiceProvider).speak(message.content);
                        }
                        return KeyedSubtree(
                          key: ValueKey(message.id),
                          child: _buildMessageBubble(message),
                        );
                      },
                    ),
            ),
            _buildInputArea(),
          ],
        ),
        // Mobile Toggle Button (Visible only when content exists, canvas is closed, and screen is small)
        if (canvasState.type != CanvasContentType.empty && 
            !canvasState.isMobileCanvasOpen && 
            MediaQuery.of(context).size.width < 750) // < minLeft + minRight
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.auto_awesome_mosaic, color: Colors.white),
              onPressed: () => ref.read(canvasProvider.notifier).toggleMobileCanvas(true),
            ),
          ),
      ],
    );

    return SplitPaneLayout(
      childLeft: const CanvasHost(),
      childRight: chatUi,
      initialRatio: 0.5, // 50/50 split on desktop
      minLeftWidth: 350,
      minRightWidth: 400,
      showLeftPaneOnMobile: canvasState.isMobileCanvasOpen,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.robot, size: 48, color: Colors.blueAccent.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'The Agentic Workshop is open.',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a tool or ask Brian for help.',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    
    if (message.type == MessageType.toolUsage) {
      return _buildToolUsageIndicator(message);
    }

    if (message.type == MessageType.approvalWidget) {
      return _buildApprovalWidget(message);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAgentAvatar(message.sender),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                  Material(
                    color: isUser ? Colors.blueAccent : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : null,
                      bottomLeft: !isUser ? const Radius.circular(4) : null,
                    ),
                    elevation: 1,
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                         border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                         borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isUser ? const Radius.circular(4) : null,
                            bottomLeft: !isUser ? const Radius.circular(4) : null,
                         ),
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUser)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: message.content));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(12.0), // Generous padding for touch target
                                  child: Icon(Icons.copy, size: 18, color: Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  _textController.text = message.content;
                                  // Requests focus to ensure keyboard opens
                                  _chatFocusNode.requestFocus();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(12.0), // Generous padding for touch target
                                  child: Icon(Icons.edit, size: 18, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isUser) ...[
                        Text(
                          _getAgentName(message.sender),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      MarkdownBody(
                        data: message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.4,
                          ),
                          h1: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          h2: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          code: TextStyle(
                            backgroundColor: Colors.black.withValues(alpha: 0.2),
                            color: isUser ? Colors.white : Colors.cyanAccent,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tableBody: const TextStyle(color: Colors.white70, fontSize: 12),
                          tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          tableBorder: TableBorder.all(color: Colors.white10),
                        ),
                        imageBuilder: (uri, title, alt) {
                          return WatermarkedImage(imageUrl: uri.toString(), fit: BoxFit.contain);
                        },
                      ),
                      if (message.metadata != null && message.metadata!.containsKey('sources'))
                         SourcesCarousel(sources: (message.metadata!['sources'] as List).cast<Map<String, dynamic>>()),
                      if (message.attachments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildAttachmentsList(message.attachments),
                      ],
                    ],
                  ),
                  ),
                ),
                if (!isUser)
                  MessageActionsRow(
                    messageId: message.id, // Pass ID
                    content: message.content,
                    isUser: false,
                    modelName: _selectedModelConfig.displayName, 
                    onDownload: () {
                      // Handle download of message content as text file if needed
                      // or if message has attachments, maybe download first one?
                      if (message.attachments.isNotEmpty) {
                        launchUrl(Uri.parse(message.attachments.first.url), mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No media to download')));
                      }
                    },
                    onReport: () {
                         // Logic to report
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    'Just now',
                    style: const TextStyle(fontSize: 10, color: Colors.white24),
                  ),
                ),
              ],

            ),
          ),
          const SizedBox(width: 12),
          if (isUser) const CircleAvatar(radius: 16, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 16, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildApprovalWidget(ChatMessage message) {
    final title = message.metadata?['title'] ?? 'Review Proposal';
    final type = message.metadata?['type'] ?? 'strategy';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.circleExclamation, size: 16, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message.content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(chatProvider.notifier).sendMessage('I have some concerns about this $type. Let\'s refine.');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: const Text('Reject & Refine'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(chatProvider.notifier).sendMessage('This $type looks great. Approved!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentAvatar(MessageSender sender) {
    IconData icon;
    Color color;
    switch (sender) {
      case MessageSender.researchAgent:
        icon = FontAwesomeIcons.magnifyingGlass;
        color = Colors.greenAccent;
        break;
      case MessageSender.creativeAgent:
        icon = FontAwesomeIcons.palette;
        color = Colors.purpleAccent;
        break;
      case MessageSender.humanAgent:
        icon = FontAwesomeIcons.userCheck;
        color = Colors.orangeAccent;
        break;
      case MessageSender.orchestratorAgent:
        icon = FontAwesomeIcons.shieldHalved;
        color = Colors.redAccent;
        break;
      case MessageSender.copywriterAgent:
        icon = FontAwesomeIcons.penNib;
        color = Colors.pinkAccent;
        break;
      case MessageSender.developerAgent:
        icon = FontAwesomeIcons.code;
        color = Colors.cyanAccent;
        break;
      case MessageSender.clientOnboardingAgent:
        icon = FontAwesomeIcons.userGear;
        color = Colors.tealAccent;
        break;
      case MessageSender.extractorAgent:
        icon = FontAwesomeIcons.fileExport;
        color = Colors.amberAccent;
        break;
      case MessageSender.parserAgent:
        icon = FontAwesomeIcons.table;
        color = Colors.orangeAccent;
        break;
      case MessageSender.summarizerAgent:
        icon = FontAwesomeIcons.listCheck;
        color = Colors.lightBlueAccent;
        break;
      case MessageSender.securityAgent:
        icon = FontAwesomeIcons.shieldCat;
        color = Colors.deepOrangeAccent;
        break;
      case MessageSender.dataEngineerAgent:
        icon = FontAwesomeIcons.database;
        color = Colors.indigoAccent;
        break;
      default:
        icon = FontAwesomeIcons.brain;
        color = Colors.blueAccent;
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.1),
      child: FaIcon(icon, size: 14, color: color),
    );
  }

  String _getAgentName(MessageSender sender) {
    switch (sender) {
      case MessageSender.researchAgent: return 'RESEARCH AGENT';
      case MessageSender.creativeAgent: return 'CREATIVE AGENT';
      case MessageSender.humanAgent: return 'HUMAN AGENT';
      case MessageSender.orchestratorAgent: return 'ORCHESTRATOR';
      case MessageSender.copywriterAgent: return 'COPYWRITER';
      case MessageSender.developerAgent: return 'DEVELOPER';
      case MessageSender.clientOnboardingAgent: return 'CLIENT CONCIERGE';
      case MessageSender.extractorAgent: return 'EXTRACTOR';
      case MessageSender.parserAgent: return 'PARSER';
      case MessageSender.summarizerAgent: return 'SUMMARIZER';
      case MessageSender.securityAgent: return 'SECURITY GUARDIAN';
      case MessageSender.dataEngineerAgent: return 'DATA ENGINEER';
      case MessageSender.system: return 'INHAUS BRAIN';
      default: return '';
    }
  }

  Widget _buildToolUsageIndicator(ChatMessage message) {
    return ThinkingIndicator(message: message);
  }

  Widget _buildAttachmentsList(List<Attachment> attachments) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((attachment) {
        // Handle Video
        if (attachment.type == AttachmentType.video || 
            attachment.url.toLowerCase().endsWith('.mp4') ||
            attachment.url.toLowerCase().endsWith('.mov')) {
          return GestureDetector(
            onTap: () {
               // todo: add video support to canvas
               // ref.read(canvasProvider.notifier).showVideo(attachment.url, title: attachment.name);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 300, 
                child: AppVideoPlayer(videoUrl: attachment.url),
              ),
            ),
          );
        }

        // Handle Audio
        if (attachment.type == AttachmentType.voice || 
            attachment.url.toLowerCase().endsWith('.mp3') ||
            attachment.url.toLowerCase().endsWith('.wav')) {
          return SizedBox(
            width: 300,
            child: AppAudioPlayer(audioUrl: attachment.url),
          );
        }
        
        // Handle Images (Default)
        return GestureDetector(
          onTap: () {
            ref.read(canvasProvider.notifier).showImage(attachment.url, title: attachment.name);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              width: 300, 
              child: WatermarkedImage(
                imageUrl: attachment.url,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_pendingAttachments.isNotEmpty) ...[
               _buildPendingAttachmentsBar(),
               const SizedBox(height: 12),
            ],
            
            // Voice Visualizer
            Consumer(
              builder: (context, ref, _) {
                final voiceSvc = ref.watch(voiceServiceProvider);
                return VoiceVisualizer(
                  isActive: voiceSvc.isListening || voiceSvc.isSpeaking,
                  soundLevel: voiceSvc.soundLevel,
                );
              },
            ),

            // Tool Selector Bar (New)
            ToolSelectorBar(
              selectedMode: _toolMode,
              onModeChanged: (mode) => setState(() => _toolMode = mode),
            ),

            Row(
              children: [
                _buildModelPicker(),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.bookOpen, size: 16, color: Colors.white54),
                  tooltip: 'Context Board',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const Dialog(
                        backgroundColor: Colors.transparent,
                        child: KnowledgeLibraryWidget(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isAutoReadEnabled ? Icons.volume_up : Icons.volume_off,
                    size: 18,
                    color: _isAutoReadEnabled ? Colors.blueAccent : Colors.white24,
                  ),
                  tooltip: 'Toggle Auto-Read',
                  onPressed: () => setState(() => _isAutoReadEnabled = !_isAutoReadEnabled),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white54),
                  onPressed: () {
                    // Show multimodal injection picker
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: MultiModalInputSection(
                          onAttachmentsChanged: (attachments) {
                            setState(() => _pendingAttachments = attachments);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _chatFocusNode,
                    onSubmitted: (_) => _handleSend(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _getHintText(),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      suffixIcon: _buildVoiceButton(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final authState = ref.watch(authStateProvider);
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const Dialog(
                             backgroundColor: Colors.transparent,
                             child: SizedBox(
                               width: 500,
                               height: 600,
                               child: ProfileSettingsScreen()
                             ),
                          ),
                        );
                      },
                      child: authState.when(
                        data: (user) => CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blueAccent,
                          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                          child: user?.photoURL == null 
                            ? const Icon(Icons.person, size: 18, color: Colors.white) 
                            : null,
                        ),
                        loading: () => const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (error, stack) => const CircleAvatar(radius: 16, backgroundColor: Colors.red, child: Icon(Icons.error, size: 16)),
                      ),
                    );
                  }
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 18, color: Colors.white),
                    onPressed: _handleSend,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getHintText() {
    switch (_toolMode) {
      case ToolMode.image: return 'Describe the image you want to generate...';
      case ToolMode.video: return 'Describe the video you want to generate...';
      case ToolMode.code: return 'Describe the code you need...';
      case ToolMode.chat: default: return 'Collaborate with agents...';
    }
  }

  Widget _buildModelPicker() {
    return PopupMenuButton<AIModelConfig>(
      tooltip: 'Select AI Model',
      color: const Color(0xFF1E1E1E),
      offset: const Offset(0, -300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(_getModelIcon(_selectedModelConfig), size: 12, color: Colors.blueAccent),
            const SizedBox(width: 4),
            Text(
              _selectedModelConfig.displayName.split(' ').first, // Short name
              style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildGroupHeader('TEXT MODELS'),
        _buildModelMenuItem(AIModelConfig.geminiFlash, FontAwesomeIcons.bolt),
        _buildModelMenuItem(AIModelConfig.geminiPro, FontAwesomeIcons.google),
        _buildModelMenuItem(AIModelConfig.geminiFlashLite, FontAwesomeIcons.gaugeHigh),
        const PopupMenuDivider(),
        _buildGroupHeader('RESEARCH'),
        _buildModelMenuItem(AIModelConfig.geminiResearch, FontAwesomeIcons.magnifyingGlass),
        _buildModelMenuItem(AIModelConfig.geminiDeepResearch, FontAwesomeIcons.microscope),
        const PopupMenuDivider(),
        _buildGroupHeader('MEDIA'),
        _buildModelMenuItem(AIModelConfig.imagen4, FontAwesomeIcons.image),
        _buildModelMenuItem(AIModelConfig.veo31, FontAwesomeIcons.video),
        if (AppConfig.isStaging) ...[
          const PopupMenuDivider(),
          _buildGroupHeader('EDGE / EXPERIMENTAL'),
          _buildModelMenuItem(AIModelConfig.gemma3Fast, FontAwesomeIcons.gem),
          _buildModelMenuItem(AIModelConfig.gemma3Quality, FontAwesomeIcons.gem),
          _buildModelMenuItem(AIModelConfig.gemma2n, FontAwesomeIcons.microchip),
        ],
      ],
      onSelected: (config) {
        setState(() => _selectedModelConfig = config);
      },
    );
  }

  PopupMenuItem<AIModelConfig> _buildGroupHeader(String title) {
    return PopupMenuItem<AIModelConfig>(
      enabled: false,
      height: 24,
      child: Text(
        title, 
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2)
      ),
    );
  }

  PopupMenuItem<AIModelConfig> _buildModelMenuItem(AIModelConfig config, IconData icon) {
    return PopupMenuItem<AIModelConfig>(
      value: config,
      child: Row(
        children: [
          Icon(icon, size: 14, color: _selectedModelConfig == config ? Colors.blueAccent : Colors.white54),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              config.displayName,
              style: TextStyle(color: _selectedModelConfig == config ? Colors.blueAccent : Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getModelIcon(AIModelConfig config) {
    switch (config.provider) {
      case AIProvider.gemini: return FontAwesomeIcons.google;
      case AIProvider.vertex: return FontAwesomeIcons.cloud;
      case AIProvider.gemma: return FontAwesomeIcons.gem;
      case AIProvider.litert: return FontAwesomeIcons.mobileScreen;
    }
  }

  Widget _buildPendingAttachmentsBar() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingAttachments.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 12, color: Colors.blueAccent),
                const SizedBox(width: 6),
                Text(_pendingAttachments[index].name, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => setState(() => _pendingAttachments.removeAt(index)),
                  child: const Icon(Icons.close, size: 14, color: Colors.white38),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVoiceButton() {
    return Consumer(
      builder: (context, ref, _) {
        final voiceSvc = ref.watch(voiceServiceProvider);
        final isListening = voiceSvc.isListening;
        final isEnglish = voiceSvc.currentLocale == 'en-US';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Language Toggle
            InkWell(
              onTap: () {
                final nextLocale = isEnglish ? 'es-EC' : 'en-US';
                voiceSvc.setLocale(nextLocale);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  isEnglish ? "🇺🇸" : "🇪🇨",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: isListening ? Colors.redAccent : Colors.white38,
                size: 20,
              ),
              onPressed: () {
                if (isListening) {
                  voiceSvc.stopListening();
                } else {
                  voiceSvc.startListening((text) {
                    if (!mounted) return;
                    
                    // INTENT PROCESSING
                    final intent = VoiceCommandProcessor.process(text, voiceSvc.currentLocale);
                    if (intent != null) {
                      _handleVoiceIntent(intent);
                    } else {
                      _textController.text = text;
                      _handleSend(); 
                    }
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleVoiceIntent(VoiceIntent intent) {
    switch (intent.type) {
      case VoiceIntentType.switchAgent:
        setState(() => _selectedModelConfig = intent.data as AIModelConfig);
        break;
      case VoiceIntentType.clearChat:
        // Future: Clear session logic
        break;
      case VoiceIntentType.sendText:
        _handleSend();
        break;
    }
  }
}
