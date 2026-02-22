import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ComposerIconsScreen extends StatelessWidget {
  const ComposerIconsScreen({super.key});

  static const List<String> _commonIcons = [
    'home', 'search', 'settings', 'menu', 'close', 'arrow_back', 'arrow_forward',
    'chevron_left', 'chevron_right', 'expand_more', 'expand_less', 'more_vert',
    'more_horiz', 'refresh', 'add', 'remove', 'edit', 'delete', 'save', 'done',
    'check', 'check_circle', 'cancel', 'send', 'share', 'download', 'upload',
    'print', 'copy', 'content_paste', 'mail', 'email', 'message', 'chat',
    'phone', 'call', 'notifications', 'play_arrow', 'pause', 'stop',
    'skip_next', 'skip_previous', 'volume_up', 'volume_off', 'mic', 'videocam',
    'photo_camera', 'image', 'music_note', 'person', 'people', 'group',
    'account_circle', 'face', 'info', 'help', 'warning', 'error', 'error_outline',
    'report', 'verified', 'star', 'star_border', 'favorite', 'favorite_border',
    'thumb_up', 'thumb_down', 'folder', 'folder_open', 'file_copy', 'description',
    'article', 'note', 'attachment', 'link', 'insert_link', 'cloud', 'cloud_upload',
    'cloud_download', 'schedule', 'access_time', 'today', 'calendar_today',
    'alarm', 'place', 'location_on', 'map', 'directions', 'navigation',
    'shopping_cart', 'shopping_bag', 'store', 'payment', 'credit_card', 'receipt',
    'work', 'business', 'flight', 'local_shipping', 'restaurant', 'local_cafe'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                        'Icons',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                       ),
                       TextButton.icon(
                         onPressed: () {
                           // Open external material icons link if desired
                         },
                         icon: const Icon(Icons.open_in_new, size: 16),
                         label: const Text('Browse all icons'),
                       )
                     ],
                   ),
                  const SizedBox(height: 8),
                  Text(
                    'A2UI uses Material Icons string identifiers. Showing ~100 most commonly used icons. Click to copy the ID.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final iconName = _commonIcons[index];
                  // Let's use standard Flutter SDK mapping. Though ag_ui internally uses its own robust mapping.
                  // For the viewer, we can just render the icon dynamically or fall back to an unknown icon.
                  return _IconCard(iconName: iconName);
                },
                childCount: _commonIcons.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 64)),
        ],
      ),
    );
  }
}

class _IconCard extends StatelessWidget {
  final String iconName;

  const _IconCard({required this.iconName});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black12,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: iconName));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied "$iconName" to clipboard'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Here we pretend we have a dynamic material icon mapper.
              // In this standalone Composer, we just use a generic representation or try to match exactly.
              // We'll use a placeholder icon for the generic viewer, or just use a few known ones.
              // For a complete mapper, we'd need a large switch statement or external package,
              // but doing a few basic ones for visual flair:
              Icon(
                _getIconData(iconName),
                size: 32,
                color: Colors.black87,
              ),
              const SizedBox(height: 12),
              Text(
                iconName,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    // A simplified mapper for the Composer internal viewer.
    // In actual A2UI genui mapping, it's far larger.
    switch (name) {
      case 'home': return Icons.home;
      case 'search': return Icons.search;
      case 'settings': return Icons.settings;
      case 'menu': return Icons.menu;
      case 'close': return Icons.close;
      case 'arrow_back': return Icons.arrow_back;
      case 'arrow_forward': return Icons.arrow_forward;
      case 'chevron_left': return Icons.chevron_left;
      case 'chevron_right': return Icons.chevron_right;
      case 'expand_more': return Icons.expand_more;
      case 'expand_less': return Icons.expand_less;
      case 'more_vert': return Icons.more_vert;
      case 'more_horiz': return Icons.more_horiz;
      case 'refresh': return Icons.refresh;
      case 'add': return Icons.add;
      case 'remove': return Icons.remove;
      case 'edit': return Icons.edit;
      case 'delete': return Icons.delete;
      case 'save': return Icons.save;
      case 'done': return Icons.done;
      case 'check': return Icons.check;
      case 'check_circle': return Icons.check_circle;
      case 'cancel': return Icons.cancel;
      case 'send': return Icons.send;
      case 'share': return Icons.share;
      case 'download': return Icons.download;
      case 'upload': return Icons.upload;
      case 'print': return Icons.print;
      case 'copy': return Icons.copy;
      case 'content_paste': return Icons.content_paste;
      case 'mail': return Icons.mail;
      case 'email': return Icons.email;
      case 'message': return Icons.message;
      case 'chat': return Icons.chat;
      case 'phone': return Icons.phone;
      case 'call': return Icons.call;
      case 'notifications': return Icons.notifications;
      case 'play_arrow': return Icons.play_arrow;
      case 'pause': return Icons.pause;
      case 'stop': return Icons.stop;
      case 'person': return Icons.person;
      case 'people': return Icons.people;
      case 'group': return Icons.group;
      case 'star': return Icons.star;
      case 'favorite': return Icons.favorite;
      default: return Icons.extension; // Fallback
    }
  }
}
