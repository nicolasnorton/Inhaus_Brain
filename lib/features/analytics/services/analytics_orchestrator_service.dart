import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../agents/analytics_agents.dart';
import '../agents/dashboard_agent.dart';

class AnalyticsOrchestratorService {
  final PerformanceAnalystAgent _analyst = PerformanceAnalystAgent();
  final DataScientistAgent _scientist = DataScientistAgent();
  final DigitalStrategyAgent _strategist = DigitalStrategyAgent();
  final DashboardAgent _dashboardAgent = DashboardAgent();

  Future<Map<String, dynamic>> generateDashboard(String query) async {
    debugPrint('Analytics Orchestrator: Coordinating team for query: $query');
    
    // 1. Analyst processes the query
    final analystReport = await _analyst.execute(userPrompt: query, context: []);
    
    // 2. Scientist processes query + analyst report
    final scientistReport = await _scientist.execute(
      userPrompt: "Query: $query\nAnalyst Report: $analystReport", 
      context: [],
    );
    
    // 3. Strategist creates actions
    final strategyReport = await _strategist.execute(
      userPrompt: "Reports: Analyst: $analystReport, Scientist: $scientistReport",
      context: [],
    );
    
    // 4. Dashboard agent creates the UI
    final dashboardJsonString = await _dashboardAgent.execute(
      userPrompt: "Strategy: $strategyReport\nInsights: $analystReport",
      context: [],
    );
    
    try {
      // Find JSON block if it exists
      String cleanJson = dashboardJsonString.trim();
      final regex = RegExp(r'\{.*\}', dotAll: true);
      final match = regex.firstMatch(cleanJson);
      if (match != null) {
        cleanJson = match.group(0)!;
      }
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing dashboard JSON: $e');
      return {
        "title": "Error generating dashboard",
        "components": [
          {"type": "insight", "text": "Failed to generate dynamic dashboard. Using fallback UI."}
        ]
      };
    }
  }
}
