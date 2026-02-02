import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_model.dart';
import '../providers/client_provider.dart';

class ClientEditScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientEditScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientEditScreen> createState() => _ClientEditScreenState();
}

class _ClientEditScreenState extends ConsumerState<ClientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _industryController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  
  Map<String, dynamic> _customFields = {};
  final List<TextEditingController> _customKeyControllers = [];
  final List<TextEditingController> _customValueControllers = [];

  @override
  void initState() {
    super.initState();
    final clientState = ref.read(clientProvider);
    final client = clientState.clients.firstWhere((c) => c.id == widget.clientId);
    
    _nameController = TextEditingController(text: client.name);
    _industryController = TextEditingController(text: client.industry);
    _emailController = TextEditingController(text: client.primaryContactEmail ?? '');
    _websiteController = TextEditingController(text: client.website ?? '');
    _addressController = TextEditingController(text: client.address ?? '');
    _descriptionController = TextEditingController(text: client.description ?? '');
    
    _customFields = Map.from(client.customFields);
    _customFields.forEach((key, value) {
      _customKeyControllers.add(TextEditingController(text: key));
      _customValueControllers.add(TextEditingController(text: value.toString()));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    for (var c in _customKeyControllers) {
      c.dispose();
    }
    for (var c in _customValueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCustomField() {
    setState(() {
      _customKeyControllers.add(TextEditingController());
      _customValueControllers.add(TextEditingController());
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customKeyControllers.removeAt(index);
      _customValueControllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedCustomFields = <String, dynamic>{};
    for (int i = 0; i < _customKeyControllers.length; i++) {
      final key = _customKeyControllers[i].text.trim();
      final value = _customValueControllers[i].text.trim();
      if (key.isNotEmpty) {
        updatedCustomFields[key] = value;
      }
    }

    final clientState = ref.read(clientProvider);
    final client = clientState.clients.firstWhere((c) => c.id == widget.clientId);
    
    final updatedClient = client.copyWith(
      name: _nameController.text.trim(),
      industry: _industryController.text.trim(),
      primaryContactEmail: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      customFields: updatedCustomFields,
    );

    await ref.read(clientProvider.notifier).updateClient(updatedClient);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: AppBar(
        title: const Text('Edit Client Company Info'),
        backgroundColor: const Color(0xFF0F1116),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),
              _buildTextField('Client Name', _nameController, isRequired: true),
              const SizedBox(height: 16),
              _buildTextField('Industry', _industryController, isRequired: true),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Company Details'),
              _buildTextField('Contact Email', _emailController),
              const SizedBox(height: 16),
              _buildTextField('Website', _websiteController, hint: 'https://...'),
              const SizedBox(height: 16),
              _buildTextField('Office Address', _addressController),
              const SizedBox(height: 16),
              _buildTextField('Company Description', _descriptionController, maxLines: 3),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Custom Fields'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                    onPressed: _addCustomField,
                    tooltip: 'Add Custom Field',
                  ),
                ],
              ),
              const Text(
                'Add specific attributes like Taxes, Region, or Segment.',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildCustomFields(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, String? hint, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white38),
        hintStyle: const TextStyle(color: Colors.white12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: isRequired ? (value) => (value == null || value.isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _buildCustomFields() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _customKeyControllers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField('Field Name (e.g. VAT)', _customKeyControllers[index]),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildTextField('Value', _customValueControllers[index]),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _removeCustomField(index),
            ),
          ],
        );
      },
    );
  }
}
