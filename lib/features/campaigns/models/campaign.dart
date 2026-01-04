enum CampaignStatus {
  draft,
  researching,
  designing,
  inProduction,
  published,
  archived
}

class Campaign {
  final String id;
  final String title;
  final String description;
  final String? clientName;
  final CampaignStatus status;
  final DateTime createdAt;

  Campaign({
    required this.id,
    required this.title,
    required this.description,
    this.clientName,
    this.status = CampaignStatus.draft,
    required this.createdAt,
  });

  Campaign copyWith({
    String? id,
    String? title,
    String? description,
    String? clientName,
    CampaignStatus? status,
    DateTime? createdAt,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
