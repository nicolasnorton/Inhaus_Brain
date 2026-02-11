import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/models/user_model.dart';
import 'auth_service.dart';

enum AppPermission {
  // Campaigns
  campaignCreate,
  campaignEdit,
  campaignDelete,
  campaignPublish,
  
  // Projects/Clients
  clientManage,
  clientView,
  
  // AI & Agents
  agentExecute,
  agentConfigure,
  
  // Finance
  financeView,
  financeManage,
  
  // Admin
  userManage,
  systemSettings,
  auditLogsView,
}

/// Permission Manager (Inhaus Brain v2.0 Production)
/// 
/// Provides a centralized, role-based access control (RBAC) check.
class PermissionManager {
  final Ref _ref;

  PermissionManager(this._ref);

  /// Check if the current user has a specific permission
  bool hasPermission(AppPermission permission) {
    final user = _ref.watch(appUserProvider).value;
    if (user == null) return false;

    // Super Admin has all permissions
    if (user.role == UserRole.superAdmin) return true;

    switch (permission) {
      case AppPermission.campaignCreate:
      case AppPermission.campaignEdit:
        return [
          UserRole.admin,
          UserRole.accountManager,
          UserRole.designer,
          UserRole.socialMediaManager,
          UserRole.adManager,
          UserRole.humanAgencyStaff
        ].contains(user.role);

      case AppPermission.campaignDelete:
      case AppPermission.campaignPublish:
        return [
          UserRole.admin,
          UserRole.accountManager,
          UserRole.adManager
        ].contains(user.role);

      case AppPermission.clientManage:
        return [UserRole.admin, UserRole.accountManager].contains(user.role);

      case AppPermission.clientView:
        return true; // All roles can view assigned clients

      case AppPermission.agentExecute:
        return true; // All roles can use agents for now

      case AppPermission.agentConfigure:
        return [UserRole.admin, UserRole.accountManager].contains(user.role);

      case AppPermission.financeView:
      case AppPermission.financeManage:
        return [UserRole.admin, UserRole.accountManager].contains(user.role);

      case AppPermission.userManage:
      case AppPermission.systemSettings:
      case AppPermission.auditLogsView:
        return user.role == UserRole.admin;
    }
  }

  /// Check if the user is authorized for a specific resource
  bool canAccessResource(String clientId) {
    final user = _ref.watch(appUserProvider).value;
    if (user == null) return false;
    
    // Internal staff and admins see everything
    if ([UserRole.superAdmin, UserRole.admin, UserRole.humanAgencyStaff].contains(user.role)) {
      return true;
    }
    
    // Clients only see their own assigned data
    return user.assignedClientIds.contains(clientId);
  }
}

final permissionManagerProvider = Provider<PermissionManager>((ref) {
  return PermissionManager(ref);
});
