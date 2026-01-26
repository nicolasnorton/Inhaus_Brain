import '../../../core/adk/models/pipeline_models.dart';

class BudgetExceededException implements Exception {
  final String message;
  BudgetExceededException(this.message);
  @override
  String toString() => "BudgetExceeded: $message";
}

class BudgetGovernor {
  int _remainingCredits;
  final int _initialCredits;

  BudgetGovernor({int initialCredits = 100})
      : _remainingCredits = initialCredits,
        _initialCredits = initialCredits;

  int get remainingCredits => _remainingCredits;

  /// Check if sufficient credits exist for a given cost
  bool canAfford(int cost) {
    return _remainingCredits >= cost;
  }

  /// Debit credits. Throws if insufficient.
  void debit(int cost, String reason) {
    if (_remainingCredits < cost) {
      throw BudgetExceededException(
          "Insufficient credits for '$reason'. Cost: $cost, Remaining: $_remainingCredits");
    }
    _remainingCredits -= cost;
  }
  
  /// Determine cost for a node
  static int getCostForNode(WorkflowNodeType type) {
    switch (type) {
      case WorkflowNodeType.llm:
        return 1; // Basic generation
      case WorkflowNodeType.agent:
        return 3; // Agentic reasoning (cot)
      case WorkflowNodeType.trigger:
      case WorkflowNodeType.userInput:
      case WorkflowNodeType.ifElse:
      case WorkflowNodeType.loop:
      case WorkflowNodeType.start:
      case WorkflowNodeType.output:
      case WorkflowNodeType.answer:
      case WorkflowNodeType.variableAssigner:
        return 0; // Logic is free
      case WorkflowNodeType.knowledgeRetrieval:
        return 2; // Embedding search
      case WorkflowNodeType.tool:
        // Depends on tool? Assume average
        return 5; 
      // Hypothetical costly tools
      // case WorkflowNodeType.videoGen: return 20; 
      // case WorkflowNodeType.imageGen: return 5;
      default:
        return 1;
    }
  }

  void reset() {
    _remainingCredits = _initialCredits;
  }
}
