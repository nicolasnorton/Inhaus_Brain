import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../adk/screens/workflow_canvas_screen.dart';
import '../providers/campaign_provider.dart';
import '../templates/campaign_weavy_template.dart';

/// Campaign-aware wrapper around WorkflowCanvasScreen.
///
/// Loads campaign context and lets the user pick a preset template,
/// then opens the canvas pre-loaded with that template.
class CreativeCampaignCanvasScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const CreativeCampaignCanvasScreen({super.key, required this.campaignId});

  @override
  ConsumerState<CreativeCampaignCanvasScreen> createState() =>
      _CreativeCampaignCanvasScreenState();
}

class _CreativeCampaignCanvasScreenState
    extends ConsumerState<CreativeCampaignCanvasScreen> {
  String? _selectedTemplate;
  bool _showTemplatePicker = true;

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignListProvider);
    final campaign =
        campaigns.where((c) => c.id == widget.campaignId).firstOrNull;

    // Once a template is selected, show the canvas
    if (!_showTemplatePicker && _selectedTemplate != null) {
      final templateFactory = CampaignWeavyTemplates.all[_selectedTemplate!];
      return WorkflowCanvasScreen(
        pipelineId: null,
        initialSteps: templateFactory != null ? templateFactory() : null,
      );
    }

    // Template picker
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Designer Canvas', style: TextStyle(fontSize: 16)),
            if (campaign != null)
              Text(campaign.title,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5))),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('Choose a Template',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Start with a pre-built workflow or create from scratch.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _buildTemplateCard(
                        icon: FontAwesomeIcons.wandMagicSparkles,
                        title: 'Default Campaign',
                        description:
                            '7-node chain: Moodboard → BrainWeave → ImageGen → Inpaint → Video → Composite → Approval',
                        color: const Color(0xFF9C1AFF),
                        templateKey: 'Default Campaign Workflow',
                        imageUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=600&q=80',
                      ),
                      _buildTemplateCard(
                        icon: FontAwesomeIcons.lightbulb,
                        title: 'Hero Product Relight',
                        description:
                            'Upload product → Studio & Dramatic lighting → Side-by-side composite',
                        color: const Color(0xFFEA580C),
                        templateKey: 'Hero Product Relight',
                        imageUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=600&q=80',
                      ),
                      _buildTemplateCard(
                        icon: FontAwesomeIcons.hashtag,
                        title: 'Social Media Variations',
                        description:
                            'One prompt → 3 formats: Stories (9:16), Feed (1:1), Portrait (4:5)',
                        color: const Color(0xFFDB2777),
                        templateKey: 'Social Media Variations',
                        imageUrl: 'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=600&q=80',
                      ),
                      _buildTemplateCard(
                        icon: FontAwesomeIcons.video,
                        title: 'Video Ad + Lip-sync',
                        description:
                            'ImageGen → Video with narration → Text overlay → Stitch landing page',
                        color: const Color(0xFF7C3AED),
                        templateKey: 'Video Ad with Lip-sync',
                        imageUrl: 'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=600&q=80',
                      ),
                      _buildTemplateCard(
                        icon: FontAwesomeIcons.rotate,
                        title: 'Multi-Angle 360°',
                        description:
                            'Upload reference → 4 ControlNet angles (front, 45°, side, back) → Grid composite',
                        color: const Color(0xFF0EA5E9),
                        templateKey: 'Multi-Angle 360°',
                        imageUrl: 'https://images.unsplash.com/photo-1622979135225-d2ba269cf1ac?w=600&q=80',
                      ),
                      _buildTemplateCard(
                        icon: FontAwesomeIcons.plus,
                        title: 'Blank Canvas',
                        description: 'Start from scratch with an empty workflow.',
                        color: Colors.white24,
                        templateKey: '_blank',
                        imageUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=600&q=80',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String templateKey,
    String? imageUrl,
  }) {
    final isSelected = _selectedTemplate == templateKey;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTemplate = templateKey);
      },
      onDoubleTap: () {
        setState(() {
          _selectedTemplate = templateKey;
          _showTemplatePicker = false;
        });
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          image: imageUrl != null ? DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ) : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: color.withValues(alpha: 0.2),
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: color.withValues(alpha: 0.3)),
                     ),
                     child: FaIcon(icon, color: color, size: 16),
                   ),
                  const Spacer(),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(description,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
