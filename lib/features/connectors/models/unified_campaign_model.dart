
import 'connected_account_model.dart';

class UnifiedCampaign {
  final String id;
  final String connectedAccountId;
  final AdPlatform platform;
  final String name;
  final String status; // 'ENABLED', 'PAUSED', 'REMOVED'
  final DateTime startDate;
  final DateTime? endDate;
  
  // Metrics
  final double budgetAmount;
  final double spend;
  final int impressions;
  final int clicks;
  final double ctr; // 0.0 to 1.0
  final double conversions;
  final double roas;

  UnifiedCampaign({
    required this.id,
    required this.connectedAccountId,
    required this.platform,
    required this.name,
    required this.status,
    required this.startDate,
    this.endDate,
    this.budgetAmount = 0.0,
    this.spend = 0.0,
    this.impressions = 0,
    this.clicks = 0,
    this.ctr = 0.0,
    this.conversions = 0.0,
    this.roas = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connectedAccountId': connectedAccountId,
      'platform': platform.index,
      'name': name,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'budgetAmount': budgetAmount,
      'spend': spend,
      'impressions': impressions,
      'clicks': clicks,
      'ctr': ctr,
      'conversions': conversions,
      'roas': roas,
    };
  }

  factory UnifiedCampaign.fromJson(Map<String, dynamic> json) {
    // Basic implementation - in reality, platform specific parsers map to this
    return UnifiedCampaign(
      id: json['id'],
      connectedAccountId: json['connectedAccountId'],
      platform: AdPlatform.values[json['platform'] ?? 0],
      name: json['name'],
      status: json['status'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble() ?? 0.0,
      spend: (json['spend'] as num?)?.toDouble() ?? 0.0,
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      ctr: (json['ctr'] as num?)?.toDouble() ?? 0.0,
      conversions: (json['conversions'] as num?)?.toDouble() ?? 0.0,
      roas: (json['roas'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
