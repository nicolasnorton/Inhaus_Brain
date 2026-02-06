import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Proposal document model
class Proposal {
  final String id;
  final String title;
  final String clientId;
  final String clientName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? datasetId; // Reference to Knowledge Base
  final List<ProposalSource> sources;
  final List<ProposalOutput> outputs;
  final ProposalStatus status;

  Proposal({
    required this.id,
    required this.title,
    required this.clientId,
    required this.clientName,
    required this.createdAt,
    required this.updatedAt,
    this.datasetId,
    List<ProposalSource>? sources,
    List<ProposalOutput>? outputs,
    this.status = ProposalStatus.draft,
  })  : sources = sources ?? [],
        outputs = outputs ?? [];

  factory Proposal.create({
    required String title,
    required String clientId,
    required String clientName,
    String? datasetId,
  }) {
    final now = DateTime.now();
    return Proposal(
      id: const Uuid().v4(),
      title: title,
      clientId: clientId,
      clientName: clientName,
      createdAt: now,
      updatedAt: now,
      datasetId: datasetId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'clientId': clientId,
      'clientName': clientName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'datasetId': datasetId,
      'sources': sources.map((s) => s.toJson()).toList(),
      'outputs': outputs.map((o) => o.toJson()).toList(),
      'status': status.toString().split('.').last,
    };
  }

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'],
      title: json['title'],
      clientId: json['clientId'],
      clientName: json['clientName'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      datasetId: json['datasetId'],
      sources: (json['sources'] as List<dynamic>?)
          ?.map((e) => ProposalSource.fromJson(e))
          .toList(),
      outputs: (json['outputs'] as List<dynamic>?)
          ?.map((e) => ProposalOutput.fromJson(e))
          .toList(),
      status: ProposalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ProposalStatus.draft,
      ),
    );
  }

  Proposal copyWith({
    String? id,
    String? title,
    String? clientId,
    String? clientName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? datasetId,
    List<ProposalSource>? sources,
    List<ProposalOutput>? outputs,
    ProposalStatus? status,
  }) {
    return Proposal(
      id: id ?? this.id,
      title: title ?? this.title,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      datasetId: datasetId ?? this.datasetId,
      sources: sources ?? this.sources,
      outputs: outputs ?? this.outputs,
      status: status ?? this.status,
    );
  }
}

/// Proposal status
enum ProposalStatus {
  draft,
  generated,
  sent,
  accepted,
  rejected;

  String get displayName {
    switch (this) {
      case ProposalStatus.draft:
        return 'Draft';
      case ProposalStatus.generated:
        return 'Generated';
      case ProposalStatus.sent:
        return 'Sent';
      case ProposalStatus.accepted:
        return 'Accepted';
      case ProposalStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Proposal source type
enum ProposalSourceType {
  clientBrief,
  campaignData,
  file,
  text,
  web;

  String get displayName {
    switch (this) {
      case ProposalSourceType.clientBrief:
        return 'Client Brief';
      case ProposalSourceType.campaignData:
        return 'Campaign Data';
      case ProposalSourceType.file:
        return 'File';
      case ProposalSourceType.text:
        return 'Text';
      case ProposalSourceType.web:
        return 'Web';
    }
  }
}

/// Proposal source
class ProposalSource {
  final String id;
  final String proposalId;
  final ProposalSourceType type;
  final String name;
  final String? content;
  final String? uri;
  final DateTime addedAt;

  ProposalSource({
    required this.id,
    required this.proposalId,
    required this.type,
    required this.name,
    this.content,
    this.uri,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'proposalId': proposalId,
        'type': type.toString().split('.').last,
        'name': name,
        'content': content,
        'uri': uri,
        'addedAt': addedAt.toIso8601String(),
      };

  factory ProposalSource.fromJson(Map<String, dynamic> json) {
    return ProposalSource(
      id: json['id'],
      proposalId: json['proposalId'],
      type: ProposalSourceType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ProposalSourceType.text,
      ),
      name: json['name'],
      content: json['content'],
      uri: json['uri'],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }
}

/// Proposal output type
enum ProposalOutputType {
  detailedPdf,
  onePagePdf,
  googleSlides;

  String get displayName {
    switch (this) {
      case ProposalOutputType.detailedPdf:
        return 'Detailed Proposal (PDF)';
      case ProposalOutputType.onePagePdf:
        return 'One-Page Quote (PDF)';
      case ProposalOutputType.googleSlides:
        return 'Google Slides';
    }
  }
}

/// Proposal output
class ProposalOutput {
  final String id;
  final String title;
  final ProposalOutputType type;
  final String? uri;
  final DateTime createdAt;

  ProposalOutput({
    required this.id,
    required this.title,
    required this.type,
    this.uri,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.toString().split('.').last,
        'uri': uri,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProposalOutput.fromJson(Map<String, dynamic> json) {
    return ProposalOutput(
      id: json['id'],
      title: json['title'],
      type: ProposalOutputType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ProposalOutputType.detailedPdf,
      ),
      uri: json['uri'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Proposal data structure (for generation)
class ProposalData {
  final String type; // 'detailed' or 'one_page'
  final String format; // 'pdf' or 'slides'
  final ProposalHeader header;
  final List<ProposalSection>? sections; // For detailed
  final ProposalSummary? summary; // For one_page
  final String? footer;
  final List<String> embeddedImages;

  ProposalData({
    required this.type,
    required this.format,
    required this.header,
    this.sections,
    this.summary,
    this.footer,
    this.embeddedImages = const [],
  });

  factory ProposalData.fromJson(Map<String, dynamic> json) {
    return ProposalData(
      type: json['type'] ?? 'detailed',
      format: json['format'] ?? 'pdf',
      header: ProposalHeader.fromJson(json['header'] ?? {}),
      sections: (json['sections'] as List?)
          ?.map((s) => ProposalSection.fromJson(s))
          .toList(),
      summary: json['summary'] != null
          ? ProposalSummary.fromJson(json['summary'])
          : null,
      footer: json['footer'],
      embeddedImages: List<String>.from(json['embedded_images'] ?? []),
    );
  }

  factory ProposalData.fromRawJson(String raw) {
    String cleanStr = raw;
    if (raw.contains('```json')) {
      cleanStr = raw.split('```json')[1].split('```')[0].trim();
    } else if (raw.contains('```')) {
      cleanStr = raw.split('```')[1].split('```')[0].trim();
    }
    return ProposalData.fromJson(json.decode(cleanStr));
  }
}

class ProposalHeader {
  final String agencyTitle;
  final String clientName;
  final String? clientLogoUrl;
  final String date;

  ProposalHeader({
    required this.agencyTitle,
    required this.clientName,
    this.clientLogoUrl,
    required this.date,
  });

  factory ProposalHeader.fromJson(Map<String, dynamic> json) {
    return ProposalHeader(
      agencyTitle: json['agency_title'] ?? 'INHAUS ESTUDIO CREATIVO',
      clientName: json['client_name'] ?? 'Inhaus Client',
      clientLogoUrl: json['client_logo_url'],
      date: json['date'] ?? '',
    );
  }
}

class ProposalSection {
  final String title;
  final String description;
  final List<String> bullets;
  final List<String> includes;
  final List<String> excludes;
  final ProposalPrice price;

  ProposalSection({
    required this.title,
    required this.description,
    required this.bullets,
    required this.includes,
    required this.excludes,
    required this.price,
  });

  factory ProposalSection.fromJson(Map<String, dynamic> json) {
    return ProposalSection(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      bullets: List<String>.from(json['bullets'] ?? []),
      includes: List<String>.from(json['includes'] ?? []),
      excludes: List<String>.from(json['excludes'] ?? []),
      price: ProposalPrice.fromJson(json['price'] ?? {}),
    );
  }
}

class ProposalSummary {
  final String intro;
  final List<String> keyServices;
  final ProposalPrice totalPrice;
  final String cta;

  ProposalSummary({
    required this.intro,
    required this.keyServices,
    required this.totalPrice,
    required this.cta,
  });

  factory ProposalSummary.fromJson(Map<String, dynamic> json) {
    return ProposalSummary(
      intro: json['intro'] ?? '',
      keyServices: List<String>.from(json['key_services'] ?? []),
      totalPrice: ProposalPrice.fromJson(json['total_price'] ?? {}),
      cta: json['cta'] ?? '',
    );
  }
}

class ProposalPrice {
  final String label;
  final String amount;

  ProposalPrice({required this.label, required this.amount});

  factory ProposalPrice.fromJson(Map<String, dynamic> json) {
    return ProposalPrice(
      label: json['label'] ?? 'PRECIO:',
      amount: json['amount'] ?? 'TBD',
    );
  }
}
