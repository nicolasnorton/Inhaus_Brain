import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../models/section.dart';
import '../models/proforma_style.dart';
import '../models/constants.dart';
import '../providers/proposals_providers.dart';
import '../services/proposals_repository.dart';
import '../services/quote_pdf_generator.dart';

/// Full-featured quote editor ported from `editor-modal.tsx`.
///
/// Sidebar-driven navigation with sections for:
///   -3  Style selector
///   -2  Logo picker
///   -1  Client / Date / Discount / IVA
///    0…n  Package items (name, price, billing, sections)
///   99  Extra blocks (notes)
///   98  Total adjustment
class QuoteEditorView extends ConsumerStatefulWidget {
  final Quote? existingQuote;
  final VoidCallback? onClose;
  final void Function(Quote saved)? onSaved;

  const QuoteEditorView({
    super.key,
    this.existingQuote,
    this.onClose,
    this.onSaved,
  });

  @override
  ConsumerState<QuoteEditorView> createState() => _QuoteEditorViewState();
}

class _QuoteEditorViewState extends ConsumerState<QuoteEditorView> {
  // ---- state ----
  String _client = '';
  String _date = '';
  double _discount = 0;
  bool _applyIva = true;
  String _logoVariant = 'ESTUDIO';
  String? _styleId;
  List<QuoteItem> _items = [];
  List<ExtraBlock> _extraBlocks = [];
  double _extraAmt = 0;
  String _totalNote = '';
  int _activeSection = -1; // sidebar selection

  List<ProformaStyle> _styles = [];
  bool _loadingStyles = true;

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuote;
    if (q != null) {
      _client = q.client;
      _date = q.date;
      _discount = q.discount;
      _applyIva = q.applyIva;
      _logoVariant = q.logoVariant;
      _styleId = q.styleId;
      _items = List.of(q.items);
      _extraBlocks = List.of(q.extraBlocks);
      _extraAmt = q.extraAmount;
      _totalNote = q.totalNote;
    } else {
      _date = todayStr();
    }
    _loadStyles();
  }

  Future<void> _loadStyles() async {
    try {
      _styles = await ref.read(proposalsRepositoryProvider).getStyles();
    } catch (_) {
      // non-fatal
    } finally {
      if (mounted) setState(() => _loadingStyles = false);
    }
  }

  // ---- totals ----
  double get _subtotal {
    final t = calcTotals(items: _items, discount: _discount, applyIva: _applyIva);
    return t.total;
  }

  double get _finalTotal => _subtotal + _extraAmt;

  Quote _buildQuote() {
    return Quote(
      id: widget.existingQuote?.id ?? '',
      client: _client,
      date: _date,
      discount: _discount,
      applyIva: _applyIva,
      logoVariant: _logoVariant,
      styleId: _styleId ?? '',
      createdAt: widget.existingQuote?.createdAt ?? DateTime.now(),
      items: _items,
      extraBlocks: _extraBlocks,
      extraAmount: _extraAmt,
      totalNote: _totalNote,
    );
  }

  Future<void> _downloadPdf() async {
    final quote = _buildQuote();
    ProformaStyle? style;
    if (_styleId != null && _styles.isNotEmpty) {
      style = _styles.firstWhere(
        (s) => s.id == _styleId, 
        orElse: () => _styles.first
      );
    } else {
      style = ProformaStyle(
        id: 'default',
        name: 'Clásico',
        colors: StyleColors.defaultColors,
        referenceImages: [],
        isDefault: true,
        createdAt: DateTime.now(),
      );
    }
    
    final pdfBytes = await QuotePdfGenerator.generate(quote, style);
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'cotizacion_${_client.isEmpty ? "inhaus" : _client.replaceAll(' ', '_')}.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---- item helpers ----
  void _updateItem(int i, QuoteItem Function(QuoteItem) updater) {
    setState(() => _items[i] = updater(_items[i]));
  }

  void _addSection(int itemIdx) {
    setState(() {
      final item = _items[itemIdx];
      _items[itemIdx] = QuoteItem(
        id: item.id,
        name: item.name,
        category: item.category,
        price: item.price,
        billing: item.billing,
        sections: [...item.sections, Section(title: '', content: '')],
      );
    });
  }

  void _removeSection(int itemIdx, int secIdx) {
    setState(() {
      final item = _items[itemIdx];
      final newSections = List<Section>.from(item.sections)..removeAt(secIdx);
      _items[itemIdx] = QuoteItem(
        id: item.id,
        name: item.name,
        category: item.category,
        price: item.price,
        billing: item.billing,
        sections: newSections,
      );
    });
  }

  void _moveItem(int i, int dir) {
    final j = i + dir;
    if (j < 0 || j >= _items.length) return;
    setState(() {
      final tmp = _items[i];
      _items[i] = _items[j];
      _items[j] = tmp;
      _activeSection = j;
    });
  }

  void _addExtraBlock() {
    setState(() {
      _extraBlocks.add(ExtraBlock(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        content: '',
      ));
    });
  }

  void _removeExtra(String id) {
    setState(() => _extraBlocks.removeWhere((b) => b.id == id));
  }

  // ---- build ----
  static const _accent = Color(0xFFE8006A);
  static const _bg = Color(0xFF111111);
  static const _cardBg = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('EDITOR',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 3)),
            Text('Edita cualquier campo antes de descargar',
                style: TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.visibility, size: 14),
            label: const Text('Vista previa', style: TextStyle(fontSize: 12)),
            onPressed: () {/* preview callback */},
          ),
          TextButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 14),
            label: const Text('PDF', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: _accent),
            onPressed: () => _downloadPdf(),
          ),
          if (widget.onClose != null)
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: widget.onClose),
        ],
      ),
      body: Row(
        children: [
          // ---- sidebar ----
          Container(
            width: 180,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: _border)),
            ),
            child: ListView(
              children: [
                _sideItem(-3, Icons.palette, 'Estilo'),
                _sideItem(-2, Icons.image, 'Logo'),
                _sideItem(-1, Icons.person, 'Cliente / Fecha'),
                for (var i = 0; i < _items.length; i++)
                  _sideItem(i, Icons.inventory_2, _items[i].name,
                      subtitle: formatCurrency(_items[i].price),
                      billing: _items[i].billing),
                _sideItem(99, Icons.description, 'Notas / Extras'),
                _sideItem(98, Icons.attach_money, 'Ajuste total'),
              ],
            ),
          ),
          // ---- main content ----
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(int id, IconData icon, String label,
      {String? subtitle, String? billing}) {
    final selected = _activeSection == id;
    return InkWell(
      onTap: () => setState(() => _activeSection = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 3,
              color: selected ? _accent : Colors.transparent,
            ),
          ),
          color: selected ? Colors.white.withValues(alpha: 0.04) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: selected ? Colors.white : Colors.white38),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.white54)),
                ),
              ],
            ),
            if (subtitle != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 18, top: 2),
                child: Row(
                  children: [
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: _accent)),
                    if (billing != null && billing.toLowerCase().contains('mensual')) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('/mes',
                            style: TextStyle(fontSize: 7, color: Colors.blue)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---- section content ----
  Widget _buildContent() {
    switch (_activeSection) {
      case -3:
        return _buildStyleSection();
      case -2:
        return _buildLogoSection();
      case -1:
        return _buildClientSection();
      case 99:
        return _buildExtrasSection();
      case 98:
        return _buildTotalSection();
      default:
        if (_activeSection >= 0 && _activeSection < _items.length) {
          return _buildItemSection(_activeSection);
        }
        return const Center(
          child: Text('Selecciona una sección', style: TextStyle(color: Colors.white38)),
        );
    }
  }

  // --- Style ---
  Widget _buildStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Estilo de Proforma'),
        if (_loadingStyles) const Center(child: CircularProgressIndicator(color: _accent)),
        if (!_loadingStyles) ...[
          // Default
          _styleCard(null, 'INHAUS Clásico', StyleColors.defaultColors),
          const SizedBox(height: 8),
          for (final s in _styles) ...[
            _styleCard(s.id, s.name, s.colors),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _styleCard(String? id, String name, StyleColors colors) {
    final selected = _styleId == id;
    return GestureDetector(
      onTap: () => setState(() => _styleId = id),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? _accent : _border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(int.parse(colors.background.replaceFirst('#', '0xFF'))),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COTIZACIÓN',
                      style: TextStyle(
                          fontSize: 7,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                          color: Color(int.parse(colors.textMuted.replaceFirst('#', '0xFF'))))),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paquete Demo',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(int.parse(colors.textPrimary.replaceFirst('#', '0xFF'))))),
                      Text(r'$1,000',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(int.parse(colors.accent.replaceFirst('#', '0xFF'))))),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  ...['background', 'cardBg', 'accent', 'textPrimary'].map((k) {
                    final c = colors.toJson()[k] as String;
                    return Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                        border: Border.all(color: _border),
                      ),
                    );
                  }),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(name,
                        style:
                            const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  if (selected) const Icon(Icons.check, color: _accent, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logo ---
  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Logo de la Cotización'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: logoVariants.map((v) {
            final selected = _logoVariant == v;
            return OutlinedButton(
              onPressed: () => setState(() => _logoVariant = v),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: BorderSide(color: selected ? _accent : _border, width: selected ? 2 : 1),
              ),
              child: Text(v,
                  style: TextStyle(
                      fontSize: 10,
                      color: selected ? _accent : Colors.white54,
                      fontWeight: FontWeight.bold)),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Client / Date ---
  Widget _buildClientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Datos Generales'),
        _label('NOMBRE DEL CLIENTE'),
        _field(_client, (v) => setState(() => _client = v)),
        const SizedBox(height: 12),
        _label('FECHA'),
        _field(_date, (v) => setState(() => _date = v)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('DESCUENTO (%)'),
            _field(_discount.toString(), (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                inputType: TextInputType.number),
          ])),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SwitchListTile(
                dense: true,
                value: _applyIva,
                onChanged: (v) => setState(() => _applyIva = v),
                title: const Text('Aplicar IVA (15%)', style: TextStyle(fontSize: 12, color: Colors.white54)),
                activeThumbColor: _accent,
              ),
            ),
          ),
        ]),
      ],
    );
  }

  // --- Package item ---
  Widget _buildItemSection(int idx) {
    final item = _items[idx];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _heading('Editar Paquete')),
            IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                color: Colors.white38,
                onPressed: idx > 0 ? () => _moveItem(idx, -1) : null),
            IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                color: Colors.white38,
                onPressed: idx < _items.length - 1 ? () => _moveItem(idx, 1) : null),
          ],
        ),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('NOMBRE'),
            _field(item.name, (v) => _updateItem(idx, (i) => QuoteItem(
                  id: i.id, name: v, category: i.category,
                  price: i.price, billing: i.billing, sections: i.sections))),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('PRECIO (\$)'),
            _field(item.price.toString(),
                (v) => _updateItem(idx, (i) => QuoteItem(
                      id: i.id, name: i.name, category: i.category,
                      price: double.tryParse(v) ?? 0, billing: i.billing, sections: i.sections)),
                inputType: TextInputType.number),
          ])),
        ]),
        const SizedBox(height: 12),
        _label('FACTURACIÓN'),
        DropdownButtonFormField<String>(
          initialValue: item.billing.isEmpty ? '' : item.billing,
          dropdownColor: _cardBg,
          decoration: _inputDecoration(),
          items: billingOptions.map((o) {
            return DropdownMenuItem(value: o['value'], child: Text(o['label']!,
                style: const TextStyle(fontSize: 13, color: Colors.white)));
          }).toList(),
          onChanged: (v) => _updateItem(idx, (i) => QuoteItem(
                id: i.id, name: i.name, category: i.category,
                price: i.price, billing: v ?? '', sections: i.sections)),
        ),
        const SizedBox(height: 16),
        _label('SECCIONES'),
        for (var si = 0; si < item.sections.length; si++) ...[
          _sectionCard(idx, si, item.sections[si]),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: () => _addSection(idx),
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Agregar sección', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent,
            side: BorderSide(color: _accent.withValues(alpha: 0.4), style: BorderStyle.solid),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(int itemIdx, int secIdx, Section sec) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SECCIÓN ${secIdx + 1}',
                  style: const TextStyle(fontSize: 9, letterSpacing: 2, color: Colors.white38)),
              IconButton(
                icon: const Icon(Icons.delete, size: 14, color: Colors.white38),
                onPressed: () => _removeSection(itemIdx, secIdx),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _label('Título'),
          _field(sec.title, (v) {
            setState(() {
              final item = _items[itemIdx];
              final secs = List<Section>.from(item.sections);
              secs[secIdx] = Section(title: v, content: sec.content);
              _items[itemIdx] = QuoteItem(
                  id: item.id, name: item.name, category: item.category,
                  price: item.price, billing: item.billing, sections: secs);
            });
          }),
          const SizedBox(height: 6),
          _label('Contenido'),
          _field(sec.content, (v) {
            setState(() {
              final item = _items[itemIdx];
              final secs = List<Section>.from(item.sections);
              secs[secIdx] = Section(title: sec.title, content: v);
              _items[itemIdx] = QuoteItem(
                  id: item.id, name: item.name, category: item.category,
                  price: item.price, billing: item.billing, sections: secs);
            });
          }, maxLines: 4),
        ],
      ),
    );
  }

  // --- Extras ---
  Widget _buildExtrasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Notas y Bloques Adicionales'),
        const Text('Aparecen antes del total en el PDF.',
            style: TextStyle(fontSize: 12, color: Colors.white38)),
        const SizedBox(height: 12),
        for (final b in _extraBlocks) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: _accent.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('BLOQUE',
                    style: TextStyle(fontSize: 9, letterSpacing: 2, color: _accent, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.delete, size: 14, color: Colors.white38),
                    onPressed: () => _removeExtra(b.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ]),
              _label('Título'),
              _field(b.title, (v) => setState(() {
                    final idx = _extraBlocks.indexWhere((x) => x.id == b.id);
                    _extraBlocks[idx] = ExtraBlock(id: b.id, title: v, content: b.content);
                  })),
              const SizedBox(height: 6),
              _label('Contenido'),
              _field(b.content, (v) => setState(() {
                    final idx = _extraBlocks.indexWhere((x) => x.id == b.id);
                    _extraBlocks[idx] = ExtraBlock(id: b.id, title: b.title, content: v);
                  }), maxLines: 3),
            ]),
          ),
        ],
        OutlinedButton.icon(
          onPressed: _addExtraBlock,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Agregar bloque', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent,
            side: BorderSide(color: _accent.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }

  // --- Total ---
  Widget _buildTotalSection() {
    final t = calcTotals(items: _items, discount: _discount, applyIva: _applyIva);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Ajuste de Total'),
        _label('MONTO ADICIONAL (\$)'),
        _field(_extraAmt.toString(),
            (v) => setState(() => _extraAmt = double.tryParse(v) ?? 0),
            inputType: TextInputType.number),
        const SizedBox(height: 12),
        _label('NOTA (opcional)'),
        _field(_totalNote, (v) => setState(() => _totalNote = v)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg, border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            _totalRow('Subtotal paquetes', formatCurrency(t.total), Colors.white54),
            if (_extraAmt > 0)
              _totalRow('Monto adicional', '+ ${formatCurrency(_extraAmt)}', _accent),
            const Divider(color: _border),
            _totalRow('TOTAL', formatCurrency(_finalTotal), _accent, bold: true, size: 16),
          ]),
        ),
      ],
    );
  }

  // ---- shared widgets ----
  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.white)),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white38)),
      );

  Widget _field(String value, ValueChanged<String> onChanged,
      {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      keyboardType: inputType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      decoration: _inputDecoration(),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        fillColor: _cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _accent),
        ),
      );

  Widget _totalRow(String label, String value, Color color,
      {bool bold = false, double size = 12}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: size, color: color, fontWeight: bold ? FontWeight.w900 : null)),
          Text(value,
              style: TextStyle(
                  fontSize: size, color: color, fontWeight: bold ? FontWeight.w900 : null)),
        ],
      ),
    );
  }
}
