import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_audio_player.dart';
import 'video_player_widget.dart';

/// A recursive renderer for the Atomic A2UI Spec.
///
/// This renderer handles the nested, component-tree style JSON schema
/// that mirrors Flutter's own widget tree. It enables rendering of standard
/// Material 3 widgets dynamically from JSON, achieving parity with the
/// Flutter Material widget catalog.
///
/// **Schema Format:**
/// ```json
/// {
///   "id": "unique-id",
///   "component": {
///     "WidgetType": { ...props... }
///   },
///   "children": [ ...child nodes... ]
/// }
/// ```
class AtomicUIRenderer extends StatelessWidget {
  final Map<String, dynamic> node;

  const AtomicUIRenderer({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    // The node should have a "component" key with a single entry.
    final componentMap = node['component'] as Map<String, dynamic>?;
    if (componentMap == null || componentMap.isEmpty) {
      return const SizedBox.shrink();
    }

    final widgetType = componentMap.keys.first;
    final props = (componentMap[widgetType] as Map<String, dynamic>?) ?? {};

    // Resolve children recursively
    final childrenRaw = node['children'] as List?;
    final children = childrenRaw
        ?.map((c) => c is Map<String, dynamic> ? AtomicUIRenderer(node: c) : const SizedBox.shrink())
        .toList()
        .cast<Widget>() ?? [];

    // A single child shorthand: `"child": "child-id"` is used for
    // components that wrap a single child (Card, Container, etc.)
    // In the flat-list spec the IDs would resolve, but in the nested spec
    // the child is inline, so we just pick the first child if available.
    Widget? singleChild = children.isNotEmpty ? children.first : null;

    switch (widgetType) {
      // ─── Layout ──────────────────────────────────────────────
      case 'Row':
        return Row(
          mainAxisAlignment: _mainAxis(props['distribution']),
          crossAxisAlignment: _crossAxis(props['alignment']),
          mainAxisSize: MainAxisSize.min,
          children: _applyGap(children, props['gap'], Axis.horizontal),
        );

      case 'Column':
        return Column(
          mainAxisAlignment: _mainAxis(props['distribution']),
          crossAxisAlignment: _crossAxis(props['alignment']),
          mainAxisSize: MainAxisSize.min,
          children: _applyGap(children, props['gap'], Axis.vertical),
        );

      case 'Stack':
        return Stack(
          alignment: _alignment(props['alignment']),
          children: children,
        );

      case 'Wrap':
        return Wrap(
          spacing: _double(props['spacing'], 8),
          runSpacing: _double(props['runSpacing'], 8),
          alignment: _wrapAlignment(props['alignment']),
          children: children,
        );

      case 'Expanded':
        return Expanded(
          flex: (props['flex'] as int?) ?? 1,
          child: singleChild ?? const SizedBox.shrink(),
        );

      case 'Padding':
        return Padding(
          padding: _edgeInsets(props['padding']),
          child: singleChild ?? (children.isNotEmpty ? Column(mainAxisSize: MainAxisSize.min, children: children) : const SizedBox.shrink()),
        );

      case 'Center':
        return Center(child: singleChild ?? const SizedBox.shrink());

      case 'SizedBox':
        return SizedBox(
          width: _doubleOrNull(props['width']),
          height: _doubleOrNull(props['height']),
          child: singleChild,
        );

      case 'AspectRatio':
        return AspectRatio(
          aspectRatio: _double(props['aspectRatio'], 1.0),
          child: singleChild ?? const SizedBox.shrink(),
        );

      // ─── Content ─────────────────────────────────────────────
      case 'Text':
        final text = _resolveText(props['text']);
        return Text(
          text,
          style: _textStyle(context, props),
          textAlign: _textAlign(props['alignment']),
          maxLines: props['maxLines'] as int?,
          overflow: props['maxLines'] != null ? TextOverflow.ellipsis : null,
        );

      case 'Icon':
        return Icon(
          _resolveIcon(props['icon']),
          size: _double(props['size'], 24),
          color: _resolveColor(props['color']),
        );

      case 'Image':
        final url = props['url']?.toString() ?? '';
        final fit = _boxFit(props['fit']);
        if (url.isEmpty) return const SizedBox(width: 100, height: 100, child: Icon(Icons.broken_image, color: Colors.grey));
        return ClipRRect(
          borderRadius: BorderRadius.circular(_double(props['borderRadius'], 0)),
          child: Image.network(
            url,
            fit: fit,
            width: _doubleOrNull(props['width']),
            height: _doubleOrNull(props['height']),
            errorBuilder: (_, __, ___) => Container(
              width: _double(props['width'], 100),
              height: _double(props['height'], 100),
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );

      // ─── Media ───────────────────────────────────────────────
      case 'Video':
      case 'VideoPlayer':
        return VideoPlayerWidget(data: props);
        
      case 'AudioPlayer':
      case 'Audio':
        final audioUrl = props['url']?.toString() ?? props['audioUrl']?.toString() ?? '';
        if (audioUrl.isEmpty) return const SizedBox(height: 60, child: Center(child: Text('No audio URL provided', style: TextStyle(color: Colors.grey))));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: AppAudioPlayer(audioUrl: audioUrl),
        );

      // ─── Actions ─────────────────────────────────────────────
      case 'Button':
      case 'ElevatedButton':
        return ElevatedButton(
          onPressed: () {},
          style: _buttonStyle(context, props),
          child: _buttonChild(props),
        );

      case 'FilledButton':
        return FilledButton(
          onPressed: () {},
          style: _buttonStyle(context, props),
          child: _buttonChild(props),
        );

      case 'FilledTonalButton':
        return FilledButton.tonal(
          onPressed: () {},
          style: _buttonStyle(context, props),
          child: _buttonChild(props),
        );

      case 'OutlinedButton':
        return OutlinedButton(
          onPressed: () {},
          style: _buttonStyle(context, props),
          child: _buttonChild(props),
        );

      case 'TextButton':
        return TextButton(
          onPressed: () {},
          style: _buttonStyle(context, props),
          child: _buttonChild(props),
        );

      case 'IconButton':
        return IconButton(
          onPressed: () {},
          icon: Icon(_resolveIcon(props['icon']), size: _double(props['size'], 24)),
          color: _resolveColor(props['color']),
          tooltip: props['tooltip']?.toString(),
        );

      case 'FloatingActionButton':
      case 'FAB':
        return FloatingActionButton(
          onPressed: () {},
          mini: props['mini'] == true,
          tooltip: props['tooltip']?.toString(),
          child: Icon(_resolveIcon(props['icon'] ?? 'add')),
        );

      // ─── Containers ──────────────────────────────────────────
      case 'Card':
        return Card(
          elevation: _double(props['elevation'], 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_double(props['borderRadius'], 12))),
          clipBehavior: Clip.antiAlias,
          color: _resolveColor(props['color']),
          child: singleChild ?? (children.isNotEmpty
              ? Padding(
                  padding: _edgeInsets(props['padding'] ?? 16),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: children),
                )
              : const SizedBox.shrink()),
        );

      case 'Container':
        return Container(
          width: _doubleOrNull(props['width']),
          height: _doubleOrNull(props['height']),
          padding: _edgeInsets(props['padding']),
          margin: _edgeInsets(props['margin']),
          decoration: BoxDecoration(
            color: _resolveColor(props['color']),
            borderRadius: BorderRadius.circular(_double(props['borderRadius'], 0)),
            border: props['borderColor'] != null
                ? Border.all(color: _resolveColor(props['borderColor']) ?? Colors.grey, width: _double(props['borderWidth'], 1))
                : null,
          ),
          child: singleChild ?? (children.isNotEmpty
              ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: children)
              : null),
        );

      case 'ListTile':
        return ListTile(
          leading: props['leadingIcon'] != null ? Icon(_resolveIcon(props['leadingIcon'])) : null,
          title: Text(_resolveText(props['title'])),
          subtitle: props['subtitle'] != null ? Text(_resolveText(props['subtitle'])) : null,
          trailing: props['trailingIcon'] != null ? Icon(_resolveIcon(props['trailingIcon'])) : null,
          onTap: () {},
        );

      // ─── Inputs ──────────────────────────────────────────────
      case 'TextField':
        return TextField(
          decoration: InputDecoration(
            labelText: props['label']?.toString(),
            hintText: props['placeholder']?.toString() ?? props['hint']?.toString(),
            prefixIcon: props['prefixIcon'] != null ? Icon(_resolveIcon(props['prefixIcon'])) : null,
            suffixIcon: props['suffixIcon'] != null ? Icon(_resolveIcon(props['suffixIcon'])) : null,
            border: const OutlineInputBorder(),
            filled: props['filled'] == true,
          ),
        );

      case 'CheckBox':
      case 'Checkbox':
        return _StatefulCheckbox(label: props['label']?.toString(), initialValue: props['initialValue'] == true);

      case 'Switch':
        return _StatefulSwitch(label: props['label']?.toString(), initialValue: props['initialValue'] == true);

      case 'Slider':
        return _StatefulSlider(
          min: _double(props['min'], 0),
          max: _double(props['max'], 100),
          initialValue: _double(props['initialValue'], 50),
          label: props['label']?.toString(),
        );

      case 'Radio':
        return _StatefulRadio(options: _stringList(props['options']), label: props['label']?.toString());

      case 'DropdownMenu':
      case 'Dropdown':
        return _StatefulDropdown(options: _stringList(props['options']), label: props['label']?.toString());

      // ─── Chips ────────────────────────────────────────────────
      case 'Chip':
        return Chip(
          label: Text(_resolveText(props['label'])),
          avatar: props['icon'] != null ? Icon(_resolveIcon(props['icon']), size: 18) : null,
          deleteIcon: props['deletable'] == true ? const Icon(Icons.close, size: 16) : null,
          onDeleted: props['deletable'] == true ? () {} : null,
        );

      case 'ActionChip':
        return ActionChip(
          label: Text(_resolveText(props['label'])),
          avatar: props['icon'] != null ? Icon(_resolveIcon(props['icon']), size: 18) : null,
          onPressed: () {},
        );

      case 'FilterChip':
        return _StatefulFilterChip(label: _resolveText(props['label']), selected: props['selected'] == true);

      case 'ChoiceChip':
        return _StatefulChoiceChip(label: _resolveText(props['label']), selected: props['selected'] == true);

      case 'InputChip':
        return InputChip(
          label: Text(_resolveText(props['label'])),
          avatar: props['icon'] != null ? Icon(_resolveIcon(props['icon']), size: 18) : null,
          onDeleted: () {},
          onPressed: () {},
        );

      // ─── Navigation ──────────────────────────────────────────
      case 'NavigationBar':
        final destinations = (props['destinations'] as List? ?? []).map((d) {
          if (d is Map<String, dynamic>) {
            return NavigationDestination(
              icon: Icon(_resolveIcon(d['icon'] ?? 'home')),
              selectedIcon: d['selectedIcon'] != null ? Icon(_resolveIcon(d['selectedIcon'])) : null,
              label: _resolveText(d['label']),
            );
          }
          return NavigationDestination(icon: const Icon(Icons.circle), label: d.toString());
        }).toList();
        if (destinations.length < 2) return const SizedBox.shrink();
        return NavigationBar(
          destinations: destinations,
          selectedIndex: (props['selectedIndex'] as int?) ?? 0,
          onDestinationSelected: (_) {},
        );

      case 'BottomAppBar':
        return BottomAppBar(
          child: children.isNotEmpty
              ? Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: children)
              : const SizedBox.shrink(),
        );

      case 'Tabs':
      case 'TabBar':
        final tabs = _stringList(props['tabs'] ?? props['labels']);
        if (tabs.isEmpty) return const SizedBox.shrink();
        return _StatefulTabs(tabs: tabs, children: children);

      // ─── Feedback / Progress ──────────────────────────────────
      case 'ProgressIndicator':
      case 'LinearProgressIndicator':
        final value = _doubleOrNull(props['value']);
        return LinearProgressIndicator(value: value);

      case 'CircularProgressIndicator':
        final value = _doubleOrNull(props['value']);
        return CircularProgressIndicator(value: value);

      case 'Badge':
        return Badge(
          label: props['label'] != null ? Text(_resolveText(props['label'])) : null,
          child: singleChild ?? Icon(_resolveIcon(props['icon'] ?? 'notifications')),
        );

      case 'SnackBarPreview':
        // Renders a simulated SnackBar inline (can't actually show a real one in a tree)
        return Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(4),
          color: const Color(0xFF323232),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(child: Text(_resolveText(props['message'] ?? 'Snackbar message'), style: const TextStyle(color: Colors.white))),
                if (props['actionLabel'] != null)
                  TextButton(onPressed: () {}, child: Text(_resolveText(props['actionLabel']), style: const TextStyle(color: Colors.amber))),
              ],
            ),
          ),
        );

      // ─── Decoration ──────────────────────────────────────────
      case 'Divider':
        return Divider(
          thickness: _double(props['thickness'], 1),
          color: _resolveColor(props['color']),
          height: _double(props['height'], 16),
        );

      // ─── Segmented Button ─────────────────────────────────────
      case 'SegmentedButton':
        final segments = _stringList(props['segments'] ?? props['options']);
        if (segments.isEmpty) return const SizedBox.shrink();
        return _StatefulSegmentedButton(segments: segments, selectedIndex: (props['selectedIndex'] as int?) ?? 0);

      // ─── Tooltip ──────────────────────────────────────────────
      case 'Tooltip':
        return Tooltip(
          message: _resolveText(props['message'] ?? props['text']),
          child: singleChild ?? const Icon(Icons.info_outline),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            border: Border.all(color: Colors.amber),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Unknown atomic widget: $widgetType', style: const TextStyle(color: Colors.amber, fontSize: 12)),
        );
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────

  static String _resolveText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map && value['value'] != null) return value['value'].toString();
    return value.toString();
  }

  static List<String> _stringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static double _double(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static double? _doubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static Widget _buttonChild(Map<String, dynamic> props) {
    final label = _resolveText(props['label'] ?? props['text']);
    final iconName = props['icon']?.toString();
    if (iconName != null && label.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_resolveIcon(iconName), size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    if (label.isNotEmpty) return Text(label);
    if (iconName != null) return Icon(_resolveIcon(iconName), size: 18);
    return const Text('Button');
  }

  static ButtonStyle? _buttonStyle(BuildContext context, Map<String, dynamic> props) {
    final bgColor = _resolveColor(props['backgroundColor']);
    final fgColor = _resolveColor(props['foregroundColor']);
    if (bgColor == null && fgColor == null) return null;
    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
    );
  }

  static TextStyle _textStyle(BuildContext context, Map<String, dynamic> props) {
    final theme = Theme.of(context).textTheme;
    final style = props['style']?.toString() ?? 'body';
    final color = _resolveColor(props['color']);
    final fontWeight = props['bold'] == true ? FontWeight.bold : null;
    final fontSize = _doubleOrNull(props['fontSize']);

    TextStyle base;
    switch (style) {
      case 'displayLarge':
        base = theme.displayLarge ?? const TextStyle(fontSize: 57);
        break;
      case 'displayMedium':
        base = theme.displayMedium ?? const TextStyle(fontSize: 45);
        break;
      case 'displaySmall':
        base = theme.displaySmall ?? const TextStyle(fontSize: 36);
        break;
      case 'headlineLarge':
        base = theme.headlineLarge ?? const TextStyle(fontSize: 32);
        break;
      case 'headlineMedium':
      case 'headline':
        base = theme.headlineMedium ?? const TextStyle(fontSize: 28);
        break;
      case 'headlineSmall':
        base = theme.headlineSmall ?? const TextStyle(fontSize: 24);
        break;
      case 'titleLarge':
        base = theme.titleLarge ?? const TextStyle(fontSize: 22);
        break;
      case 'titleMedium':
      case 'subhead':
        base = theme.titleMedium ?? const TextStyle(fontSize: 16);
        break;
      case 'titleSmall':
        base = theme.titleSmall ?? const TextStyle(fontSize: 14);
        break;
      case 'bodyLarge':
        base = theme.bodyLarge ?? const TextStyle(fontSize: 16);
        break;
      case 'bodyMedium':
      case 'body':
        base = theme.bodyMedium ?? const TextStyle(fontSize: 14);
        break;
      case 'bodySmall':
        base = theme.bodySmall ?? const TextStyle(fontSize: 12);
        break;
      case 'labelLarge':
        base = theme.labelLarge ?? const TextStyle(fontSize: 14);
        break;
      case 'labelMedium':
      case 'caption':
        base = theme.labelMedium ?? const TextStyle(fontSize: 12);
        break;
      case 'labelSmall':
        base = theme.labelSmall ?? const TextStyle(fontSize: 11);
        break;
      default:
        base = theme.bodyMedium ?? const TextStyle(fontSize: 14);
    }

    return base.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  static MainAxisAlignment _mainAxis(dynamic value) {
    switch (value?.toString()) {
      case 'center': return MainAxisAlignment.center;
      case 'end': return MainAxisAlignment.end;
      case 'spaceBetween': return MainAxisAlignment.spaceBetween;
      case 'spaceAround': return MainAxisAlignment.spaceAround;
      case 'spaceEvenly': return MainAxisAlignment.spaceEvenly;
      case 'start':
      default: return MainAxisAlignment.start;
    }
  }

  static CrossAxisAlignment _crossAxis(dynamic value) {
    switch (value?.toString()) {
      case 'center': return CrossAxisAlignment.center;
      case 'end': return CrossAxisAlignment.end;
      case 'start': return CrossAxisAlignment.start;
      case 'baseline': return CrossAxisAlignment.baseline;
      case 'stretch':
      default: return CrossAxisAlignment.stretch;
    }
  }

  static AlignmentGeometry _alignment(dynamic value) {
    switch (value?.toString()) {
      case 'topLeft': return Alignment.topLeft;
      case 'topCenter': return Alignment.topCenter;
      case 'topRight': return Alignment.topRight;
      case 'centerLeft': return Alignment.centerLeft;
      case 'centerRight': return Alignment.centerRight;
      case 'bottomLeft': return Alignment.bottomLeft;
      case 'bottomCenter': return Alignment.bottomCenter;
      case 'bottomRight': return Alignment.bottomRight;
      case 'center':
      default: return Alignment.center;
    }
  }

  static WrapAlignment _wrapAlignment(dynamic value) {
    switch (value?.toString()) {
      case 'center': return WrapAlignment.center;
      case 'end': return WrapAlignment.end;
      case 'spaceBetween': return WrapAlignment.spaceBetween;
      case 'spaceAround': return WrapAlignment.spaceAround;
      case 'spaceEvenly': return WrapAlignment.spaceEvenly;
      case 'start':
      default: return WrapAlignment.start;
    }
  }

  static TextAlign _textAlign(dynamic value) {
    switch (value?.toString()) {
      case 'center': return TextAlign.center;
      case 'right': return TextAlign.right;
      case 'end': return TextAlign.end;
      case 'justify': return TextAlign.justify;
      case 'left':
      case 'start':
      default: return TextAlign.start;
    }
  }

  static BoxFit _boxFit(dynamic value) {
    switch (value?.toString()) {
      case 'contain': return BoxFit.contain;
      case 'fill': return BoxFit.fill;
      case 'fitWidth': return BoxFit.fitWidth;
      case 'fitHeight': return BoxFit.fitHeight;
      case 'none': return BoxFit.none;
      case 'scaleDown': return BoxFit.scaleDown;
      case 'cover':
      default: return BoxFit.cover;
    }
  }

  static EdgeInsets _edgeInsets(dynamic value) {
    if (value == null) return EdgeInsets.zero;
    if (value is num) return EdgeInsets.all(value.toDouble());
    if (value is Map) {
      return EdgeInsets.only(
        top: _double(value['top'], 0),
        bottom: _double(value['bottom'], 0),
        left: _double(value['left'], 0),
        right: _double(value['right'], 0),
      );
    }
    return EdgeInsets.zero;
  }

  static List<Widget> _applyGap(List<Widget> children, dynamic gap, Axis axis) {
    if (children.isEmpty) return children;
    double gapSize = 0;
    if (gap is num) {
      gapSize = gap.toDouble();
    } else {
      switch (gap?.toString()) {
        case 'small': gapSize = 4; break;
        case 'medium': gapSize = 8; break;
        case 'large': gapSize = 16; break;
        case 'xlarge': gapSize = 24; break;
        default: gapSize = 0;
      }
    }
    if (gapSize <= 0) return children;

    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(SizedBox(
          width: axis == Axis.horizontal ? gapSize : 0,
          height: axis == Axis.vertical ? gapSize : 0,
        ));
      }
    }
    return result;
  }

  // ─── Icon Resolution ───────────────────────────────────────────
  static IconData _resolveIcon(dynamic value) {
    if (value == null) return Icons.circle;
    final name = value.toString().toLowerCase().replaceAll(' ', '_');

    const iconMap = <String, IconData>{
      'home': Icons.home,
      'settings': Icons.settings,
      'search': Icons.search,
      'add': Icons.add,
      'close': Icons.close,
      'check': Icons.check,
      'delete': Icons.delete,
      'edit': Icons.edit,
      'share': Icons.share,
      'favorite': Icons.favorite,
      'star': Icons.star,
      'person': Icons.person,
      'email': Icons.email,
      'phone': Icons.phone,
      'location_on': Icons.location_on,
      'calendar_today': Icons.calendar_today,
      'notifications': Icons.notifications,
      'menu': Icons.menu,
      'arrow_back': Icons.arrow_back,
      'arrow_forward': Icons.arrow_forward,
      'chevron_right': Icons.chevron_right,
      'chevron_left': Icons.chevron_left,
      'expand_more': Icons.expand_more,
      'expand_less': Icons.expand_less,
      'more_vert': Icons.more_vert,
      'more_horiz': Icons.more_horiz,
      'info': Icons.info,
      'info_outline': Icons.info_outline,
      'warning': Icons.warning,
      'error': Icons.error,
      'help': Icons.help,
      'visibility': Icons.visibility,
      'visibility_off': Icons.visibility_off,
      'lock': Icons.lock,
      'lock_open': Icons.lock_open,
      'shopping_cart': Icons.shopping_cart,
      'attach_file': Icons.attach_file,
      'link': Icons.link,
      'image': Icons.image,
      'camera': Icons.camera_alt,
      'play_arrow': Icons.play_arrow,
      'pause': Icons.pause,
      'stop': Icons.stop,
      'volume_up': Icons.volume_up,
      'download': Icons.download,
      'upload': Icons.upload,
      'refresh': Icons.refresh,
      'send': Icons.send,
      'thumb_up': Icons.thumb_up,
      'thumb_down': Icons.thumb_down,
      'code': Icons.code,
      'dashboard': Icons.dashboard,
      'explore': Icons.explore,
      'pets': Icons.pets,
      'account_circle': Icons.account_circle,
      'bookmark': Icons.bookmark,
      'library_books': Icons.library_books,
      'open_in_new': Icons.open_in_new,
      'auto_awesome': Icons.auto_awesome,
      'bolt': Icons.bolt,
      'rocket_launch': Icons.rocket_launch,
      'school': Icons.school,
      'work': Icons.work,
      'groups': Icons.groups,
      'bar_chart': Icons.bar_chart,
      'pie_chart': Icons.pie_chart,
      'show_chart': Icons.show_chart,
      'trending_up': Icons.trending_up,
      'trending_down': Icons.trending_down,
      'lightbulb': Icons.lightbulb,
      'palette': Icons.palette,
      'brush': Icons.brush,
      'format_paint': Icons.format_paint,
      'dark_mode': Icons.dark_mode,
      'light_mode': Icons.light_mode,
      'wifi': Icons.wifi,
      'bluetooth': Icons.bluetooth,
      'battery_full': Icons.battery_full,
      'circle': Icons.circle,
    };

    return iconMap[name] ?? Icons.circle;
  }

  // ─── Color Resolution ──────────────────────────────────────────
  static Color? _resolveColor(dynamic value) {
    if (value == null) return null;
    final name = value.toString().toLowerCase();

    // Named Material colors
    const colorMap = <String, Color>{
      'primary': Colors.blue,
      'secondary': Colors.purple,
      'tertiary': Colors.teal,
      'error': Colors.red,
      'success': Colors.green,
      'warning': Colors.orange,
      'info': Colors.lightBlue,
      'surface': Color(0xFFFFFBFE),
      'outline': Colors.grey,
      'white': Colors.white,
      'black': Colors.black,
      'red': Colors.red,
      'pink': Colors.pink,
      'purple': Colors.purple,
      'deepPurple': Colors.deepPurple,
      'indigo': Colors.indigo,
      'blue': Colors.blue,
      'lightBlue': Colors.lightBlue,
      'cyan': Colors.cyan,
      'teal': Colors.teal,
      'green': Colors.green,
      'lightGreen': Colors.lightGreen,
      'lime': Colors.lime,
      'yellow': Colors.yellow,
      'amber': Colors.amber,
      'orange': Colors.orange,
      'deepOrange': Colors.deepOrange,
      'brown': Colors.brown,
      'grey': Colors.grey,
      'blueGrey': Colors.blueGrey,
      'transparent': Colors.transparent,
    };

    if (colorMap.containsKey(name)) return colorMap[name];

    // Hex color
    if (name.startsWith('#')) {
      final hex = name.replaceFirst('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    }

    return null;
  }
}

// ─── Stateful Helper Widgets ────────────────────────────────────

class _StatefulCheckbox extends StatefulWidget {
  final String? label;
  final bool initialValue;
  const _StatefulCheckbox({this.label, this.initialValue = false});
  @override State<_StatefulCheckbox> createState() => _StatefulCheckboxState();
}
class _StatefulCheckboxState extends State<_StatefulCheckbox> {
  late bool _value;
  @override void initState() { super.initState(); _value = widget.initialValue; }
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: widget.label != null ? Text(widget.label!) : null,
      value: _value,
      onChanged: (v) => setState(() => _value = v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class _StatefulSwitch extends StatefulWidget {
  final String? label;
  final bool initialValue;
  const _StatefulSwitch({this.label, this.initialValue = false});
  @override State<_StatefulSwitch> createState() => _StatefulSwitchState();
}
class _StatefulSwitchState extends State<_StatefulSwitch> {
  late bool _value;
  @override void initState() { super.initState(); _value = widget.initialValue; }
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: widget.label != null ? Text(widget.label!) : null,
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}

class _StatefulSlider extends StatefulWidget {
  final double min, max, initialValue;
  final String? label;
  const _StatefulSlider({required this.min, required this.max, required this.initialValue, this.label});
  @override State<_StatefulSlider> createState() => _StatefulSliderState();
}
class _StatefulSliderState extends State<_StatefulSlider> {
  late double _value;
  @override void initState() { super.initState(); _value = widget.initialValue; }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(widget.label!, style: Theme.of(context).textTheme.bodySmall)),
        Slider(value: _value, min: widget.min, max: widget.max, onChanged: (v) => setState(() => _value = v)),
      ],
    );
  }
}

class _StatefulRadio extends StatefulWidget {
  final List<String> options;
  final String? label;
  const _StatefulRadio({required this.options, this.label});
  @override State<_StatefulRadio> createState() => _StatefulRadioState();
}
class _StatefulRadioState extends State<_StatefulRadio> {
  String? _selected;
  @override void initState() { super.initState(); _selected = widget.options.isNotEmpty ? widget.options.first : null; }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(widget.label!, style: Theme.of(context).textTheme.bodySmall)),
        ...widget.options.map((opt) => RadioListTile<String>(
          title: Text(opt),
          value: opt,
          groupValue: _selected,
          onChanged: (v) => setState(() => _selected = v),
          dense: true,
        )),
      ],
    );
  }
}

class _StatefulDropdown extends StatefulWidget {
  final List<String> options;
  final String? label;
  const _StatefulDropdown({required this.options, this.label});
  @override State<_StatefulDropdown> createState() => _StatefulDropdownState();
}
class _StatefulDropdownState extends State<_StatefulDropdown> {
  String? _selected;
  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      label: widget.label != null ? Text(widget.label!) : null,
      initialSelection: _selected,
      onSelected: (v) => setState(() => _selected = v),
      dropdownMenuEntries: widget.options.map((opt) => DropdownMenuEntry(value: opt, label: opt)).toList(),
    );
  }
}

class _StatefulFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  const _StatefulFilterChip({required this.label, this.selected = false});
  @override State<_StatefulFilterChip> createState() => _StatefulFilterChipState();
}
class _StatefulFilterChipState extends State<_StatefulFilterChip> {
  late bool _selected;
  @override void initState() { super.initState(); _selected = widget.selected; }
  @override
  Widget build(BuildContext context) {
    return FilterChip(label: Text(widget.label), selected: _selected, onSelected: (v) => setState(() => _selected = v));
  }
}

class _StatefulChoiceChip extends StatefulWidget {
  final String label;
  final bool selected;
  const _StatefulChoiceChip({required this.label, this.selected = false});
  @override State<_StatefulChoiceChip> createState() => _StatefulChoiceChipState();
}
class _StatefulChoiceChipState extends State<_StatefulChoiceChip> {
  late bool _selected;
  @override void initState() { super.initState(); _selected = widget.selected; }
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(widget.label), selected: _selected, onSelected: (v) => setState(() => _selected = v));
  }
}

class _StatefulSegmentedButton extends StatefulWidget {
  final List<String> segments;
  final int selectedIndex;
  const _StatefulSegmentedButton({required this.segments, this.selectedIndex = 0});
  @override State<_StatefulSegmentedButton> createState() => _StatefulSegmentedButtonState();
}
class _StatefulSegmentedButtonState extends State<_StatefulSegmentedButton> {
  late Set<int> _selected;
  @override void initState() { super.initState(); _selected = {widget.selectedIndex}; }
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: widget.segments.asMap().entries.map((e) => ButtonSegment(value: e.key, label: Text(e.value))).toList(),
      selected: _selected,
      onSelectionChanged: (v) => setState(() => _selected = v),
    );
  }
}

class _StatefulTabs extends StatefulWidget {
  final List<String> tabs;
  final List<Widget> children;
  const _StatefulTabs({required this.tabs, required this.children});
  @override State<_StatefulTabs> createState() => _StatefulTabsState();
}
class _StatefulTabsState extends State<_StatefulTabs> with SingleTickerProviderStateMixin {
  late TabController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TabController(length: widget.tabs.length, vsync: this);
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _controller,
          isScrollable: true,
          tabs: widget.tabs.map((t) => Tab(text: t)).toList(),
        ),
        SizedBox(
          height: 200,
          child: TabBarView(
            controller: _controller,
            children: List.generate(widget.tabs.length, (i) {
              if (i < widget.children.length) return widget.children[i];
              return Center(child: Text(widget.tabs[i]));
            }),
          ),
        ),
      ],
    );
  }
}
