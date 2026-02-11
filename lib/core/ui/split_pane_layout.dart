import 'package:flutter/material.dart';

/// A responsive split-pane layout that shows two children side-by-side on large screens
/// and handles stacking/toggling on smaller screens.
class SplitPaneLayout extends StatefulWidget {
  final Widget childLeft;
  final Widget childRight;
  final double initialRatio;
  final double minLeftWidth;
  final double minRightWidth;
  final bool showLeftPaneOnMobile; // For mobile toggle logic
  final bool showLeftPane; // New property for desktop toggle

  const SplitPaneLayout({
    super.key,
    required this.childLeft,
    required this.childRight,
    this.initialRatio = 0.5,
    this.minLeftWidth = 300,
    this.minRightWidth = 300,
    this.showLeftPaneOnMobile = false,
    this.showLeftPane = true, // Default to true
  });

  @override
  State<SplitPaneLayout> createState() => _SplitPaneLayoutState();
}

class _SplitPaneLayoutState extends State<SplitPaneLayout> {
  late double _ratio;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Breakpoint for splitting (e.g., tablet landscape or desktop)
        // If width is too small to fit both mins, switch to stacked/mobile mode
        final isMobile = width < (widget.minLeftWidth + widget.minRightWidth);

        if (isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout(constraints);
        }
      },
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    // If constraints are infinite (e.g. inside a Row/Column without Expanded), default to screen width or a safe fallback
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width;
    
    // Check if left pane should be shown
    if (!widget.showLeftPane) {
      return widget.childRight;
    }

    // Ensure ratio is clamped
    final effectiveRatio = _ratio.clamp(0.1, 0.9);
    final leftWidth = width * effectiveRatio;
    // Right width takes the rest
    
    return Row(
      children: [
        // LEFT PANE (Canvas)
        SizedBox(
          width: leftWidth,
          child: widget.childLeft,
        ),
        
        // DRAG HANDLE
        MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (_) => setState(() => _isDragging = true),
            onPanEnd: (_) => setState(() => _isDragging = false),
            onPanUpdate: (details) {
              setState(() {
                // Calculate new ratio based on drag delta
                final deltaRatio = details.delta.dx / width;
                final newRatio = (_ratio + deltaRatio).clamp(
                   widget.minLeftWidth / width, 
                   1 - (widget.minRightWidth / width)
                );
                _ratio = newRatio;
              });
            },
            child: Container(
              width: 8, 
              color: _isDragging ? Colors.blueAccent.withOpacity(0.5) : Colors.transparent,
              child: Center(
                child: Container(
                  width: 1,
                  height: 40, // Visual handle
                  color: _isDragging ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ),
        ),

        // RIGHT PANE (Chat)
        Expanded(
          child: widget.childRight,
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    // For mobile, we typically show one or the other based on state.
    // However, the requirement says "Chat primary + expandable canvas bottom sheet".
    // This widget might just stack them or let the parent handle the bottom sheet.
    // If we want this widget to handle the generic "stack", we can put childLeft
    // on top if showLeftPaneOnMobile is true, but bottom sheet is better handled
    // by the specific mobile adaptation layer. 
    //
    // For a generic SplitPane, let's render the Chat (Right) as the base,
    // and if the "Left" (Canvas) needs to be shown, it should probably be doing so
    // via a separate mechanism (Overlay) controlled by the implementation using this widget.
    //
    // BUT, to be helpful, if showLeftPaneOnMobile is true, we could stack it.
    
    return Stack(
      children: [
        widget.childRight,
        if (widget.showLeftPaneOnMobile)
          Positioned.fill(
             child: Container(
               color: Theme.of(context).scaffoldBackgroundColor,
               child: widget.childLeft
             ),
          ),
      ],
    );
  }
}
