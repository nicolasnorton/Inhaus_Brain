enum CampaignStatus {
  draft,
  researching,
  designing,
  inProduction,
  published,
  archived
}

enum AttachmentType {
  image,
  video,
  voice,
  file
}

class Attachment {
  final String id;
  final String url; // Local path or cloud URL
  final String name;
  final AttachmentType type;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.url,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      url: json['url'] as String,
      name: json['name'] as String,
      type: AttachmentType.values.firstWhere((e) => e.name == json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'name': name,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
  };
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
  final String? clientId;
  final String? industry;
  final CampaignStatus status;
  final DateTime createdAt;
  final List<ResearchInsight> insights;
  final List<Attachment> attachments;

  Campaign({
    required this.id,
    required this.title,
    required this.description,
    this.clientName,
    this.clientId,
    this.industry,
    this.status = CampaignStatus.draft,
    required this.createdAt,
    this.insights = const [],
    this.attachments = const [],
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is DateTime) return date;
      if (date is String) return DateTime.parse(date);
      // Handle Firestore Timestamp if available
      try {
        return (date as dynamic).toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    return Campaign(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      clientName: json['clientName'] as String?,
      clientId: json['clientId'] as String?,
      industry: json['industry'] as String?,
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CampaignStatus.draft,
      ),
      createdAt: parseDate(json['createdAt']),
      insights: (json['insights'] as List? ?? [])
          .map((i) => ResearchInsight.fromJson(i as Map<String, dynamic>))
          .toList(),
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => Attachment.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'clientName': clientName,
    'clientId': clientId,
    'industry': industry,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'insights': insights.map((i) => i.toJson()).toList(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  Campaign copyWith({
    String? id,
    String? title,
    String? description,
    String? clientName,
    String? clientId,
    String? industry,
    CampaignStatus? status,
    DateTime? createdAt,
    List<ResearchInsight>? insights,
    List<Attachment>? attachments,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      clientId: clientId ?? this.clientId,
      industry: industry ?? this.industry,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      insights: insights ?? this.insights,
      attachments: attachments ?? this.attachments,
    );
  }
}
