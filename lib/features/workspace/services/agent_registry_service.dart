import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agent metadata for the registry (lightweight, for system prompt injection).
class AgentRegistryEntry {
  final String name;
  final String description;
  final String modelTier;
  final List<String> tools;
  final String? promptContent; // Only loaded on-demand (lazy)

  const AgentRegistryEntry({
    required this.name,
    required this.description,
    this.modelTier = 'flash',
    this.tools = const [],
    this.promptContent,
  });

  factory AgentRegistryEntry.fromFirestore(Map<String, dynamic> data, String id) {
    return AgentRegistryEntry(
      name: data['name'] as String? ?? id,
      description: data['description'] as String? ?? 'No description.',
      modelTier: data['model_tier'] as String? ?? 'flash',
      tools: List<String>.from(data['tools'] ?? []),
      promptContent: data['prompt_content'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'model_tier': modelTier,
    'tools': tools,
    if (promptContent != null) 'prompt_content': promptContent,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// Short metadata for system prompt injection (progressive disclosure).
  String toSummary() => '- **$name**: $description';
}

/// Service for managing the agent registry in Firestore.
/// Replaces the hardcoded RouterIntent enum + router.md capabilities registry.
class AgentRegistryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AgentRegistryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference _registryRef(String userId) =>
      _firestore.collection('workspaces').doc(userId).collection('agent_registry');

  // ─── Registry Operations ──────────────────────────────────

  /// Get all agent metadata (name + description only).
  Future<List<AgentRegistryEntry>> getAgentRegistry() async {
    final uid = _userId;
    if (uid == null) return [];

    final snap = await _registryRef(uid).get();
    return snap.docs.map((doc) {
      return AgentRegistryEntry.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  /// Lazy-load the full prompt for a specific agent.
  Future<String?> getAgentPrompt(String agentName) async {
    final uid = _userId;
    if (uid == null) return null;

    final doc = await _registryRef(uid).doc(agentName).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>?;
    return data?['prompt_content'] as String?;
  }

  /// Build the agent summary section for the system prompt.
  Future<String> buildAgentSummary() async {
    final agents = await getAgentRegistry();
    if (agents.isEmpty) return '';

    final summaries = agents.map((a) => a.toSummary()).join('\n');
    return '# Available Agents\n\n$summaries';
  }

  /// Build a dynamic router prompt from the agent registry.
  Future<String> buildDynamicRouterPrompt() async {
    final agents = await getAgentRegistry();
    if (agents.isEmpty) {
      debugPrint('AgentRegistryService: No agents in registry, using static router.');
      return '';
    }

    final agentsSection = agents.map((a) =>
      '- **${a.name}**: ${a.description}'
    ).join('\n');

    return '''# Inhaus Brain — Dynamic Router

## Role
You are the **Root Router** for the Inhaus Brain system. Analyze the user's request and route it to the most capable specialized agent.

## Available Agents
$agentsSection

## Output Format
Return **ONLY** a valid JSON object:
```json
{
  "intent": "agent_name",
  "confidence": 0.95,
  "reasoning": "Brief explanation"
}
```

## Rules
- If the request is simple small talk or greetings, route to "directChat".
- If the request requires multiple agents or a full campaign, route to "pipeline".
- Always pick the single most relevant agent.
''';
  }

  // ─── Seeding from Assets ──────────────────────────────────

  /// Incremental seed: adds missing agents without overwriting existing ones.
  Future<void> seedRegistryFromAssets() async {
    final uid = _userId;
    if (uid == null) return;

    // Get existing agent IDs to avoid overwriting user edits
    final existing = await _registryRef(uid).get();
    final existingIds = existing.docs.map((d) => d.id).toSet();

    final missing = _defaultAgentEntries.where((e) => !existingIds.contains(e.name)).toList();
    if (missing.isEmpty) {
      debugPrint('AgentRegistryService: All ${_defaultAgentEntries.length} agents present.');
      return;
    }

    debugPrint('AgentRegistryService: Adding ${missing.length} new agents...');

    for (final entry in missing) {
      // Try to load the full prompt from assets
      String? promptContent;
      try {
        promptContent = await rootBundle.loadString('assets/prompts/${entry.name}.md');
      } catch (_) {
        // Some agents may not have .md files
      }

      final enrichedEntry = AgentRegistryEntry(
        name: entry.name,
        description: entry.description,
        modelTier: entry.modelTier,
        tools: entry.tools,
        promptContent: promptContent,
      );

      await _registryRef(uid).doc(entry.name).set(enrichedEntry.toFirestore());
    }

    debugPrint('AgentRegistryService: Seeded ${missing.length} new agents (total: ${_defaultAgentEntries.length}).');
  }

  /// Default agent entries (extracted from router.md capabilities registry).
  static const _defaultAgentEntries = [
    AgentRegistryEntry(
      name: 'research',
      description: 'Fact-finding, market analysis, competitor research. Trigger: "find info about", "what is", "analyze market".',
      modelTier: 'flash',
      tools: ['web_search', 'file_search', 'deep_research'],
    ),
    AgentRegistryEntry(
      name: 'creative',
      description: 'Visual concepts, art direction, logo ideas. Trigger: "generate an image", "create concept", "design".',
      modelTier: 'pro',
      tools: ['image_generation', 'web_search'],
    ),
    AgentRegistryEntry(
      name: 'copywriting',
      description: 'Writing ad copy, emails, social posts, blogs. Trigger: "write a caption", "create a script".',
      modelTier: 'flash',
      tools: ['web_search'],
    ),
    AgentRegistryEntry(
      name: 'developer',
      description: 'Coding tasks, technical explanations. Trigger: "write a function", "debug this".',
      modelTier: 'pro',
      tools: ['web_search', 'code_execution'],
    ),
    AgentRegistryEntry(
      name: 'pipeline',
      description: 'Complex multi-step requests, full campaigns. Spawns parallel tasks via Blackboard.',
      modelTier: 'pro',
      tools: ['web_search', 'orchestrate_task'],
    ),
    AgentRegistryEntry(
      name: 'strategist',
      description: 'High-level brand strategy, positioning, market entry plans.',
      modelTier: 'pro',
      tools: ['web_search'],
    ),
    AgentRegistryEntry(
      name: 'performance_analyst',
      description: 'ROAS optimization, media spend analysis, data-driven insights.',
      modelTier: 'flash',
      tools: ['web_search', 'charts'],
    ),
    AgentRegistryEntry(
      name: 'trend_scout',
      description: 'Emerging cultural shifts, TikTok trends, viral patterns.',
      modelTier: 'flash',
      tools: ['web_search'],
    ),
    AgentRegistryEntry(
      name: 'seo',
      description: 'Search Engine Optimization: schema markup, ranking audits, keyword analysis.',
      modelTier: 'flash',
      tools: ['web_search'],
    ),
    AgentRegistryEntry(
      name: 'aeo',
      description: 'Answer Engine Optimization: AI overview, featured snippets, structured data.',
      modelTier: 'flash',
      tools: ['web_search'],
    ),
    AgentRegistryEntry(
      name: 'data_analyst',
      description: 'Deep data visualization, SQL queries, BigQuery analytics.',
      modelTier: 'flash',
      tools: ['charts'],
    ),
    AgentRegistryEntry(
      name: 'account_director',
      description: 'Client-facing communication, billing queries, project status.',
      modelTier: 'flash',
      tools: [],
    ),
    AgentRegistryEntry(
      name: 'proposal_specialist',
      description: 'Generating SOWs, quotes, visual proposals in INHAUS style.',
      modelTier: 'pro',
      tools: ['web_search', 'proposal'],
    ),
    AgentRegistryEntry(
      name: 'editorial_manager',
      description: 'Multi-channel content calendars, publishing schedules.',
      modelTier: 'flash',
      tools: [],
    ),
    AgentRegistryEntry(
      name: 'crm',
      description: 'Customer relationship management, lead nurturing, email automation flows.',
      modelTier: 'flash',
      tools: [],
    ),
    AgentRegistryEntry(
      name: 'security',
      description: 'Infrastructure auditing, PII protection, compliance checks.',
      modelTier: 'flash',
      tools: [],
    ),
    AgentRegistryEntry(
      name: 'video_master',
      description: 'Complex video production planning and post-production workflows.',
      modelTier: 'pro',
      tools: ['video_generation'],
    ),
    AgentRegistryEntry(
      name: 'directChat',
      description: 'Simple greetings, questions about the system itself, small talk.',
      modelTier: 'flash',
      tools: [],
    ),
    // ─── Additional agents from assets/prompts ────────────────
    AgentRegistryEntry(
      name: 'brian',
      description: 'Core Brian personality — main conversational agent with full identity.',
      modelTier: 'pro',
      tools: ['web_search', 'skill_creator'],
    ),
    AgentRegistryEntry(
      name: 'assistant_main',
      description: 'General-purpose assistant for broad queries and task coordination.',
      modelTier: 'flash',
      tools: ['web_search'],
    ),
    AgentRegistryEntry(
      name: 'copywriter',
      description: 'Dedicated copywriting agent — long-form content, blogs, emails.',
      modelTier: 'flash',
      tools: ['web_search'],
    ),
    AgentRegistryEntry(
      name: 'intent_classifier',
      description: 'Classifies user intent for internal routing. Not user-facing.',
      modelTier: 'flash',
      tools: [],
    ),
    AgentRegistryEntry(
      name: 'router',
      description: 'Legacy static router prompt. Superseded by DynamicRouter.',
      modelTier: 'flash',
      tools: [],
    ),
    AgentRegistryEntry(
      name: 'orchestrator',
      description: 'Multi-step workflow orchestration — parallel task spawning.',
      modelTier: 'pro',
      tools: ['web_search', 'orchestrate_task'],
    ),
    AgentRegistryEntry(
      name: 'design',
      description: 'UI/UX design guidance, wireframes, design system consultation.',
      modelTier: 'pro',
      tools: ['image_generation'],
    ),
    AgentRegistryEntry(
      name: 'data_engineer',
      description: 'ETL pipelines, data modeling, BigQuery schema design.',
      modelTier: 'flash',
      tools: ['charts'],
    ),
    AgentRegistryEntry(
      name: 'developer',
      description: 'Full-stack development — Flutter, Python, Firebase, infrastructure.',
      modelTier: 'pro',
      tools: ['web_search'],
    ),
    AgentRegistryEntry(
      name: 'media_buyer',
      description: 'Paid media planning, ad buying strategy, platform optimization.',
      modelTier: 'flash',
      tools: ['web_search', 'charts'],
    ),
    AgentRegistryEntry(
      name: 'service',
      description: 'Customer service templates, FAQ generation, support workflows.',
      modelTier: 'flash',
      tools: [],
    ),
    AgentRegistryEntry(
      name: 'storytelling',
      description: 'Brand storytelling, narrative arcs, campaign narratives.',
      modelTier: 'pro',
      tools: ['web_search'],
    ),
    AgentRegistryEntry(
      name: 'video',
      description: 'Video scripting, shot lists, storyboarding.',
      modelTier: 'pro',
      tools: ['video_generation'],
    ),
    AgentRegistryEntry(
      name: 'csuite',
      description: 'Executive-level strategic advisory — board decks, investor comms.',
      modelTier: 'pro',
      tools: ['web_search'],
    ),
    AgentRegistryEntry(
      name: 'multimodal_best_practices',
      description: 'Guidelines for multimodal AI usage — image/video/audio prompting.',
      modelTier: 'flash',
      tools: [],
    ),
  ];
}

// ─── Riverpod Providers ────────────────────────────────────────

final agentRegistryServiceProvider = Provider<AgentRegistryService>((ref) {
  return AgentRegistryService();
});

final agentRegistryInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(agentRegistryServiceProvider);
  await service.seedRegistryFromAssets();
});
