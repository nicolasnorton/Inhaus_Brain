import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/features/campaigns/campaign_list_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../proposals/screens/proposals_main_screen.dart';
import '../models/agency_models.dart';

import '../../services/screens/services_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: 'Marketing'),
            Tab(icon: Icon(Icons.description), text: 'Proposals'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Services'),
            Tab(icon: Icon(Icons.people), text: 'CRM'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Reuse existing Campaign List for Marketing
          CampaignListScreen(),
          
          // ProposalsLM Module
          ProposalsMainScreen(),

          // INHAUS Services Catalog
          ServicesScreen(),

          // CRM Tab
          _CrmTab(),
        ],
      ),
    );
  }
}

class _CrmTab extends StatelessWidget {
  const _CrmTab();

  @override
  Widget build(BuildContext context) {
    // Mock Data for CRM
    final leads = [
      SalesLead(
        id: '1',
        name: 'Maria Rodriguez',
        company: 'Café Del Sol',
        email: 'maria@cafedelsol.ec',
        phone: '+593 99 123 4567',
        status: LeadStatus.proposalSent,
        estimatedValue: 15000,
        lastContacted: DateTime.now().subtract(const Duration(days: 2)),
        notes: 'Interested in rebranding and social media.',
      ),
      SalesLead(
        id: '2',
        name: 'Juan Perez',
        company: 'TechSolutions S.A.',
        email: 'juan@techsolutions.ec',
        phone: '+593 98 765 4321',
        status: LeadStatus.newLead,
        estimatedValue: 5000,
        lastContacted: DateTime.now().subtract(const Duration(days: 5)),
        notes: 'Met at networking event. Needs SEO.',
      ),
       SalesLead(
        id: '3',
        name: 'Ana Lopez',
        company: 'Boutique Floral',
        email: 'ana@floral.ec',
        phone: '+593 97 111 2222',
        status: LeadStatus.negotiation,
        estimatedValue: 8500,
        lastContacted: DateTime.now().subtract(const Duration(hours: 4)),
        notes: 'Negotiating contract terms.',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length,
      itemBuilder: (context, index) {
        final lead = leads[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(lead.status).withValues(alpha: 0.2),
              child: Icon(_getStatusIcon(lead.status), color: _getStatusColor(lead.status), size: 18),
            ),
            title: Text(lead.company, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${lead.name} • ${lead.email}'),
                Text('Est. Value: \$${lead.estimatedValue.toStringAsFixed(0)}'),
              ],
            ),
            trailing: _buildStatusChip(context, lead.status),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead: return Colors.blue;
      case LeadStatus.contacted: return Colors.orange;
      case LeadStatus.qualified: return Colors.purple;
      case LeadStatus.proposalSent: return Colors.indigo;
      case LeadStatus.negotiation: return Colors.teal;
      case LeadStatus.closedWon: return Colors.green;
      case LeadStatus.closedLost: return Colors.red;
    }
  }

  IconData _getStatusIcon(LeadStatus status) {
      switch (status) {
      case LeadStatus.newLead: return Icons.star_outline;
      case LeadStatus.contacted: return Icons.phone;
      case LeadStatus.qualified: return Icons.check_circle_outline;
      case LeadStatus.proposalSent: return FontAwesomeIcons.fileContract;
      case LeadStatus.negotiation: return FontAwesomeIcons.handshake;
      case LeadStatus.closedWon: return FontAwesomeIcons.trophy;
      case LeadStatus.closedLost: return FontAwesomeIcons.circleXmark;
    }
  }

  Widget _buildStatusChip(BuildContext context, LeadStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase().replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' '), // Split camelCase
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
