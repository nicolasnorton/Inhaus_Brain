import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/inhaus_proposal_models.dart';

/// Dialog for selecting proposal type and format
class ProposalTypeSelectionDialog extends StatefulWidget {
  final Function(ProposalType type, ProposalFormat format, ProposalLanguage language) onGenerate;

  const ProposalTypeSelectionDialog({
    super.key,
    required this.onGenerate,
  });

  @override
  State<ProposalTypeSelectionDialog> createState() => _ProposalTypeSelectionDialogState();
}

class _ProposalTypeSelectionDialogState extends State<ProposalTypeSelectionDialog> {
  ProposalType _selectedType = ProposalType.detailedMultiPage;
  ProposalFormat _selectedFormat = ProposalFormat.pdf;
  ProposalLanguage _selectedLanguage = ProposalLanguage.spanish; // Default to Spanish

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5B15D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFE5B15D),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate INHAUS Proposal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Select type, format, and language',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Language Selection (NEW)
            const Text(
              'LANGUAGE',
              style: TextStyle(
                color: Color(0xFFE5B15D),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLanguageOption(
                    language: ProposalLanguage.spanish,
                    title: 'Spanish (Español)',
                    flag: '🇪🇨', 
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLanguageOption(
                    language: ProposalLanguage.english,
                    title: 'English',
                    flag: '🇺🇸',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Proposal Type Selection
            const Text(
              'PROPOSAL TYPE',
              style: TextStyle(
                color: Color(0xFFE5B15D),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildTypeOption(
              type: ProposalType.onePageQuote,
              title: 'One Page Quote',
              subtitle: 'Condensed single-page summary with key services and total price',
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 12),
            _buildTypeOption(
              type: ProposalType.detailedMultiPage,
              title: 'Detailed Proposal (Multi-Page)',
              subtitle: 'Full proposal with per-service pricing, includes/excludes, and detailed descriptions',
              icon: Icons.article_outlined,
            ),
            const SizedBox(height: 32),

            // Output Format Selection
            const Text(
              'OUTPUT FORMAT',
              style: TextStyle(
                color: Color(0xFFE5B15D),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFormatOption(
                    format: ProposalFormat.pdf,
                    title: 'PDF',
                    subtitle: 'Portrait',
                    icon: Icons.picture_as_pdf_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormatOption(
                    format: ProposalFormat.googleSlides,
                    title: 'Slides',
                    subtitle: 'Landscape',
                    icon: Icons.slideshow_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onGenerate(_selectedType, _selectedFormat, _selectedLanguage);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5B15D),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Generate Proposal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required ProposalType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE5B15D).withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE5B15D)
                : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE5B15D).withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFE5B15D) : Colors.white38,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white54 : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFE5B15D),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required ProposalLanguage language,
    required String title,
    required String flag,
  }) {
    final isSelected = _selectedLanguage == language;
    return InkWell(
      onTap: () => setState(() => _selectedLanguage = language),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE5B15D).withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE5B15D)
                : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption({
    required ProposalFormat format,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedFormat == format;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE5B15D).withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE5B15D)
                : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFE5B15D) : Colors.white38,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white54 : Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
