import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../models/app_template.dart';
import '../data/app_templates_data.dart';
import '../providers/apps_provider.dart';
import '../../../core/adk/models/pipeline_models.dart';
import '../../adk/providers/pipeline_provider.dart';
import '../../adk/widgets/app_type_selector.dart';

class CreateAppDialog extends ConsumerStatefulWidget {
  const CreateAppDialog({super.key});

  @override
  ConsumerState<CreateAppDialog> createState() => _CreateAppDialogState();
}

class _CreateAppDialogState extends ConsumerState<CreateAppDialog> {
  int _currentStep = 0;
  AppType? _selectedType;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedIcon = '🤖';
  AppTemplate? _selectedTemplate;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNext() {
    setState(() {
      _currentStep++;
    });
  }

  void _onBack() {
    setState(() {
      _currentStep--;
    });
  }

  void _onCreate() {
    if (_nameController.text.isEmpty || _selectedType == null) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final newApp = App(
      id: id,
      name: _nameController.text,
      type: _selectedType!,
      description: _descriptionController.text,
      icon: _selectedIcon,
      status: AppStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(appsProvider.notifier).createApp(newApp);

    // Initialize Pipeline if template selected
    if (_selectedTemplate != null && _selectedTemplate!.pipelineSteps != null) {
      final newPipeline = Pipeline(
        id: id,
        name: newApp.name,
        description: newApp.description,
        steps: _selectedTemplate!.pipelineSteps!,
      );
      ref.read(pipelineProvider.notifier).savePipeline(newPipeline);
    }
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('App "${newApp.name}" created form template'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C2128),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _currentStep == 0 
                    ? 'Start from Template' 
                    : (_currentStep == 1 ? 'Choose App Type' : 'Configure App'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currentStep == 0
                ? 'Select a template or start from scratch'
                : (_currentStep == 1
                    ? 'Choose an app type to get started'
                    : 'Set the basic information for your ${_selectedType?.displayName}'),
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _buildCurrentStep(),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _onBack,
                    child: const Text('Back'),
                  ),
                const SizedBox(width: 12),
                if (_currentStep < 2)
                  ElevatedButton(
                    onPressed: () {
                      // If step 0 and no template selected, go to type selection (scratch)
                      // If step 0 and template selected, skip type selection and go to config
                      if (_currentStep == 0) {
                         _onNext(); // Just proceed logic inside onNext handles skip
                      } else if (_currentStep == 1 && _selectedType != null) {
                        _onNext();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_currentStep == 0 ? 'Start from Scratch' : 'Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: _onCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Create App'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) {
      return _buildTemplateSelection();
    } else if (_currentStep == 1) {
      return _buildTypeSelection();
    } else {
      return _buildAppConfiguration();
    }
  }

  Widget _buildTemplateSelection() {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        // "From Scratch" Card (Implicitly just going next)
        // Actually, we list templates here.
        for (final template in AppTemplatesData.templates)
          _buildTemplateCard(template),
      ],
    );
  }

  Widget _buildTemplateCard(AppTemplate template) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = template.appType;
          _selectedIcon = template.icon;
          _nameController.text = template.name;
          _descriptionController.text = template.description;
          _currentStep = 2; // Skip direct to config
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(template.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                template.description,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return SingleChildScrollView(
      child: AppTypeSelector(
        selectedType: _selectedType,
        onTypeSelected: (AppType type) {
          setState(() {
            _selectedType = type;
            _selectedIcon = type.icon;
          });
        },
      ),
    );
  }

  Widget _buildAppConfiguration() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('App Icon', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Center(
                  child: Text(
                    _selectedIcon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  // TODO: Implement icon picker
                },
                child: const Text('Change Icon'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('App Name', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter app name...',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
            autofocus: true,
          ),
          const SizedBox(height: 32),
          const Text('Description (Optional)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'What does this app do?',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}
