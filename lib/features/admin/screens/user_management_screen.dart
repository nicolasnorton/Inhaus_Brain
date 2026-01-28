import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';
import '../services/audit_service.dart';
import '../../auth/models/user_model.dart';

final allUsersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) {
  return ref.read(authServiceProvider).getAllUsers();
});

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFF0F1116),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filteredUsers = users.where((u) {
                  final matchesSearch = u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (u.displayName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                  final matchesRole = _selectedRole == null || u.role == _selectedRole;
                  return matchesSearch && matchesRole;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No users found.', style: TextStyle(color: Colors.white54)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _UserTile(user: user, onRoleChanged: () => ref.invalidate(allUsersProvider));
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search users...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Roles'),
                  selected: _selectedRole == null,
                  onSelected: (_) => setState(() => _selectedRole = null),
                ),
                ...UserRole.values.map((role) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(role.name.toUpperCase()),
                    selected: _selectedRole == role,
                    onSelected: (selected) => setState(() => _selectedRole = selected ? role : null),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final AppUser user;
  final VoidCallback onRoleChanged;

  const _UserTile({required this.user, required this.onRoleChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent.withOpacity(0.1),
        child: Text(user.email[0].toUpperCase(), style: const TextStyle(color: Colors.blueAccent)),
      ),
      title: Text(user.displayName ?? 'No Name', style: const TextStyle(color: Colors.white)),
      subtitle: Text(user.email, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(user.role.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
            backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
            side: BorderSide(color: _getRoleColor(user.role).withOpacity(0.3)),
            labelStyle: TextStyle(color: _getRoleColor(user.role)),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white54),
            onPressed: () => _showRoleDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin: return Colors.redAccent;
      case UserRole.admin: return Colors.orangeAccent;
      default: return Colors.blueAccent;
    }
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text('Change User Role', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) => ListTile(
            title: Text(role.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).updateUserRole(user.id, role);
              
              // Log to Audit Logs
              await ref.read(auditServiceProvider).logAction(
                action: 'UPDATE_USER_ROLE',
                resourceId: user.id,
                resourceType: 'USER',
                metadata: {
                  'email': user.email,
                  'new_role': role.name,
                  'old_role': user.role.name,
                },
              );

              onRoleChanged();
            },
          )).toList(),
        ),
      ),
    );
  }
}
