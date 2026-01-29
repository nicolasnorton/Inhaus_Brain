
enum AdPlatform {
  googleAds,
  googleAnalytics,
  googleSearchConsole,
  googleTrends,
  googleMaps,
  googleBusinessProfile,
  metaAds,
  facebookOrganic,
  instagramOrganic,
  tiktokAds,
  tiktokOrganic,
  twitterAds,
  twitterOrganic,
  linkedinAds,
  linkedinOrganic,
  pinterestAds,
  pinterestOrganic,
  appleSearchAds,
  notion,
  slack,
  goHighLevel,
  gmail,
  googleWorkspace,
  other
}

enum AccountStatus {
  active,
  needsRelink,
  revoked,
  error
}

class ConnectedAccount {
  final String id;
  final String clientId; // The Inhaus Client ID who owns this
  final AdPlatform platform;
  final String accountName; // e.g. "Nike US Google Ads"
  final String externalAccountId; // The ID on the platform (e.g. 123-456-7890)
  final String? accessToken; // Stored securely (in prod, maybe encrypted or excluded from client read)
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final AccountStatus status;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata; // Extra fields like 'propertyId', 'pixelId'

  ConnectedAccount({
    required this.id,
    required this.clientId,
    required this.platform,
    required this.accountName,
    required this.externalAccountId,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.status = AccountStatus.active,
    required this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'platform': platform.index,
      'accountName': accountName,
      'externalAccountId': externalAccountId,
      'accessToken': accessToken, // BEWARE: In real prod, exclude sensitive tokens from plain JSON log
      'refreshToken': refreshToken,
      'tokenExpiresAt': tokenExpiresAt?.toIso8601String(),
      'status': status.index,
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ConnectedAccount.fromJson(Map<String, dynamic> json) {
    return ConnectedAccount(
      id: json['id'],
      clientId: json['clientId'],
      platform: AdPlatform.values[json['platform'] ?? 0],
      accountName: json['accountName'] ?? 'Unknown Account',
      externalAccountId: json['externalAccountId'] ?? '',
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenExpiresAt: json['tokenExpiresAt'] != null 
          ? DateTime.parse(json['tokenExpiresAt']) 
          : null,
      status: AccountStatus.values[json['status'] ?? 0],
      updatedAt: DateTime.parse(json['updatedAt']),
      metadata: json['metadata'] ?? {},
    );
  }
}
