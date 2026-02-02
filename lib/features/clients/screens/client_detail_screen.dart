import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/features/clients/models/client_model.dart';
import 'package:inhaus_brain/features/clients/providers/client_provider.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  final Widget child; // For nested routes (RouterOutlet)

  const ClientDetailScreen({
    super.key,
    required this.clientId,
    required this.child,
  });

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mapping tabs to routes
  final List<String> _tabs = [
    'overview',
    'projects',
    'tasks',
    'integrations',
    'reports'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index < 0 || index >= _tabs.length) return;
    context.go('/clients/${widget.clientId}/${_tabs[index]}');
  }

  // Update tab index based on current location
  void _updateTabIndex() {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.endsWith(_tabs[i])) {
        if (_tabController.index != i) {
          _tabController.animateTo(i);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the provider knows which client is selected, even if navigated directly via URL
    // TODO: This might be side-effecty in build, better in router redirect or init
    // But for now it acts as a safeguard.
    final clientState = ref.watch(clientProvider);
    final client = clientState.clients.firstWhere(
      (c) => c.id == widget.clientId,
      orElse: () => Client(id: 'unknown', name: 'Loading...', industry: ''),
    );
    
    // Defer tab index update to next frame to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTabIndex());

    // If client not found and done loading, maybe redirect?
    if (client.id == 'unknown' && !clientState.isLoading && clientState.clients.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Client not found'),
              ElevatedButton(
                onPressed: () => context.go('/clients'),
                child: const Text('Back to Clients'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/clients'),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: _onTabTapped,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Projects', icon: Icon(Icons.folder_outlined)),
            Tab(text: 'Tasks', icon: Icon(Icons.check_circle_outline)),
            Tab(text: 'Integrations', icon: Icon(Icons.hub_outlined)),
            Tab(text: 'Reports', icon: Icon(Icons.analytics_outlined)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
               // Open Client Settings
            },
          ),
        ],
      ),
      body: widget.child,
    );
  }
}

// Sub-screens placeholders
class ClientOverviewScreen extends StatelessWidget {
  final String clientId;
  const ClientOverviewScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Client Overview: $clientId'));
  }
}

class ClientProjectsScreen extends StatelessWidget {
  final String clientId;
  const ClientProjectsScreen({super.key, required this.clientId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Client Projects'));
  }
}

class ClientTasksScreen extends StatelessWidget {
  final String clientId;
  const ClientTasksScreen({super.key, required this.clientId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Client Tasks'));
  }
}

// ClientIntegrationsScreen will be beefed up later
class ClientIntegrationsScreen extends StatelessWidget {
  final String clientId;
  const ClientIntegrationsScreen({super.key, required this.clientId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Client Integrations Management'));
  }
}

// ClientReportsScreen will be beefed up later
class ClientReportsScreen extends StatelessWidget {
  final String clientId;
  const ClientReportsScreen({super.key, required this.clientId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Client Reports'));
  }
}
