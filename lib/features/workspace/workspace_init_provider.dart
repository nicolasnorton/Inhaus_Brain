import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/workspace_service.dart';
import 'services/agent_registry_service.dart';

/// Top-level provider that initializes the Inhaus Brain workspace on app start.
/// Seeds workspace docs + agent registry from assets on first load.
final workspaceInitProvider = FutureProvider<void>((ref) async {
  try {
    // 1. Initialize workspace (identity, soul, etc.)
    final workspaceService = ref.read(workspaceServiceProvider);
    await workspaceService.initializeWorkspace();
    debugPrint('WorkspaceInit: Workspace initialized.');

    // 2. Seed agent registry
    final registryService = ref.read(agentRegistryServiceProvider);
    await registryService.seedRegistryFromAssets();
    debugPrint('WorkspaceInit: Agent registry seeded.');
  } catch (e) {
    debugPrint('WorkspaceInit: Error during initialization: $e');
    // Non-fatal — app can still function with static assets
  }
});
