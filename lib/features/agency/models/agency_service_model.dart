import 'package:uuid/uuid.dart';

/// Represents a single agency service/product offering
class AgencyService {
  final String id;
  final String name;
  final String description;
  final List<String> details;
  final List<String> includes;
  final List<String> excludes;
  final String price; // Can be range like "1000.00-1500.00" or single "1500.00"
  final String frequency; // "one-time", "monthly", "bimonthly", "quarterly", "yearly"
  final String? timeEstimate; // e.g., "1.5 months", "2 weeks"
  final String? minAdSpend; // For pauta services
  final Map<String, dynamic> metadata; // Additional flexible data
  final DateTime createdAt;
  final DateTime updatedAt;
  final String version; // For tracking updates

  AgencyService({
    required this.id,
    required this.name,
    required this.description,
    this.details = const [],
    this.includes = const [],
    this.excludes = const [],
    required this.price,
    required this.frequency,
    this.timeEstimate,
    this.minAdSpend,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.version = '1.0',
  });

  factory AgencyService.create({
    required String name,
    required String description,
    List<String>? details,
    List<String>? includes,
    List<String>? excludes,
    required String price,
    required String frequency,
    String? timeEstimate,
    String? minAdSpend,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return AgencyService(
      id: const Uuid().v4(),
      name: name,
      description: description,
      details: details ?? [],
      includes: includes ?? [],
      excludes: excludes ?? [],
      price: price,
      frequency: frequency,
      timeEstimate: timeEstimate,
      minAdSpend: minAdSpend,
      metadata: metadata ?? {},
      createdAt: now,
      updatedAt: now,
      version: '1.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'details': details,
      'includes': includes,
      'excludes': excludes,
      'price': price,
      'frequency': frequency,
      'timeEstimate': timeEstimate,
      'minAdSpend': minAdSpend,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
    };
  }

  factory AgencyService.fromJson(Map<String, dynamic> json) {
    return AgencyService(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      details: (json['details'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      includes: (json['includes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      excludes: (json['excludes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      price: json['price'] ?? '0.00',
      frequency: json['frequency'] ?? 'one-time',
      timeEstimate: json['time_estimate'] ?? json['timeEstimate'],
      minAdSpend: json['min_ad_spend'] ?? json['minAdSpend'],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      version: json['version'] ?? '1.0',
    );
  }

  AgencyService copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? details,
    List<String>? includes,
    List<String>? excludes,
    String? price,
    String? frequency,
    String? timeEstimate,
    String? minAdSpend,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? version,
  }) {
    return AgencyService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      details: details ?? this.details,
      includes: includes ?? this.includes,
      excludes: excludes ?? this.excludes,
      price: price ?? this.price,
      frequency: frequency ?? this.frequency,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      minAdSpend: minAdSpend ?? this.minAdSpend,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  /// Helper to get numeric price (handles ranges by returning min value)
  double getMinPrice() {
    final priceStr = price.replaceAll(r'$', '').replaceAll(',', '');
    if (priceStr.contains('-')) {
      return double.tryParse(priceStr.split('-')[0]) ?? 0.0;
    }
    return double.tryParse(priceStr) ?? 0.0;
  }

  /// Helper to get max price (for ranges)
  double getMaxPrice() {
    final priceStr = price.replaceAll(r'$', '').replaceAll(',', '');
    if (priceStr.contains('-')) {
      return double.tryParse(priceStr.split('-')[1]) ?? getMinPrice();
    }
    return double.tryParse(priceStr) ?? 0.0;
  }

  /// Check if this is a recurring service
  bool get isRecurring => frequency != 'one-time';

  @override
  String toString() {
    return 'AgencyService(id: $id, name: $name, price: $price, frequency: $frequency)';
  }
}

/// Catalog metadata
class ServiceCatalog {
  final String id;
  final String name;
  final String description;
  final List<AgencyService> services;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String version;
  final Map<String, dynamic> metadata;

  ServiceCatalog({
    required this.id,
    required this.name,
    required this.description,
    this.services = const [],
    required this.createdAt,
    required this.updatedAt,
    this.version = '1.0',
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'services': services.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
      'metadata': metadata,
    };
  }

  factory ServiceCatalog.fromJson(Map<String, dynamic> json) {
    return ServiceCatalog(
      id: json['id'] ?? 'catalog',
      name: json['name'] ?? 'Agency Services Catalog',
      description: json['description'] ?? '',
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => AgencyService.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      version: json['version'] ?? '1.0',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  ServiceCatalog copyWith({
    String? id,
    String? name,
    String? description,
    List<AgencyService>? services,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? version,
    Map<String, dynamic>? metadata,
  }) {
    return ServiceCatalog(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      services: services ?? this.services,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      metadata: metadata ?? this.metadata,
    );
  }
}
