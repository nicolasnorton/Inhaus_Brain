import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/proposal_model.dart';
import '../providers/proposals_provider.dart';
import '../../clients/providers/client_provider.dart';
import '../../clients/models/client_model.dart';
import '../../agency/models/agency_service_model.dart';
import '../../agency/providers/service_catalog_riverpod_provider.dart';

class ProposalsMainScreen extends ConsumerStatefulWidget {
  const ProposalsMainScreen({super.key});

  @override
  ConsumerState<ProposalsMainScreen> createState() => _ProposalsMainScreenState();
}

class _ProposalsMainScreenState extends ConsumerState<ProposalsMainScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    List<String> localSelectedServiceIds = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final servicesAsync = ref.watch(servicesListProvider);

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text("New Proposal", style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Proposal Title",
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: "e.g., Social Media Package Q1 2026",
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "SELECT SERVICES",
                      style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    servicesAsync.when(
                      data: (services) {
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: services.length,
                            itemBuilder: (context, index) {
                              final service = services[index];
                              final isSelected = localSelectedServiceIds.contains(service.id);
                              return CheckboxListTile(
                                title: Text(service.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                subtitle: Text("\$${service.basePrice.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                value: isSelected,
                                activeColor: AppTheme.primary,
                                checkColor: Colors.white,
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == true) {
                                      localSelectedServiceIds.add(service.id);
                                    } else {
                                      localSelectedServiceIds.remove(service.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text("Error loading services: $err", style: const TextStyle(color: Colors.red)),
                    ),
                  ],
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
                      serviceIds: localSelectedServiceIds,
                    );

                    await ref.read(proposalsServiceProvider).createProposal(proposal);
                    
                    if (mounted) {
                      Navigator.pop(context);
                      context.go('/agency/sales/proposals/${proposal.id}');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final selectedClient = ref.watch(selectedClientProvider);
    final proposalsAsync = ref.watch(allProposalsProvider);

    final isMobile = MediaQuery.of(context).size.width < 700;

    // Filter clients based on search query
    final filteredClients = clientState.clients.where((client) {
      final nameMatches = client.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final industryMatches = client.industry.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || industryMatches;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: isMobile
            ? const Text("Proposals", style: TextStyle(color: Colors.white, fontSize: 16))
            : Row(
                children: [
                   IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: selectedClient != null 
                      ? () => ref.read(clientProvider.notifier).selectClient(null)
                      : null,
                  ),
                  const Text("Proposals", style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildClientSearchBar(),
                  ),
                ],
              ),
        backgroundColor: AppTheme.surface,
        centerTitle: false,
        actions: [
          if (selectedClient != null)
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
      body: selectedClient == null || _searchQuery.isNotEmpty
          ? _buildClientCardsGrid(filteredClients, selectedClient)
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

  Widget _buildClientSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search clients by name or industry...",
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 18),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white24, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildClientCardsGrid(List<Client> filteredClients, Client? selectedClient) {
    if (filteredClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? "No Clients Found" : "No results for \"$_searchQuery\"",
              style: const TextStyle(color: Colors.white54, fontSize: 20),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 2.2,
      ),
      itemCount: filteredClients.length,
      itemBuilder: (context, index) {
        final client = filteredClients[index];
        return _buildClientCard(client, client.id == selectedClient?.id);
      },
    );
  }

  Widget _buildClientCard(Client client, bool isSelected) {
    return Card(
      color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          ref.read(clientProvider.notifier).selectClient(client.id);
          _searchController.clear();
          setState(() => _searchQuery = '');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    child: Text(client.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          client.industry,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Last Proposal",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                      ),
                      const Text(
                        "Today", // Mock for now, will connect to real data later
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _showNewProposalDialog(context, client),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text("New Proposal", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
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
