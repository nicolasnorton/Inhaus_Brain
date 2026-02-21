
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../../../core/services/ai_proxy_service.dart';
import '../../../core/tokens/llm_provider.dart';

class ReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  /// Get stream of reports for a specific client (or user).
  /// For Inhaus Brain, we might filter by clientId.
  Stream<List<Report>> getReports(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Report.fromJson(doc.data()))
          .toList();
    });
  }

  /// Get a single report by ID.
  Future<Report?> getReport(String reportId) async {
    final doc = await _firestore.collection(_collection).doc(reportId).get();
    if (doc.exists && doc.data() != null) {
      return Report.fromJson(doc.data()!);
    }
    return null;
  }

  /// Create a new report.
  Future<void> createReport(Report report) async {
    await _firestore.collection(_collection).doc(report.id).set(report.toJson());
  }

  /// Update an existing report (e.g. adding sources).
  Future<void> updateReport(Report report) async {
    await _firestore
        .collection(_collection)
        .doc(report.id)
        .update(report.toJson());
  }
  
  /// Delete a report
  Future<void> deleteReport(String reportId) async {
    await _firestore.collection(_collection).doc(reportId).delete();
  }

  /// PROD-GRADE: Generate a report using Deep Research + Strict Schema (Gemini 3 Pro)
  Future<Report> generateReport({
    required String title,
    required String prompt,
    required String userId, // Keep for potential future use or logging
    required String clientId,
    bool useDeepResearch = false,
  }) async {
    String content = "";

    // 1. Gather Data (Deep Research or Standard Search)
    if (useDeepResearch) {
        final researchPrompt = "Deep Research Task: $prompt\n\nObjective: Gather comprehensive data for a $title report.";
        final interaction = await AIProxyService.startResearch(prompt: researchPrompt);
        final id = interaction['interactionId'];
        
        // Poll until done
        int attempts = 0;
        while (attempts < 60) {
          await Future.delayed(const Duration(seconds: 5));
          final res = await AIProxyService.pollResearch(id);
          final status = (res['status'] ?? 'unknown').toString().toLowerCase();
          
          if (status == 'completed' || status == 'complete') {
            // New Interaction API returns 'outputs' (list)
            if (res['outputs'] != null && (res['outputs'] as List).isNotEmpty) {
                final List<dynamic> outputs = res['outputs'];
                // Join all text outputs
                content = outputs
                    .where((o) => o['type'] == 'text')
                    .map((o) => o['text'] ?? '')
                    .join('\n\n');
                
                if (content.isEmpty) {
                    // Fallback: check if metadata or thought blocks have anything
                    content = outputs
                        .map((o) => o['text'] ?? o['thought'] ?? '')
                        .join('\n\n');
                }
            } else if (res['output'] != null) {
                // Legacy fallback
                content = res['output'];
            }
            break;
          }
          attempts++;
        }
    } else {
      // Standard Gemini 3 Pro with Search
       final config = AIModelConfig.geminiResearch;
       final res = await AIProxyService.generateContent(
         prompt: prompt,
         config: config,
         usePython: true
       );
       // Handle candidates safely
       if (res['candidates'] != null && (res['candidates'] as List).isNotEmpty) {
           content = res['candidates'][0]['content']['parts'][0]['text'];
       } else {
           content = "No data found.";
       }
    }

    // 2. Format with Strict Schema (Gemini 3 Pro JSON Mode)
    final strictPrompt = """
    You are an expert analyst. Convert the following research data into a strictly structured JSON report.
    
    RESEARCH DATA:
    $content
    
    OUTPUT SCHEMA (JSON):
    {
      "executive_summary": "string",
      "key_insights": ["string"],
      "strategic_recommendations": ["string"],
      "detailed_analysis": "markdown_string",
      "metrics": [{"name": "string", "value": "string", "trend": "up|down|flat"}]
    }
    """;

    final formatConfig = AIModelConfig.geminiPro.copyWith(
      responseMimeType: 'application/json'
    );
    
    final formattedRes = await AIProxyService.generateContent(
      prompt: strictPrompt,
      config: formatConfig,
      usePython: true
    );
    
    String jsonText = "{}";
    if (formattedRes['candidates'] != null && (formattedRes['candidates'] as List).isNotEmpty) {
        jsonText = formattedRes['candidates'][0]['content']['parts'][0]['text'];
    }
    
    // 3. Create Report Object
    final now = DateTime.now();
    final reportId = const Uuid().v4();
    
    final newReport = Report(
      id: reportId,
      title: title,
      clientId: clientId,
      createdAt: now,
      updatedAt: now,
      outputs: [
          ReportOutput(
              id: "${reportId}_out_1",
              title: "Analysis JSON",
              type: ReportOutputType.text, // Using text to store JSON
              content: jsonText,
              createdAt: now
          )
      ]
    );

    await createReport(newReport);
    return newReport;
  }
}

