import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/architecture/blackboard.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/auth/auth_service.dart';
import '../../knowledge/providers/knowledge_provider.dart';
import '../models/brainweave_node.dart';
import '../services/brainweave_pipeline_service.dart';
import '../services/brainweave_storage_service.dart';
import '../services/brainweave_stats_service.dart';
import '../services/brainweave_mcp_client.dart';
import 'knowledge_graph_explorer.dart';
import 'brainweave_file_upload.dart';

// ─── Colors & Style Constants ────────────────────────────────────────────────

const _kBrainWeaveGrad = LinearGradient(
  colors: [Color(0xFF6C3DE8), Color(0xFF9B5DEA), Color(0xFFBE7FEA)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _kPhasePurple = Color(0xFF7C3AED);
const _kPhaseAmber  = Color(0xFFF59E0B);
const _kPhaseGreen  = Color(0xFF10B981);
const _kPhaseRed    = Color(0xFFEF4444);

// ─── Sample Clients for Demo ─────────────────────────────────────────────────

const _kSampleClients = [
  {
    'id':          'demo_banco_del_austro',
    'identity':    'Banco del Austro',
    'methodology': 'Community banking strength through trust, proximity, and local economic empowerment.',
    'goals':       'Grow SME loan portfolio 25% in 2026; launch youth savings campaign.',
    'projectId':   'bda_brand_strategy_2026',
  },
  {
    'id':          'demo_bajaj_ecuador',
    'identity':    'Bajaj Ecuador',
    'methodology': 'Accessible mobility for Ecuador\'s growing urban commuter market.',
    'goals':       'Launch Scooter 125cc in Q1; achieve 20% YoY growth in digital leads.',
    'projectId':   'bajaj_scooter_launch_2026',
  },
  {
    'id':          'demo_nutrileche',
    'identity':    'Nutrileche',
    'methodology': 'Nutrition-first brand for Ecuadorian families through science-backed storytelling.',
    'goals':       'Reposition brand for Gen-Z parents; introduce protein+ line.',
    'projectId':   'nutrileche_brand_refresh_2026',
  },
];

// ─── Main Workspace Tab ───────────────────────────────────────────────────────

/// BrainWeave Workspace – the living knowledge system UI for the 6R pipeline.
/// Implements the ArsContexta 3-Space Architecture natively in Flutter.
class BrainWeaveWorkspaceTab extends ConsumerStatefulWidget {
  const BrainWeaveWorkspaceTab({super.key});

  @override
  ConsumerState<BrainWeaveWorkspaceTab> createState() =>
      _BrainWeaveWorkspaceTabState();
}

class _BrainWeaveWorkspaceTabState
    extends ConsumerState<BrainWeaveWorkspaceTab>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inboxController = TextEditingController();
  final TextEditingController _queryController  = TextEditingController();

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;

  String? _activeSessionId;
  String? _statusMessage;
  bool    _isRunning    = false;
  bool    _isExporting  = false;
  String? _exportUrl;
  List<Map<String, dynamic>> _searchResults = [];
  bool    _isSearching = false;
  bool    _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _checkSuperAdmin();
  }

  Future<void> _checkSuperAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final idTokenResult = await user.getIdTokenResult();
    final claims = idTokenResult.claims;
    if (mounted && claims != null) {
      setState(() {
        _isSuperAdmin = claims['superadmin'] == true ||
            claims['role'] == 'superAdmin';
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inboxController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'demo';

  Future<void> _loadSampleClients() async {
    setState(() => _statusMessage = 'Loading sample clients into Core Space…');
    final db = FirebaseFirestore.instance;
    for (final client in _kSampleClients) {
      await db.collection('brainweave_cores').doc(client['id']).set({
        'id':          client['id'],
        'clientId':    _userId,
        'projectId':   client['projectId'],
        'ownerId':     _userId,
        'identity':    client['identity'],
        'methodology': client['methodology'],
        'goals':       client['goals'],
        'createdAt':   FieldValue.serverTimestamp(),
        'updatedAt':   FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    if (mounted) {
      setState(() => _statusMessage = '✅ 3 sample clients loaded into Core Space.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧠 BrainWeave: 3 demo clients loaded!'),
          backgroundColor: _kPhasePurple,
        ),
      );
    }
  }

  Future<void> _runPipeline() async {
    if (_inboxController.text.trim().isEmpty) return;
    setState(() {
      _isRunning     = true;
      _statusMessage = 'Starting 6R Pipeline…';
    });
    try {
      final pipeline = ref.read(brainWeavePipelineServiceProvider);
      final sessionId = 'bw_${DateTime.now().millisecondsSinceEpoch}';
      _activeSessionId = sessionId;
      await pipeline.runPipeline(sessionId, _inboxController.text.trim());
      if (mounted) {
        setState(() {
          _statusMessage = '⏸ Awaiting Reweave approval (Gavel)…';
          _isRunning     = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = '❌ Pipeline error: $e';
          _isRunning     = false;
        });
      }
    }
  }

  Future<void> _approveGavel(bool isRethink) async {
    if (_activeSessionId == null) return;
    setState(() {
      _isRunning     = true;
      _statusMessage = isRethink
          ? 'Executing Rethink phase…'
          : 'Executing Reweave → Verify phases…';
    });
    try {
      final pipeline = ref.read(brainWeavePipelineServiceProvider);
      if (!isRethink) {
        await pipeline.resumePipelineOnApproval(_activeSessionId!);
        if (mounted) {
        setState(() {
          _statusMessage = '⏸ Awaiting Rethink approval (Gavel)…';
          _isRunning     = false;
        });
      }
      } else {
        await pipeline.finalizeRethink(_activeSessionId!);
        if (mounted) {
        setState(() {
          _statusMessage = '✅ 6R Pipeline complete. Knowledge graph updated.';
          _isRunning     = false;
          _activeSessionId = null;
        });
      }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = '❌ Error: $e';
          _isRunning     = false;
        });
      }
    }
  }

  Future<void> _exportZip() async {
    setState(() {
      _isExporting  = true;
      _statusMessage = 'Exporting vault as ZIP…';
    });
    try {
      final storage = ref.read(brainWeaveStorageServiceProvider);
      final url     = await storage.exportVaultAsZip();
      if (mounted) {
        setState(() {
          _exportUrl    = url;
          _isExporting  = false;
          _statusMessage = '✅ ZIP exported.';
        });
        // Auto-open download URL
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) setState(() {
        _isExporting  = false;
        _statusMessage = '❌ Export error: $e';
      });
    }
  }

  Future<void> _exportPdf() async {
    setState(() {
      _isExporting  = true;
      _statusMessage = 'Generating PDF summary…';
    });
    try {
      final storage = ref.read(brainWeaveStorageServiceProvider);
      final url     = await storage.exportVaultSummaryPdf();
      if (mounted) {
        setState(() {
          _exportUrl    = url;
          _isExporting  = false;
          _statusMessage = '✅ PDF exported.';
        });
        // Auto-open download URL
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) setState(() {
        _isExporting  = false;
        _statusMessage = '❌ Export error: $e';
      });
    }
  }

  Future<void> _performSemanticSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _statusMessage = 'Generating vector embedding for query…';
      _isSearching = true;
      _searchResults = [];
    });
    try {
      final vertexAi = ref.read(vertexApiServiceProvider);
      final embeddings = await vertexAi.getEmbeddings([query]);
      if (embeddings.isNotEmpty) {
        setState(() => _statusMessage = 'Searching Weave Space via cosine similarity…');
        final results = await vertexAi.searchVectorIndex(
          queryVector: embeddings.first,
          neighborCount: 10,
        );
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
            _statusMessage = '✅ Semantic search complete. Found ${results.length} related nodes.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Semantic Search: Found ${results.length} related nodes.'),
              backgroundColor: _kPhaseGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _statusMessage = '⚠️ Could not generate embedding for query.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _statusMessage = '❌ Semantic Search error: $e';
        });
      }
    }
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.insights, size: 16, color: Colors.purpleAccent),
            const SizedBox(width: 6),
            Text(
              'Semantic Matches (${_searchResults.length})',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _searchResults = []),
              child: const Text('Clear', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(
          _searchResults.length,
          (i) {
            final result = _searchResults[i];
            final score = (result['score'] as double?) ?? 0.0;
            final pct = (score * 100).toStringAsFixed(0);
            final title = result['title'] ?? 'Untitled';
            final desc = result['description'] ?? '';
            final type = result['type'] ?? 'atomic';
            final topics = (result['topics'] as List?)?.cast<String>() ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.purpleAccent.withValues(alpha: 0.15 + score * 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score badge
                  Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: score > 0.7
                          ? Colors.green.withValues(alpha: 0.15)
                          : score > 0.5
                              ? Colors.amber.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$pct%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: score > 0.7
                            ? Colors.greenAccent
                            : score > 0.5
                                ? Colors.amberAccent
                                : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (desc.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              desc,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _resultTag(type, Colors.purpleAccent),
                            ...topics.take(3).map(
                                (t) => _resultTag(t, Colors.amber)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _resultTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.brainweaveEnabled) {
      return const Center(
        child: Text(
          'BrainWeave is currently disabled.\nEnable in Remote Config: brainweave_enabled = true',
          textAlign: TextAlign.center,
        ),
      );
    }

    final blackboard     = ref.watch(blackboardProvider);
    final isReviewPhase  = blackboard.phase == BlackboardPhase.reviewPending;

    // Determine which Gavel we're at (Reweave vs Rethink) from status string
    final isRethinkGavel = _statusMessage?.contains('Rethink') ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Demo Banner ──────────────────────────────────────────────────
            _DemoBanner(pulseAnimation: _pulseAnimation),
            const SizedBox(height: 12),

            const SizedBox(height: 8),

            // ── Load Sample Clients ──────────────────────────────────────────
            _SampleClientsCard(onLoad: _loadSampleClients),
            const SizedBox(height: 24),

            // ── Pipeline Status Bar ──────────────────────────────────────────
            _PipelineStatusBar(
              phase:         blackboard.phase,
              isRunning:     _isRunning,
              statusMessage: _statusMessage,
            ),
            const SizedBox(height: 24),

            // ── Gavel Cards (Human-in-the-Loop) ──────────────────────────────
            if (isReviewPhase) ...[
              _GavelCard(
                isRethink:   isRethinkGavel,
                onApprove:   () => _approveGavel(isRethinkGavel),
                isProcessing: _isRunning,
              ),
              const SizedBox(height: 24),
            ],

            // ── Inbox (Record Phase) ─────────────────────────────────────────
            _InboxCapture(
              controller:  _inboxController,
              isRunning:   _isRunning,
              onSubmit:    _runPipeline,
            ),
            const SizedBox(height: 16),

            // ── PDF Parser Evolution: File Upload ─────────────────────────────
            if (FeatureFlags.brainweavePdfParserEvolutionEnabled)
              BrainWeaveFileUploadButton(
                onUploadComplete: () {
                  // Refresh stats after upload
                  setState(() {});
                },
              ),
            const SizedBox(height: 24),

            // ── Query Field (NL Fallback) ─────────────────────────────────────
            _QueryField(
              controller: _queryController,
              onSubmitted: _performSemanticSearch,
            ),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            if (_searchResults.isNotEmpty)
              _buildSearchResults(),
            const SizedBox(height: 24),

            // ── Knowledge Graph Explorer ──────────────────────────────────────
            _GraphExplorerLauncher(userId: _userId),
            const SizedBox(height: 24),

            // ── Graph Stats Dashboard ────────────────────────────────────────
            const _BrainWeaveStatsCard(),
            const SizedBox(height: 16),

            // ── Security Dashboard (Superadmin) ──────────────────────────────
            if (_isSuperAdmin) ...[
              const SecurityStatusPanel(),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),

            // ── Export Actions ────────────────────────────────────────────────
            _ExportActions(
              isExporting: _isExporting,
              exportUrl:   _exportUrl,
              onExportZip: _exportZip,
              onExportPdf: _exportPdf,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _DemoBanner extends StatelessWidget {
  final Animation<double> pulseAnimation;
  const _DemoBanner({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: pulseAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
        decoration: BoxDecoration(
          gradient: _kBrainWeaveGrad,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C3DE8).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.brain, color: Colors.white, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BrainWeave 3.0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Living Knowledge System  ·  Unified Agent Skills',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Record', 'Research', 'Reduce', 'Reflect', 'Reweave', 'Verify', 'Rethink']
                        .map((label) => Chip(
                              label: Text(label,
                                  style: const TextStyle(fontSize: 10, color: Colors.white)),
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleClientsCard extends StatelessWidget {
  final VoidCallback onLoad;
  const _SampleClientsCard({required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.usersViewfinder, color: Colors.purpleAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Load Sample Clients',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text('Pre-loads Banco del Austro, Bajaj & Nutrileche into Core Space.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onLoad,
            icon: const FaIcon(FontAwesomeIcons.bolt, size: 14),
            label: const Text('Load'),
            style: FilledButton.styleFrom(backgroundColor: _kPhasePurple),
          ),
        ],
      ),
    );
  }
}

class _PipelineStatusBar extends StatelessWidget {
  final BlackboardPhase phase;
  final bool isRunning;
  final String? statusMessage;

  const _PipelineStatusBar({
    required this.phase,
    required this.isRunning,
    this.statusMessage,
  });

  static const _phases = [
    'Record', 'Research', 'Reduce', 'Reflect', 'Reweave', 'Verify', 'Rethink',
  ];

  static const _phaseMap = {
    BlackboardPhase.brainweaveRecord:   0,
    BlackboardPhase.brainweaveResearch: 1,
    BlackboardPhase.brainweaveReduce:   2,
    BlackboardPhase.brainweaveReflect:  3,
    BlackboardPhase.brainweaveReweave:  4,
    BlackboardPhase.brainweaveVerify:   5,
    BlackboardPhase.brainweaveRethink:  6,
    BlackboardPhase.reviewPending:      4, // stuck at Reweave or Rethink
  };

  @override
  Widget build(BuildContext context) {
    final activeIdx = _phaseMap[phase] ?? -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('6R Pipeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 12),
            if (isRunning)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPhasePurple),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _phases.asMap().entries.map((e) {
            final idx      = e.key;
            final label    = e.value;
            final isActive = idx == activeIdx;
            final isDone   = idx < activeIdx;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: isDone
                            ? _kPhaseGreen
                            : isActive
                                ? _kPhasePurple
                                : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? _kPhasePurple : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (statusMessage != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusMessage!,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ),
        ],
      ],
    );
  }
}

class _GavelCard extends StatelessWidget {
  final bool isRethink;
  final VoidCallback onApprove;
  final bool isProcessing;

  const _GavelCard({
    required this.isRethink,
    required this.onApprove,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final label = isRethink ? 'Rethink Phase' : 'Reweave Phase';
    final desc = isRethink
        ? 'Approve to modify BrainWeave Methodology (Core Space). This is irreversible without a backup.'
        : 'Approve to backward-update the Knowledge Graph (Weave Space). Review proposed nodes above.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPhaseAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPhaseAmber.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.gavel, color: _kPhaseAmber, size: 22),
              const SizedBox(width: 10),
              Text('Gavel – $label Approval Required',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: _kPhaseAmber)),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: isProcessing ? null : onApprove,
                icon: isProcessing
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const FaIcon(FontAwesomeIcons.circleCheck, size: 14),
                label: Text(isProcessing ? 'Processing…' : 'Approve & Continue'),
                style: FilledButton.styleFrom(backgroundColor: _kPhaseAmber),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InboxCapture extends StatelessWidget {
  final TextEditingController controller;
  final bool isRunning;
  final VoidCallback onSubmit;

  const _InboxCapture({
    required this.controller,
    required this.isRunning,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inbox – Record Phase',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text('Zero-friction capture. Enter any raw knowledge, note, or observation.',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'e.g. "Banco del Austro needs a Q1 SME loan campaign focused on trust…"',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPhasePurple, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isRunning ? null : onSubmit,
            icon: isRunning
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const FaIcon(FontAwesomeIcons.play, size: 14),
            label: Text(isRunning ? 'Pipeline Running…' : 'Run 6R Pipeline'),
            style: FilledButton.styleFrom(
              backgroundColor: _kPhasePurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _QueryField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  const _QueryField({required this.controller, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Natural language query across nodes…',
        prefixIcon: const Icon(Icons.search, color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple.withValues(alpha: 0.15)),
        ),
      ),
    );
  }
}

class _GraphExplorerLauncher extends ConsumerWidget {
  final String userId;
  const _GraphExplorerLauncher({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Knowledge Graph – Weave Space',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('brainweave_nodes')
              .where('ownerId', isEqualTo: userId)
              .orderBy('updatedAt', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _kPhasePurple));
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.diagramProject,
                          color: Colors.white24, size: 32),
                      SizedBox(height: 12),
                      Text('No nodes yet. Run the 6R pipeline to populate the graph.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }
            final nodes = docs.map((doc) =>
                BrainWeaveNode.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
            return Column(
              children: [
                // ── Explore Button ──
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            body: KnowledgeGraphExplorer(),
                          ),
                        ),
                      );
                    },
                    icon: const FaIcon(FontAwesomeIcons.diagramProject, size: 14),
                    label: Text('Explore Knowledge Graph  ·  ${nodes.length} nodes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1D27),
                      foregroundColor: const Color(0xFFD4A574),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: const Color(0xFF2A2D3A)),
                      ),
                    ),
                  ),
                ),
                // Agency View toggle (superadmin only)
                FutureBuilder<bool>(
                  future: ref.read(authServiceProvider).isSuperAdmin,
                  builder: (ctx, snap) {
                    if (snap.data != true) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const Scaffold(
                                  body: KnowledgeGraphExplorer(agencyMode: true),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.admin_panel_settings, size: 14, color: Color(0xFF7C3AED)),
                          label: const Text('Agency-Wide Graph View',
                              style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // ── Node preview list ──
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nodes.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) => _NodeTile(node: nodes[idx]),
                ),
                if (nodes.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+ ${nodes.length - 5} more nodes — tap Explore to see all',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _NodeTile extends StatelessWidget {
  final BrainWeaveNode node;
  const _NodeTile({required this.node});

  Color get _typeColor {
    switch (node.type) {
      case BrainWeaveNodeType.moc:   return _kPhaseGreen;
      case BrainWeaveNodeType.topic: return _kPhaseAmber;
      default:                       return _kPhasePurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _typeColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _typeColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              node.type.name.toUpperCase(),
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.bold, color: _typeColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (node.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(node.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
                if (node.topics.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: node.topics.take(4).map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 9)),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const FaIcon(FontAwesomeIcons.link, size: 12, color: Colors.white24),
        ],
      ),
    );
  }
}

class _ExportActions extends StatelessWidget {
  final bool isExporting;
  final String? exportUrl;
  final VoidCallback onExportZip;
  final VoidCallback onExportPdf;

  const _ExportActions({
    required this.isExporting,
    this.exportUrl,
    required this.onExportZip,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Export Vault',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isExporting ? null : onExportZip,
                icon: isExporting
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const FaIcon(FontAwesomeIcons.fileZipper, size: 14),
                label: const Text('Export ZIP'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.purple.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isExporting ? null : onExportPdf,
                icon: const FaIcon(FontAwesomeIcons.filePdf, size: 14),
                label: const Text('Export PDF'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        if (exportUrl != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              launchUrl(Uri.parse(exportUrl!), mode: LaunchMode.externalApplication);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kPhaseGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kPhaseGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.circleCheck, color: _kPhaseGreen, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⬇ Tap to download: ${exportUrl!.length > 50 ? '${exportUrl!.substring(0, 50)}…' : exportUrl!}',
                      style: const TextStyle(fontSize: 11, color: _kPhaseGreen, decoration: TextDecoration.underline, decorationColor: _kPhaseGreen),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const FaIcon(FontAwesomeIcons.download, color: _kPhaseGreen, size: 12),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Stats Card ─────────────────────────────────────────────────────────────

class _BrainWeaveStatsCard extends StatefulWidget {
  const _BrainWeaveStatsCard();

  @override
  State<_BrainWeaveStatsCard> createState() => _BrainWeaveStatsCardState();
}

class _BrainWeaveStatsCardState extends State<_BrainWeaveStatsCard> {
  final _stats = BrainWeaveStatsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _stats.getStats();
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_data == null) return const SizedBox.shrink();

    final nodes = _data!['node_count'] ?? 0;
    final edges = _data!['edge_count'] ?? 0;
    final daily = _data!['daily_interactions'] ?? 0;
    final cost  = (_data!['est_cost_usd'] ?? 0.0).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1D27),
            const Color(0xFF1A1D27).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2D3A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights, size: 18, color: _kPhasePurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your Graph: $nodes nodes \u2022 $edges edges \u2014 '
              '$daily interactions today \u2022 Est. cost \$$cost',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Security Status Panel (Superadmin Only) ────────────────────────────────

class SecurityStatusPanel extends StatefulWidget {
  const SecurityStatusPanel({super.key});

  @override
  State<SecurityStatusPanel> createState() => _SecurityStatusPanelState();
}

class _SecurityStatusPanelState extends State<SecurityStatusPanel> {
  final _mcp = BrainWeaveMcpClient();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _mcp.getSecurityStatus();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null || _data == null) return const SizedBox.shrink();

    final encryption = _data!['encryption'] ?? 'UNKNOWN';
    final fgac = _data!['fgac_enabled'] == true;
    final promotes = _data!['recent_promotes_24h'] ?? 0;
    final pending = _data!['pending_approvals'] ?? 0;
    final totalNodes = _data!['total_nodes'] ?? 0;
    final totalUsers = _data!['total_users'] ?? 0;
    final rateLimit = _data!['rate_limit_max'] ?? 100;
    final lastCheck = _data!['last_check'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D1117),
            const Color(0xFF161B22),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, size: 18, color: fgac ? Colors.green : const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              const Text(
                'Security Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: encryption == 'CMEK'
                      ? Colors.green.withValues(alpha: 0.2)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  encryption,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: encryption == 'CMEK' ? Colors.green : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _statusChip(Icons.people, '$totalUsers users', Colors.blue),
              _statusChip(Icons.hub, '$totalNodes nodes', Colors.purple),
              _statusChip(Icons.publish, '$promotes promotes (24h)', Colors.teal),
              if (pending > 0)
                _statusChip(Icons.pending_actions, '$pending pending', Colors.orange),
              _statusChip(Icons.speed, 'Rate: $rateLimit', Colors.grey),
              _statusChip(
                fgac ? Icons.lock : Icons.lock_open,
                fgac ? 'FGAC ON' : 'FGAC OFF',
                fgac ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last check: ${lastCheck.length > 19 ? lastCheck.substring(0, 19) : lastCheck}',
            style: const TextStyle(fontSize: 10, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.9))),
      ],
    );
  }
}
