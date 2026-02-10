import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:form_builder_validators/form_builder_validators.dart'; // Optional validation

class DynamicFormWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final _formKey = GlobalKey<FormBuilderState>();

  DynamicFormWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Intake Form';
    final fields = data['fields'] as List<dynamic>? ?? [];
    final submitLabel = data['submit_label'] ?? 'Submit';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          FormBuilder(
            key: _formKey,
            child: Column(
              children: fields.map<Widget>((field) {
                final name = field['name'] ?? 'unknown';
                final label = field['label'] ?? name;
                final type = field['type'] ?? 'text';
                
                // Common decoration
                final decoration = InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  filled: true,
                  fillColor: Colors.black12,
                );

                Widget inputWidget;
                switch (type) {
                  case 'number':
                    inputWidget = FormBuilderTextField(
                      name: name,
                      decoration: decoration,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                    );
                    break;
                  case 'date':
                   inputWidget = FormBuilderDateTimePicker(
                      name: name,
                      decoration: decoration,
                      inputType: InputType.date,
                      style: const TextStyle(color: Colors.white),
                    );
                    break;
                  case 'checkbox_group':
                    final options = (field['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
                    inputWidget = FormBuilderCheckboxGroup(
                      name: name,
                      decoration: decoration.copyWith(border: InputBorder.none, enabledBorder: InputBorder.none),
                      options: options.map((opt) => FormBuilderFieldOption(value: opt, child: Text(opt, style: const TextStyle(color: Colors.white)))).toList(),
                    );
                    break;
                  case 'dropdown':
                    final options = (field['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
                    inputWidget = FormBuilderDropdown(
                      name: name,
                      decoration: decoration,
                       dropdownColor: const Color(0xFF2D333B),
                       style: const TextStyle(color: Colors.white),
                      items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                    );
                    break;
                  case 'text':
                  default:
                    inputWidget = FormBuilderTextField(
                      name: name,
                      decoration: decoration,
                      style: const TextStyle(color: Colors.white),
                      maxLines: field['maxLines'] ?? 1,
                    );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: inputWidget,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.saveAndValidate() ?? false) {
                  debugPrint(_formKey.currentState?.value.toString());
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing input... (Demo)")));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}
