import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'strategy_board_widget.dart';
import 'budget_chart_widget.dart';
import 'kanban_board_widget.dart';
import 'trend_report_widget.dart';
import 'recipe_card_widget.dart';
import 'dynamic_form_widget.dart';
import 'mind_map_widget.dart';
import 'media_carousel_widget.dart';
import 'interactive_table_widget.dart';
import 'radial_gauge_widget.dart';
import 'accordion_widget.dart';
import 'stepper_wizard_widget.dart';
import 'word_cloud_widget.dart';
import 'calendar_widget.dart';
import 'dialogue_scene_widget.dart';
import 'avatar_conversation_widget.dart';
import 'live_session_widget.dart';
import 'code_viewer_widget.dart';
import 'video_player_widget.dart';
import 'deep_analysis_report_widget.dart';
import 'knowledge_dashboard_widget.dart';
import 'stitch_design_preview_widget.dart';
import 'stitch_design_carousel_widget.dart';
import 'stitch_code_export_widget.dart';

/// A shared factory widget to render GenUI components based on a JSON payload.
/// This ensures consistent rendering across the Assistant chat and the Canvas.
class GenUIRenderer extends StatelessWidget {
  final Map<String, dynamic> payload;
  final bool isCanvas;

  const GenUIRenderer({
    super.key, 
    required this.payload,
    this.isCanvas = false,
  });

  @override
  Widget build(BuildContext context) {
    final type = payload['type'] ?? payload['component_type'];
    
    switch (type) {
      case 'strategy_board':
        return StrategyBoardWidget(data: payload);
      case 'budget_chart':
        return BudgetChartWidget(data: payload);
      case 'kanban_board':
        return KanbanBoardWidget(data: payload);
      case 'recipe_card':
        return RecipeCardWidget(data: payload);
      case 'dynamic_form':
        return DynamicFormWidget(data: payload);
      case 'mind_map':
        return MindMapWidget(data: payload);
      case 'media_carousel':
      case 'carousel':
        return MediaCarouselWidget(data: payload);
      case 'interactive_table':
        return InteractiveTableWidget(data: payload);
      case 'radial_gauge':
        return RadialGaugeWidget(data: payload);
      case 'accordion':
        return AccordionWidget(data: payload);
      case 'stepper_wizard':
      case 'stepper':
        return StepperWizardWidget(data: payload);
      case 'word_cloud':
        return WordCloudWidget(data: payload);
      case 'calendar':
        return CalendarWidget(data: payload);
      case 'trend_report':
      case 'analysis_report':
      case 'timeline':
        return TrendReportWidget(data: payload);
      case 'deep_analysis':
        return DeepAnalysisReportWidget(data: payload);
      case 'knowledge_dashboard':
        return KnowledgeDashboardWidget(data: payload);
      case 'dialogue_scene':
        return DialogueSceneWidget(
          initialUrl: payload['initialUrl'] ?? payload['url'],
          htmlContent: payload['htmlContent'] ?? payload['content'],
        );
      case 'avatar_conversation':
        return AvatarConversationWidget(
          speakerName: payload['speaker_name'] ?? payload['speakerName'] ?? 'Assistant',
          text: payload['text'] ?? '',
          avatarUrl: payload['avatar_url'] ?? payload['avatarUrl'],
          isRightAligned: payload['is_right_aligned'] ?? payload['isRightAligned'] ?? false,
        );
      case 'code_viewer':
        return isCanvas 
            ? Center(child: SizedBox(width: 800, child: CodeViewerWidget(data: payload)))
            : CodeViewerWidget(data: payload);
      case 'video_player':
        return isCanvas
            ? Center(child: SizedBox(width: 800, child: VideoPlayerWidget(data: payload)))
            : VideoPlayerWidget(data: payload);
      case 'live_multimodal_session':
        return LiveMultimodalSessionWidget(data: payload);
      case 'stitch_design_preview':
        return StitchDesignPreviewWidget(data: payload);
      case 'stitch_design_carousel':
        return StitchDesignCarouselWidget(data: payload);
      case 'stitch_code_export':
        return StitchCodeExportWidget(data: payload);
      case 'gen_ui_layout':
        return GenUiLayoutWidget(payload: payload, isCanvas: isCanvas);
      default:
        // Fallback for any other type that might have sections (generic report)
        if (payload.containsKey('sections') || payload.containsKey('trends')) {
          return TrendReportWidget(data: payload);
        }
        return Center(
          child: Text(
            "Unknown component: $type", 
            style: const TextStyle(color: Colors.white54)
          )
        );
    }
  }
}

/// A widget that combines multiple GenUI components into a single layout.
class GenUiLayoutWidget extends StatelessWidget {
  final Map<String, dynamic> payload;
  final bool isCanvas;

  const GenUiLayoutWidget({
    super.key, 
    required this.payload,
    this.isCanvas = false,
  });

  @override
  Widget build(BuildContext context) {
    final layout = payload['layout'] ?? 'stacked';
    final title = payload['title'] as String?;
    final components = (payload['components'] as List?) ?? [];

    if (components.isEmpty) return const SizedBox.shrink();

    final renderedWidgets = components.map<Widget>((comp) {
      if (comp is! Map<String, dynamic>) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GenUIRenderer(payload: comp, isCanvas: isCanvas),
      );
    }).toList();

    Widget content;
    switch (layout) {
      case 'grid':
        final crossAxisCount = (payload['columns'] as int?) ?? 2;
        content = LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: renderedWidgets.map((w) => SizedBox(width: itemWidth, child: w)).toList(),
            );
          },
        );
        break;
      case 'split':
        // Two-pane horizontal split
        if (renderedWidgets.length >= 2) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: renderedWidgets[0]),
              const SizedBox(width: 16),
              Expanded(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: renderedWidgets.sublist(1),
              )),
            ],
          );
        } else {
          content = Column(mainAxisSize: MainAxisSize.min, children: renderedWidgets);
        }
        break;
      case 'tabs':
        content = _CompositeTabView(
          tabs: components.map((c) => (c as Map<String, dynamic>)['title']?.toString() ?? (c as Map<String, dynamic>)['type']?.toString() ?? 'Tab').toList(),
          children: renderedWidgets,
        );
        break;
      case 'stacked':
      default:
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: renderedWidgets,
        );
    }

    return Container(
      padding: const EdgeInsets.all(isCanvas ? 24 : 16), // More padding on Canvas
      decoration: BoxDecoration(
        color: const Color(0xFF0F1116),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent.withOpacity(0.2), Colors.purpleAccent.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.dashboard_customize, size: 18, color: Colors.blueAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${components.length} Components',
                    style: TextStyle(fontSize: 10, color: Colors.blueAccent.withOpacity(0.8), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 16),
          ],
          content,
        ],
      ),
    );
  }
}

/// A simple tab view for composite GenUI layouts.
class _CompositeTabView extends StatefulWidget {
  final List<String> tabs;
  final List<Widget> children;

  const _CompositeTabView({required this.tabs, required this.children});

  @override
  State<_CompositeTabView> createState() => _CompositeTabViewState();
}

class _CompositeTabViewState extends State<_CompositeTabView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.tabs.asMap().entries.map((entry) {
              final isSelected = entry.key == _selectedIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = entry.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? Colors.blueAccent : Colors.white54,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedIndex < widget.children.length)
          widget.children[_selectedIndex],
      ],
    );
  }
}
