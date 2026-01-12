import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/globals.dart';

/// Registry of tools available to the AI Assistant
class AssistantTools {
  final BuildContext context;

  AssistantTools(this.context);

  /// maps tool names to their execution functions
  Map<String, Function> get tools => {
    'navigate': _navigate,
    'confetti': _throwConfetti,
    'create_campaign': _createCampaign,
    'create_app_from_template': _createAppFromTemplate,
  };

  /// Navigate to a specific route
  void _navigate(Map<String, dynamic> args) {
    final route = args['route'] as String?;
    if (route != null) {
      context.go(route);
    }
  }

  /// Just for fun/demo - show a snackbar or similar
  void _throwConfetti(Map<String, dynamic> args) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('🎉 Confetti! (Imagine it raining down) 🎉')),
    );
  }

  /// Mock creating a campaign
  void _createCampaign(Map<String, dynamic> args) {
     scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Creating campaign: ${args['title'] ?? 'Untitled'}')),
    );
    context.go('/campaigns/create');
  }

  /// Create an app from a template (Mock)
  /// In a real app, this would call the AppsProvider directly to create the app
  void _createAppFromTemplate(Map<String, dynamic> args) {
    // For demo, we just navigate to the create dialog or show success
    // Ideally this would:
    // 1. Get template ID
    // 2. Look up template data
    // 3. Create App object
    // 4. Add to provider
    // 5. Navigate to app detail
    
    // Simulating the action:
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Creating app from template: ${args['template_id']}')),
    );
    // context.go('/app/${newAppId}'); // Mock navigation
  }
}
