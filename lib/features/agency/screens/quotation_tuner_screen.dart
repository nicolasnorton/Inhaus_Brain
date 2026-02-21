import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inhaus_proposal_models.dart';
import '../../proposals/services/proposals_lm_service.dart';

class QuotationTunerScreen extends ConsumerStatefulWidget {
  const QuotationTunerScreen({super.key});

  @override
  ConsumerState<QuotationTunerScreen> createState() => _QuotationTunerScreenState();
}

class _QuotationTunerScreenState extends ConsumerState<QuotationTunerScreen> {
  final TextEditingController _rawTextController = TextEditingController();
  bool _isParsing = false;
  List<InhausLineItem> _parsedItems = [];

  @override
  void dispose() {
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _parseText() async {
    if (_rawTextController.text.trim().isEmpty) return;

    setState(() {
      _isParsing = true;
    });

    try {
      final items = await ProposalsLMService.parseUnstructuredQuote(_rawTextController.text);
      if (mounted) {
        setState(() {
          _parsedItems = items;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote parsed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing quote: \$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isParsing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('El Tuneador (Quotation Tuner)'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _isParsing ? null : _parseText,
              icon: _isParsing 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Parse Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0055),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Raw Input Panel
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RAW INPUT', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Paste text or drop a file here to automatically extract quote items.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TextField(
                        controller: _rawTextController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: 'e.g. "We need 3 social media posts per week and a brand refresh for \$1500..."',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right: Structured Output Panel
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STRUCTURED OUTPUT', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Parsed services, pricing, and cadence will appear here.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _parsedItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.list_alt, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                const Text('No data parsed yet', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _parsedItems.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = _parsedItems[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  child: Icon(Icons.check, color: Theme.of(context).primaryColor, size: 16),
                                ),
                                title: Text(item.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(item.description ?? 'No description provided.'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(item.price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF0055))),
                                    if (item.paymentType != null)
                                      Text(item.paymentType!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
