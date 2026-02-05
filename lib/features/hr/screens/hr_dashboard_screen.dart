import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/core/theme/app_theme.dart';
import '../providers/hr_provider.dart';
import '../services/hr_service.dart';

class HRDashboardScreen extends ConsumerStatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  ConsumerState<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends ConsumerState<HRDashboardScreen> with SingleTickerProviderStateMixin {
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

    final employees = ref.read(hrEmployeesProvider);

    setState(() {
      _chatMessages.add({'role': 'user', 'content': query});
      _chatController.clear();
      _isChatLoading = true;
      _chatMessages.add({'role': 'ai', 'content': ''});
    });

    try {
      final stream = HRService.chatWithHRAgent(employees, query, ref);
      
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
        title: const Text("Human Resources"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Team"),
            Tab(icon: Icon(FontAwesomeIcons.userTie), text: "HR Director"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamTab(),
          _buildChatTab(),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
     final employees = ref.watch(hrEmployeesProvider);
     
     return ListView.builder(
       padding: const EdgeInsets.all(16),
       itemCount: employees.length,
       itemBuilder: (context, index) {
         final e = employees[index];
         return Card(
           margin: const EdgeInsets.only(bottom: 12),
           child: ListTile(
             leading: CircleAvatar(
               backgroundColor: AppTheme.primary.withOpacity(0.2),
               child: Text(e.fullName.substring(0,1), style: const TextStyle(color: AppTheme.primary)),
             ),
             title: Text(e.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
             subtitle: Text("${e.role} • ${e.department.name.toUpperCase()}"),
             trailing: Chip(
               label: Text(e.status.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
               backgroundColor: e.status.name == 'probation' ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.1),
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
                     Icon(FontAwesomeIcons.userTie, size: 64, color: AppTheme.primary.withOpacity(0.3)),
                     const SizedBox(height: 24),
                     const Text(
                       "HR Director Agent", 
                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70)
                     ),
                     const SizedBox(height: 8),
                     const Text(
                       "Ask about contracts, Ecuador labor law, or soft skills.",
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
                     hintText: "Draft a memo for holiday schedule...",
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
