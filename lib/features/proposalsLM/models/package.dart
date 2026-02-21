import 'section.dart';

class Package {
  final String id;
  final String slug;
  final String name;
  final String category;
  final double price;
  final String billing;
  final List<Section> sections;
  final bool isCustom;
  final String packageGroup;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime createdAt;

  Package({
    required this.id,
    required this.slug,
    required this.name,
    required this.category,
    required this.price,
    required this.billing,
    required this.sections,
    required this.isCustom,
    required this.packageGroup,
    this.deletedAt,
    this.deletedBy,
    required this.createdAt,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: (json['id'] ?? '').toString(),
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      billing: json['billing'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isCustom: json['isCustom'] as bool? ?? false,
      packageGroup: json['packageGroup'] as String? ?? 'Estudio',
      deletedAt: json['deletedAt'] != null
          ? (json['deletedAt'] is DateTime
              ? json['deletedAt'] as DateTime
              : DateTime.tryParse(json['deletedAt'].toString()))
          : null,
      deletedBy: json['deletedBy'] as String?,
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'name': name,
    'category': category,
    'price': price,
    'billing': billing,
    'sections': sections.map((e) => e.toJson()).toList(),
    'isCustom': isCustom,
    'packageGroup': packageGroup,
    'deletedAt': deletedAt?.toIso8601String(),
    'deletedBy': deletedBy,
    'createdAt': createdAt.toIso8601String(),
  };

  Package copyWith({
    String? id,
    String? slug,
    String? name,
    String? category,
    double? price,
    String? billing,
    List<Section>? sections,
    bool? isCustom,
    String? packageGroup,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
  }) {
    return Package(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      billing: billing ?? this.billing,
      sections: sections ?? this.sections,
      isCustom: isCustom ?? this.isCustom,
      packageGroup: packageGroup ?? this.packageGroup,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
