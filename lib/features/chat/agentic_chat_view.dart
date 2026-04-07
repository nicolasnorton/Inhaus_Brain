import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../core/ui/split_pane_layout.dart';
import '../canvas/ui/canvas_host.dart';
import '../canvas/providers/canvas_provider.dart';
import 'widgets/budget_dashboard_widget.dart';

class AgenticChatView extends ConsumerStatefulWidget {
  const AgenticChatView({super.key});

  @override
  ConsumerState<AgenticChatView> createState() => _AgenticChatViewState();
}

class _AgenticChatViewState extends ConsumerState<AgenticChatView> {
  late final LlmProvider _provider;

  @override
  void initState() {
    super.initState();
    // Use the official Firebase AI initialization mapping for LlmChatView
    final model = FirebaseAI.instance.generativeModel('gemini-3-flash');
    _provider = FirebaseProvider(model);
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);

    final chatUi = Stack(
      children: [
        // Completely stripped out custom `ListView`, avatars, and prompt ingestion.
        // Replaced entirely with standardized Toolkit component.
        LlmChatView(
          provider: _provider,
        ),
        
        if (canvasState.type != CanvasContentType.empty && 
            !canvasState.isMobileCanvasOpen && 
            MediaQuery.of(context).size.width < 750)
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.auto_awesome_mosaic, color: Colors.white),
              onPressed: () => ref.read(canvasProvider.notifier).toggleMobileCanvas(true),
            ),
          ),
        
        // Retaining the governor widget in top-left
        const Positioned(
          left: 12,
          top: 12,
          child: BudgetDashboardWidget(),
        ),
      ],
    );

    return SplitPaneLayout(
      childLeft: const CanvasHost(),
      childRight: chatUi,
      initialRatio: 0.5,
      minLeftWidth: 350,
      minRightWidth: 400,
      showLeftPaneOnMobile: canvasState.isMobileCanvasOpen,
    );
  }
}
