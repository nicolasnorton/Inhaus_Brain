import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import '../../../core/services/integration_service.dart';
import '../../connectors/services/connected_accounts_service.dart';
import '../../connectors/models/connected_account_model.dart';
import '../../knowledge/services/knowledge_ingestion_service.dart';
import '../../knowledge/providers/knowledge_service_providers.dart';

class DataIngestionService {
  final IntegrationService _integrationService;
  final ConnectedAccountsService _accountsService;
  final KnowledgeIngestionService _knowledgeIngestion;
  final FirebaseFirestore _firestore;

  DataIngestionService({
    required IntegrationService integrationService,
    required ConnectedAccountsService accountsService,
    required KnowledgeIngestionService knowledgeIngestion,
    FirebaseFirestore? firestore,
  })  : _integrationService = integrationService,
        _accountsService = accountsService,
        _knowledgeIngestion = knowledgeIngestion,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Trigger a full sync for a specific client
  Future<Map<String, dynamic>> syncClientData(String clientId) async {
    debugPrint('DataIngestion: Starting sync for client $clientId');
    final results = <String, dynamic>{
      'success': true,
      'syncedAccounts': 0,
      'errors': [],
    };

    try {
      // 1. Get Accounts using the stream but taking just one snapshot
      final accounts = await _accountsService.getAccounts(clientId).first;
      
      if (accounts.isEmpty) {
        debugPrint('DataIngestion: No accounts found for client $clientId');
        return results;
      }

      // 2. Iterate and Sync
      for (final account in accounts) {
        if (account.status != AccountStatus.active) continue;

        try {
          await _syncAccount(account, clientId);
          results['syncedAccounts'] = (results['syncedAccounts'] as int) + 1;
        } catch (e) {
          debugPrint('DataIngestion: Error syncing account ${account.accountName}: $e');
          (results['errors'] as List).add({
            'accountId': account.id,
            'error': e.toString(),
          });
        }
      }
    } catch (e) {
      debugPrint('DataIngestion: Critical error: $e');
      results['success'] = false;
      results['criticalError'] = e.toString();
    }

    return results;
  }

  Future<void> _syncAccount(ConnectedAccount account, String clientId) async {
    // Define date range (e.g. last 30 days)
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));

    // 1. Pull Data
    final data = await _integrationService.syncDataForAccount(account, start, end);
    
    // 2. Store Raw Metrics in Firestore
    // Collection: clients/{clientId}/metrics/{timestamp}_{platform}_{accountId}
    final docId = '${end.millisecondsSinceEpoch}_${account.platform.name}_${account.id}';
    
    await _firestore
        .collection('clients')
        .doc(clientId)
        .collection('metrics')
        .doc(docId)
        .set({
      'accountId': account.id,
      'platform': account.platform.index,
      'syncedAt': FieldValue.serverTimestamp(),
      'data': data, // Verify this isn't too large for 1 doc (1MB limit)
    });

    // 3. Ingest into Knowledge Base (Semantic Search)
    // We convert the structured data into a compact text representation first
    final summary = _generateSummary(account, data);
    await _knowledgeIngestion.ingestPlatformData(account.platform, clientId, summary);
  }

  String _generateSummary(ConnectedAccount account, Map<String, dynamic> data) {
    // Create a natural language friendly summary for RAG
    final buffer = StringBuffer();
    buffer.writeln('Platform: ${account.platform.name}');
    buffer.writeln('Account: ${account.accountName}');
    buffer.writeln('Date Range: Last 30 Days');
    
    if (data.containsKey('insights')) {
      buffer.writeln('Key Insights: ${data['insights']}');
    }

    if (data.containsKey('campaigns')) {
      final campaigns = data['campaigns'] as List;
      buffer.writeln('Campaign Performance:');
      for (var c in campaigns) {
        buffer.writeln('- ${c['name']}: Spend \$${c['spend']}, ROAS ${c['roas']}');
      }
    }

    if (data.containsKey('posts')) {
      final posts = data['posts'] as List;
      buffer.writeln('Recent Posts:');
      for (var p in posts.take(5)) { // Top 5
        buffer.writeln('- "${p['caption']}": ${p['likes']} likes, ${p['impressions']} views');
      }
    }
    
    if (data.containsKey('report')) {
       final report = data['report'] as Map;
       if (report.containsKey('totals')) {
         buffer.writeln('Analytics Totals: ${report['totals']}');
       }
    }

    return buffer.toString();
  }
}

// Providers
final connectedAccountsServiceProvider = Provider<ConnectedAccountsService>((ref) {
  return ConnectedAccountsService();
});

final dataIngestionServiceProvider = Provider<DataIngestionService>((ref) {
  final integration = ref.watch(integrationServiceProvider);
  final accounts = ref.watch(connectedAccountsServiceProvider);
  final knowledge = ref.watch(knowledgeIngestionServiceProvider);
  
  return DataIngestionService(
    integrationService: integration,
    accountsService: accounts,
    knowledgeIngestion: knowledge,
  );
});
