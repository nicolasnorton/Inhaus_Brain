enum CampaignStatus {
  draft,
  researching,
  designing,
  inProduction,
  published,
  archived
}

class ResearchInsight {
  final String id;
  final String content;
  final bool isApproved;

  ResearchInsight({
    required this.id,
    required this.content,
    this.isApproved = false,
  });

  factory ResearchInsight.fromJson(Map<String, dynamic> json) {
    return ResearchInsight(
      id: json['id'] as String,
      content: json['content'] as String,
      isApproved: json['isApproved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'isApproved': isApproved,
  };

  ResearchInsight copyWith({bool? isApproved}) {
    return ResearchInsight(
      id: id,
      content: content,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

class Campaign {
  final String id;
  final String title;
  final String description;
  final String? clientName;
  final CampaignStatus status;
  final DateTime createdAt;
  final List<ResearchInsight> insights;

  Campaign({
    required this.id,
    required this.title,
    required this.description,
    this.clientName,
    this.status = CampaignStatus.draft,
    required this.createdAt,
    this.insights = const [],
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      clientName: json['clientName'] as String?,
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CampaignStatus.draft,
      ),
      createdAt: (json['createdAt'] as dynamic).toDate(), // Firestore Timestamp
      insights: (json['insights'] as List? ?? [])
          .map((i) => ResearchInsight.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'clientName': clientName,
    'status': status.name,
    'createdAt': createdAt,
    'insights': insights.map((i) => i.toJson()).toList(),
  };

  Campaign copyWith({
    String? id,
    String? title,
    String? description,
    String? clientName,
    CampaignStatus? status,
    DateTime? createdAt,
    List<ResearchInsight>? insights,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      insights: insights ?? this.insights,
    );
  }
}
