import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../models/finance_model.dart';

class FinanceService {
  
  // --- SYSTEM PROMPTS (Specialized for Ecuador) ---

  static String _financeAnalystPrompt(String context) => """
You are the **Chief Financial Officer (CFO)** and **Lead Accountant** for 'Inhaus', a creative agency in Ecuador.
You are an expert in:
1.  **Ecuadorian Tax Law (SRI)**: You know LORTI (Ley de Régimen Tributario Interno), VAT (IVA 15%), Retentions (Retenciones en la Fuente), and deductions.
2.  **Agency Finance**: You follow GAAP but optimized for a service-based agency (high payroll, variable ad spend).
3.  **Ad Spend Optimization**: You analyze campaign ROI.

Your goal is to provide **accurate, actionable, and legally compliant** financial advice.

**Context Data (Transactions & Reports):**
$context

**Tone**: Professional, analytical, trustworthy. Use Spanish terminology for tax concepts (e.g., "Factura", "Retención", "Gasto Deducible") even if speaking English, or clarify them.
""";

  static String _transactionCategorizerPrompt(String rawText) => """
You are a data entry automation bot. Analyze the detailed text from a receipt or bank statement and extract the transaction details.
Map categories to: Ad Spend, Software, Payroll, Rent, Utilities, Office Supplies, Travel, Taxes SRI, Other.

Input Text:
$rawText

Output JSON:
{
  "title": "Short description",
  "amount": 0.00,
  "date": "YYYY-MM-DD",
  "type": "expense", 
  "category": "category_enum_string"
}
""";

  /// Analyzes a financial query using the provided context (transactions).
  static Stream<String> chatWithFinanceAgent(List<FinanceTransaction> transactions, String query, dynamic ref) async* {
     final context = _buildContextFromTransactions(transactions);
     
     final stream = EdgeAIService.generateTextStream(
       query,
       systemInstruction: _financeAnalystPrompt(context),
       config: AIModelConfig.geminiPro, // Use Pro for complex reasoning
       ref: ref
     );

     await for (final result in stream) {
        yield result.text;
     }
  }

  /// Parses raw text (e.g., PDF extract) into a structured Transaction.
  static Future<FinanceTransaction?> parseTransactionFromText(String text, dynamic ref) async {
    try {
      final res = await EdgeAIService.generateText(
        _transactionCategorizerPrompt(text),
        modelConfig: AIModelConfig.geminiFlash,
        outputMode: 'json',
        ref: ref,
      );
      
      // Basic JSON parsing (assuming EdgeAI returns clean JSON in code block)
      // Note: A real impl would use a robust JSON parser helper
      final cleanJson = res.text.replaceAll('```json', '').replaceAll('```', '').trim();
      // ... JSON parsing logic ...
      // For this step, we return null as we need a proper parser utility, 
      // but the prompt logic is here.
      return null; 
    } catch (e) {
      print("FinanceService: Parsing failed: $e");
      return null;
    }
  }

  static String _buildContextFromTransactions(List<FinanceTransaction> txs) {
    if (txs.isEmpty) return "No recent transactions available.";
    
    final buffer = StringBuffer();
    buffer.writeln("RECENT TRANSACTIONS (Last 30 Days):");
    
    // Sort by date desc
    final sorted = List<FinanceTransaction>.from(txs)..sort((a, b) => b.date.compareTo(a.date));
    
    for (var tx in sorted.take(50)) { // Limit context size
      buffer.writeln("- ${tx.date.toString().substring(0,10)} | ${tx.title} | \$${tx.amount.toStringAsFixed(2)} | ${tx.category?.name ?? 'Uncategorized'} | Type: ${tx.type.name}");
    }
    
    // Basic Aggregates
    double totalIncome = txs.where((t) => t.type == TransactionType.income).fold(0, (sum, t) => sum + t.amount);
    double totalExpense = txs.where((t) => t.type == TransactionType.expense).fold(0, (sum, t) => sum + t.amount);
    
    buffer.writeln("\nSUMMARY:");
    buffer.writeln("Total Income: \$$totalIncome");
    buffer.writeln("Total Expenses: \$$totalExpense");
    buffer.writeln("Net Cash Flow: \$${totalIncome - totalExpense}");
    
    return buffer.toString();
  }
}
