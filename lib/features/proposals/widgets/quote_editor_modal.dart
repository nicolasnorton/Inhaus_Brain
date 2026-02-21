import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/proposal_model.dart';
import '../providers/proposal_session_provider.dart';

class QuoteEditorModal extends ConsumerStatefulWidget {
  final Proposal proposal;

  const QuoteEditorModal({super.key, required this.proposal});

  @override
  ConsumerState<QuoteEditorModal> createState() => _QuoteEditorModalState();
}

class _QuoteEditorModalState extends ConsumerState<QuoteEditorModal> {
  late TextEditingController _clientNameController;
  late TextEditingController _dateController;
  late TextEditingController _discountController;
  late bool _applyIva;

  @override
  void initState() {
    super.initState();
    _clientNameController = TextEditingController(text: widget.proposal.clientName);
    _dateController = TextEditingController(text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}");
    _discountController = TextEditingController(text: widget.proposal.discount.toStringAsFixed(0));
    _applyIva = widget.proposal.applyIva;
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _dateController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final notifier = ref.read(proposalSessionProvider.notifier);
    
    if (_clientNameController.text.isNotEmpty) {
      notifier.setClientName(_clientNameController.text.trim());
    }
    
    double? discount = double.tryParse(_discountController.text);
    if (discount != null && discount >= 0 && discount <= 100) {
      notifier.setDiscount(discount);
    }
    
    notifier.setIva(_applyIva);
    notifier.saveSession();

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cambios aplicados."), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Editar Cotización", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white24),
            
            // Edit Fields
            TextField(
              controller: _clientNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Cliente",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _dateController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Fecha (YYYY-MM-DD)",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Descuento (%)",
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: SwitchListTile(
                    title: const Text("Aplicar IVA (15%)", style: TextStyle(color: Colors.white)),
                    value: _applyIva,
                    activeColor: AppTheme.primary,
                    onChanged: (val) {
                      setState(() => _applyIva = val);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _saveChanges,
                child: const Text("Guardar Cambios", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
