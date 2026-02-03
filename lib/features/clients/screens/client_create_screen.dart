import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import '../providers/client_provider.dart';
import '../models/client_model.dart';

class ClientCreateScreen extends ConsumerStatefulWidget {
  const ClientCreateScreen({super.key});

  @override
  ConsumerState<ClientCreateScreen> createState() => _ClientCreateScreenState();
}

class _ClientCreateScreenState extends ConsumerState<ClientCreateScreen> {
  int _currentStep = 0;
  ClientType _selectedType = ClientType.corporate;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _industryController = TextEditingController(); // Used as Profession for Independent
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _fiscalAddressController = TextEditingController();
  final _sizeController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _birthDate;

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _fiscalAddressController.dispose();
    _sizeController.dispose();
    _legalNameController.dispose();
    _taxIdController.dispose();
    _portfolioController.dispose();
    _linkedinController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await ref.read(clientProvider.notifier).addClient(
          name: _nameController.text.trim(),
          clientType: _selectedType,
          industry: _industryController.text.trim(),
          email: _emailController.text.trim(),
          website: _websiteController.text.trim(),
          address: _addressController.text.trim(),
          fiscalAddress: _fiscalAddressController.text.trim(),
          size: _sizeController.text.trim(),
          description: _descController.text.trim(),
          legalName: _legalNameController.text.trim(),
          taxId: _taxIdController.text.trim(),
          profession: _selectedType == ClientType.independent ? _industryController.text.trim() : null,
          personalTaxId: _selectedType == ClientType.independent ? _taxIdController.text.trim() : null,
          portfolioUrl: _portfolioController.text.trim(),
          linkedinUrl: _linkedinController.text.trim(),
          birthDate: _birthDate,
        );
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_currentStep == 0 ? 'Select Client Type' : 'New Client Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentStep == 0 ? _buildTypeSelection() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'What type of client are you onboarding?',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        _buildTypeCard(
          icon: FontAwesomeIcons.building,
          title: 'Corporate Client',
          description: 'Company, Agency, or Organization',
          isSelected: _selectedType == ClientType.corporate,
          onTap: () => setState(() => _selectedType = ClientType.corporate),
        ),
        const SizedBox(height: 24),
        _buildTypeCard(
          icon: FontAwesomeIcons.userTie,
          title: 'Independent Professional',
          description: 'Freelancer, Consultant, or Solo Artist',
          isSelected: _selectedType == ClientType.independent,
          onTap: () => setState(() => _selectedType = ClientType.independent),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('CONTINUE'),
        ),
      ],
    );
  }

  Widget _buildTypeCard({required IconData icon, required String title, required String description, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, color: isSelected ? Colors.white : Colors.white54, size: 24),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final isCorporate = _selectedType == ClientType.corporate;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        key: const ValueKey('step2'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Basic Info'),
            _buildTextField(isCorporate ? 'Company Name' : 'Full Name', _nameController, isRequired: true),
            const SizedBox(height: 16),
            _buildTextField(isCorporate ? 'Industry' : 'Profession/Title', _industryController, isRequired: true),
            const SizedBox(height: 32),

            _buildSectionHeader('Legal & Fiscal'),
            _buildTextField(isCorporate ? 'Legal Name (Razón Social)' : 'Legal Full Name', _legalNameController, isRequired: true),
            const SizedBox(height: 16),
            _buildTextField(isCorporate ? 'Tax ID (RUC)' : 'Personal Tax ID (Cédula/RUC)', _taxIdController, isRequired: true),
            const SizedBox(height: 16),
            _buildTextField('Fiscal Address', _fiscalAddressController),
            const SizedBox(height: 32),

            _buildSectionHeader('Contact & Profile'),
            _buildTextField('Primary Email', _emailController),
            const SizedBox(height: 16),
            if (isCorporate) ...[
              _buildTextField('Website', _websiteController),
              const SizedBox(height: 16),
              _buildTextField('Office Address', _addressController),
              const SizedBox(height: 16),
              _buildTextField('Company Size (Employees)', _sizeController),
            ] else ...[
              _buildTextField('Portfolio URL', _portfolioController),
              const SizedBox(height: 16),
              _buildTextField('LinkedIn Profile', _linkedinController),
              const SizedBox(height: 16),
              // Birthdate picker could go here
            ],
            const SizedBox(height: 16),
            _buildTextField('Description / Notes', _descController, maxLines: 3),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('CREATE CLIENT'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: isRequired ? (value) => (value == null || value.isEmpty) ? 'Required' : null : null,
    );
  }
}
