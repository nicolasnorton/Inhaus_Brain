import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:genui/genui.dart';
import 'package:genui_a2a/genui_a2a.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../../core/ui/split_pane_layout.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';

class A2UIComposerScreen extends ConsumerStatefulWidget {
  const A2UIComposerScreen({super.key});

  @override
  ConsumerState<A2UIComposerScreen> createState() => _A2UIComposerScreenState();
}

class _A2UIComposerScreenState extends ConsumerState<A2UIComposerScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  String? _errorText;

  // Utilize the official GenUI A2UI Adapter
  late final A2uiTransportAdapter _adapter;

  @override
  void initState() {
    super.initState();
    // Setup Official GenUI Adapter for Gemini 3
    final model = FirebaseAI.instance.generativeModel('gemini-3-flash');
    _adapter = A2uiTransportAdapter(model);
  }

  final List<String> _catalogItems = [
    'kanban_board', 'strategy_board', 'budget_chart', 'recipe_card', 
    'dynamic_form', 'mind_map', 'media_carousel', 'interactive_table',
    'radial_gauge', 'accordion', 'stepper_wizard', 'word_cloud',
    'calendar', 'trend_report'
  ];

  Future<void> _generateComponent(String prompt) async {
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _errorText = null;
    });

    try {
      final systemInstruction = '''
You are the A2UI Composer Agent. Your task is to generate UI components based on the user's prompt.
You MUST output your response matching the A2UI JSON protocol. Use the `surfaceUpdate` type.
Available component types: ${_catalogItems.join(', ')}.
''';

      // Pipe generation request straight to the GenUI adapter
      // Adapter handles the A2UI spec parsing natively (no more regex)
      await _adapter.generateWithSystemInstructions(
         prompt: prompt,
         systemInstruction: systemInstruction,
      );

    } catch (e) {
      _setError('Error generating component: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _setError(String err) {
    setState(() {
      _errorText = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final leftSidebar = Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.code, color: Colors.blueAccent),
              const SizedBox(width: 12),
              const Text('A2UI Composer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Design and preview native Generative UI components via GenUI SDK.', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 32),
          const Text('PROMPT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white54)),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            maxLines: 5,
            minLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Build a kanban board for a marketing campaign launch...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : () => _generateComponent(_promptController.text),
              icon: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 16),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Surface'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('CATALOG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white54)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _catalogItems.length,
              itemBuilder: (context, index) {
                final item = _catalogItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      _promptController.text = 'Generate dummy data for $item component.';
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace')),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    final rightCanvas = Container(
      color: const Color(0xFF0F1116), // Darker canvas background
      child: Center(
        child: _errorText != null 
          ? Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
          )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                // Replaced GenUIRenderer with the official GenUi surface tied to the adapter
                child: GenUi(adapter: _adapter),
              ),
            ),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SplitPaneLayout(
        childLeft: leftSidebar,
        childRight: rightCanvas,
        initialRatio: 0.35,
        minLeftWidth: 300,
      ),
    );
  }
}
