import 'package:flutter/material.dart';
import '../views/quotes_dashboard_view.dart';
import '../views/quote_editor_view.dart';
import '../views/packages_manager_view.dart';
import '../views/tuneador_view.dart';
import '../views/styles_config_view.dart';
import '../services/proposals_repository.dart';
import '../models/quote.dart';

/// Unified Cotizador panel that embeds all 4 features of the
/// Live Cotizador into a single widget with sidebar navigation.
///
/// Sections:
///   - Productos (PackagesManagerView)
///   - El Tuneador (TuneadorView)
///   - Estilos (StylesConfigView)
///   - Historial (QuotesDashboardView)
///   - Editor (QuoteEditorView) — opens when editing/creating a quote
class CotizadorPanel extends StatefulWidget {
  final VoidCallback? onClose;

  const CotizadorPanel({super.key, this.onClose});

  @override
  State<CotizadorPanel> createState() => _CotizadorPanelState();
}

enum _CotizadorSection { productos, tuneador, estilos, historial, editor }

class _CotizadorPanelState extends State<CotizadorPanel> {
  _CotizadorSection _active = _CotizadorSection.productos;
  Quote? _editingQuote;

  final _repo = ProposalsRepository();

  static const _accent = Color(0xFFE8006A);
  static const _sidebarBg = Color(0xFF0D0D0D);
  static const _sidebarW = 160.0;

  void _openEditor([Quote? quote]) {
    setState(() {
      _editingQuote = quote;
      _active = _CotizadorSection.editor;
    });
  }

  void _closeEditor() {
    setState(() {
      _editingQuote = null;
      _active = _CotizadorSection.historial;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ---- Sidebar ----
        Container(
          width: _sidebarW,
          color: _sidebarBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _navItem(Icons.grid_view_rounded, 'Productos', _CotizadorSection.productos),
              _navItem(Icons.auto_fix_high, 'El Tuneador', _CotizadorSection.tuneador),
              _navItem(Icons.palette_outlined, 'Estilos', _CotizadorSection.estilos),
              _navItem(Icons.history, 'Historial', _CotizadorSection.historial),
              const Spacer(),
              // New Quote button
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nueva', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: Colors.white10),
        // ---- Content ----
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _navItem(IconData icon, String label, _CotizadorSection section) {
    final isActive = _active == section;
    return InkWell(
      onTap: () => setState(() => _active = section),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.04) : null,
          border: Border(
            left: BorderSide(
              width: 3,
              color: isActive ? _accent : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : Colors.white38),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? Colors.white : Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_active) {
      case _CotizadorSection.productos:
        return PackagesManagerView(
          onAddToQuote: (pkg) {
            // TODO: Add package to the active quote session
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${pkg.name} agregado a la cotización'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onEditPackage: (pkg) {
            // TODO: Open edit form
          },
        );
      case _CotizadorSection.tuneador:
        return TuneadorView(
          onLoadToEditor: (quoteState) {
            // Open editor with parsed data
            _openEditor();
          },
        );
      case _CotizadorSection.estilos:
        return StylesConfigView();
      case _CotizadorSection.historial:
        return QuotesDashboardView(
          onEdit: (quote) => _openEditor(quote),
          onPreview: (quote) {
            // TODO: Preview modal
          },
          onPrint: (quote) {
            // TODO: PDF generation
          },
        );
      case _CotizadorSection.editor:
        return QuoteEditorView(
          existingQuote: _editingQuote,
          onClose: _closeEditor,
          onSaved: (saved) {
            _closeEditor();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cotización guardada'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
    }
  }
}
