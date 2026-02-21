import 'package:flutter/material.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/section.dart';
import '../models/constants.dart';
import '../providers/proposals_providers.dart';

/// "El Tuneador" – AI-powered text-to-quote converter.
///
/// Ported from `tuneador-view.tsx`.  Two phases:
///   1. **Input**:  paste text or upload a document
///   2. **Review**: edit the AI-parsed items, then open in Editor
class TuneadorView extends ConsumerStatefulWidget {
  final void Function(Map<String, dynamic> quoteState)? onLoadToEditor;

  const TuneadorView({
    super.key,
    this.onLoadToEditor,
  });

  @override
  ConsumerState<TuneadorView> createState() => _TuneadorViewState();
}

class _TuneadorViewState extends ConsumerState<TuneadorView> {
  // phase
  bool _isReview = false;

  // input
  final _textCtrl = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  // review
  String _client = '';
  double _discount = 0;
  bool _applyIva = true;
  List<_TunedItem> _items = [];

  static const _accent = Color(0xFFE8006A);
  static const _bg = Color(0xFF111111);
  static const _cardBg = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2A2A2A);

  // ---- analyse ----
  Future<void> _handleAnalyze() async {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await ref.read(proposalsRepositoryProvider).tuneProforma(_textCtrl.text);
      _client = data['client'] as String? ?? '';
      _discount = (data['discount'] as num?)?.toDouble() ?? 0;
      _applyIva = data['applyIva'] as bool? ?? true;
      _items = (data['items'] as List<dynamic>? ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        return _TunedItem(
          id: m['id'] as String,
          name: m['name'] as String,
          category: m['category'] as String,
          price: (m['price'] as num).toDouble(),
          billing: m['billing'] as String? ?? '',
          sections: (m['sections'] as List<dynamic>? ?? [])
              .map((s) => Section.fromJson(s as Map<String, dynamic>))
              .toList(),
          editing: false,
        );
      }).toList();
      _isReview = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _reset() {
    setState(() {
      _isReview = false;
      _textCtrl.clear();
      _items = [];
      _client = '';
      _discount = 0;
      _applyIva = true;
      _error = '';
    });
  }

  void _loadToEditor() {
    if (_items.isEmpty) return;
    widget.onLoadToEditor?.call({
      'client': _client,
      'discount': _discount,
      'applyIva': _applyIva,
      'date': todayStr(),
      'items': _items
          .map((i) => {
                'id': i.id,
                'name': i.name,
                'category': i.category,
                'price': i.price,
                'billing': i.billing,
                'sections': i.sections.map((s) => s.toJson()).toList(),
              })
          .toList(),
    });
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        title: Text(_isReview ? 'PROFORMA TUNEADA' : 'EL TUNEADOR',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 3)),
        actions: _isReview
            ? [
                TextButton(
                    onPressed: _reset,
                    child: const Text('Nueva', style: TextStyle(fontSize: 12))),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: _items.isNotEmpty ? _loadToEditor : null,
                  icon: const Icon(Icons.auto_fix_high, size: 14),
                  label: const Text('Abrir en Editor', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: _accent),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: _isReview ? _buildReview() : _buildInput(),
    );
  }

  // ---- INPUT PHASE ----
  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Pega o sube una proforma existente y conviértela en una cotización editable',
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _textCtrl,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Pega aquí el contenido de la proforma que quieres tunear...',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleAnalyze,
            icon: _isLoading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_fix_high, size: 16),
            label: Text(_isLoading ? 'Analizando proforma...' : 'Tunear Proforma',
                style: const TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
          ),
        ),
      ]),
    );
  }

  // ---- REVIEW PHASE ----
  Widget _buildReview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Client + discount
        Row(children: [
          Expanded(
            child: _infoCard('Cliente', TextFormField(
              initialValue: _client,
              onChanged: (v) => _client = v,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Nombre del cliente'),
            )),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: _infoCard('Descuento (%)', TextFormField(
              initialValue: _discount.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              onChanged: (v) => _discount = double.tryParse(v) ?? 0,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(border: InputBorder.none),
            )),
          ),
        ]),
        const SizedBox(height: 12),
        // Summary row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${_items.length} producto${_items.length != 1 ? 's' : ''} detectado${_items.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13, color: Colors.white54)),
          Text('Subtotal: ${formatCurrency(_subtotal)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
        const SizedBox(height: 12),

        // Items
        for (var i = 0; i < _items.length; i++) ...[
          _buildItemCard(i),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _infoCard(String label, Widget child) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg, border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white38)),
        const SizedBox(height: 4),
        child,
      ]),
    );
  }

  Widget _buildItemCard(int idx) {
    final item = _items[idx];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg, border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(item.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 6),
                _badge(item.category, Colors.white24),
                if (item.billing.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _badge(item.billing,
                      item.billing.toLowerCase().contains('mensual')
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3)),
                ],
              ]),
              const SizedBox(height: 4),
              Text(formatCurrency(item.price),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _accent)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 14),
            color: Colors.white38,
            onPressed: () => setState(() => _items[idx] = item.copyWith(editing: !item.editing)),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 14),
            color: Colors.redAccent,
            onPressed: () => setState(() => _items.removeAt(idx)),
          ),
        ]),

        // Edit form
        if (item.editing) ...[
          const Divider(color: _border),
          Row(children: [
            Expanded(child: _miniField('Nombre', item.name, (v) =>
                setState(() => _items[idx] = item.copyWith(name: v)))),
            const SizedBox(width: 8),
            SizedBox(width: 100, child: _miniField('Precio', item.price.toString(), (v) =>
                setState(() => _items[idx] = item.copyWith(price: double.tryParse(v) ?? 0)),
                inputType: TextInputType.number)),
          ]),
          const SizedBox(height: 8),
          // Sections
          for (var si = 0; si < item.sections.length; si++)
            _reviewSectionCard(idx, si, item.sections[si]),
          TextButton.icon(
            onPressed: () => setState(() {
              item.sections.add(Section(title: '', content: ''));
            }),
            icon: const Icon(Icons.add, size: 12),
            label: const Text('Sección', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(foregroundColor: _accent),
          ),
        ],

        // Collapsed section previews
        if (!item.editing && item.sections.isNotEmpty)
          ...item.sections.map((sec) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    '${sec.title}: ${sec.content.length > 120 ? '${sec.content.substring(0, 120)}...' : sec.content}',
                    style: const TextStyle(fontSize: 12, color: Colors.white38)),
              )),
      ]),
    );
  }

  Widget _reviewSectionCard(int itemIdx, int secIdx, Section sec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _miniField('Título', sec.title, (v) {
            setState(() {
              _items[itemIdx].sections[secIdx] = Section(title: v, content: sec.content);
            });
          })),
          IconButton(
            icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
            onPressed: () => setState(() => _items[itemIdx].sections.removeAt(secIdx)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
        const SizedBox(height: 4),
        _miniField('Contenido', sec.content, (v) {
          setState(() {
            _items[itemIdx].sections[secIdx] = Section(title: sec.title, content: v);
          });
        }, maxLines: 2),
      ]),
    );
  }

  // ---- helpers ----
  Widget _badge(String text, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      );

  Widget _miniField(String hint, String value, ValueChanged<String> onChanged,
      {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      keyboardType: inputType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 12, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _accent)),
      ),
    );
  }
}

// ---- helper model ----
class _TunedItem {
  String id;
  String name;
  String category;
  double price;
  String billing;
  List<Section> sections;
  bool editing;

  _TunedItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.billing,
    required this.sections,
    required this.editing,
  });

  _TunedItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? billing,
    List<Section>? sections,
    bool? editing,
  }) {
    return _TunedItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      billing: billing ?? this.billing,
      sections: sections ?? this.sections,
      editing: editing ?? this.editing,
    );
  }
}
