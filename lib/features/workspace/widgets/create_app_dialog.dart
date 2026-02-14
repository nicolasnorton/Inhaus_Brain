import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../models/app_template.dart';
import '../data/app_templates_data.dart';
import '../providers/apps_provider.dart';
import '../../../core/adk/models/pipeline_models.dart';
import '../../adk/providers/pipeline_provider.dart';
import '../../adk/widgets/app_type_selector.dart';
import '../../adk/widgets/start_node_selector.dart';
import '../../adk/models/app_type_models.dart' as adk;

class CreateAppDialog extends ConsumerStatefulWidget {
  final AppTemplate? initialTemplate;
  const CreateAppDialog({super.key, this.initialTemplate});

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
  adk.StartNodeType _startNodeType = adk.StartNodeType.userInput;

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplate != null) {
      _selectedTemplate = widget.initialTemplate;
      _selectedType = widget.initialTemplate!.appType;
      _selectedIcon = widget.initialTemplate!.icon;
      _nameController.text = widget.initialTemplate!.name;
      _descriptionController.text = widget.initialTemplate!.description;
      _currentStep = 2; // Jump to configuration
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNext() {
    setState(() {
      // If we selected Chatflow or other non-workflow type, skip StartNodeSelector step (step 2)
      if (_currentStep == 1 && _selectedType != AppType.workflow) {
        _currentStep = 3;
      } else {
        _currentStep++;
      }
    });
  }

  void _onBack() {
    setState(() {
      if (_currentStep == 3 && _selectedType != AppType.workflow) {
        _currentStep = 1;
      } else {
        _currentStep--;
      }
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

    // Initialize Pipeline
    List<PipelineStep> initialSteps = [];
    if (_selectedTemplate != null && _selectedTemplate!.pipelineSteps != null) {
      initialSteps = _selectedTemplate!.pipelineSteps!;
    } else {
      // Default nodes based on type
      if (_selectedType == AppType.workflow) {
        if (_startNodeType == adk.StartNodeType.userInput) {
          initialSteps = [
            PipelineStep(
              id: 'start-node',
              nodeType: WorkflowNodeType.userInput,
              instruction: 'User Input',
              uiPosition: {'x': 100, 'y': 200},
              config: {'fields': []},
            ),
          ];
        } else {
          initialSteps = [
            PipelineStep(
              id: 'start-node',
              nodeType: WorkflowNodeType.trigger,
              instruction: 'Trigger',
              uiPosition: {'x': 100, 'y': 200},
              config: {'trigger_type': 'Schedule'},
            ),
          ];
        }
      } else if (_selectedType == AppType.chatflow || _selectedType == AppType.chatbot) {
        initialSteps = [
          PipelineStep(
            id: 'start-node',
            nodeType: WorkflowNodeType.start,
            instruction: 'Start',
            uiPosition: {'x': 100, 'y': 200},
            config: {'fields': []},
          ),
          PipelineStep(
            id: 'llm-node',
            nodeType: WorkflowNodeType.llm,
            instruction: 'LLM',
            uiPosition: {'x': 400, 'y': 200},
            config: {'model': 'gemini-3-pro-preview'},
          ),
          PipelineStep(
            id: 'answer-node',
            nodeType: WorkflowNodeType.answer, 
            instruction: 'Answer',
            uiPosition: {'x': 700, 'y': 200},
            config: {},
          ),
        ];
      } else if (_selectedType == AppType.agent) {
         initialSteps = [
          PipelineStep(
            id: 'start-node',
            nodeType: WorkflowNodeType.start,
            instruction: 'Start',
            uiPosition: {'x': 100, 'y': 200},
            config: {'fields': []},
          ),
          PipelineStep(
            id: 'agent-node', 
            nodeType: WorkflowNodeType.agent, // Assuming agent node exists or generic LLM
            instruction: 'Agent',
            uiPosition: {'x': 400, 'y': 200},
            config: {'mode': 'agent', 'tools': ['search', 'calculator']},
          ),
        ];
      } else if (_selectedType == AppType.textGenerator) {
        initialSteps = [
           PipelineStep(
            id: 'start-node',
            nodeType: WorkflowNodeType.userInput,
            instruction: 'User Input',
            uiPosition: {'x': 100, 'y': 200},
            config: {'fields': []},
          ),
           PipelineStep(
            id: 'generator-node',
            nodeType: WorkflowNodeType.llm,
            instruction: 'Text Generator',
            uiPosition: {'x': 400, 'y': 200},
            config: {'model': 'gemini-pro'},
          ),
        ];
      }
    }

    if (initialSteps.isNotEmpty) {
      final newPipeline = Pipeline(
        id: id,
        name: newApp.name,
        description: newApp.description,
        steps: initialSteps,
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
                    : (_currentStep == 1 
                        ? 'Choose App Type' 
                        : (_currentStep == 2 ? 'Start Point' : 'Configure App')),
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
                    : (_currentStep == 2
                        ? 'Define how your workflow begins'
                        : 'Set the basic information for your ${_selectedType?.displayName}')),
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
                         _onNext(); 
                      } else if (_currentStep == 1 && _selectedType != null) {
                        _onNext();
                      } else if (_currentStep == 2) {
                        _onNext();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_currentStep == 0 ? 'Start from Scratch' : (_currentStep == 2 ? 'Continue' : 'Next')),
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
    } else if (_currentStep == 2) {
      return _buildStartNodeSelection();
    } else {
      return _buildAppConfiguration();
    }
  }

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Retail',
    'Media & Entertainment',
    'Automotive & Logistics',
    'Financial Services',
    'Healthcare & Life Sciences',
    'Telecommunications',
    'Travel & Hospitality',
    'Manufacturing & Energy',
    'Public Sector',
    'Productivity',
    'Other'
  ];

  Widget _buildTemplateSelection() {
    // 1. Get all templates (including new blueprints)
    final allTemplates = AppTemplatesData.allTemplates;

    // 2. Filter by category
    final filteredTemplates = _selectedCategory == 'All'
        ? allTemplates
        : allTemplates.where((t) {
            // Check if our special blueprint format (Industry: Description) matches
            if (t.description.startsWith('$_selectedCategory:')) {
              return true;
            }
            // For standard templates with no specific format, keep them in 'Other' or just All
             if (_selectedCategory == 'Other' && !t.description.contains(':')) {
               return true;
            }
            return false;
          }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Sidebar
        Container(
          width: 200,
          margin: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              return ListTile(
                title: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.blueAccent : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedTileColor: Colors.blueAccent.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () => setState(() => _selectedCategory = category),
                dense: true,
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),

        // Template Grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: filteredTemplates.length,
            itemBuilder: (context, index) {
              return _buildTemplateCard(filteredTemplates[index]);
            },
          ),
        ),
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
          _selectedTemplate = template; // Track the template!
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
                      fontSize: 14,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                template.description,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
             const SizedBox(height: 8),
             // Industry Tag (if applicable)
             if (template.description.contains(':'))
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(
                   color: Colors.blueAccent.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(4),
                   border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                 ),
                 child: Text(
                   template.description.split(':').first,
                   style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
                   maxLines: 1,
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

  Widget _buildStartNodeSelection() {
    return SingleChildScrollView(
      child: StartNodeSelector(
        onTypeSelected: (adk.StartNodeType type) {
          setState(() {
            _startNodeType = type;
          });
        },
      ),
    );
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text('Choose Icon', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.count(
            crossAxisCount: 5,
            padding: const EdgeInsets.all(8),
            children: [
              '🤖', '🧠', '💼', '🎨', '📝', 
              '📊', '🔐', '🌐', '🎮', '🎵',
              '🎥', '⚙️', '🔍', '💡', '💬',
              '🚀', '⭐', '🔥', '❤️', '✅'
            ].map((emoji) => InkWell(
              onTap: () {
                setState(() => _selectedIcon = emoji);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedIcon == emoji ? Colors.blueAccent.withValues(alpha: 0.3) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            )).toList(),
          ),
        ),
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
                  color: Colors.white.withValues(alpha: 0.05),
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
                onPressed: _showIconPicker, // Connect the new picker
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
              fillColor: Colors.white.withValues(alpha: 0.05),
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
              fillColor: Colors.white.withValues(alpha: 0.05),
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
