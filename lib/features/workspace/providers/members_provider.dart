import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member_models.dart';

/// Provider for workspace members
final membersProvider = StateNotifierProvider<MembersNotifier, List<Member>>((ref) {
  return MembersNotifier();
});

/// Provider for workspace invitations
final invitationsProvider = StateNotifierProvider<InvitationsNotifier, List<WorkspaceInvite>>((ref) {
  return InvitationsNotifier();
});

/// State notifier for members
class MembersNotifier extends StateNotifier<List<Member>> {
  MembersNotifier() : super(_getMockMembers());

  void addMember(Member member) {
    state = [...state, member];
  }

  void updateMemberRole(String memberId, MemberRole role) {
    state = state.map((m) {
      if (m.id == memberId) {
        return m.copyWith(role: role);
      }
      return m;
    }).toList();
  }

  void removeMember(String memberId) {
    state = state.where((m) => m.id != memberId).toList();
  }
}

/// State notifier for invitations
class InvitationsNotifier extends StateNotifier<List<WorkspaceInvite>> {
  InvitationsNotifier() : super([]);

  void sendInvite(String email, MemberRole role) {
    final invite = WorkspaceInvite(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      role: role,
      sentAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    state = [...state, invite];
  }

  void cancelInvite(String id) {
    state = state.where((i) => i.id != id).toList();
  }
}

/// Mock members for development
List<Member> _getMockMembers() {
  return [
    Member(
      id: 'm1',
      name: 'John Doe',
      email: 'john@example.com',
      role: MemberRole.owner,
      joinedAt: DateTime.now().subtract(const Duration(days: 365)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Member(
      id: 'm2',
      name: 'Jane Smith',
      email: 'jane@example.com',
      role: MemberRole.admin,
      joinedAt: DateTime.now().subtract(const Duration(days: 180)),
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Member(
      id: 'm3',
      name: 'Bob Wilson',
      email: 'bob@example.com',
      role: MemberRole.editor,
      joinedAt: DateTime.now().subtract(const Duration(days: 30)),
      lastActive: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Member(
      id: 'm4',
      name: 'Alice Brown',
      email: 'alice@example.com',
      role: MemberRole.viewer,
      joinedAt: DateTime.now().subtract(const Duration(days: 7)),
      lastActive: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];
}
