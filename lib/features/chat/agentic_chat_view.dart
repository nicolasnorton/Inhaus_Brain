import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'providers/chat_provider.dart';
import 'models/chat_models.dart';
import '../campaigns/widgets/multi_modal_input_section.dart';
import '../campaigns/models/campaign.dart';
import '../knowledge/widgets/knowledge_library_widget.dart';
import '../settings/profile_settings_screen.dart';
import '../../core/auth/auth_service.dart';
import '../../core/tokens/llm_provider.dart';

class AgenticChatView extends ConsumerStatefulWidget {
  const AgenticChatView({super.key});

  @override
  ConsumerState<AgenticChatView> createState() => _AgenticChatViewState();
}

class _AgenticChatViewState extends ConsumerState<AgenticChatView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<Attachment> _pendingAttachments = [];
  AIModelConfig _selectedModelConfig = AIModelConfig.geminiFlash;

  void _handleSend() {
    if (_textController.text.isEmpty && _pendingAttachments.isEmpty) return;
    
    ref.read(chatProvider.notifier).sendMessage(
      _textController.text,
      attachments: _pendingAttachments,
      modelConfig: _selectedModelConfig,
    );
    
    _textController.clear();
    setState(() => _pendingAttachments = []);
    
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

    return Column(
      children: [
        Expanded(
          child: session == null || session.messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: session.messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(session.messages[index]);
                  },
                ),
        ),
        _buildInputArea(),
      ],
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
            'Ask the Research or Creative Agent for help.',
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blueAccent : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : null,
                      bottomLeft: !isUser ? const Radius.circular(4) : null,
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (message.attachments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildAttachmentsList(message.attachments),
                      ],
                    ],
                  ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Text(
            message.content,
            style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList(List<Attachment> attachments) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((a) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_file, size: 12, color: Colors.white38),
            const SizedBox(width: 4),
            Text(a.name, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
      )).toList(),
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
            Row(
              children: [
                _buildModelPicker(),
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
                    onSubmitted: (_) => _handleSend(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Collaborate with agents...',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  Widget _buildModelPicker() {
    return PopupMenuButton<AIModelConfig>(
      tooltip: 'Select AI Model',
      color: const Color(0xFF1E1E1E),
      offset: const Offset(0, -200),
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
        _buildModelMenuItem(AIModelConfig.geminiFlash, FontAwesomeIcons.bolt),
        _buildModelMenuItem(AIModelConfig.geminiPro, FontAwesomeIcons.google),
        _buildModelMenuItem(AIModelConfig.gpt4o, FontAwesomeIcons.microchip),
        _buildModelMenuItem(AIModelConfig.claude3Sonnet, FontAwesomeIcons.brain),
        _buildModelMenuItem(AIModelConfig.grok1, FontAwesomeIcons.xTwitter),
      ],
      onSelected: (config) {
        setState(() => _selectedModelConfig = config);
      },
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
      case AIProvider.openai: return FontAwesomeIcons.microchip;
      case AIProvider.claude: return FontAwesomeIcons.brain;
      case AIProvider.grok: return FontAwesomeIcons.xTwitter;
      default: return FontAwesomeIcons.robot;
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
}
