import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/agency_service_model.dart';

class AgencyServiceForm extends StatefulWidget {
  final AgencyService? service;
  final Function(Map<String, dynamic>) onSave;

  const AgencyServiceForm({super.key, this.service, required this.onSave});

  @override
  State<AgencyServiceForm> createState() => _AgencyServiceFormState();
}

class _AgencyServiceFormState extends State<AgencyServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _basePriceController;
  late TextEditingController _costController;
  late TextEditingController _marginController;
  late TextEditingController _executionController;
  late TextEditingController _teamController;
  late TextEditingController _deliverablesController;
  late TextEditingController _includesController;
  late TextEditingController _excludesController;
  late TextEditingController _descriptionController;
  late ServiceType _type;
  late BillingCycle _billingCycle;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descriptionController = TextEditingController(text: widget.service?.description ?? '');
    _priceController = TextEditingController(text: widget.service?.price ?? '');
    _basePriceController = TextEditingController(text: widget.service?.basePrice.toString() ?? '');
    _costController = TextEditingController(text: widget.service?.deliveryCost.toString() ?? '');
    _marginController = TextEditingController(text: widget.service?.targetMargin.toString() ?? '35.0');
    _executionController = TextEditingController(text: widget.service?.execution ?? '');
    _teamController = TextEditingController(text: widget.service?.team.join(', ') ?? '');
    _deliverablesController = TextEditingController(text: widget.service?.deliverables.join(', ') ?? '');
    _includesController = TextEditingController(text: widget.service?.includes.join(', ') ?? '');
    _excludesController = TextEditingController(text: widget.service?.excludes.join(', ') ?? '');
    _type = widget.service?.type ?? ServiceType.individual;
    _billingCycle = widget.service?.billingCycle ?? BillingCycle.oneTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _basePriceController.dispose();
    _costController.dispose();
    _marginController.dispose();
    _executionController.dispose();
    _teamController.dispose();
    _deliverablesController.dispose();
    _includesController.dispose();
    _excludesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_nameController, "Service Name", "e.g., SEO Management / Gestión SEO"),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, "Description", "Brief overview of the service", maxLines: 2),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDropdown<ServiceType>("Type", _type, ServiceType.values, (val) => setState(() => _type = val!))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown<BillingCycle>("Billing", _billingCycle, BillingCycle.values, (val) => setState(() => _billingCycle = val!))),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_priceController, "Price Display String", "e.g., 1000.00-1500.00 or 1500.00"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildNumberField(_basePriceController, "Calc Price (\$)")),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_costController, "Delivery Cost (\$)")),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_marginController, "Target Margin (%)")),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_executionController, "Execution Details", "Describe how the service is delivered", maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(_teamController, "Team Members", "e.g., Designer, Developer, Project Manager", maxLines: 2),
            const SizedBox(height: 16),
            _buildTextField(_deliverablesController, "Deliverables", "e.g., Logo files, Brand guidelines, Social media templates", maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(_includesController, "Included", "e.g., 3 revision rounds, Source files, Brand guidelines", maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(_excludesController, "Not Included", "e.g., Printing costs, Stock photography, Domain registration", maxLines: 3),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: Text(widget.service == null ? "Create Service" : "Update Service"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white24),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
      ),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
      ),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDropdown<T extends Enum>(String label, T value, List<T> items, ValueChanged<T?> onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
      onChanged: onChanged,
      dropdownColor: AppTheme.surface,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      // Parse comma-separated values into lists
      List<String> parseCommaSeparated(String text) {
        return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }

      widget.onSave({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'type': _type.name,
        'price': _priceController.text,
        'basePrice': double.parse(_basePriceController.text),
        'deliveryCost': double.parse(_costController.text),
        'targetMargin': double.parse(_marginController.text),
        'execution': _executionController.text,
        'team': parseCommaSeparated(_teamController.text),
        'deliverables': parseCommaSeparated(_deliverablesController.text),
        'includes': parseCommaSeparated(_includesController.text),
        'excludes': parseCommaSeparated(_excludesController.text),
        'billingCycle': _billingCycle.name,
      });
    }
  }
}
