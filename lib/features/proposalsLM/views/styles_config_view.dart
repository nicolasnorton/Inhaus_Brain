import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/proforma_style.dart';
import '../providers/proposals_providers.dart';
import '../services/proposals_repository.dart';

/// Proforma style manager ported from `styles-view.tsx`.
///
/// Lists custom styles with color swatches, supports creating/editing styles
/// with a 7-property color palette and reference images, and shows a live
/// preview mini-card.
class StylesConfigView extends ConsumerStatefulWidget {
  const StylesConfigView({super.key});

  @override
  ConsumerState<StylesConfigView> createState() => _StylesConfigViewState();
}

class _StylesConfigViewState extends ConsumerState<StylesConfigView> {
  List<ProformaStyle> _styles = [];
  bool _loading = true;

  // form state
  bool _creating = false;
  String? _editingId;
  String _name = '';
  StyleColors _colors = StyleColors.defaultColors;
  bool _showNameError = false;
  bool _saving = false;

  static const _accent = Color(0xFFE8006A);
  static const _bg = Color(0xFF111111);
  static const _cardBg = Color(0xFF1A1A1A);
  static const _borderColor = Color(0xFF2A2A2A);

  static const _colorLabels = <String, String>{
    'background': 'Fondo',
    'cardBg': 'Tarjetas',
    'accent': 'Acento',
    'textPrimary': 'Texto principal',
    'textSecondary': 'Texto secundario',
    'textMuted': 'Texto sutil',
    'border': 'Bordes',
  };

  @override
  void initState() {
    super.initState();
    _loadStyles();
  }

  Future<void> _loadStyles() async {
    try {
      _styles = await ref.read(proposalsRepositoryProvider).getStyles();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  bool get _isFormOpen => _creating || _editingId != null;

  void _startCreate() => setState(() {
        _creating = true;
        _editingId = null;
        _name = '';
        _colors = StyleColors.defaultColors;
        _showNameError = false;
      });

  void _startEdit(ProformaStyle s) => setState(() {
        _editingId = s.id;
        _creating = false;
        _name = s.name;
        _colors = s.colors;
        _showNameError = false;
      });

  void _resetForm() => setState(() {
        _creating = false;
        _editingId = null;
        _name = '';
        _colors = StyleColors.defaultColors;
        _showNameError = false;
      });

  Future<void> _handleSave() async {
    if (_name.trim().isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'name': _name,
        'colors': _colors.toJson(),
        'referenceImages': <String>[],
        'isDefault': false,
      };
      if (_editingId != null) {
        await ref.read(proposalsRepositoryProvider).updateStyleById(_editingId!, data);
      } else {
        await ref.read(proposalsRepositoryProvider).createStyleFromMap(data);
      }
      _resetForm();
      await _loadStyles();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(dynamic id) async {
    await ref.read(proposalsRepositoryProvider).deleteStyle(id);
    _loadStyles();
  }

  void _updateColor(String key, String hex) {
    setState(() {
      _colors = StyleColors(
        background: key == 'background' ? hex : _colors.background,
        cardBg: key == 'cardBg' ? hex : _colors.cardBg,
        accent: key == 'accent' ? hex : _colors.accent,
        textPrimary: key == 'textPrimary' ? hex : _colors.textPrimary,
        textSecondary: key == 'textSecondary' ? hex : _colors.textSecondary,
        textMuted: key == 'textMuted' ? hex : _colors.textMuted,
        border: key == 'border' ? hex : _colors.border,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        title: const Text('ESTILOS DE PROFORMA',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 3)),
        actions: [
          if (!_isFormOpen)
            TextButton.icon(
              onPressed: _startCreate,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nuevo estilo', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: _accent),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isFormOpen) _buildForm(),
                if (!_isFormOpen && _styles.isEmpty) _buildEmpty(),
                if (!_loading)
                  ..._styles.map(_buildStyleCard).toList(),
              ],
            ),
    );
  }

  // ---- Form ----
  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_editingId != null ? 'Editar Estilo' : 'Crear Nuevo Estilo',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.white)),
          IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.white38), onPressed: _resetForm),
        ]),
        const SizedBox(height: 12),
        // Name
        const Text('NOMBRE DEL ESTILO *',
            style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white38)),
        const SizedBox(height: 4),
        TextField(
          onChanged: (v) {
            _name = v;
            if (v.trim().isNotEmpty) setState(() => _showNameError = false);
          },
          controller: TextEditingController(text: _name),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Ej: Elegante Oscuro, Minimalista, Corporativo...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _showNameError ? Colors.redAccent : _borderColor),
            ),
          ),
        ),
        if (_showNameError)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Dale un nombre a tu estilo para poder guardarlo',
                style: TextStyle(fontSize: 11, color: Colors.redAccent)),
          ),
        const SizedBox(height: 16),

        // Color swatches
        const Text('PALETA DE COLORES',
            style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white38)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorLabels.entries.map((e) {
            final colorHex = _colors.toJson()[e.key] as String;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => _showColorPicker(e.key, colorHex),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseHex(colorHex),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _borderColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(e.value,
                  style: const TextStyle(fontSize: 8, color: Colors.white38),
                  textAlign: TextAlign.center),
            ]);
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Preview
        const Text('VISTA PREVIA',
            style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white38)),
        const SizedBox(height: 8),
        _StylePreviewMini(colors: _colors),
        const SizedBox(height: 16),

        // Actions
        Row(children: [
          ElevatedButton.icon(
            onPressed: _saving ? null : _handleSave,
            icon: _saving
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check, size: 14),
            label: Text(_editingId != null ? 'Guardar cambios' : 'Crear estilo',
                style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _resetForm,
            child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
          ),
        ]),
      ]),
    );
  }

  void _showColorPicker(String key, String currentHex) {
    final ctrl = TextEditingController(text: currentHex);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text('${_colorLabels[key]}',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            labelText: 'HEX color',
            hintText: '#E8006A',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              _updateColor(key, ctrl.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---- Style card ----
  Widget _buildStyleCard(ProformaStyle style) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        // Color bar header
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            gradient: LinearGradient(colors: [
              _parseHex(style.colors.background),
              _parseHex(style.colors.cardBg),
            ]),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: style.colors.toJson().values.take(7).map((c) {
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _parseHex(c as String),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Info + actions
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: Row(children: [
                Text(style.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                if (style.isDefault) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(4)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star, size: 10, color: Colors.white54),
                      SizedBox(width: 2),
                      Text('Default', style: TextStyle(fontSize: 8, color: Colors.white54)),
                    ]),
                  ),
                ],
              ]),
            ),
            OutlinedButton.icon(
              onPressed: () => _startEdit(style),
              icon: const Icon(Icons.edit, size: 12),
              label: const Text('Editar', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white54),
            ),
            if (!style.isDefault) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete, size: 14, color: Colors.redAccent),
                onPressed: () => _delete(style.id),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: _accent.withOpacity(0.1)),
          child: const Icon(Icons.add_photo_alternate, size: 32, color: _accent),
        ),
        const SizedBox(height: 12),
        const Text('No hay estilos personalizados',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
        const SizedBox(height: 4),
        const Text('Crea tu primer estilo subiendo una imagen de referencia.',
            style: TextStyle(fontSize: 12, color: Colors.white38), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _startCreate,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Crear primer estilo', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  Color _parseHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ---- Preview mini ----
class _StylePreviewMini extends StatelessWidget {
  final StyleColors colors;
  const _StylePreviewMini({required this.colors});

  Color _hex(String h) => Color(int.parse('FF${h.replaceFirst('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hex(colors.background),
        border: Border.all(color: _hex(colors.border)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COTIZACIÓN',
            style: TextStyle(fontSize: 7, letterSpacing: 3, fontWeight: FontWeight.bold,
                color: _hex(colors.textMuted))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hex(colors.cardBg),
            border: Border.all(color: _hex(colors.border)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PAQUETE EJEMPLO',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _hex(colors.textPrimary))),
            Text('20 piezas mensuales',
                style: TextStyle(fontSize: 7, color: _hex(colors.textSecondary))),
            Align(
              alignment: Alignment.centerRight,
              child: Text(r'$1,000',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _hex(colors.accent))),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hex(colors.cardBg),
            border: Border.all(color: _hex(colors.border)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('TOTAL',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _hex(colors.accent))),
            Text(r'$1,150',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _hex(colors.accent))),
          ]),
        ),
      ]),
    );
  }
}
