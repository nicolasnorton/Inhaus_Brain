import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/features/clients/models/client_model.dart';
import 'package:inhaus_brain/features/clients/providers/client_provider.dart';
import 'client_projects_screen.dart';
import 'client_tasks_screen.dart';
import 'client_integrations_screen.dart';
import 'client_reports_screen.dart';

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
               context.go('/clients/${widget.clientId}/edit');
            },
          ),
        ],
      ),
      body: widget.child,
    );
  }
}

// Sub-screens placeholders
class ClientOverviewScreen extends ConsumerWidget {
  final String clientId;
  const ClientOverviewScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientState = ref.watch(clientProvider);
    final client = clientState.clients.firstWhere((c) => c.id == clientId, orElse: () => Client(id: 'err', name: 'Err', industry: ''));
    
    if (client.id == 'err') {
       return const Center(child: Text('Client not found'));
    }

    final isCorporate = client.clientType == ClientType.corporate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, client, isCorporate),
          const SizedBox(height: 32),
          _buildInfoSection(context, 'Legal & Fiscal', [
             if (isCorporate) ...[
                _InfoItem('Legal Name', client.legalName),
                _InfoItem('Tax ID', client.taxId),
                _InfoItem('Fiscal Address', client.fiscalAddress),
                _InfoItem('Company Size', client.size),
             ] else ...[
                _InfoItem('Profession', client.profession),
                _InfoItem('Personal Tax ID', client.personalTaxId),
                _InfoItem('Birth Date', client.birthDate?.toIso8601String().split('T').first),
             ]
          ]),
          const SizedBox(height: 24),
          _buildInfoSection(context, 'Contact & Profile', [
             _InfoItem('Primary Email', client.primaryContactEmail),
             if (isCorporate) ...[
                _InfoItem('Website', client.website),
                _InfoItem('Address', client.address),
             ] else ...[
                _InfoItem('Portfolio', client.portfolioUrl),
                _InfoItem('LinkedIn', client.linkedinUrl),
             ]
          ]),
           const SizedBox(height: 24),
           if (client.description != null && client.description!.isNotEmpty)
            _buildInfoSection(context, 'Notes', [_InfoItem(null, client.description)]),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Client client, bool isCorporate) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: FaIcon(
            isCorporate ? FontAwesomeIcons.building : FontAwesomeIcons.userTie,
            size: 40,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.name, 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 4),
              Text(
                client.industry,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
             color: Theme.of(context).cardColor,
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String? label;
  final String? value;
  const _InfoItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           if (label != null)
            Text(label!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
           if (label != null) const SizedBox(height: 4),
           Text(value!, style: const TextStyle(color: Colors.white, fontSize: 16)),
         ],
      ),
    );
  }
}

// End of file
