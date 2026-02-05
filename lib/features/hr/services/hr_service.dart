import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../models/hr_model.dart';

class HRService {
  
  // --- SYSTEM PROMPTS (Specialized for Ecuador) ---

  static String _hrDirectorPrompt(String context) => """
You are the **HR Director** for 'Inhaus', a creative agency in Ecuador.
You are an expert in:
1.  **Ecuadorian Labor Code (Código de Trabajo)**: You strictly adhere to local regulations regarding contracts, probation periods (90 days), 13th/14th salary (Décimos), IESS (Social Security), and termination rules (Desahucio, Visto Bueno).
2.  **Agency Culture**: You foster a creative, inclusive, and high-performance environment.
3.  **Soft Skills**: You provide coaching on leadership, communication, and conflict resolution.

Your goal is to provide **legally compliant** and **culturally positive** HR advice.

**Context Data (Employees & Docs):**
$context

**Tone**: Professional, empathetic, compliant. Use Spanish terminology for legal concepts (e.g., "Acta de Finiquito", "Roles de Pago", "IESS") even if speaking English.
""";

  /// Chat with the HR Expert.
  static Stream<String> chatWithHRAgent(List<Employee> employees, String query, dynamic ref) async* {
     final context = _buildContextFromEmployees(employees);
     
     final stream = EdgeAIService.generateTextStream(
       query,
       systemInstruction: _hrDirectorPrompt(context),
       config: AIModelConfig.geminiPro,
       ref: ref
     );

     await for (final result in stream) {
        yield result.text;
     }
  }

  static String _buildContextFromEmployees(List<Employee> employees) {
    if (employees.isEmpty) return "No employee records found.";
    
    final buffer = StringBuffer();
    buffer.writeln("ACTIVE TEAM ROSTER:");
    
    for (var e in employees) {
      buffer.writeln("- ${e.fullName} (${e.role}) | Dept: ${e.department.name} | Status: ${e.status.name} | Hired: ${e.hireDate.toString().substring(0,10)}");
    }
    
    return buffer.toString();
  }
}
