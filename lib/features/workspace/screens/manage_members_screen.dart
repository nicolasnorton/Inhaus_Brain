import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/member_models.dart';
import '../providers/members_provider.dart';

class ManageMembersScreen extends ConsumerStatefulWidget {
  const ManageMembersScreen({super.key});

  @override
  ConsumerState<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
  final TextEditingController _emailController = TextEditingController();
  MemberRole _selectedRole = MemberRole.editor;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invite Team Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'colleague@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...MemberRole.values.where((role) => role != MemberRole.owner).map((role) {
                return RadioListTile<MemberRole>(
                  title: Text(role.displayName),
                  subtitle: Text(role.description, style: const TextStyle(fontSize: 12)),
                  value: role,
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => _selectedRole = value);
                    }
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_emailController.text.isNotEmpty) {
                  ref.read(invitationsProvider.notifier).sendInvite(
                        _emailController.text,
                        _selectedRole,
                      );
                  Navigator.pop(context);
                  _emailController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitation sent')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Invitation'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = ref.watch(membersProvider);
    final invitations = ref.watch(invitationsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(FontAwesomeIcons.users, color: theme.primaryColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team Members',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your workspace collaborators and their permissions',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showInviteDialog,
                  icon: const Icon(FontAwesomeIcons.userPlus, size: 14),
                  label: const Text('Invite Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          // Members List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Workspace Members (${members.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...members.map((member) => _buildMemberTile(theme, member)),
                if (invitations.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Pending Invitations (${invitations.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...invitations.map((invite) => _buildInviteTile(theme, invite)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(ThemeData theme, Member member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
          child: Text(
            member.name.substring(0, 1),
            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(member.email, style: const TextStyle(fontSize: 12, color: Colors.white60)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleBadge(theme, member.role),
            const SizedBox(width: 16),
            if (member.role != MemberRole.owner)
              PopupMenuButton<MemberRole>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (role) {
                  ref.read(membersProvider.notifier).updateMemberRole(member.id, role);
                },
                itemBuilder: (context) => MemberRole.values
                    .where((r) => r != MemberRole.owner)
                    .map((role) => PopupMenuItem(
                          value: role,
                          child: Text('Change to ${role.displayName}'),
                        ))
                    .toList()
                  ..add(
                    PopupMenuItem(
                      child: const Text('Remove Member', style: TextStyle(color: Colors.red)),
                      onTap: () => ref.read(membersProvider.notifier).removeMember(member.id),
                    ),
                  ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteTile(ThemeData theme, WorkspaceInvite invite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          child: const Icon(Icons.mail_outline, color: Colors.white60),
        ),
        title: Text(invite.email, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Invited as ${invite.role.displayName}', style: const TextStyle(fontSize: 12, color: Colors.white38)),
        trailing: TextButton(
          onPressed: () => ref.read(invitationsProvider.notifier).cancelInvite(invite.id),
          child: const Text('Cancel Request', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(ThemeData theme, MemberRole role) {
    Color color;
    switch (role) {
      case MemberRole.owner:
        color = Colors.amber;
        break;
      case MemberRole.admin:
        color = Colors.redAccent;
        break;
      case MemberRole.editor:
        color = Colors.blueAccent;
        break;
      case MemberRole.viewer:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.displayName.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
