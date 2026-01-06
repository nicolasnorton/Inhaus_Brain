class Client {
  final String id;
  final String name;
  final String industry;
  final String? logoUrl;
  final List<String> campaignIds;
  final String? primaryContactEmail;

  Client({
    required this.id,
    required this.name,
    required this.industry,
    this.logoUrl,
    this.campaignIds = const [],
    this.primaryContactEmail,
  });

  Client copyWith({
    String? name,
    String? industry,
    String? logoUrl,
    List<String>? campaignIds,
    String? primaryContactEmail,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      logoUrl: logoUrl ?? this.logoUrl,
      campaignIds: campaignIds ?? this.campaignIds,
      primaryContactEmail: primaryContactEmail ?? this.primaryContactEmail,
    );
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      name: json['name'] as String,
      industry: json['industry'] as String,
      logoUrl: json['logoUrl'] as String?,
      campaignIds: (json['campaignIds'] as List? ?? []).cast<String>(),
      primaryContactEmail: json['primaryContactEmail'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'industry': industry,
    'logoUrl': logoUrl,
    'campaignIds': campaignIds,
    'primaryContactEmail': primaryContactEmail,
  };
}
