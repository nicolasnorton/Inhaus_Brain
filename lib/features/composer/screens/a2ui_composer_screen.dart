import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/ui/split_pane_layout.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../assistant/presentation/widgets/gen_ui/gen_ui_renderer.dart';
import '../../../core/tokens/llm_provider.dart';

class A2UIComposerScreen extends ConsumerStatefulWidget {
  const A2UIComposerScreen({super.key});

  @override
  ConsumerState<A2UIComposerScreen> createState() => _A2UIComposerScreenState();
}

class _A2UIComposerScreenState extends ConsumerState<A2UIComposerScreen> {
  final TextEditingController _promptController = TextEditingController();
  Map<String, dynamic>? _currentPayload;
  bool _isGenerating = false;
  String? _errorText;

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
Wrap your output exactly like this:
```json
---a2ui_JSON---
{
  "type": "surfaceUpdate",
  "data": {
    "component_type": "<one of the valid types>",
    ... component fields ...
  }
}
---a2ui_JSON---
```
Available component types: ${_catalogItems.join(', ')}.
Respond ONLY with the JSON block. Do not include markdown chat outside the block.
''';

      final aiRes = await EdgeAIService.generateText(
        prompt,
        systemInstruction: systemInstruction,
        ref: ref,
        modelConfig: AIModelConfig.geminiPro,
      );

      final a2uiRegex = RegExp(r'```json\s*---a2ui_JSON---\s*(\{.*?\})\s*```', dotAll: true, caseSensitive: false);
      final match = a2uiRegex.firstMatch(aiRes.text);

      if (match != null) {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          final decoded = jsonDecode(jsonStr);
          if (decoded['type'] == 'surfaceUpdate' && decoded['data'] != null) {
             setState(() {
               _currentPayload = Map<String, dynamic>.from(decoded['data']);
             });
          } else {
             _setError('Invalid A2UI structure: Missing surfaceUpdate or data.');
          }
        }
      } else {
        // Fallback: try raw JSON parse if model ignored backticks or boundary tags
        try {
           // Strip markdown code block formatting if it exists
           String cleanResponse = aiRes.text;
           if (cleanResponse.contains('```json')) {
               cleanResponse = cleanResponse.split('```json')[1];
               if (cleanResponse.contains('```')) {
                   cleanResponse = cleanResponse.split('```')[0];
               }
           } else if (cleanResponse.contains('```')) {
               cleanResponse = cleanResponse.split('```')[1];
               if (cleanResponse.contains('```')) {
                   cleanResponse = cleanResponse.split('```')[0];
               }
           }
           // Strip the custom boundary tags as well
           cleanResponse = cleanResponse.replaceAll('---a2ui_JSON---', '');
           cleanResponse = cleanResponse.trim();

           final parsed = jsonDecode(cleanResponse);
           if (parsed['type'] == 'surfaceUpdate' && parsed['data'] != null) {
             setState(() {
               _currentPayload = Map<String, dynamic>.from(parsed['data']);
             });
           } else if (parsed['component_type'] != null) {
             setState(() {
               _currentPayload = Map<String, dynamic>.from(parsed);
             });
           } else {
              _setError('Could not find A2UI JSON payload in response.\\nResponse: ${aiRes.text}');
           }
        } catch (e) {
          _setError('Could not parse A2UI JSON block from response.\\nError: $e\\nResponse: ${aiRes.text}');
        }
      }
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
          const Text('Design and preview native Generative UI components via conversational prompting.', style: TextStyle(color: Colors.white54, fontSize: 13)),
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
          : _currentPayload == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.borderNone, size: 64, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 24),
                  const Text('Preview Canvas', style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Generated components will appear here.', style: TextStyle(color: Colors.white38)),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: GenUIRenderer(payload: _currentPayload!, isCanvas: true),
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
