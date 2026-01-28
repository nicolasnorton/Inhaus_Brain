import 'package:flutter/foundation.dart';
import '../../chat/agents/knowledge_librarian_agent.dart';
import 'knowledge_api_service.dart';

class KnowledgeLibrarianService {
  final KnowledgeLibrarianAgent _agent = KnowledgeLibrarianAgent();
  final KnowledgeApiService _knowledgeApi;

  KnowledgeLibrarianService(this._knowledgeApi);

  Future<void> performLibraryAudit() async {
    debugPrint('Librarian: Starting autonomous audit...');
    
    // 1. Fetch current datasets
    final datasets = await _knowledgeApi.listKnowledgeBases();
    
    // 2. Formulate audit prompt
    final prompt = "Audit the following datasets: ${datasets.map((d) => d.name).join(', ')}. Identify if we need new categories or reorganization.";
    
    // 3. Execute Librarian Agent
    final auditResult = await _agent.execute(
      userPrompt: prompt,
      context: [], // Can pass current directory or samples
    );
    
    debugPrint('Librarian Audit Result: $auditResult');
    
    // 4. In a real scenario, the service would then apply the Librarian's suggestions 
    // (e.g., delete redundant docs, rename datasets, etc.)
  }
}
