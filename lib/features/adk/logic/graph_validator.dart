import '../../../core/adk/models/pipeline_models.dart';
import '../models/workflow_execution_models.dart';

class GraphValidator {
  
  /// Validates a workflow graph for cycles, connectivity, and basic integrity.
  static ValidationResult validate(List<PipelineStep> steps) {
    final List<ValidationIssue> issues = [];
    
    if (steps.isEmpty) {
      return const ValidationResult(isValid: true, issues: []);
    }

    // 1. Cycle Detection (Topological integrity)
    final cycleIssues = _detectCycles(steps);
    issues.addAll(cycleIssues);

    // 2. Connectivity Check (Orphans)
    final connectivityIssues = _checkConnectivity(steps);
    issues.addAll(connectivityIssues);

    // 3. Dependency Existence Check
    final dependencyIssues = _checkDependenciesExist(steps);
    issues.addAll(dependencyIssues);
    
    // Future: Variable Validation (Fourth-Order)

    final hasErrors = issues.any((i) => i.severity == ValidationSeverity.error);
    return ValidationResult(isValid: !hasErrors, issues: issues);
  }

  static List<ValidationIssue> _detectCycles(List<PipelineStep> steps) {
    final issues = <ValidationIssue>[];
    final nodeMap = {for (var s in steps) s.id: s};
    final visited = <String>{}; // Currently visiting in recursion stack
    final processed = <String>{}; // Fully processed nodes

    // Helper for DFS
    bool visit(String nodeId, List<String> path) {
      if (processed.contains(nodeId)) return false;
      if (visited.contains(nodeId)) {
        // Cycle detected
        issues.add(ValidationIssue(
          nodeId: nodeId,
          nodeName: nodeMap[nodeId]?.label ?? nodeId,
          message: "Cycle detected involving this node. Path: ${path.join(' -> ')} -> $nodeId",
          severity: ValidationSeverity.error,
        ));
        return true;
      }

      visited.add(nodeId);
      path.add(nodeId);

      final node = nodeMap[nodeId];
      if (node != null) {
        // Find children (nodes that depend on this node)
        // Or traverse dependencies?
        // "Dependencies" field lists PARENTS. So "A depends on B". Arrow B -> A.
        // To detect cycles, we traverse dependencies (upstream). 
        // A cycle is A -> B -> A.
        // So validation logic: For each node, traverse specific directed edges.
        // Here dependencies are "upstream links". So we are traversing backwards.
        // A cycle in backward traversal is same as forward.
        
        for (final depId in node.dependencies) {
           if (visit(depId, path)) return true;
        }
      }

      visited.remove(nodeId);
      path.removeLast();
      processed.add(nodeId);
      return false;
    }

    for (final step in steps) {
      visit(step.id, []);
    }

    return issues;
  }

  static List<ValidationIssue> _checkConnectivity(List<PipelineStep> steps) {
    final issues = <ValidationIssue>[];
    // Definition of "Start": Node with no dependencies? 
    // Or explicit Start node.
    
    // Nodes unreachable from any "Start" are orphans?
    // Actually, in a dependency graph, execution flows from Dependency to Dependent.
    // If A depends on B. B must run before A.
    // Roots are nodes with No Dependencies. They can run immediately.
    // If we have a cycle, we handled it.
    
    // Is it possible to have a node that is not reachable?
    // In dependency logic, any node with valid dependencies will eventually run (unless infinite loop).
    // An "Orphan" in this UI might be a node that NO ONE depends on, AND is not an Output?
    // That's just dead code. Warning level.
    
    // Build reverse map: Parent -> Children
    final childrenMap = <String, List<String>>{};
    for (var step in steps) {
      for (var dep in step.dependencies) {
        childrenMap.putIfAbsent(dep, () => []).add(step.id);
      }
    }

    // Find "Leaf" nodes (no one depends on them).
    // If a Leaf is NOT an Output/End node, warn.
    for (var step in steps) {
       if (!childrenMap.containsKey(step.id) || childrenMap[step.id]!.isEmpty) {
          if (step.nodeType != WorkflowNodeType.output && step.nodeType != WorkflowNodeType.answer) {
             issues.add(ValidationIssue(
               nodeId: step.id,
               nodeName: step.label,
               message: "Dead end node. This node's output is not used by any other node, and it is not an Output node.",
               severity: ValidationSeverity.info,
             ));
          }
       }
    }

    return issues;
  }
  
  static List<ValidationIssue> _checkDependenciesExist(List<PipelineStep> steps) {
    final issues = <ValidationIssue>[];
    final ids = steps.map((s) => s.id).toSet();
    
    for (var step in steps) {
      for (var depId in step.dependencies) {
        if (!ids.contains(depId)) {
          issues.add(ValidationIssue(
            nodeId: step.id,
            nodeName: step.label,
            message: "Missing dependency: Node depends on ID '$depId' which does not exist.",
            severity: ValidationSeverity.error,
          ));
        }
      }
    }
    return issues;
  }
}
