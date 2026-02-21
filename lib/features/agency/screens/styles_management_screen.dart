import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proposal_style.dart';
import '../providers/proposal_style_provider.dart';

class StylesManagementScreen extends ConsumerStatefulWidget {
  const StylesManagementScreen({super.key});

  @override
  ConsumerState<StylesManagementScreen> createState() => _StylesManagementScreenState();
}

class _StylesManagementScreenState extends ConsumerState<StylesManagementScreen> {
  // Temporary state for editing
  ProposalStyle? _editingStyle;
  
  // Controllers for hex values
  late TextEditingController _nameCtrl;
  late TextEditingController _fondoCtrl;
  late TextEditingController _tarjetasCtrl;
  late TextEditingController _acentoCtrl;
  late TextEditingController _textoPrincipalCtrl;
  late TextEditingController _textoSecundarioCtrl;
  late TextEditingController _textoSutilCtrl;
  late TextEditingController _bordesCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameCtrl = TextEditingController();
    _fondoCtrl = TextEditingController();
    _tarjetasCtrl = TextEditingController();
    _acentoCtrl = TextEditingController();
    _textoPrincipalCtrl = TextEditingController();
    _textoSecundarioCtrl = TextEditingController();
    _textoSutilCtrl = TextEditingController();
    _bordesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fondoCtrl.dispose();
    _tarjetasCtrl.dispose();
    _acentoCtrl.dispose();
    _textoPrincipalCtrl.dispose();
    _textoSecundarioCtrl.dispose();
    _textoSutilCtrl.dispose();
    _bordesCtrl.dispose();
    super.dispose();
  }

  void _loadStyleIntoEditor(ProposalStyle style) {
    setState(() {
      _editingStyle = style;
      _nameCtrl.text = style.name;
      _fondoCtrl.text = style.fondoHex;
      _tarjetasCtrl.text = style.tarjetasHex;
      _acentoCtrl.text = style.acentoHex;
      _textoPrincipalCtrl.text = style.textoPrincipalHex;
      _textoSecundarioCtrl.text = style.textoSecundarioHex;
      _textoSutilCtrl.text = style.textoSutilHex;
      _bordesCtrl.text = style.bordesHex;
    });
  }

  void _startNewStyle() {
    _loadStyleIntoEditor(ProposalStyle.inhausClasico.copyWith(
      name: 'Nuevo Estilo',
      isDefault: false,
    ));
  }

  Future<void> _saveStyle() async {
    if (_editingStyle == null) return;

    final updatedStyle = _editingStyle!.copyWith(
      name: _nameCtrl.text,
      fondoHex: _fondoCtrl.text,
      tarjetasHex: _tarjetasCtrl.text,
      acentoHex: _acentoCtrl.text,
      textoPrincipalHex: _textoPrincipalCtrl.text,
      textoSecundarioHex: _textoSecundarioCtrl.text,
      textoSutilHex: _textoSutilCtrl.text,
      bordesHex: _bordesCtrl.text,
    );

    final repo = ref.read(proposalStyleRepositoryProvider);
    if (updatedStyle.id.isEmpty) {
      await repo.createStyle(updatedStyle);
    } else {
      await repo.updateStyle(updatedStyle);
    }

    // Refresh list and clear editor
    ref.invalidate(proposalStylesProvider);
    setState(() {
      _editingStyle = null;
    });
  }

  Future<void> _deleteStyle(ProposalStyle style) async {
    if (style.isDefault) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Style'),
        content: Text('Are you sure you want to delete "${style.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      )
    );

    if (confirm == true) {
      final repo = ref.read(proposalStyleRepositoryProvider);
      await repo.deleteStyle(style.id);
      ref.invalidate(proposalStylesProvider);
      if (_editingStyle?.id == style.id) {
        setState(() => _editingStyle = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stylesAsync = ref.watch(proposalStylesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estilos de Proforma'),
        actions: [
          if (_editingStyle == null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: _startNewStyle,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nuevo Estilo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0055), // INHAUS Pink
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: List of Styles
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(16),
              color: Theme.of(context).cardColor,
              child: stylesAsync.when(
                data: (styles) => ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: styles.length,
                  itemBuilder: (context, index) {
                    final style = styles[index];
                    final isEditingThis = _editingStyle?.id == style.id || (_editingStyle?.id.isEmpty == true && index == styles.length); // Rough logic
                    
                    return ListTile(
                      selected: isEditingThis,
                      selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _colorFromHex(style.acentoHex),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(style.name),
                      trailing: style.isDefault 
                          ? const Chip(label: Text('Default', style: TextStyle(fontSize: 10)), padding: EdgeInsets.zero)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _loadStyleIntoEditor(style),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                  onPressed: () => _deleteStyle(style),
                                ),
                              ],
                            ),
                      onTap: () => _loadStyleIntoEditor(style),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
          
          // Right: Editor Panel
          if (_editingStyle != null)
            Expanded(
              flex: 2,
              child: Card(
                margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('EDITAR ESTILO', style: Theme.of(context).textTheme.titleLarge),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _editingStyle = null),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'NOMBRE DEL ESTILO *', border: OutlineInputBorder()),
                        enabled: !_editingStyle!.isDefault,
                      ),
                      const SizedBox(height: 32),
                      const Text('PALETA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 16),
                      // Hex Input Grid
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            _buildColorInput('Fondo', _fondoCtrl),
                            _buildColorInput('Tarjetas', _tarjetasCtrl),
                            _buildColorInput('Acento', _acentoCtrl),
                            _buildColorInput('Texto Principal', _textoPrincipalCtrl),
                            _buildColorInput('Texto Secundario', _textoSecundarioCtrl),
                            _buildColorInput('Texto Sutil', _textoSutilCtrl),
                            _buildColorInput('Bordes', _bordesCtrl),
                          ],
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (!_editingStyle!.isDefault)
                            ElevatedButton.icon(
                              onPressed: _saveStyle,
                              icon: const Icon(Icons.save),
                              label: const Text('Guardar cambios'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF0055),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: () => setState(() => _editingStyle = null),
                            child: const Text('Cancelar'),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorInput(String label, TextEditingController controller) {
    return Row(
      children: [
        // Color Preview Box
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _colorFromHex(controller.text),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: '#XXXXXX',
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) {
              if (val.length == 7 && val.startsWith('#')) {
                setState(() {}); // Trigger rebuild to update preview box
              }
            },
            enabled: _editingStyle != null && !_editingStyle!.isDefault,
          ),
        ),
      ],
    );
  }

  Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    final intColor = int.tryParse(buffer.toString(), radix: 16);
    if (intColor == null) return Colors.transparent;
    return Color(intColor);
  }
}
