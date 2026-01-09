import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workflow_execution_models.dart';
import '../providers/workflow_execution_provider.dart';

/// Text field with slash command variable insertion
class VariableTextField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;

  const VariableTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.onChanged,
  });

  @override
  ConsumerState<VariableTextField> createState() => _VariableTextFieldState();
}

class _VariableTextFieldState extends ConsumerState<VariableTextField> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  String _searchQuery = '';
  int _cursorPosition = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    if (!selection.isValid) return;
    
    _cursorPosition = selection.baseOffset;
    
    // Check if user typed / or {
    if (_cursorPosition > 0) {
      final charBefore = text[_cursorPosition - 1];
      if (charBefore == '/' || charBefore == '{') {
        _showVariableSuggestions();
      } else {
        // Update search query if overlay is showing
        if (_overlayEntry != null) {
          _updateSearchQuery(text);
        }
      }
    } else {
      _removeOverlay();
    }
  }

  void _updateSearchQuery(String text) {
    // Find the trigger character position
    int triggerPos = _cursorPosition - 1;
    while (triggerPos >= 0 && text[triggerPos] != '/' && text[triggerPos] != '{') {
      triggerPos--;
    }
    
    if (triggerPos >= 0) {
      _searchQuery = text.substring(triggerPos + 1, _cursorPosition).toLowerCase();
      _overlayEntry?.markNeedsBuild();
    } else {
      _removeOverlay();
    }
  }

  void _showVariableSuggestions() {
    _removeOverlay();
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry() {
    final availableVariables = ref.read(availableVariablesProvider);
    
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _buildSuggestionsList(availableVariables),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(List<VariableReference> variables) {
    final filtered = variables.where((v) {
      if (_searchQuery.isEmpty) return true;
      return v.displayName.toLowerCase().contains(_searchQuery) ||
          (v.description?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No variables found',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      shrinkWrap: true,
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final variable = filtered[index];
        return _buildSuggestionItem(variable);
      },
    );
  }

  Widget _buildSuggestionItem(VariableReference variable) {
    return InkWell(
      onTap: () => _insertVariable(variable),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Category icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _getCategoryColor(variable.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _getCategoryIcon(variable.category),
                size: 14,
                color: _getCategoryColor(variable.category),
              ),
            ),
            const SizedBox(width: 8),
            
            // Variable info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variable.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (variable.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      variable.description!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Data type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                variable.dataType,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _insertVariable(VariableReference variable) {
    final text = widget.controller.text;
    
    // Find the trigger character position
    int triggerPos = _cursorPosition - 1;
    while (triggerPos >= 0 && text[triggerPos] != '/' && text[triggerPos] != '{') {
      triggerPos--;
    }
    
    if (triggerPos >= 0) {
      // Replace from trigger to cursor with variable reference
      final before = text.substring(0, triggerPos);
      final after = text.substring(_cursorPosition);
      final newText = '$before${variable.reference}$after';
      
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: before.length + variable.reference.length,
        ),
      );
      
      widget.onChanged?.call(newText);
    }
    
    _removeOverlay();
    _focusNode.requestFocus();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchQuery = '';
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }

  IconData _getCategoryIcon(VariableCategory category) {
    switch (category) {
      case VariableCategory.system:
        return Icons.settings_outlined;
      case VariableCategory.input:
        return Icons.input_outlined;
      case VariableCategory.output:
        return Icons.output_outlined;
      case VariableCategory.conversation:
        return Icons.chat_bubble_outline;
      case VariableCategory.environment:
        return Icons.lock_outline;
    }
  }

  Color _getCategoryColor(VariableCategory category) {
    switch (category) {
      case VariableCategory.system:
        return const Color(0xFF8B5CF6);
      case VariableCategory.input:
        return const Color(0xFF3B82F6);
      case VariableCategory.output:
        return const Color(0xFF10B981);
      case VariableCategory.conversation:
        return const Color(0xFFF59E0B);
      case VariableCategory.environment:
        return const Color(0xFFEF4444);
    }
  }
}
