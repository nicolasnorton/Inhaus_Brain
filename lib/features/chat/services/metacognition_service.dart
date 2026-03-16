import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/adk/services/adk_service.dart';
import '../agents/tools/brainweave_tools.dart';

/// The Metacognition Layer
/// 
/// Listens to the global ADK Event Bus for agent activities and automatically 
/// writes significant insights back to the knowledge graph via CreateAtomicNodeTool.
/// This fulfills the "Shared Mind" architecture principle asynchronously.
class MetacognitionService {
  final Ref _ref;
  
  MetacognitionService(this._ref) {
    debugPrint('🧠 Metacognition Layer Activated. Listening to AI Events...');
    _initListener();
  }

  void _initListener() {
    AdkEventBus().events.listen((event) {
      if (event.type == AdkEventType.agentCompleted && event.message != null && event.message!.length > 100) {
         _ingestAgentOutput(event.source, event.message!);
      }
      
      if (event.type == AdkEventType.toolCompleted && event.message != null) {
          // Future: we can ingest tool payloads too
      }
    });
  }

  Future<void> _ingestAgentOutput(String agentName, String content) async {
    try {
      final createTool = CreateAtomicNodeTool();
      await createTool.execute({
        'title': 'Insight: $agentName',
        'description': 'Metacognitive auto-ingestion from $agentName output',
        'content': content.length > 2000 ? content.substring(0, 2000) : content,
        'type': 'insight',
        'topics': ['metacognition', 'agent_output', agentName.toLowerCase().replaceAll(' ', '_')],
      }, ref: _ref);
      debugPrint('🧠 Metacognition: Ingested output from $agentName');
    } catch (e) {
      debugPrint('🧠 Metacognition: Auto-ingestion failed silently: $e');
    }
  }
}

final metacognitionServiceProvider = Provider<MetacognitionService>((ref) {
  return MetacognitionService(ref);
});

final metacognitionInitProvider = Provider<void>((ref) {
  // Call to initialize eagerly
  ref.watch(metacognitionServiceProvider);
});
