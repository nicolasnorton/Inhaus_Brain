import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/architecture/blackboard.dart';
import 'package:intl/intl.dart';

class FlightRecorderOverlay extends ConsumerWidget {
  const FlightRecorderOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blackboard = ref.watch(blackboardProvider);
    final theme = Theme.of(context);

    // Filter mainly relevant events for the timeline
    final recentEvents = blackboard.events.reversed.take(50).toList();

    return Container(
      width: 350,
      color: Colors.black.withOpacity(0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'FLIGHT RECORDER',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    blackboard.phase.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          
          // Active Agents Monitor
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE AGENTS', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AgentStatusBadge(name: 'Router', status: blackboard.activeAgents['Router'] ?? AgentStatus.idle),
                    _AgentStatusBadge(name: 'Strategist', status: blackboard.activeAgents['Strategist'] ?? AgentStatus.idle),
                    _AgentStatusBadge(name: 'Copywriter', status: blackboard.activeAgents['Copywriter'] ?? AgentStatus.idle),
                    _AgentStatusBadge(name: 'Creative', status: blackboard.activeAgents['Creative'] ?? AgentStatus.idle),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white24),
          
          // Event Timeline
          Expanded(
            child: ListView.builder(
              itemCount: recentEvents.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final event = recentEvents[index];
                return _TimelineItem(event: event);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentStatusBadge extends StatelessWidget {
  final String name;
  final AgentStatus status;

  const _AgentStatusBadge({required this.name, required this.status});

  Color get _statusColor {
    switch (status) {
      case AgentStatus.idle: return Colors.grey;
      case AgentStatus.working: return Colors.green;
      case AgentStatus.blocked: return Colors.amber;
      case AgentStatus.failed: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.2),
        border: Border.all(color: _statusColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final WorkflowEvent event;

  const _TimelineItem({required this.event});

  Color _typeColor(WorkflowEventType type) {
    switch (type) {
      case WorkflowEventType.userRequested: return Colors.blueAccent;
      case WorkflowEventType.taskFinished: return Colors.greenAccent;
      case WorkflowEventType.errorOccurred: return Colors.redAccent;
      case WorkflowEventType.humanFeedbackNeeded: return Colors.orangeAccent;
      case WorkflowEventType.phaseTransition: return Colors.purpleAccent;
      case WorkflowEventType.agentStatusChange: return Colors.tealAccent;
      case WorkflowEventType.agentAction: return Colors.limeAccent;
      case WorkflowEventType.agentFinished: return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm:ss');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _typeColor(event.type),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 1,
                height: 20, // Connector line
                color: Colors.white10,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.type.name.toUpperCase(),
                      style: TextStyle(
                        color: _typeColor(event.type),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateFormat.format(event.timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
