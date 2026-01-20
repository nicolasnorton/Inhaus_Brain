import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'providers/creative_provider.dart';
import 'models/design_concept.dart';
import '../chat/agentic_chat_view.dart';
import '../../core/widgets/app_video_player.dart';
import '../../core/widgets/app_audio_player.dart';

class CreativeStudioScreen extends ConsumerWidget {
  const CreativeStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concepts = ref.watch(creativeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Content: Creative Concepts
          Expanded(
            flex: 3,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: Text(AppLocalizations.of(context)!.creativeStudio, overflow: TextOverflow.ellipsis),
                  backgroundColor: Colors.transparent,
                  actions: [
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.wandMagicSparkles),
                      onPressed: () {
                        // TODO: Trigger manual generation
                      },
                      tooltip: AppLocalizations.of(context)!.proposeNewConcept,
                    ),
                  ],
                ),
                if (concepts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FontAwesomeIcons.palette, size: 64, color: Colors.white12),
                          SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noCreativeConceptsYet,
                            style: const TextStyle(color: Colors.white54, fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.completeResearchApprovalMsg,
                            style: const TextStyle(color: Colors.white30),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildConceptItem(context, ref, concepts[index]),
                        childCount: concepts.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Side Panel: Agentic Chat (Expanded to fill vertical space)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.commentDots, size: 16, color: Colors.blueAccent),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.designFeedback,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const Expanded(child: AgenticChatView()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptItem(BuildContext context, WidgetRef ref, DesignConcept concept) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2329), // Darker, rich card color
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.designConcept,
                          style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        concept.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.campaignIdLabel(concept.campaignId.length > 8 ? concept.campaignId.substring(0, 8) : concept.campaignId),
                        style: const TextStyle(color: Colors.white38, fontSize: 13, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                 if (concept.isApproved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text('APPROVED', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  )
                else
                   OutlinedButton.icon(
                    onPressed: () {
                      ref.read(creativeProvider.notifier).updateConcept(
                        concept.copyWith(isApproved: true),
                      );
                    },
                    icon: const Icon(Icons.thumb_up),
                    label: Text(AppLocalizations.of(context)!.approve.toUpperCase()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.edit_note, color: Colors.white70),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.copyProposition,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: MarkdownBody(
                    data: concept.copy,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
                      strong: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      h1: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                 Row(children: [
                  const Icon(Icons.image_search, color: Colors.white70),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.visualStrategyPrompt,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1115), // Terminal-like background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: SelectableText(
                    concept.visualPrompt,
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, height: 1.5, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),
                _buildMoodboardsSection(context, concept.moodboards),
                if (concept.isApproved) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.finalProductionAssets,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      if (!concept.isFinalReady)
                        ElevatedButton.icon(
                          onPressed: () => ref.read(creativeProvider.notifier).generateHighTierAssets(concept),
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: Text(AppLocalizations.of(context)!.generateHighTierAssets),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (concept.isFinalReady && concept.finalCopy != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                              SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.finalHighFidelityCopy,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            concept.finalCopy!,
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (concept.finalImageURL != null) 
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(concept.finalImageURL!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            alignment: Alignment.bottomRight,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                              ),
                            ),
                            child: Chip(
                              label: Text(AppLocalizations.of(context)!.finalVisualMock, style: const TextStyle(fontSize: 10)),
                              backgroundColor: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                    if (concept.finalVideoURL != null) ...[
                      const SizedBox(height: 16),
                       ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                           aspectRatio: 16/9,
                           child: AppVideoPlayer(videoUrl: concept.finalVideoURL!),
                        ),
                      ),
                    ],

                    if (concept.finalAudioURL != null) ...[
                      const SizedBox(height: 16),
                      AppAudioPlayer(audioUrl: concept.finalAudioURL!),
                    ],
                  ] else if (concept.isApproved && !concept.isFinalReady)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.conceptApprovedReadyProduction,
                              style: const TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodboardsSection(BuildContext context, List<Moodboard> moodboards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.styleBoards,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            Text(
              AppLocalizations.of(context)!.suggestedCount(moodboards.length),
              style: const TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: moodboards.length,
            itemBuilder: (context, index) {
              final mb = moodboards[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mb.imageUrls.isNotEmpty)
                      Container(
                        height: 80,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(mb.imageUrls.isNotEmpty ? mb.imageUrls.first : 'https://placehold.co/600x400/1E2329/blueaccent?text=Idea'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Text(mb.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      mb.description,
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
