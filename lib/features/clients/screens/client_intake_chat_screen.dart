import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../chat/models/chat_models.dart';
import '../models/client_model.dart';
import '../models/intake_field_model.dart';
import '../providers/client_intake_provider.dart';

class ClientIntakeChatScreen extends ConsumerStatefulWidget {
  const ClientIntakeChatScreen({super.key});

  @override
  ConsumerState<ClientIntakeChatScreen> createState() =>
      _ClientIntakeChatScreenState();
}

class _ClientIntakeChatScreenState
    extends ConsumerState<ClientIntakeChatScreen> with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _send([String? override]) {
    final text = override ?? _inputController.text;
    if (text.trim().isEmpty &&
        ref.read(intakeConversationProvider).currentField?.isRequired == true) {
      return;
    }
    _inputController.clear();
    ref.read(intakeConversationProvider.notifier).handleUserResponse(text);
    _scrollToBottom();
  }

  Future<void> _confirm() async {
    final success =
        await ref.read(intakeConversationProvider.notifier).submitClient();
    if (success && mounted) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(intakeConversationProvider);

    ref.listen<IntakeConversationState>(intakeConversationProvider,
        (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: _buildAppBar(state),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              itemCount: state.messages.length +
                  (state.isComplete && !state.isSaving ? 1 : 0) +
                  (state.isResearching ? 1 : 0) +
                  (state.researchResults != null && !state.researchConfirmed ? 1 : 0),
              itemBuilder: (context, index) {
                // Messages
                if (index < state.messages.length) {
                  return _MessageBubble(
                    message: state.messages[index],
                    index: index,
                  );
                }

                final offset = index - state.messages.length;

                // Research spinner
                if (state.isResearching && offset == 0) {
                  return const _ResearchingIndicator();
                }

                // Research results card
                final researchOffset = state.isResearching ? 1 : 0;
                if (state.researchResults != null &&
                    !state.researchConfirmed &&
                    offset == researchOffset) {
                  return _ResearchCard(
                    results: state.researchResults!,
                    onConfirm: () => ref
                        .read(intakeConversationProvider.notifier)
                        .confirmResearch(),
                    onEdit: () => ref
                        .read(intakeConversationProvider.notifier)
                        .skipResearch(),
                  );
                }

                // Summary card
                if (state.isComplete && !state.isSaving) {
                  return _SummaryCard(
                    data: state.collectedData,
                    clientType: state.clientType,
                    fields: state.fields,
                    onConfirm: _confirm,
                    onEdit: () =>
                        ref.read(intakeConversationProvider.notifier).reset(),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          if (!state.isComplete && !state.isResearching &&
              !(state.researchResults != null && !state.researchConfirmed))
            _buildChips(state),
          if (!state.isComplete && !state.isResearching &&
              !(state.researchResults != null && !state.researchConfirmed))
            _buildInputBar(state),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(IntakeConversationState state) {
    return AppBar(
      backgroundColor: const Color(0xFF0E1117),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white60, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          // Animated avatar with gradient ring
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C5CE7),
                  const Color(0xFFA29BFE),
                  const Color(0xFF6C5CE7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFF0E1117),
              child: Icon(Icons.smart_toy_rounded, size: 16, color: Color(0xFFA29BFE)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
                ).createShader(bounds),
                child: const Text(
                  'Onboarding Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Text(
                'Client Intake',
                style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.restart_alt_rounded, color: Colors.white24, size: 20),
          tooltip: 'Restart',
          onPressed: () =>
              ref.read(intakeConversationProvider.notifier).reset(),
        ),
      ],
      bottom: state.clientType != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: _ProgressDots(
                total: state.fields.length,
                current: state.currentFieldIndex.clamp(0, state.fields.length),
              ),
            )
          : null,
    );
  }

  Widget _buildChips(IntakeConversationState state) {
    if (state.clientType == null) {
      return _ChipRow(
        options: const ['🏢 Corporate', '👤 Independent'],
        onTap: _send,
      );
    }
    final field = state.currentField;
    if (field != null && field.type == IntakeFieldType.selection) {
      return _ChipRow(options: field.options, onTap: _send);
    }
    if (field != null && !field.isRequired) {
      return _ChipRow(options: const ['Skip →'], onTap: _send);
    }
    return const SizedBox.shrink();
  }

  Widget _buildInputBar(IntakeConversationState state) {
    final field = state.currentField;
    final isSelection = field?.type == IntakeFieldType.selection;
    final hint = field?.hint ?? 'Type your answer...';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 80, 16), // 80px right for Brian's FAB
      decoration: BoxDecoration(
        color: const Color(0xFF0E1117),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Send button on the LEFT
            _SendButton(
              onTap: isSelection ? null : () => _send(),
              enabled: !isSelection,
            ),
            const SizedBox(width: 10),
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                  ),
                  color: Colors.white.withValues(alpha: 0.04),
                ),
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  enabled: !isSelection,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: isSelection ? 'Tap a choice above' : hint,
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Send Button ─────────────────────────────────────────────────

class _SendButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool enabled;
  const _SendButton({this.onTap, this.enabled = true});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _ctrl.reverse() : null,
      onTapUp: widget.enabled
          ? (_) {
              _ctrl.forward();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.enabled ? () => _ctrl.forward() : null,
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.enabled
                  ? [const Color(0xFF6C5CE7), const Color(0xFF8B7CF6)]
                  : [Colors.white10, Colors.white10],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            Icons.arrow_upward_rounded,
            color: widget.enabled ? Colors.white : Colors.white24,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── Progress Dots ───────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;
  const _ProgressDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: List.generate(total, (i) {
          final isActive = i <= current;
          final isCurrent = i == current;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              height: isCurrent ? 4 : 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive
                    ? const Color(0xFF6C5CE7)
                    : Colors.white.withValues(alpha: 0.06),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Message Bubble ──────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;
  const _MessageBubble({required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(isUser ? 16 : -16, 0) * (1 - value),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              // Agent avatar with gradient ring
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                  ),
                ),
                child: const CircleAvatar(
                  radius: 13,
                  backgroundColor: Color(0xFF0A0C10),
                  child: Icon(Icons.smart_toy_rounded, size: 13, color: Color(0xFFA29BFE)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF5A4BD1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser ? null : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  border: isUser
                      ? null
                      : Border.all(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                        ),
                  boxShadow: isUser
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: _RichText(message.content, isUser: isUser),
              ),
            ),
            if (isUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// ── Rich Text ──────────────────────────────────────────────────

class _RichText extends StatelessWidget {
  final String text;
  final bool isUser;
  const _RichText(this.text, {this.isUser = false});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.82),
          fontSize: 14,
          height: 1.5,
          letterSpacing: 0.1,
        ),
        children: spans,
      ),
    );
  }
}

// ── Chip Row ────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final ValueChanged<String> onTap;
  const _ChipRow({required this.options, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: options
            .map((opt) => _AnimatedChip(label: opt, onTap: () => onTap(opt)))
            .toList(),
      ),
    );
  }
}

class _AnimatedChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _AnimatedChip({required this.label, required this.onTap});

  @override
  State<_AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<_AnimatedChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                  const Color(0xFF6C5CE7).withValues(alpha: 0.04),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Color(0xFFA29BFE),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Researching Indicator ───────────────────────────────────────

class _ResearchingIndicator extends StatefulWidget {
  const _ResearchingIndicator();

  @override
  State<_ResearchingIndicator> createState() => _ResearchingIndicatorState();
}

class _ResearchingIndicatorState extends State<_ResearchingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              ),
            ),
            child: const CircleAvatar(
              radius: 13,
              backgroundColor: Color(0xFF0A0C10),
              child: Icon(Icons.smart_toy_rounded, size: 13, color: Color(0xFFA29BFE)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      const Color(0xFFA29BFE).withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
                  ).createShader(bounds),
                  child: const Text(
                    '🔍 Researching company info...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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

// ── Research Card ───────────────────────────────────────────────

class _ResearchCard extends StatelessWidget {
  final Map<String, String> results;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  const _ResearchCard({
    required this.results,
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              const Color(0xFF0A0C10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.travel_explore_rounded,
                      color: Color(0xFFA29BFE), size: 20),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
                    ).createShader(bounds),
                    child: const Text(
                      'Research Results',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Fields
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                children: results.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6, right: 10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            _formatKey(e.key),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white38,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ask me instead', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Use these', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .replaceFirst(key[0], key[0].toUpperCase())
        .trim();
  }
}

// ── Summary Card ────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final Map<String, String> data;
  final ClientType? clientType;
  final List<IntakeFormField> fields;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const _SummaryCard({
    required this.data,
    required this.clientType,
    required this.fields,
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C5CE7).withValues(alpha: 0.08),
              const Color(0xFF0A0C10),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fact_check_rounded,
                      color: Color(0xFFA29BFE), size: 20),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
                    ).createShader(bounds),
                    child: const Text(
                      'Client Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                    ),
                    child: Text(
                      clientType == ClientType.independent
                          ? 'Independent'
                          : 'Corporate',
                      style: const TextStyle(
                        color: Color(0xFFA29BFE),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Data rows
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                children: fields.where((f) => data.containsKey(f.key)).map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            f.label,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            data[f.key] ?? '—',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Start Over', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white38,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('Confirm & Create', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
