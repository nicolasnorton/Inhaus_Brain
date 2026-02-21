import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../agency/models/agency_service_model.dart';
import '../../agency/providers/service_catalog_riverpod_provider.dart';
import '../providers/proposal_session_provider.dart';

class CreatePackageModal extends ConsumerStatefulWidget {
  const CreatePackageModal({super.key});

  @override
  ConsumerState<CreatePackageModal> createState() => _CreatePackageModalState();
}

class _CreatePackageModalState extends ConsumerState<CreatePackageModal> {
  int _currentStep = 0;
  
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  
  String _category = 'Estudio';
  String _frequency = 'Pago único';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      if (_currentStep == 0 && _nameController.text.isEmpty) return;
      if (_currentStep == 1 && _priceController.text.isEmpty) return;
      
      setState(() => _currentStep++);
    } else {
      _savePackage();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _savePackage() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;
    
    setState(() => _isSaving = true);
    
    try {
      final basePrice = double.tryParse(_priceController.text) ?? 0.0;
      
      final newService = AgencyService.create(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: 'USD ${basePrice.toStringAsFixed(2)}',
        basePrice: basePrice,
        frequency: _frequency,
        metadata: {'category': _category},
      );
      
      // Save it to firestore
      final serviceCatalog = ref.read(serviceCatalogRepositoryProvider);
      await serviceCatalog.addService(newService);
      
      // Invalidate the catalog so it refreshes
      ref.invalidate(servicesListProvider);
      ref.invalidate(serviceCatalogProvider);
      
      // Add it to the current proposal session automatically
      ref.read(proposalSessionProvider.notifier).addService(newService);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${newService.name} creado y agregado a la cotización."), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al crear paquete: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primary),
                    SizedBox(width: 12),
                    Text("Crear Paquete", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white24),
            
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildStep(
                    title: "¿Cómo se llama el nuevo paquete?",
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: "Ej. Paquete Branding Pro",
                        hintStyle: TextStyle(color: Colors.white24),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                      ),
                      autofocus: true,
                    ),
                  ),
                  _buildStep(
                    title: "¿Cuál es el precio base?",
                    child: Column(
                      children: [
                        TextField(
                          controller: _priceController,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: "\$ ",
                            prefixStyle: TextStyle(color: Colors.white, fontSize: 18),
                            hintText: "1500",
                            hintStyle: TextStyle(color: Colors.white24),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                          ),
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _frequency,
                          dropdownColor: AppTheme.surface,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Tipo de cobro",
                            labelStyle: const TextStyle(color: Colors.white54),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                          ),
                          items: ["Pago único", "Mensual", "Anual"].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _frequency = val!),
                        ),
                      ],
                    ),
                  ),
                  _buildStep(
                    title: "¿A qué categoría pertenece?",
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: AppTheme.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                      ),
                      items: ["Estudio", "Media", "Producción", "Nuhaus"].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                  ),
                  _buildStep(
                    title: "Breve descripción de los entregables",
                    child: TextField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Incluye:\n- 12 Posts\n- 4 Reels\n...",
                        hintStyle: const TextStyle(color: Colors.white24),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                      ),
                      autofocus: true,
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Atrás"),
                    onPressed: _prevStep,
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  )
                else
                  const SizedBox(),
                  
                ElevatedButton(
                  onPressed: _isSaving ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_currentStep < 3 ? "Siguiente" : "Crear Paquete", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}
