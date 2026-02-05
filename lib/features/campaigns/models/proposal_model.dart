import 'dart:convert';

class ProposalData {
  final String title;
  final String client;
  final ProposalCover cover;
  final List<ProposalSection> sections;
  final List<String> visuals;

  ProposalData({
    required this.title,
    required this.client,
    required this.cover,
    required this.sections,
    required this.visuals,
  });

  factory ProposalData.fromJson(Map<String, dynamic> json) {
    return ProposalData(
      title: json['title'] ?? 'Untitled Proposal',
      client: json['client'] ?? 'Valued Client',
      cover: ProposalCover.fromJson(json['cover'] ?? {}),
      sections: (json['sections'] as List? ?? [])
          .map((s) => ProposalSection.fromJson(s))
          .toList(),
      visuals: List<String>.from(json['visuals'] ?? []),
    );
  }

  factory ProposalData.fromRawJson(String raw) {
    // Extract JSON from markdown if needed
    String cleanStr = raw;
    if (raw.contains('```json')) {
      cleanStr = raw.split('```json')[1].split('```')[0].trim();
    } else if (raw.contains('```')) {
      cleanStr = raw.split('```')[1].split('```')[0].trim();
    }
    return ProposalData.fromJson(json.decode(cleanStr));
  }
}

class ProposalCover {
  final String title;
  final String subtitle;

  ProposalCover({required this.title, required this.subtitle});

  factory ProposalCover.fromJson(Map<String, dynamic> json) {
    return ProposalCover(
      title: json['title'] ?? 'INHAUS PROPOSAL',
      subtitle: json['subtitle'] ?? 'STRICTLY CONFIDENTIAL',
    );
  }
}

class ProposalSection {
  final String type;
  final String? contentEn;
  final String? contentEs;
  final List<ProposalServiceItem>? items;
  final List<Map<String, dynamic>>? pricingTable;
  final List<ProposalMilestone>? milestones;

  ProposalSection({
    required this.type,
    this.contentEn,
    this.contentEs,
    this.items,
    this.pricingTable,
    this.milestones,
  });

  factory ProposalSection.fromJson(Map<String, dynamic> json) {
    return ProposalSection(
      type: json['type'] ?? 'text',
      contentEn: json['content_en'],
      contentEs: json['content_es'],
      items: (json['items'] as List?)?.map((i) => ProposalServiceItem.fromJson(i)).toList(),
      pricingTable: (json['table'] as List?)?.map((i) => Map<String, dynamic>.from(i)).toList(),
      milestones: (json['milestones'] as List?)?.map((m) => ProposalMilestone.fromJson(m)).toList(),
    );
  }
}

class ProposalServiceItem {
  final String name;
  final String descriptionEn;
  final String descriptionEs;
  final String benefits;

  ProposalServiceItem({
    required this.name,
    required this.descriptionEn,
    required this.descriptionEs,
    required this.benefits,
  });

  factory ProposalServiceItem.fromJson(Map<String, dynamic> json) {
    return ProposalServiceItem(
      name: json['name'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      descriptionEs: json['description_es'] ?? '',
      benefits: json['benefits'] ?? '',
    );
  }
}

class ProposalMilestone {
  final String date;
  final String eventEn;
  final String eventEs;

  ProposalMilestone({required this.date, required this.eventEn, required this.eventEs});

  factory ProposalMilestone.fromJson(Map<String, dynamic> json) {
    return ProposalMilestone(
      date: json['date'] ?? '',
      eventEn: json['event_en'] ?? '',
      eventEs: json['event_es'] ?? '',
    );
  }
}
