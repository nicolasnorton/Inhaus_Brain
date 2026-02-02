import '../models/connected_account_model.dart';

class UnifiedPost {
  final String id;
  final String connectedAccountId;
  final AdPlatform platform;
  final String? caption;
  final String? mediaUrl;
  final String? permalink;
  final DateTime publishedAt;
  
  // Metrics
  final int impressions;
  final int reach;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final int clicks;
  final double engagementRate;

  UnifiedPost({
    required this.id,
    required this.connectedAccountId,
    required this.platform,
    this.caption,
    this.mediaUrl,
    this.permalink,
    required this.publishedAt,
    this.impressions = 0,
    this.reach = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.clicks = 0,
    this.engagementRate = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connectedAccountId': connectedAccountId,
      'platform': platform.index,
      'caption': caption,
      'mediaUrl': mediaUrl,
      'permalink': permalink,
      'publishedAt': publishedAt.toIso8601String(),
      'impressions': impressions,
      'reach': reach,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'saves': saves,
      'clicks': clicks,
      'engagementRate': engagementRate,
    };
  }

  factory UnifiedPost.fromJson(Map<String, dynamic> json) {
    return UnifiedPost(
      id: json['id'],
      connectedAccountId: json['connectedAccountId'],
      platform: AdPlatform.values[json['platform'] ?? 0],
      caption: json['caption'],
      mediaUrl: json['mediaUrl'],
      permalink: json['permalink'],
      publishedAt: DateTime.parse(json['publishedAt']),
      impressions: json['impressions'] ?? 0,
      reach: json['reach'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      saves: json['saves'] ?? 0,
      clicks: json['clicks'] ?? 0,
      engagementRate: (json['engagementRate'] ?? 0.0).toDouble(),
    );
  }
}
