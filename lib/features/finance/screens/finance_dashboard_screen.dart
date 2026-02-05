import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/core/theme/app_theme.dart';
import '../providers/finance_provider.dart';
import '../services/finance_service.dart';

class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends ConsumerState<FinanceDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleChatSubmit() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    final transactions = ref.read(financeTransactionsProvider);

    setState(() {
      _chatMessages.add({'role': 'user', 'content': query});
      _chatController.clear();
      _isChatLoading = true;
      _chatMessages.add({'role': 'ai', 'content': ''});
    });

    try {
      final stream = FinanceService.chatWithFinanceAgent(transactions, query, ref);
      
      await for (final chunk in stream) {
        if (!mounted) break;
        setState(() {
          final lastIdx = _chatMessages.length - 1;
          _chatMessages[lastIdx]['content'] = _chatMessages[lastIdx]['content']! + chunk;
        });
      }
    } catch (e) {
      if (mounted) {
         setState(() {
           final lastIdx = _chatMessages.length - 1;
           _chatMessages[lastIdx]['content'] = "Error: \$e";
         });
      }
    } finally {
      if (mounted) setState(() => _isChatLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finance Director"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Dashboard"),
            Tab(icon: Icon(FontAwesomeIcons.robot), text: "CFO Agent"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildChatTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
     final snapshot = ref.watch(financeSnapshotProvider);
     
     return SingleChildScrollView(
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           // KPIs
           Row(
             children: [
               Expanded(child: _buildKpiCard("Revenue", "\$${snapshot.totalRevenue.toStringAsFixed(0)}", Colors.green)),
               const SizedBox(width: 16),
               Expanded(child: _buildKpiCard("Expenses", "\$${snapshot.totalExpenses.toStringAsFixed(0)}", Colors.redAccent)),
             ],
           ),
           const SizedBox(height: 16),
           Row(
             children: [
               Expanded(child: _buildKpiCard("Net Profit", "\$${snapshot.netProfit.toStringAsFixed(0)}", 
                 snapshot.netProfit >= 0 ? Colors.greenAccent : Colors.orangeAccent)),
               const SizedBox(width: 16),
               Expanded(child: _buildKpiCard("Est. Taxes (SRI)", "\$${snapshot.estimatedTaxLiability.toStringAsFixed(0)}", Colors.blueGrey)),
             ],
           ),
           
           const SizedBox(height: 32),
           const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
           const SizedBox(height: 16),
           _buildTransactionList(),
         ],
       ),
     );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = ref.watch(financeTransactionsProvider);
    // Show last 10
    final recent = List.from(transactions.reversed).take(10).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final tx = recent[index];
        return Card(
           margin: const EdgeInsets.only(bottom: 8),
           child: ListTile(
             leading: CircleAvatar(
               backgroundColor: tx.type.name == 'income' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
               child: Icon(
                 tx.type.name == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                 color: tx.type.name == 'income' ? Colors.green : Colors.red,
                 size: 16,
               ),
             ),
             title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
             subtitle: Text(tx.category?.name.replaceAll('_', ' ').toUpperCase() ?? 'UNCATEGORIZED'),
             trailing: Text(
               "\$${tx.amount.toStringAsFixed(2)}", 
               style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
             ),
           ),
        );
      },
    );
  }

  Widget _buildChatTab() {
    return Column(
       children: [
         Expanded(
           child: _chatMessages.isEmpty
             ? Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(FontAwesomeIcons.robot, size: 64, color: AppTheme.primary.withOpacity(0.3)),
                     const SizedBox(height: 24),
                     const Text(
                       "Ecuadorian Finance Expert", 
                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70)
                     ),
                     const SizedBox(height: 8),
                     const Text(
                       "Ask about SRI taxes, burn rate, or ad spend efficiency.",
                       style: TextStyle(color: Colors.white30),
                     ),
                   ],
                 ),
               )
             : ListView.builder(
                 padding: const EdgeInsets.all(16),
                 itemCount: _chatMessages.length,
                 itemBuilder: (_, index) {
                   final msg = _chatMessages[index];
                   final isUser = msg['role'] == 'user';
                   return _buildMessageBubble(msg['content']!, isUser);
                 },
               ),
         ),
         Container(
           padding: const EdgeInsets.all(16),
           decoration: const BoxDecoration(
             color: AppTheme.surface,
             border: Border(top: BorderSide(color: Colors.white10)),
           ),
           child: Row(
             children: [
               Expanded(
                 child: TextField(
                   controller: _chatController,
                   onSubmitted: (_) => _handleChatSubmit(),
                   style: const TextStyle(color: Colors.white),
                   decoration: InputDecoration(
                     hintText: "Review our Q1 ad spend...",
                     hintStyle: const TextStyle(color: Colors.white30),
                     filled: true,
                     fillColor: AppTheme.background,
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                   ),
                 ),
               ),
               const SizedBox(width: 8),
               IconButton(
                 onPressed: _isChatLoading ? null : _handleChatSubmit,
                 icon: _isChatLoading 
                   ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                   : const Icon(Icons.send, color: AppTheme.primary),
               ),
             ],
           ),
         ),
       ],
     );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isUser ? AppTheme.primary.withOpacity(0.5) : Colors.white10),
        ),
        constraints: const BoxConstraints(maxWidth: 600),
        child: SelectableText(
           content,
           style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
