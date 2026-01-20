import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/slide_deck_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SlideDeckConfigDialog extends StatefulWidget {
  final Function(SlideDeckFormat, String, SlideDeckLength, String) onGenerate;

  const SlideDeckConfigDialog({super.key, required this.onGenerate});

  @override
  State<SlideDeckConfigDialog> createState() => _SlideDeckConfigDialogState();
}

class _SlideDeckConfigDialogState extends State<SlideDeckConfigDialog> {
  SlideDeckFormat _selectedFormat = SlideDeckFormat.detailed;
  String _selectedLanguage = 'Español (Latinoamérica)';
  SlideDeckLength _selectedLength = SlideDeckLength.standard; // 'Default' map to standard
  final TextEditingController _promptController = TextEditingController();

  final List<String> _languages = [
    'English (US)',
    'Español (Latinoamérica)',
    'Français',
    'Deutsch',
    'Português',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
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
                const Row(
                  children: [
                    Icon(FontAwesomeIcons.layerGroup, color: Colors.amber, size: 20),
                    SizedBox(width: 12),
                    Text("Customize Slide Deck", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),

            // Format Selection
            const Text("Format", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildFormatCard(
                  SlideDeckFormat.detailed,
                  "Detailed Deck",
                  "A comprehensive deck with full text and details, perfect for emailing or reading on its own.",
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildFormatCard(
                  SlideDeckFormat.presenter,
                  "Presenter Slides",
                  "Clean, visual slides with key talking points to support you while you speak.",
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Language & Length Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Choose language", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            dropdownColor: AppTheme.background,
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white),
                            items: _languages.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedLanguage = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Length", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            _buildLengthOption(SlideDeckLength.short, "Short"),
                            Container(width: 1, height: 40, color: Colors.white10),
                            _buildLengthOption(SlideDeckLength.standard, "Default"),
                            Container(width: 1, height: 40, color: Colors.white10),
                            _buildLengthOption(SlideDeckLength.long, "Long"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Prompt
            const Text("Describe the slide deck you want to create", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a high-level outline, or guide the audience, style, and focus: "Create a deck for beginners using a bold and playful style..."',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onGenerate(
                      _selectedFormat,
                      _selectedLanguage,
                      _selectedLength,
                      _promptController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text("Generate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard(SlideDeckFormat format, String title, String description) {
    final isSelected = _selectedFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = format),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (isSelected) const Icon(Icons.check, color: AppTheme.primary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildLengthOption(SlideDeckLength length, String label) {
    final isSelected = _selectedLength == length;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedLength = length),
        child: Container(
          height: 40,
          color: isSelected ? Colors.white10 : Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
