/// EpisodicMemoryListener — Async background save of agent episodes.
///
/// Listens to [AdkEventBus] for [agentCompleted] events and
/// asynchronously persists them to BrainWeave via [ContextAssembler],
/// decoupling episodic memory from the main agent execution path.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../adk/services/adk_event_bus.dart';
import '../architecture/context_assembler.dart';

class EpisodicMemoryListener {
  static final EpisodicMemoryListener _instance = EpisodicMemoryListener._internal();
  factory EpisodicMemoryListener() => _instance;

  StreamSubscription<AdkEvent>? _subscription;
  ProviderContainer? _container;

  EpisodicMemoryListener._internal();

  /// Initialize with a [ProviderContainer] so we can read
  /// [contextAssemblerProvider] outside of a widget tree.
  void init(ProviderContainer container) {
    if (_subscription != null) return;
    _container = container;

    _subscription = AdkEventBus().events.listen((event) {
      if (event.type == AdkEventType.agentCompleted &&
          event.message != null &&
          event.message!.isNotEmpty) {
        _handleAgentCompleted(event);
      }
    });

    debugPrint('EpisodicMemoryListener: Initialized and listening for ADK events.');
  }

  void _handleAgentCompleted(AdkEvent event) {
    if (_container == null) return;

    try {
      final assembler = _container!.read(contextAssemblerProvider);
      assembler
          .saveEpisode(
            agentName: event.source,
            taskSummary: event.metadata['task'] as String? ?? 'Agent execution',
            output: event.message!,
          )
          .catchError((e) {
        debugPrint('EpisodicMemoryListener: Failed to save episode for ${event.source}: $e');
      });
    } catch (e) {
      debugPrint('EpisodicMemoryListener: Provider read failed: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _container = null;
  }
}
