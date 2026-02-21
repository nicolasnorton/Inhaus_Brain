import 'section.dart';

class QuoteItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String billing;
  final List<Section> sections;

  QuoteItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.billing,
    required this.sections,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      billing: json['billing'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'billing': billing,
    'sections': sections.map((e) => e.toJson()).toList(),
  };

  QuoteItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? billing,
    List<Section>? sections,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      billing: billing ?? this.billing,
      sections: sections ?? this.sections,
    );
  }
}

class ExtraBlock {
  final String id;
  final String title;
  final String content;

  ExtraBlock({
    required this.id,
    required this.title,
    required this.content,
  });

  factory ExtraBlock.fromJson(Map<String, dynamic> json) {
    return ExtraBlock(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
  };

  ExtraBlock copyWith({String? id, String? title, String? content}) {
    return ExtraBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}

class Quote {
  final String id;
  final String client;
  final String date;
  final double discount;
  final bool applyIva;
  final List<QuoteItem> items;
  final List<ExtraBlock> extraBlocks;
  final double extraAmount;
  final String totalNote;
  final String logoVariant;
  final String? styleId;
  final DateTime createdAt;

  Quote({
    required this.id,
    required this.client,
    required this.date,
    required this.discount,
    required this.applyIva,
    required this.items,
    required this.extraBlocks,
    required this.extraAmount,
    required this.totalNote,
    required this.logoVariant,
    this.styleId,
    required this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: (json['id'] ?? '').toString(),
      client: json['client'] as String? ?? '',
      date: json['date'] as String? ?? '',
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      applyIva: json['applyIva'] as bool? ?? true,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => QuoteItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extraBlocks: (json['extraBlocks'] as List<dynamic>?)
              ?.map((e) => ExtraBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extraAmount: (json['extraAmount'] as num?)?.toDouble() ?? 0.0,
      totalNote: json['totalNote'] as String? ?? '',
      logoVariant: json['logoVariant'] as String? ?? 'ESTUDIO',
      styleId: json['styleId']?.toString(),
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'client': client,
    'date': date,
    'discount': discount,
    'applyIva': applyIva,
    'items': items.map((e) => e.toJson()).toList(),
    'extraBlocks': extraBlocks.map((e) => e.toJson()).toList(),
    'extraAmount': extraAmount,
    'totalNote': totalNote,
    'logoVariant': logoVariant,
    'styleId': styleId,
    'createdAt': createdAt.toIso8601String(),
  };

  Quote copyWith({
    String? id,
    String? client,
    String? date,
    double? discount,
    bool? applyIva,
    List<QuoteItem>? items,
    List<ExtraBlock>? extraBlocks,
    double? extraAmount,
    String? totalNote,
    String? logoVariant,
    String? styleId,
    DateTime? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      client: client ?? this.client,
      date: date ?? this.date,
      discount: discount ?? this.discount,
      applyIva: applyIva ?? this.applyIva,
      items: items ?? this.items,
      extraBlocks: extraBlocks ?? this.extraBlocks,
      extraAmount: extraAmount ?? this.extraAmount,
      totalNote: totalNote ?? this.totalNote,
      logoVariant: logoVariant ?? this.logoVariant,
      styleId: styleId ?? this.styleId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
