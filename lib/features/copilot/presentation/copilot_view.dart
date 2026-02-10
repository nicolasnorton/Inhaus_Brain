import 'package:ag_ui/ag_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/copilot_repository.dart';
import '../../../core/architecture/blackboard.dart';
import '../../chat/widgets/approval_card.dart';



class CopilotView extends ConsumerStatefulWidget {
  const CopilotView({super.key});

  @override
  ConsumerState<CopilotView> createState() => _CopilotViewState();
}

class _CopilotViewState extends ConsumerState<CopilotView> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.isEmpty) return;

    final userMsg = UserMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      _controller.clear();
    });
    
    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final repo = ref.read(copilotRepositoryProvider);

    repo.sendMessage(text, history: _messages).listen((event) {
        if (event is TextMessageContentEvent) {
             _handleTextDelta(event.delta);
        } else if (event is TextMessageChunkEvent) {
             if (event.delta != null) {
                _handleTextDelta(event.delta!);
             }
        } else if (event is RunFinishedEvent) {
             setState(() => _isLoading = false);
        } else if (event is RunErrorEvent) {
            setState(() {
                 _isLoading = false;
                 // Add system error message
                 // SystemMessage require content
                 _messages.add(SystemMessage(id: 'err', content: 'Error: ${event.code} - ${event.message}'));
            });
        }
    }, onError: (err) {
        setState(() {
            _isLoading = false;
            _messages.add(SystemMessage(id: 'err', content: 'Connection Error: $err'));
        });
    });
  }

  void _handleTextDelta(String delta) {
      setState(() {
         if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
             final last = _messages.last as AssistantMessage;
             final newContent = (last.content ?? '') + delta;
             _messages.last = last.copyWith(content: newContent);
         } else {
             _messages.add(AssistantMessage(
                 id: DateTime.now().toString(),
                 content: delta,
             ));
         }
      });
  }

  @override
  Widget build(BuildContext context) {
    final blackboardState = ref.watch(blackboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inhaus Copilot')),
      body: Column(
        children: [
          Expanded(
            child: FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(),
              descendantsAreFocusable: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.role == MessageRole.user;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      child: Text(
                        msg.content ?? '',
                        style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          _isLoading 
            ? const LinearProgressIndicator()
            : const SizedBox(height: 4),
          if (blackboardState.phase == BlackboardPhase.reviewPending)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               child: ApprovalCard(
                 title: "Review Required",
                 description: "The agent has proposed a strategy or content. Please review to proceed.",
                 onApprove: () {
                    ref.read(blackboardProvider.notifier).transitionTo(BlackboardPhase.copywriting);
                 },
                 onReject: (feedback) {
                    _controller.text = "Feedback: $feedback";
                    _sendMessage();
                    // Agent logic (AssistantService) should see the feedback and phase state
                    ref.read(blackboardProvider.notifier).transitionTo(BlackboardPhase.strategy);
                 },
               ),
             ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: 'Ask Copilot...',
                        border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
