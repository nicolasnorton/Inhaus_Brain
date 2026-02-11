import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/canvas_provider.dart';
import 'monaco_editor_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/strategy_board_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/budget_chart_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/kanban_board_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/trend_report_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/recipe_card_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/dynamic_form_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/mind_map_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/media_carousel_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/interactive_table_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/radial_gauge_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/accordion_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/stepper_wizard_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/word_cloud_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/calendar_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/dialogue_scene_widget.dart';
import '../../assistant/presentation/widgets/gen_ui/avatar_conversation_widget.dart';

class CanvasHost extends ConsumerStatefulWidget {
  const CanvasHost({super.key});

  @override
  ConsumerState<CanvasHost> createState() => _CanvasHostState();
}

class _CanvasHostState extends ConsumerState<CanvasHost> {
  bool _showPinboard = false;

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    final hasPinned = canvasState.pinnedItems.isNotEmpty;

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // Header
          if (canvasState.type != CanvasContentType.empty || _showPinboard)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                color: Colors.white.withOpacity(0.02),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: hasPinned ? () => setState(() => _showPinboard = !_showPinboard) : null,
                    child: Row(
                      children: [
                        Icon(
                          _showPinboard ? Icons.collections_bookmark : _getIconForType(canvasState.type), 
                          size: 16, 
                          color: _showPinboard ? Colors.amberAccent : Colors.blueAccent
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showPinboard ? 'PINBOARD' : (canvasState.title?.toUpperCase() ?? 'CANVAS'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _showPinboard ? Colors.amberAccent : Colors.white70,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!_showPinboard && canvasState.type != CanvasContentType.empty)
                    IconButton(
                      icon: Icon(
                        canvasState.isPinned ? Icons.push_pin : Icons.push_pin_outlined, 
                        size: 16, 
                        color: canvasState.isPinned ? Colors.amberAccent : Colors.white38
                      ),
                      onPressed: () => ref.read(canvasProvider.notifier).togglePin(),
                      tooltip: canvasState.isPinned ? 'Unpin' : 'Pin to Canvas',
                    ),
                  if (hasPinned && !_showPinboard)
                    IconButton(
                      icon: const Icon(Icons.collections_bookmark_outlined, size: 16, color: Colors.white38),
                      onPressed: () => setState(() => _showPinboard = true),
                      tooltip: 'View Pinboard',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                    onPressed: () {
                      if (_showPinboard) {
                        setState(() => _showPinboard = false);
                      } else {
                        ref.read(canvasProvider.notifier).clear();
                      }
                    },
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: _showPinboard ? _buildPinboard(canvasState) : _buildContent(context, canvasState),
          ),
        ],
      ),
    );
  }

  Widget _buildPinboard(CanvasState state) {
    if (state.pinnedItems.isEmpty) {
       return Center(
         child: Text("No pinned items", style: TextStyle(color: Colors.white.withOpacity(0.2))),
       );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: state.pinnedItems.length,
      itemBuilder: (context, index) {
        final item = state.pinnedItems[index];
        return GestureDetector(
          onTap: () {
            // "Open" item from pinboard
            if (item.type == CanvasContentType.html) ref.read(canvasProvider.notifier).showHtml(item.content!, title: item.title);
            if (item.type == CanvasContentType.code) ref.read(canvasProvider.notifier).showCode(item.content!, title: item.title);
            if (item.type == CanvasContentType.markdown) ref.read(canvasProvider.notifier).showMarkdown(item.content!, title: item.title);
            if (item.type == CanvasContentType.image) ref.read(canvasProvider.notifier).showImage(item.content!, title: item.title);
            if (item.type == CanvasContentType.custom) ref.read(canvasProvider.notifier).showGenUI(item.metadata!, title: item.title);
            setState(() => _showPinboard = false);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getIconForType(item.type), size: 14, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title ?? 'Untitled',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.type == CanvasContentType.code ? 'Code Snippet' : (item.content ?? 'Artifact'),
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, CanvasState state) {
    switch (state.type) {
      case CanvasContentType.html:
        // TODO: Use real WebView or HtmlWidget for full HTML support
        // For now, treating as text/mock
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(state.content ?? '', style: const TextStyle(fontFamily: 'monospace')),
        );
      
      case CanvasContentType.markdown:
        return Markdown(
          data: state.content ?? '',
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
             p: const TextStyle(color: Colors.white70),
          ),
        );

      case CanvasContentType.code:
        return MonacoEditorWidget(
          code: state.content ?? '',
          language: state.metadata?['language'] ?? 'javascript',
        );

      case CanvasContentType.image:
        return Center(
          child: Image.network(
            state.content ?? '',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white24, size: 48),
          ),
        );

      case CanvasContentType.custom:
        final type = state.metadata?['type'] as String?;
        final data = state.metadata ?? {};
        
        switch (type) {
          case 'strategy_board': return Center(child: StrategyBoardWidget(data: data));
          case 'budget_chart': return Center(child: BudgetChartWidget(data: data));
          case 'kanban_board': return Center(child: KanbanBoardWidget(data: data));
          case 'trend_report': return Center(child: TrendReportWidget(data: data));
          case 'recipe_card': return Center(child: RecipeCardWidget(data: data));
          case 'dynamic_form': return Center(child: DynamicFormWidget(data: data));
          case 'mind_map': return Center(child: MindMapWidget(data: data));
          case 'media_carousel': return Center(child: MediaCarouselWidget(data: data));
          case 'interactive_table': return Center(child: InteractiveTableWidget(data: data));
          case 'radial_gauge': return Center(child: RadialGaugeWidget(data: data));
          case 'accordion': return Center(child: AccordionWidget(data: data));
          case 'stepper_wizard': return Center(child: StepperWizardWidget(data: data));
          case 'word_cloud': return Center(child: WordCloudWidget(data: data));
          case 'calendar': return Center(child: CalendarWidget(data: data));
          case 'dialogue_scene': 
            return Center(child: DialogueSceneWidget(
              initialUrl: data['initialUrl'] ?? data['url'],
              htmlContent: data['htmlContent'] ?? data['content'],
            ));
          case 'avatar_conversation': 
            return Center(child: AvatarConversationWidget(
              speakerName: data['speakerName'] ?? 'Assistant',
              text: data['text'] ?? '',
              avatarUrl: data['avatarUrl'],
              isRightAligned: data['isRightAligned'] ?? false,
            ));
          default:
            return Center(child: Text("Unknown component: $type", style: const TextStyle(color: Colors.white54)));
        }

      case CanvasContentType.empty:
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard_customize_outlined, size: 64, color: Colors.white.withOpacity(0.05)),
              const SizedBox(height: 16),
              Text(
                "Select an item to view in Canvas",
                style: TextStyle(color: Colors.white.withOpacity(0.2)),
              ),
            ],
          ),
        );
    }
  }

  IconData _getIconForType(CanvasContentType type) {
    switch (type) {
      case CanvasContentType.html: return Icons.web;
      case CanvasContentType.code: return Icons.code;
      case CanvasContentType.markdown: return Icons.article;
      case CanvasContentType.image: return Icons.image;
      case CanvasContentType.video: return Icons.movie;
      case CanvasContentType.custom: return Icons.widgets;
      default: return Icons.grid_view;
    }
  }
}
