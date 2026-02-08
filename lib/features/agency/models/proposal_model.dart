import 'package:uuid/uuid.dart';

enum ProposalStatus {
  draft,
  sent,
  accepted,
  rejected
}

enum ProposalOutputType {
  pdf,
  slides,
  text
}

enum ProposalSourceType {
  file,      // PDF, CSV, Text
  web,       // URL
  dataConnector, // BigQuery, SQL
  pastedText // Copied Text
}

class ProposalSource {
  final String id;
  final String proposalId;
  final ProposalSourceType type;
  final String name;
  final String? content; // For text-extracted content
  final String? uri;     // URL or Path
  final Map<String, dynamic> metadata;
  final DateTime addedAt;

  ProposalSource({
    required this.id,
    required this.proposalId,
    required this.type,
    required this.name,
    this.content,
    this.uri,
    this.metadata = const {},
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proposalId': proposalId,
      'type': type.index,
      'name': name,
      'content': content,
      'uri': uri,
      'metadata': metadata,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory ProposalSource.fromJson(Map<String, dynamic> json) {
    return ProposalSource(
      id: json['id'],
      proposalId: json['proposalId'],
      type: ProposalSourceType.values[json['type'] ?? 0],
      name: json['name'],
      content: json['content'],
      uri: json['uri'],
      metadata: json['metadata'] ?? {},
      addedAt: DateTime.parse(json['addedAt']),
    );
  }
}

class ProposalOutput {
  final String id;
  final String title;
  final ProposalOutputType type;
  final String? content; // For text/markdown
  final String? uri; // For file paths
  final DateTime createdAt;

  ProposalOutput({
    required this.id,
    required this.title,
    required this.type,
    this.content,
    this.uri,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.index,
    'content': content,
    'uri': uri,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProposalOutput.fromJson(Map<String, dynamic> json) {
    return ProposalOutput(
      id: json['id'],
      title: json['title'],
      type: ProposalOutputType.values[json['type'] ?? 0],
      content: json['content'],
      uri: json['uri'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Proposal {
  final String id;
  final String title;
  final String clientId;
  final String clientName; // Human-readable client name
  final ProposalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? datasetId; // Reference to Knowledge Base for RAG
  final List<String> serviceIds; 
  final List<ProposalSource> sources;
  final List<ProposalOutput> outputs;

  Proposal({
    required this.id,
    required this.title,
    required this.clientId,
    required this.clientName,
    this.status = ProposalStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    this.datasetId,
    this.serviceIds = const [],
    List<ProposalSource>? sources,
    List<ProposalOutput>? outputs,
  }) : sources = sources ?? [], outputs = outputs ?? [];

  factory Proposal.create({
    required String title, 
    required String clientId,
    required String clientName,
    String? datasetId,
    List<String> serviceIds = const [],
  }) {
    final now = DateTime.now();
    return Proposal(
      id: const Uuid().v4(),
      title: title,
      clientId: clientId,
      clientName: clientName,
      status: ProposalStatus.draft,
      createdAt: now,
      updatedAt: now,
      datasetId: datasetId,
      serviceIds: serviceIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'clientId': clientId,
      'clientName': clientName,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'datasetId': datasetId,
      'serviceIds': serviceIds,
      'sources': sources.map((s) => s.toJson()).toList(),
      'outputs': outputs.map((o) => o.toJson()).toList(),
    };
  }

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'],
      title: json['title'],
      clientId: json['clientId'],
      clientName: json['clientName'] ?? '',
      status: ProposalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProposalStatus.draft,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      datasetId: json['datasetId'],
      serviceIds: List<String>.from(json['serviceIds'] ?? []),
      sources: (json['sources'] as List<dynamic>?)
          ?.map((e) => ProposalSource.fromJson(e))
          .toList(),
      outputs: (json['outputs'] as List<dynamic>?)
          ?.map((e) => ProposalOutput.fromJson(e))
          .toList(),
    );
  }

  Proposal copyWith({
    String? id,
    String? title,
    String? clientId,
    String? clientName,
    ProposalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? datasetId,
    List<String>? serviceIds,
    List<ProposalSource>? sources,
    List<ProposalOutput>? outputs,
  }) {
    return Proposal(
      id: id ?? this.id,
      title: title ?? this.title,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      datasetId: datasetId ?? this.datasetId,
      serviceIds: serviceIds ?? this.serviceIds,
      sources: sources ?? this.sources,
      outputs: outputs ?? this.outputs,
    );
  }
}
