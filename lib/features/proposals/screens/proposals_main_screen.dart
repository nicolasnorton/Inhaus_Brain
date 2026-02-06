import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/proposal_model.dart';
import '../providers/proposals_provider.dart';
import '../../clients/providers/client_provider.dart';
import '../../clients/models/client_model.dart';

class ProposalsMainScreen extends ConsumerStatefulWidget {
  const ProposalsMainScreen({super.key});

  @override
  ConsumerState<ProposalsMainScreen> createState() => _ProposalsMainScreenState();
}

class _ProposalsMainScreenState extends ConsumerState<ProposalsMainScreen> {
  void _showNewProposalDialog(BuildContext context, Client? selectedClient) {
    if (selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a client first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("New Proposal", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Proposal Title",
            labelStyle: TextStyle(color: Colors.white70),
            hintText: "e.g., Social Media Package Q1 2026",
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final proposal = Proposal.create(
                title: title,
                clientId: selectedClient.id,
                clientName: selectedClient.name,
              );

              await ref.read(proposalsServiceProvider).createProposal(proposal);
              
                context.go('/agency/sales/proposals/${proposal.id}');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final selectedClient = ref.watch(selectedClientProvider);
    final proposalsAsync = ref.watch(allProposalsProvider);

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: isMobile
            ? const Text("Proposals", style: TextStyle(color: Colors.white, fontSize: 16))
            : Row(
                children: [
                  const Text("Proposals", style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(width: 24),
                  if (clientState.clients.isNotEmpty)
                    _buildClientSelector(selectedClient, clientState),
                ],
              ),
        backgroundColor: AppTheme.surface,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(isMobile ? "New" : "New Proposal", style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => _showNewProposalDialog(context, selectedClient),
            ),
          ),
        ],
      ),
      body: selectedClient == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text("No Client Selected", style: TextStyle(color: Colors.white54, fontSize: 20)),
                  const SizedBox(height: 8),
                  const Text(
                    "Please select a client from the top bar to view proposals.",
                    style: TextStyle(color: Colors.white24),
                  ),
                ],
              ),
            )
          : proposalsAsync.when(
              data: (proposals) {
                final clientProposals = proposals.where((p) => p.clientId == selectedClient.id).toList();
                
                if (clientProposals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text("No Proposals Yet", style: TextStyle(color: Colors.white54, fontSize: 20)),
                        const SizedBox(height: 8),
                        const Text(
                          "Create your first proposal for this client.",
                          style: TextStyle(color: Colors.white24),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("New Proposal"),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                          onPressed: () => _showNewProposalDialog(context, selectedClient),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: clientProposals.length,
                  itemBuilder: (context, index) {
                    final proposal = clientProposals[index];
                    return _buildProposalCard(context, proposal);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text("Error loading proposals: $error", style: const TextStyle(color: Colors.red)),
              ),
            ),
    );
  }

  Widget _buildProposalCard(BuildContext context, Proposal proposal) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/agency/sales/proposals/${proposal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proposal.clientName,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Updated ${_formatDate(proposal.updatedAt)}",
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildStatusBadge(proposal.status),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ProposalStatus status) {
    Color color;
    switch (status) {
      case ProposalStatus.draft:
        color = Colors.grey;
        break;
      case ProposalStatus.generated:
        color = Colors.blue;
        break;
      case ProposalStatus.sent:
        color = Colors.orange;
        break;
      case ProposalStatus.accepted:
        color = Colors.green;
        break;
      case ProposalStatus.rejected:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildClientSelector(Client? selectedClient, dynamic clientState, {bool isFullWidth = false}) {
    return DropdownButton<String>(
      value: selectedClient?.id,
      hint: const Text('Select Client', style: TextStyle(color: Colors.white70)),
      dropdownColor: AppTheme.surface,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      underline: isFullWidth ? const SizedBox.shrink() : Container(height: 1, color: Colors.white24),
      isExpanded: isFullWidth,
      onChanged: (String? newValue) {
        if (newValue != null) {
          ref.read(clientProvider.notifier).selectClient(newValue);
        }
      },
      items: clientState.clients.map<DropdownMenuItem<String>>((Client client) {
        return DropdownMenuItem<String>(
          value: client.id,
          child: Text(client.name),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return "today";
    } else if (diff.inDays == 1) {
      return "yesterday";
    } else if (diff.inDays < 7) {
      return "${diff.inDays} days ago";
    } else {
      return "${date.month}/${date.day}/${date.year}";
    }
  }
}
