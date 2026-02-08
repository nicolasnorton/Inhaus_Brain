
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agency_models.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/sales_chat_provider.dart';
import '../services/sales_service.dart';

class LeadDetailScreen extends ConsumerWidget {
  final SalesLead lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lead.company),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified, color: Colors.green),
            tooltip: 'Convert to Client',
            onPressed: () => _confirmConversion(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit Lead
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  child: Text(lead.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.name, style: Theme.of(context).textTheme.titleLarge),
                      Text(lead.email, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                       Chip(
                        label: Text(lead.status.toString().split('.').last.toUpperCase()),
                        backgroundColor: Colors.indigo.withOpacity(0.1),
                        labelStyle: const TextStyle(fontSize: 10, color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Tabs (Activity vs Chat)
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: "Details & Notes"),
                      Tab(text: "Agent Chat"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDetailsTab(context, lead),
                        _buildChatTab(context, ref),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context, SalesLead lead) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader("Contact Info"),
        ListTile(
          leading: const Icon(Icons.phone),
          title: Text(lead.phone.isNotEmpty ? lead.phone : "No phone"),
        ),
        ListTile(
          leading: const Icon(Icons.email),
          title: Text(lead.email),
        ),
        
        const SizedBox(height: 24),
        _buildSectionHeader("Notes"),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(lead.notes.isNotEmpty ? lead.notes : "No notes available."),
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab(BuildContext context, WidgetRef ref) {
    // 1. Watch the specific chat state for this lead
    final chatState = ref.watch(salesChatProvider(lead.id));
    final chatNotifier = ref.read(salesChatProvider(lead.id).notifier);
    final textController = TextEditingController();

    return Column(
      children: [
        // Message List
        Expanded(
          child: chatState.messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.robot, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("Start a conversation about ${lead.company}", style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatState.messages[index];
                    return Align(
                      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: msg.isUser ? Colors.indigo : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          msg.text,
                          style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Loading Indicator
        if (chatState.isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          ),

        // Error Message
        if (chatState.error != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(chatState.error!, style: const TextStyle(color: Colors.red)),
          ),

        // Input Area
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: "Ask agent to research or update GHL...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      chatNotifier.sendMessage(val, lead);
                      textController.clear();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.indigo),
                onPressed: () {
                  if (textController.text.trim().isNotEmpty) {
                    chatNotifier.sendMessage(textController.text, lead);
                    textController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmConversion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Client?'),
        content: Text('This will create a new Client record for "${lead.company}", mark this lead as Won, and update GHL.\n\nProceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Converting lead...')));
      
      try {
        // Need to import salesServiceProvider
        await ref.read(salesServiceProvider).convertLeadToClient(lead);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Success! Lead converted to Client.')));
          Navigator.pop(context); // Go back to list
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
