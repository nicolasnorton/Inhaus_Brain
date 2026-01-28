import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:share_plus/share_plus.dart'; // Future integration

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/services/telemetry_service.dart';

enum FeedbackState { none, thumbsUp, thumbsDown }

class MessageActionsRow extends ConsumerStatefulWidget {
  final String messageId; // Added for tracking
  final String content;
  final bool isUser;
  final String? modelName;
  final VoidCallback? onDownload;
  final VoidCallback? onReport;

  const MessageActionsRow({
    super.key,
    required this.messageId,
    required this.content,
    required this.isUser,
    this.modelName,
    this.onDownload,
    this.onReport,
  });

  @override
  ConsumerState<MessageActionsRow> createState() => _MessageActionsRowState();
}

class _MessageActionsRowState extends ConsumerState<MessageActionsRow> {
  FeedbackState _feedback = FeedbackState.none;
  bool _isCopied = false;

  void _handleFeedback(FeedbackState state) {
    setState(() {
      if (_feedback == state) {
        _feedback = FeedbackState.none;
      } else {
        _feedback = state;
      }
    });
    
    if (state != FeedbackState.none) {
      final isPositive = state == FeedbackState.thumbsUp;
      ref.read(telemetryServiceProvider).logFeedback(
        messageId: widget.messageId,
        content: widget.content, // Telemetry service handles privacy (only logs length/hash if configured)
        isPositive: isPositive,
        modelName: widget.modelName,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPositive ? 'Thanks for the feedback!' : 'Thanks! We will improve this.'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    setState(() => _isCopied = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isCopied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show actions for AI messages, or simplified actions for user
    if (widget.isUser) {
      return const SizedBox.shrink(); // Or maybe just copy/edit?
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // Model Label
          if (widget.modelName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Model: ${widget.modelName}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
          ] else
            const Spacer(),

          // Actions
          _buildIconButton(
            icon: _feedback == FeedbackState.thumbsUp ? Icons.thumb_up : Icons.thumb_up_outlined,
            color: _feedback == FeedbackState.thumbsUp ? Colors.greenAccent : Colors.white24,
            onPressed: () => _handleFeedback(FeedbackState.thumbsUp),
            tooltip: 'Good response',
          ),
          _buildIconButton(
            icon: _feedback == FeedbackState.thumbsDown ? Icons.thumb_down : Icons.thumb_down_outlined,
            color: _feedback == FeedbackState.thumbsDown ? Colors.redAccent : Colors.white24,
            onPressed: () => _handleFeedback(FeedbackState.thumbsDown),
            tooltip: 'Bad response',
          ),
          _buildIconButton(
            icon: _isCopied ? Icons.check : Icons.content_copy,
            color: _isCopied ? Colors.greenAccent : Colors.white24,
            onPressed: _handleCopy,
            tooltip: 'Copy',
          ),
          
          // More Menu
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: const Color(0xFF1E1E1E),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16, color: Colors.white24),
              tooltip: 'More actions',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              position: PopupMenuPosition.under,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 16, color: Colors.white70),
                      SizedBox(width: 12),
                      Text('Download to device', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'docs',
                  child: Row(
                    children: [
                      Icon(FontAwesomeIcons.fileLines, size: 16, color: Colors.blueAccent),
                      SizedBox(width: 12),
                      Text('Export to Docs', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'gmail',
                  child: Row(
                    children: [
                      Icon(FontAwesomeIcons.envelope, size: 16, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Text('Draft in Gmail', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 16, color: Colors.orangeAccent),
                      SizedBox(width: 12),
                      Text('Report issue', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'download':
                    widget.onDownload?.call();
                    break;
                  case 'report':
                    widget.onReport?.call();
                    // Fallback visual feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted for review')),
                    );
                    break;
                  case 'docs':
                  case 'gmail':
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exporting to $value... (Placeholder)')),
                    );
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      splashRadius: 16,
    );
  }
}
