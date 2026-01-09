/// Flow logic node models

/// Comparison operator for conditions
enum ComparisonOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  contains,
  startsWith,
  endsWith;

  String get symbol {
    switch (this) {
      case ComparisonOperator.equals:
        return '==';
      case ComparisonOperator.notEquals:
        return '!=';
      case ComparisonOperator.greaterThan:
        return '>';
      case ComparisonOperator.lessThan:
        return '<';
      case ComparisonOperator.greaterOrEqual:
        return '>=';
      case ComparisonOperator.lessOrEqual:
        return '<=';
      case ComparisonOperator.contains:
        return 'contains';
      case ComparisonOperator.startsWith:
        return 'starts with';
      case ComparisonOperator.endsWith:
        return 'ends with';
    }
  }

  String get displayName {
    switch (this) {
      case ComparisonOperator.equals:
        return 'Equals';
      case ComparisonOperator.notEquals:
        return 'Not Equals';
      case ComparisonOperator.greaterThan:
        return 'Greater Than';
      case ComparisonOperator.lessThan:
        return 'Less Than';
      case ComparisonOperator.greaterOrEqual:
        return 'Greater or Equal';
      case ComparisonOperator.lessOrEqual:
        return 'Less or Equal';
      case ComparisonOperator.contains:
        return 'Contains';
      case ComparisonOperator.startsWith:
        return 'Starts With';
      case ComparisonOperator.endsWith:
        return 'Ends With';
    }
  }
}

/// Logical operator for combining conditions
enum LogicalOperator {
  and,
  or;

  String get displayName {
    switch (this) {
      case LogicalOperator.and:
        return 'AND';
      case LogicalOperator.or:
        return 'OR';
    }
  }
}

/// Single condition for IF/ELSE
class IfElseCondition {
  final String leftOperand;
  final ComparisonOperator operator;
  final String rightOperand;

  const IfElseCondition({
    required this.leftOperand,
    required this.operator,
    required this.rightOperand,
  });

  Map<String, dynamic> toJson() => {
        'left_operand': leftOperand,
        'operator': operator.name,
        'right_operand': rightOperand,
      };

  factory IfElseCondition.fromJson(Map<String, dynamic> json) {
    return IfElseCondition(
      leftOperand: json['left_operand'] as String,
      operator: ComparisonOperator.values.byName(json['operator'] as String),
      rightOperand: json['right_operand'] as String,
    );
  }

  /// Evaluate this condition
  bool evaluate(Map<String, dynamic> variables) {
    final left = _resolveValue(leftOperand, variables);
    final right = _resolveValue(rightOperand, variables);

    switch (operator) {
      case ComparisonOperator.equals:
        return left == right;
      case ComparisonOperator.notEquals:
        return left != right;
      case ComparisonOperator.greaterThan:
        return (left as num) > (right as num);
      case ComparisonOperator.lessThan:
        return (left as num) < (right as num);
      case ComparisonOperator.greaterOrEqual:
        return (left as num) >= (right as num);
      case ComparisonOperator.lessOrEqual:
        return (left as num) <= (right as num);
      case ComparisonOperator.contains:
        return (left as String).contains(right as String);
      case ComparisonOperator.startsWith:
        return (left as String).startsWith(right as String);
      case ComparisonOperator.endsWith:
        return (left as String).endsWith(right as String);
    }
  }

  dynamic _resolveValue(String value, Map<String, dynamic> variables) {
    // Check if it's a variable reference (e.g., {{variable}})
    if (value.startsWith('{{') && value.endsWith('}}')) {
      final varName = value.substring(2, value.length - 2);
      return variables[varName];
    }
    
    // Try to parse as number
    final num? numValue = num.tryParse(value);
    if (numValue != null) return numValue;
    
    // Try to parse as boolean
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    
    // Return as string
    return value;
  }
}

/// Enhanced IF/ELSE configuration
class EnhancedIfElseConfig {
  final List<IfElseCondition> conditions;
  final LogicalOperator logicalOperator;
  final String trueBranchId;
  final String falseBranchId;

  const EnhancedIfElseConfig({
    required this.conditions,
    required this.logicalOperator,
    required this.trueBranchId,
    required this.falseBranchId,
  });

  Map<String, dynamic> toJson() => {
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'logical_operator': logicalOperator.name,
        'true_branch_id': trueBranchId,
        'false_branch_id': falseBranchId,
      };

  factory EnhancedIfElseConfig.fromJson(Map<String, dynamic> json) {
    return EnhancedIfElseConfig(
      conditions: (json['conditions'] as List)
          .map((c) => IfElseCondition.fromJson(c as Map<String, dynamic>))
          .toList(),
      logicalOperator:
          LogicalOperator.values.byName(json['logical_operator'] as String),
      trueBranchId: json['true_branch_id'] as String,
      falseBranchId: json['false_branch_id'] as String,
    );
  }

  /// Evaluate all conditions
  bool evaluate(Map<String, dynamic> variables) {
    if (conditions.isEmpty) return false;

    if (logicalOperator == LogicalOperator.and) {
      return conditions.every((c) => c.evaluate(variables));
    } else {
      return conditions.any((c) => c.evaluate(variables));
    }
  }
}

/// Switch case
class SwitchCase {
  final String value;
  final String targetNodeId;

  const SwitchCase({
    required this.value,
    required this.targetNodeId,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'target_node_id': targetNodeId,
      };

  factory SwitchCase.fromJson(Map<String, dynamic> json) {
    return SwitchCase(
      value: json['value'] as String,
      targetNodeId: json['target_node_id'] as String,
    );
  }
}

/// Switch/Case configuration
class SwitchCaseConfig {
  final String variable;
  final List<SwitchCase> cases;
  final String defaultBranchId;

  const SwitchCaseConfig({
    required this.variable,
    required this.cases,
    required this.defaultBranchId,
  });

  Map<String, dynamic> toJson() => {
        'variable': variable,
        'cases': cases.map((c) => c.toJson()).toList(),
        'default_branch_id': defaultBranchId,
      };

  factory SwitchCaseConfig.fromJson(Map<String, dynamic> json) {
    return SwitchCaseConfig(
      variable: json['variable'] as String,
      cases: (json['cases'] as List)
          .map((c) => SwitchCase.fromJson(c as Map<String, dynamic>))
          .toList(),
      defaultBranchId: json['default_branch_id'] as String,
    );
  }

  /// Find matching case
  String findMatchingBranch(Map<String, dynamic> variables) {
    final value = _resolveVariable(variable, variables);
    
    for (final case_ in cases) {
      if (case_.value == value.toString()) {
        return case_.targetNodeId;
      }
    }
    
    return defaultBranchId;
  }

  dynamic _resolveVariable(String varName, Map<String, dynamic> variables) {
    if (varName.startsWith('{{') && varName.endsWith('}}')) {
      final name = varName.substring(2, varName.length - 2);
      return variables[name];
    }
    return varName;
  }
}

/// For Each loop configuration
class ForEachLoopConfig {
  final String arrayVariable;
  final String itemVariableName;
  final String? indexVariableName;
  final int maxIterations;
  final String? breakCondition;
  final String loopBodyBranchId;
  final String afterLoopBranchId;

  const ForEachLoopConfig({
    required this.arrayVariable,
    required this.itemVariableName,
    this.indexVariableName,
    this.maxIterations = 1000,
    this.breakCondition,
    required this.loopBodyBranchId,
    required this.afterLoopBranchId,
  });

  Map<String, dynamic> toJson() => {
        'array_variable': arrayVariable,
        'item_variable_name': itemVariableName,
        if (indexVariableName != null) 'index_variable_name': indexVariableName,
        'max_iterations': maxIterations,
        if (breakCondition != null) 'break_condition': breakCondition,
        'loop_body_branch_id': loopBodyBranchId,
        'after_loop_branch_id': afterLoopBranchId,
      };

  factory ForEachLoopConfig.fromJson(Map<String, dynamic> json) {
    return ForEachLoopConfig(
      arrayVariable: json['array_variable'] as String,
      itemVariableName: json['item_variable_name'] as String,
      indexVariableName: json['index_variable_name'] as String?,
      maxIterations: json['max_iterations'] as int? ?? 1000,
      breakCondition: json['break_condition'] as String?,
      loopBodyBranchId: json['loop_body_branch_id'] as String,
      afterLoopBranchId: json['after_loop_branch_id'] as String,
    );
  }
}

/// While loop configuration
class WhileLoopConfig {
  final String condition;
  final int maxIterations;
  final String counterVariableName;
  final String loopBodyBranchId;
  final String afterLoopBranchId;

  const WhileLoopConfig({
    required this.condition,
    this.maxIterations = 1000,
    required this.counterVariableName,
    required this.loopBodyBranchId,
    required this.afterLoopBranchId,
  });

  Map<String, dynamic> toJson() => {
        'condition': condition,
        'max_iterations': maxIterations,
        'counter_variable_name': counterVariableName,
        'loop_body_branch_id': loopBodyBranchId,
        'after_loop_branch_id': afterLoopBranchId,
      };

  factory WhileLoopConfig.fromJson(Map<String, dynamic> json) {
    return WhileLoopConfig(
      condition: json['condition'] as String,
      maxIterations: json['max_iterations'] as int? ?? 1000,
      counterVariableName: json['counter_variable_name'] as String,
      loopBodyBranchId: json['loop_body_branch_id'] as String,
      afterLoopBranchId: json['after_loop_branch_id'] as String,
    );
  }
}
