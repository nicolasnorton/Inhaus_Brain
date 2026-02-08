import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  final List<String> serviceIds; // IDs of services from the catalog
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
    this.serviceIds = const [],
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
    List<String> serviceIds = const [],
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
      serviceIds: serviceIds,
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
      'serviceIds': serviceIds,
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
      serviceIds: List<String>.from(json['serviceIds'] ?? []),
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
    List<String>? serviceIds,
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
      serviceIds: serviceIds ?? this.serviceIds,
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
  final DocumentSettings? settings;
  final VisualTheme? theme;
  final List<ProposalSection>? sections; // For detailed
  final ProposalSummary? summary; // For one_page
  final String? footer;
  final List<String> embeddedImages;

  ProposalData({
    required this.type,
    required this.format,
    required this.header,
    this.settings,
    this.theme,
    this.sections,
    this.summary,
    this.footer,
    this.embeddedImages = const [],
  });

  factory ProposalData.fromJson(Map<String, dynamic> json) {
    // Handle modular structure
    if (json.containsKey('client_proposal')) {
      final clientProposal = json['client_proposal'] as Map<String, dynamic>? ?? {};
      final settings = json['document_settings'] != null 
          ? DocumentSettings.fromJson(json['document_settings'] as Map<String, dynamic>) 
          : null;
      final theme = json['visual_theme'] != null 
          ? VisualTheme.fromJson(json['visual_theme'] as Map<String, dynamic>) 
          : null;
      
      return ProposalData(
        type: clientProposal['proposal_type'] ?? 'detailed',
        format: json['format'] ?? 'pdf',
        settings: settings,
        theme: theme,
        header: ProposalHeader(
          agencyTitle: settings?.agencyName ?? 'INHAUS ESTUDIO CREATIVO',
          clientName: clientProposal['client_name'] ?? 'Inhaus Client',
          date: settings?.dateGenerated ?? '',
        ),
        sections: (clientProposal['sections'] as List?)
            ?.map((s) => ProposalSection.fromJson(s as Map<String, dynamic>))
            .toList(),
        footer: settings?.website ?? 'inhauscorp.com',
        embeddedImages: List<String>.from(json['embedded_images'] ?? []),
      );
    }

    // Handle legacy/one_page structure
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
    try {
      String cleanStr = raw;
      if (raw.contains('```json')) {
        cleanStr = raw.split('```json')[1].split('```')[0].trim();
      } else if (raw.contains('```')) {
        cleanStr = raw.split('```')[1].split('```')[0].trim();
      }
      return ProposalData.fromJson(json.decode(cleanStr));
    } catch (e) {
      debugPrint('ProposalData: Failed to parse raw JSON: $e\nRaw String: $raw');
      rethrow;
    }
  }
}

class DocumentSettings {
  final String agencyName;
  final String website;
  final String dateGenerated;
  final String currency;
  final String locale;

  DocumentSettings({
    required this.agencyName,
    required this.website,
    required this.dateGenerated,
    required this.currency,
    required this.locale,
  });

  factory DocumentSettings.fromJson(Map<String, dynamic> json) {
    return DocumentSettings(
      agencyName: json['agency_name'] ?? 'INHAUS ESTUDIO CREATIVO',
      website: json['website'] ?? 'inhauscorp.com',
      dateGenerated: json['date_generated'] ?? '',
      currency: json['currency'] ?? 'USD',
      locale: json['locale'] ?? 'es-EC',
    );
  }
}

class VisualTheme {
  final Map<String, String> colors;

  VisualTheme({required this.colors});

  factory VisualTheme.fromJson(Map<String, dynamic> json) {
    return VisualTheme(
      colors: Map<String, String>.from(json['colors'] ?? {}),
    );
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
  final String? layoutType;
  final ProposalContent content;
  final ProposalPrice price;

  ProposalSection({
    required this.title,
    this.layoutType,
    required this.content,
    required this.price,
  });

  factory ProposalSection.fromJson(Map<String, dynamic> json) {
    // Check if it's the new modular section content or legacy
    if (json.containsKey('content')) {
      return ProposalSection(
        title: json['title'] ?? '',
        layoutType: json['layout_type'],
        content: ProposalContent.fromJson(json['content'] as Map<String, dynamic>? ?? {}),
        price: ProposalPrice.fromJson(json['pricing'] as Map<String, dynamic>? ?? {}),
      );
    }

    // Legacy fallback
    return ProposalSection(
      title: json['title'] ?? '',
      content: ProposalContent(
        headerInfo: json['description'] != null ? [json['description'] as String] : [],
        items: List<String>.from(json['bullets'] ?? []),
      ),
      price: ProposalPrice.fromJson(json['price'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class ProposalContent {
  final List<String> headerInfo;
  final List<String> items;
  final List<ProposalColumn> columns;

  ProposalContent({
    this.headerInfo = const [],
    this.items = const [],
    this.columns = const [],
  });

  factory ProposalContent.fromJson(Map<String, dynamic> json) {
    return ProposalContent(
      headerInfo: List<String>.from(json['header_info'] ?? []),
      items: List<String>.from(json['items'] ?? []),
      columns: (json['columns'] as List?)
          ?.map((c) => ProposalColumn.fromJson(c))
          .toList() ?? [],
    );
  }
}

class ProposalColumn {
  final String title;
  final String value;

  ProposalColumn({required this.title, required this.value});

  factory ProposalColumn.fromJson(Map<String, dynamic> json) {
    return ProposalColumn(
      title: json['title'] ?? '',
      value: json['value'] ?? '',
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
  final String? terms;

  ProposalPrice({required this.label, required this.amount, this.terms});

  factory ProposalPrice.fromJson(Map<String, dynamic> json) {
    return ProposalPrice(
      label: json['label'] ?? 'PRECIO:',
      amount: json['amount'] ?? 'TBD',
      terms: json['terms'],
    );
  }
}
