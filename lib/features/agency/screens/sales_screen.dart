import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/features/campaigns/campaign_list_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../proposals/screens/proposals_main_screen.dart';
import '../models/agency_models.dart';

import '../../services/screens/services_screen.dart';
import '../services/sales_service.dart';
import 'lead_detail_screen.dart';

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

class _CrmTab extends ConsumerWidget {
  const _CrmTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesService = ref.watch(salesServiceProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLeadDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<SalesLead>>(
        stream: salesService.getLeads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final leads = snapshot.data ?? [];
          if (leads.isEmpty) {
            return const Center(child: Text('No leads found. Add one to sync with GHL!'));
          }

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
                    backgroundColor: _getStatusColor(lead.status).withOpacity(0.2),
                    child: Icon(_getStatusIcon(lead.status), color: _getStatusColor(lead.status), size: 18),
                  ),
                  title: Text(lead.company, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${lead.name} • ${lead.email}'),
                      if (lead.estimatedValue > 0)
                        Text('Est. Value: \$${lead.estimatedValue.toStringAsFixed(0)}'),
                    ],
                  ),
                  trailing: _buildStatusChip(context, lead.status),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddLeadDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final companyController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add GHL Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final lead = SalesLead(
                id: '', // Will be assigned by GHL/Firestore
                name: nameController.text,
                company: companyController.text,
                email: emailController.text,
                phone: phoneController.text,
                status: LeadStatus.newLead,
                estimatedValue: 0,
                lastContacted: DateTime.now(),
                notes: '',
              );
              ref.read(salesServiceProvider).createLead(lead);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Creating contact in GHL... Sync may take a moment.')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
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
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
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
