import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'providers/creative_provider.dart';
import 'models/design_concept.dart';
import '../chat/agentic_chat_view.dart';

class CreativeStudioScreen extends ConsumerWidget {
  const CreativeStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concepts = ref.watch(creativeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Main Content: Creative Concepts
          Expanded(
            flex: 3,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: const Text('Creative Studio', overflow: TextOverflow.ellipsis),
                  backgroundColor: Colors.transparent,
                  actions: [
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.wandMagicSparkles),
                      onPressed: () {
                        // TODO: Trigger manual generation
                      },
                      tooltip: 'Propose New Concept',
                    ),
                  ],
                ),
                if (concepts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FontAwesomeIcons.palette, size: 64, color: Colors.white12),
                          SizedBox(height: 16),
                          Text(
                            'No creative concepts yet.',
                            style: TextStyle(color: Colors.white54, fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Complete a campaign research approval to trigger the Design Agent.',
                            style: TextStyle(color: Colors.white30),
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
          
          // Side Panel: Agentic Chat (Flexible width for smaller screens)
          Flexible(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  constraints: const BoxConstraints(minWidth: 280, maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.commentDots, size: 16, color: Colors.blueAccent),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'DESIGN FEEDBACK',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
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
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptItem(BuildContext context, WidgetRef ref, DesignConcept concept) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        concept.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Campaign ID: ${concept.campaignId.substring(0, 8)}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (concept.isApproved)
                  const Icon(Icons.check_circle, color: Colors.green, size: 32)
                else
                  ElevatedButton(
                    onPressed: () {
                      ref.read(creativeProvider.notifier).updateConcept(
                        concept.copyWith(isApproved: true),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                      foregroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Approve'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Copy Proposition',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  concept.copy,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Visual Strategy Prompt',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    concept.visualPrompt,
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
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
                      const Text(
                        'Final Production Assets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      if (!concept.isFinalReady)
                        ElevatedButton.icon(
                          onPressed: () => ref.read(creativeProvider.notifier).generateHighTierAssets(concept),
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Generate High-Tier Assets'),
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
                          const Row(
                            children: [
                              Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Final High-Fidelity Copy (Vertex AI)',
                                style: TextStyle(
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
                            child: const Chip(
                              label: Text('Final Visual Mock (Imagen-3)', style: TextStyle(fontSize: 10)),
                              backgroundColor: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                  ] else if (concept.isApproved && !concept.isFinalReady)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Concept approved. Ready for high-fidelity production.',
                              style: TextStyle(color: Colors.white38),
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
            const Text(
              'Style Boards',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            Text(
              '${moodboards.length} Suggested',
              style: const TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
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
