import 'package:flutter/material.dart';

class EditorModal extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final VoidCallback onPreview;
  final Function(String, String) onSave;

  const EditorModal({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.onPreview,
    required this.onSave,
  });

  @override
  State<EditorModal> createState() => _EditorModalState();
}

class _EditorModalState extends State<EditorModal> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void baseInit() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void initState() {
    baseInit();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    setState(() => _isSaving = true);
    await widget.onSave(_titleController.text, _contentController.text);
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // AppTheme.surface equivalent
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                   Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1), // AppTheme.primary
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_document, color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Document Editor", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Review and edit the content before finalizing", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.preview, color: Colors.white70),
                        label: const Text("Preview", style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        onPressed: widget.onPreview,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: _isSaving 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Icon(Icons.check_circle_outline),
                        label: Text(_isSaving ? "Saving..." : "Save Content"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1), // AppTheme.primary
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: _isSaving ? null : _handleSave,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Editor Body
            Expanded(
              child: Row(
                children: [
                  // Writing Area
                  Expanded(
                    flex: 7,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: "Document Title",
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                              border: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: TextField(
                              controller: _contentController,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, height: 1.6),
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                hintText: "Start writing here...",
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Helper Sidebar
                  Container(
                    width: 300,
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.white12)),
                      color: Color(0xFF141414), // AppTheme.background equivalent
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("AI Assistant", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 16),
                        _buildAssistantTip(Icons.auto_fix_high, "Improve Writing", "Enhance clarity and tone"),
                        _buildAssistantTip(Icons.short_text, "Summarize", "Create a bullet-point summary"),
                        _buildAssistantTip(Icons.translate, "Translate", "Convert to another language"),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 16),
                                  SizedBox(width: 8),
                                  Text("Pro Tip", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("You can highlight text in the editor to get specific AI suggestions for that section.", 
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantTip(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

