import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/json.dart' as highlight_json;
import 'package:ag_ui/ag_ui.dart' hide State;
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../providers/widget_storage_provider.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../assistant/presentation/widgets/gen_ui/gen_ui_renderer.dart';

class WidgetEditorScreen extends ConsumerStatefulWidget {
  final String? widgetId;
  const WidgetEditorScreen({super.key, this.widgetId});

  @override
  ConsumerState<WidgetEditorScreen> createState() => _WidgetEditorScreenState();
}

class _WidgetEditorScreenState extends ConsumerState<WidgetEditorScreen> {
  late CodeController _codeController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _previewPayload;
  String _widgetName = 'Untitled Widget';
  bool _hasUnsavedChanges = false;
  
  // Copilot State
  bool _isCopilotThinking = false;
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': 'Hi! Im your A2UI Copilot. Describe changes to the widget and I will update the JSON code.'}
  ];

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '''{
  "id": "root",
  "component": {
    "Text": {
      "text": { "value": "Start typing A2UI JSON here..." }
    }
  }
}''',
      language: highlight_json.json,
    );
    _codeController.addListener(_onCodeChanged);
    
    // Defer loading to after first frame if we have an ID
    if (widget.widgetId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWidget(widget.widgetId!);
      });
    } else {
      _tryParseAndRender();
    }
  }

  @override
  void didUpdateWidget(WidgetEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.widgetId != oldWidget.widgetId) {
      if (widget.widgetId == null) {
        // Reset to default new widget state
        setState(() {
          _widgetName = 'Untitled Widget';
          _codeController.text = '''{
  "id": "root",
  "component": {
    "Text": {
      "text": { "value": "Start typing A2UI JSON here..." }
    }
  }
}''';
          _hasUnsavedChanges = false;
        });
        _tryParseAndRender();
      } else {
        // Load the selected widget from history
        _loadWidget(widget.widgetId!);
      }
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
    _tryParseAndRender();
  }

  void _tryParseAndRender() {
    try {
      final parsed = jsonDecode(_codeController.text);
      if (parsed is Map<String, dynamic> && parsed.containsKey('component')) {
        setState(() {
          _previewPayload = Map<String, dynamic>.from(parsed);
        });
      }
    } catch (e) {
      // Invalid JSON, don't update preview, maybe show subtle error
    }
  }

  void _loadWidget(String id) {
    final widgetsAsync = ref.read(widgetStorageProvider);
    final widgets = widgetsAsync.valueOrNull ?? [];
    final widgetFound = widgets.where((w) => w.id == id).firstOrNull;
    
    if (widgetFound != null) {
      setState(() {
        _widgetName = widgetFound.name;
        _codeController.text = widgetFound.jsonSchema;
        _hasUnsavedChanges = false;
      });
      _tryParseAndRender();
    }
  }

  Future<void> _saveWidget() async {
    try {
      final notifier = ref.read(widgetStorageProvider.notifier);
      final newId = await notifier.saveWidget(
        _widgetName,
        _codeController.text,
        existingId: widget.widgetId,
      );
      setState(() {
        _hasUnsavedChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Widget saved successfully!')),
        );
        if (widget.widgetId == null) {
          context.go('/composer/editor/\$newId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save widget: \$e')),
        );
      }
    }
  }

  Future<void> _sendMessageToCopilot() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isCopilotThinking) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isCopilotThinking = true;
      _chatController.clear();
    });
    
    _scrollToBottom();

    final systemPrompt = '''You are an expert A2UI Composer Copilot.
You modify the A2UI JSON schema provided by the user based on their request.
Return ONLY valid JSON. Do not return markdown backticks.

CURRENT WIDGET JSON:
\${_codeController.text}''';

    try {
      final stream = EdgeAIService.generateTextStream(
        text,
        systemInstruction: systemPrompt,
        config: AIModelConfig.geminiPro,
        ref: ref,
      );
      
      String botResponse = '';
      setState(() {
        _messages.add({'role': 'assistant', 'content': ''});
      });

      await for (final chunk in stream) {
         if (!mounted) break;
         botResponse += chunk.text;
         setState(() {
           _messages.last['content'] = botResponse;
         });
         _scrollToBottom();
      }
      
      // Attempt to clean and apply the JSON
      if (mounted) {
         String cleanJson = botResponse.trim();
         if (cleanJson.startsWith('```json')) {
             cleanJson = cleanJson.split('```json')[1].split('```')[0].trim();
         } else if (cleanJson.startsWith('```')) {
             cleanJson = cleanJson.split('```')[1].split('```')[0].trim();
         }
         
         // Try to parse it to ensure it's valid before injecting
         try {
            jsonDecode(cleanJson);
            setState(() {
               _codeController.text = cleanJson;
            });
         } catch (e) {
            setState(() {
               _messages.add({'role': 'assistant', 'content': '⚠️ I tried to update the code, but my output was invalid JSON. Please try rewording your request.'});
            });
            _scrollToBottom();
         }
      }
    } catch (e) {
       if (mounted) {
         setState(() {
           _messages.last['content'] = 'An error occurred: \$e';
         });
       }
    } finally {
       if (mounted) {
         setState(() {
           _isCopilotThinking = false;
         });
       }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECEF),
      body: Column(
        children: [
          // Top Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.white,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        _widgetName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      if (_hasUnsavedChanges)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.circle, size: 8, color: Colors.orange),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _codeController.text));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied JSON')));
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy JSON'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _hasUnsavedChanges ? _saveWidget : null,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Save Widget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          
          // 3-Pane Layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. JSON Editor Pane
                Expanded(
                  flex: 3,
                  child: _buildEditorPane(),
                ),
                
                // 2. Preview Canvas Pane
                Expanded(
                  flex: 4,
                  child: _buildPreviewPane(),
                ),
                
                // 3. Copilot Assistant Pane
                Expanded(
                  flex: 3,
                  child: _buildCopilotPane(),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEditorPane() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.black12)),
      ),
      child: CodeTheme(
        data: CodeThemeData(styles: atomOneDarkTheme),
        child: SingleChildScrollView(
          child: CodeField(
            controller: _codeController,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            lineNumberStyle: const LineNumberStyle(
              textStyle: TextStyle(color: Colors.white38),
            ),
            background: const Color(0xFF282C34),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPane() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: _previewPayload != null
                ? GenUIRenderer(payload: _previewPayload!)
                : const Center(
                    child: Text(
                      'Invalid JSON / Rendering Error',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopilotPane() {
    return Container(
      color: Colors.white,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12)),
              color: Color(0xFFF8F9FA),
            ),
            child: Row(
              children: const [
                Icon(Icons.auto_awesome, color: Colors.purple, size: 18),
                SizedBox(width: 8),
                Text('Widget Copilot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.25),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
                      border: Border.all(color: isUser ? Colors.blue.withOpacity(0.3) : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12).copyWith(
                        bottomRight: Radius.circular(isUser ? 0 : 12),
                        bottomLeft: Radius.circular(isUser ? 12 : 0),
                      ),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isUser ? Colors.blue[900] : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Chat Input Placeholder
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _chatController,
              onSubmitted: (_) => _sendMessageToCopilot(),
              decoration: InputDecoration(
                hintText: 'e.g. "Change the text to Hello"',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                suffixIcon: _isCopilotThinking 
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.send, size: 18),
                        onPressed: _sendMessageToCopilot,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
