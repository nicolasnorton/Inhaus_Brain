import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../models/constants.dart';
import '../providers/proposals_providers.dart';

/// Displays all saved quotations (mirrors `history-view.tsx`).
///
/// Each card shows the client name, date, item summary, total and action
/// buttons for Preview, Edit, Print-PDF, and Delete.
class QuotesDashboardView extends ConsumerStatefulWidget {
  final void Function(Quote quote)? onPreview;
  final void Function(Quote quote)? onEdit;
  final void Function(Quote quote)? onPrint;

  const QuotesDashboardView({
    super.key,
    this.onPreview,
    this.onEdit,
    this.onPrint,
  });

  @override
  ConsumerState<QuotesDashboardView> createState() => _QuotesDashboardViewState();
}

class _QuotesDashboardViewState extends ConsumerState<QuotesDashboardView> {
  late Future<List<Quote>> _quotesFuture;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  void _loadQuotes() {
    _quotesFuture = ref.read(proposalsRepositoryProvider).getQuotes();
  }

  Future<void> _deleteQuote(dynamic id) async {
    await ref.read(proposalsRepositoryProvider).deleteQuote(id.toString());
    setState(_loadQuotes);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE8006A);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text(
          'HISTORIAL',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 3,
          ),
        ),
        backgroundColor: const Color(0xFF111111),
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Quote>>(
        future: _quotesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accent));
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.white70)),
            );
          }
          final quotes = snap.data ?? [];
          if (quotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No hay cotizaciones guardadas.',
                      style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Usa el chat para crear tu primera cotización.',
                      style: TextStyle(color: Colors.white30, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: quotes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final q = quotes[index];
              final totals = calcTotals(
                items: q.items,
                discount: q.discount,
                applyIva: q.applyIva,
              );
              final itemNames = q.items.map((i) => i.name).join(', ');

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.client.isEmpty ? 'Sin cliente' : q.client,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            itemNames,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.white54),
                          ),
                          const SizedBox(height: 2),
                          Text(q.date,
                              style: const TextStyle(fontSize: 10, color: Colors.white30)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right: total + actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(totals.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionBtn(Icons.visibility, 'Ver', () => widget.onPreview?.call(q)),
                            _ActionBtn(Icons.edit, 'Editar', () => widget.onEdit?.call(q),
                                color: accent),
                            _ActionBtn(Icons.print, '', () => widget.onPrint?.call(q)),
                            _ActionBtn(Icons.delete, '', () => _deleteQuote(q.id),
                                color: Colors.redAccent),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {/* navigate to new quote */},
        backgroundColor: accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// Small icon-text button used in quote cards.
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn(this.icon, this.label, this.onTap, {this.color = Colors.white70});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ],
        ),
      ),
    );
  }
}
