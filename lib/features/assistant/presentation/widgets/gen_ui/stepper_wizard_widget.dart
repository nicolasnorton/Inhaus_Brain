import 'package:flutter/material.dart';
import 'package:im_stepper/stepper.dart';

class StepperWizardWidget extends StatefulWidget {
  final Map<String, dynamic> data;

  const StepperWizardWidget({super.key, required this.data});

  @override
  State<StepperWizardWidget> createState() => _StepperWizardWidgetState();
}

class _StepperWizardWidgetState extends State<StepperWizardWidget> {
  int _activeStep = 0;
  List<dynamic> _steps = [];

  @override
  void initState() {
    super.initState();
    _steps = widget.data['steps'] ?? [];
    _activeStep = (widget.data['current_step_index'] ?? 0).clamp(0, (_steps.length - 1).coerceAtLeast(0));
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) return const SizedBox.shrink();

    final currentStepData = _steps[_activeStep];
    final title = currentStepData['title'] ?? 'Step ${_activeStep + 1}';
    final content = currentStepData['content'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                 'Workflow: ${widget.data['title'] ?? 'Guided Process'}',
                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
               ),
               Text(
                 '${_activeStep + 1}/${_steps.length}',
                 style: const TextStyle(fontSize: 14, color: Colors.white38),
               ),
            ],
          ),
          const SizedBox(height: 16),

          // Stepper
          IconStepper(
            icons: _steps.map((s) => Icon(s['icon'] != null ? IconData(s['icon'], fontFamily: 'MaterialIcons') : Icons.circle)).toList(),
            activeStep: _activeStep,
            onStepReached: (index) {
              setState(() {
                _activeStep = index;
              });
            },
            activeStepColor: Colors.blueAccent,
            stepColor: Colors.white24,
            lineColor: Colors.white10,
            activeStepBorderColor: Colors.blueAccent,
            stepRadius: 16,
          ),
          
          const SizedBox(height: 24),

          // Content Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D333B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            constraints: const BoxConstraints(minHeight: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                ),
                
                // Action Buttons (Next/Back)
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_activeStep > 0)
                      TextButton(
                        onPressed: () => setState(() => _activeStep--),
                        child: const Text('Back'),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_activeStep < _steps.length - 1) {
                          setState(() => _activeStep++);
                        } else {
                          // Finish logic
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Process Completed!")));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _activeStep == _steps.length - 1 ? Colors.green : Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_activeStep == _steps.length - 1 ? 'Finish' : 'Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension CoerceAtLeast on int {
  int coerceAtLeast(int min) => this < min ? min : this;
}
