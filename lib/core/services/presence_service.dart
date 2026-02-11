import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presence State for Real-time Collaboration
class UserPresence {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final Color cursorColor;
  final DateTime lastSeen;
  final String? currentLocation; // e.g., "canvas:abc123" or "chat"

  UserPresence({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.cursorColor,
    required this.lastSeen,
    this.currentLocation,
  });

  bool get isActive => DateTime.now().difference(lastSeen).inSeconds < 30;
}

/// Presence Service (InhausBrain v2.0)
/// 
/// Manages real-time user presence using Firestore Realtime Database.
class PresenceService {
  final Ref _ref;

  PresenceService(this._ref);

  // In production, this would connect to Firebase Realtime Database
  // and update the user's presence heartbeat every 15 seconds.
  
  Future<void> updatePresence({
    required String userId,
    required String location,
  }) async {
    // TODO: Implement Firebase Realtime DB presence
    debugPrint('Presence: User $userId is at $location');
  }

  Stream<List<UserPresence>> watchPresence(String resourceId) {
    // TODO: Stream active users from Realtime DB
    return Stream.value([]);
  }
}

final presenceServiceProvider = Provider<PresenceService>((ref) => PresenceService(ref));

/// Presence Indicator Widget
class PresenceIndicator extends ConsumerWidget {
  final String resourceId;

  const PresenceIndicator({super.key, required this.resourceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = ref.watch(presenceStreamProvider(resourceId));

    return presence.when(
      data: (users) {
        if (users.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline, size: 14, color: Colors.white54),
              const SizedBox(width: 8),
              ...users.take(3).map((u) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: u.cursorColor,
                  backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                  child: u.avatarUrl == null ? Text(u.displayName[0], style: const TextStyle(fontSize: 8)) : null,
                ),
              )),
              if (users.length > 3)
                Text('+${users.length - 3}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

final presenceStreamProvider = StreamProvider.family<List<UserPresence>, String>((ref, resourceId) {
  return ref.watch(presenceServiceProvider).watchPresence(resourceId);
});
