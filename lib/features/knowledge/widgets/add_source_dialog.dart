import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/knowledge_source.dart';

class AddSourceDialog extends StatefulWidget {
  final Function(KnowledgeSource) onSourceAdded;

  const AddSourceDialog({super.key, required this.onSourceAdded});

  @override
  State<AddSourceDialog> createState() => _AddSourceDialogState();
}

class _AddSourceDialogState extends State<AddSourceDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  
  String? _activeInputMode; // 'url', 'text', 'drive', null (default)

  @override
  void dispose() {
    _searchController.dispose();
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleFileUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'json', 'csv', 'mp3', 'wav', 'm4a', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        final String content = file.bytes != null 
             ? String.fromCharCodes(file.bytes!) // Note: binary files like audio/images won't convert nicely to string here, but for MVP/Source model we hold path/uri or base64. 
             : 'File path: ${file.path}';
        
        // Determine type
        KnowledgeSourceType type = KnowledgeSourceType.file;
        final ext = file.extension?.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) type = KnowledgeSourceType.image;
        if (['mp3', 'wav', 'm4a', 'ogg'].contains(ext)) type = KnowledgeSourceType.audio;
        if (ext == 'pdf') type = KnowledgeSourceType.pdf;

        final newSource = KnowledgeSource(
          id: const Uuid().v4(),
          title: file.name,
          content: content, // Real impl would upload to storage and get URL
          type: type,
          createdAt: DateTime.now(),
          metadata: {
            'fileSize': '${(file.size / 1024).toStringAsFixed(2)} KB',
            'extension': file.extension ?? 'unknown',
          },
        );
        
        widget.onSourceAdded(newSource);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _handleAddUrl() {
    if (_urlController.text.isEmpty) return;
    final url = _urlController.text;
    KnowledgeSourceType type = KnowledgeSourceType.url;
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      type = KnowledgeSourceType.youtube;
    }

    final newSource = KnowledgeSource(
      id: const Uuid().v4(),
      title: url, // Could notify to fetch metadata
      content: url,
      type: type,
      createdAt: DateTime.now(),
    );
    widget.onSourceAdded(newSource);
    Navigator.pop(context);
  }

  void _handleAddText() {
    if (_textController.text.isEmpty) return;
    
    // Extract title from first line or default
    final lines = _textController.text.split('\n');
    String title = lines.isNotEmpty ? lines.first : 'Copied Text';
    if (title.length > 50) title = '${title.substring(0, 47)}...';

    final newSource = KnowledgeSource(
      id: const Uuid().v4(),
      title: title,
      content: _textController.text,
      type: KnowledgeSourceType.text,
      createdAt: DateTime.now(),
    );
    widget.onSourceAdded(newSource);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text("Add new source", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_activeInputMode == null) ...[
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search the web for new sources',
                          hintStyle: TextStyle(color: Colors.white30),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onSubmitted: (val) {
                          // Implement web search source adding logic
                          final newSource = KnowledgeSource(
                            id: const Uuid().v4(), 
                            title: 'Search: $val',
                            content: 'Web search results for $val',
                            type: KnowledgeSourceType.url,
                            createdAt: DateTime.now(),
                          );
                          widget.onSourceAdded(newSource);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                      child: const Row(children: [Icon(Icons.public, size: 14, color: Colors.white70), SizedBox(width: 4), Text("Web", style: TextStyle(color: Colors.white70, fontSize: 12))])
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // "Or drop your files here" area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white10, style: BorderStyle.solid), // Dashed border ideal
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.02),
                ),
                child: Column(
                  children: [
                    const Text("or drop your files here", style: TextStyle(color: Colors.white54, fontSize: 16)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildOptionButton(Icons.upload_file, "Upload files", () => _handleFileUpload()),
                        const SizedBox(width: 12),
                        _buildOptionButton(FontAwesomeIcons.globe, "Websites", () => setState(() => _activeInputMode = 'url')),
                        const SizedBox(width: 12),
                        _buildOptionButton(FontAwesomeIcons.googleDrive, "Drive", () {}), // TODO: Drive Integration
                        const SizedBox(width: 12),
                        _buildOptionButton(Icons.assignment, "Copied text", () => setState(() => _activeInputMode = 'text')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Limits info
              const Text(
                "Limit: 50 sources, 500k words each. Audio/Video supported.",
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ] else ...[
              _buildInputModeUI(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInputModeUI() {
    String title = '';
    Widget content = const SizedBox();
    VoidCallback onConfirm = () {};

    if (_activeInputMode == 'url') {
      title = 'Add Website / YouTube';
      content = TextField(
        controller: _urlController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'https://example.com or YouTube URL',
          hintStyle: const TextStyle(color: Colors.white30),
          filled: true,
          fillColor: AppTheme.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      onConfirm = _handleAddUrl;
    } else if (_activeInputMode == 'text') {
      title = 'Paste Text';
      content = TextField(
        controller: _textController,
        style: const TextStyle(color: Colors.white),
        maxLines: 8,
        decoration: InputDecoration(
          hintText: 'Paste your text here...',
          hintStyle: const TextStyle(color: Colors.white30),
          filled: true,
          fillColor: AppTheme.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      onConfirm = _handleAddText;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => setState(() => _activeInputMode = null),
          ),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        content,
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
             TextButton(
              onPressed: () => setState(() => _activeInputMode = null),
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text("Add Source", style: TextStyle(color: Colors.white)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildOptionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
