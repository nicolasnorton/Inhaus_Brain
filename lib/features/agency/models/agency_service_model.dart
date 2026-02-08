import 'package:uuid/uuid.dart';

enum ServiceType {
  individual,
  bundle,
}

enum BillingCycle {
  monthly,
  bimonthly,
  oneTime,
  project,
}

/// Represents a single agency service/product offering
class AgencyService {
  final String id;
  final String name;
  final String nameEs; // Spanish name
  final String description;
  final ServiceType type;
  final List<String> details; // Highlights or Deliverables
  final List<String> team; // Team members involved
  final List<String> deliverables; // Specific deliverables
  final List<String> includes;
  final List<String> excludes;
  final String execution; // Execution details/process
  final String price; // Can be range like "1000.00-1500.00" or single "1500.00"
  final double basePrice; // Specific numeric price for calculations
  final double deliveryCost; // Internal cost to deliver
  final double targetMargin; // Target profit margin %
  final String frequency; // "one-time", "monthly", "bimonthly", "quarterly", "yearly"
  final BillingCycle billingCycle;
  final String? timeEstimate; // e.g., "1.5 months", "2 weeks"
  final String? minAdSpend; // For pauta services
  final Map<String, dynamic> metadata; // Additional flexible data
  final DateTime createdAt;
  final DateTime updatedAt;
  final String version; // For tracking updates

  AgencyService({
    required this.id,
    required this.name,
    this.nameEs = '',
    required this.description,
    this.type = ServiceType.individual,
    this.details = const [],
    this.team = const [],
    this.deliverables = const [],
    this.includes = const [],
    this.excludes = const [],
    this.execution = '',
    required this.price,
    this.basePrice = 0.0,
    this.deliveryCost = 0.0,
    this.targetMargin = 0.0,
    required this.frequency,
    this.billingCycle = BillingCycle.oneTime,
    this.timeEstimate,
    this.minAdSpend,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.version = '1.0',
  });

  factory AgencyService.create({
    required String name,
    String nameEs = '',
    required String description,
    ServiceType type = ServiceType.individual,
    List<String>? details,
    List<String>? team,
    List<String>? deliverables,
    List<String>? includes,
    List<String>? excludes,
    String execution = '',
    required String price,
    double basePrice = 0.0,
    double deliveryCost = 0.0,
    double targetMargin = 0.0,
    required String frequency,
    BillingCycle billingCycle = BillingCycle.oneTime,
    String? timeEstimate,
    String? minAdSpend,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return AgencyService(
      id: const Uuid().v4(),
      name: name,
      nameEs: nameEs,
      description: description,
      type: type,
      details: details ?? [],
      team: team ?? [],
      deliverables: deliverables ?? [],
      includes: includes ?? [],
      excludes: excludes ?? [],
      execution: execution,
      price: price,
      basePrice: basePrice,
      deliveryCost: deliveryCost,
      targetMargin: targetMargin,
      frequency: frequency,
      billingCycle: billingCycle,
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
      'nameEs': nameEs,
      'description': description,
      'type': type.name,
      'details': details,
      'team': team,
      'deliverables': deliverables,
      'includes': includes,
      'excludes': excludes,
      'execution': execution,
      'price': price,
      'basePrice': basePrice,
      'deliveryCost': deliveryCost,
      'targetMargin': targetMargin,
      'frequency': frequency,
      'billingCycle': billingCycle.name,
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
      nameEs: json['nameEs'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] != null 
          ? ServiceType.values.byName(json['type']) 
          : ServiceType.individual,
      details: (json['details'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      team: (json['team'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      deliverables: (json['deliverables'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      includes: (json['includes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      excludes: (json['excludes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      execution: json['execution'] ?? '',
      price: json['price'] ?? '0.00',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? (json['base_price'] as num?)?.toDouble() ?? 0.0,
      deliveryCost: (json['deliveryCost'] as num?)?.toDouble() ?? (json['delivery_cost'] as num?)?.toDouble() ?? 0.0,
      targetMargin: (json['targetMargin'] as num?)?.toDouble() ?? (json['target_margin'] as num?)?.toDouble() ?? 0.0,
      frequency: json['frequency'] ?? 'one-time',
      billingCycle: json['billingCycle'] != null 
          ? BillingCycle.values.byName(json['billingCycle']) 
          : (json['billing_cycle'] != null 
              ? BillingCycle.values.byName(json['billing_cycle']) 
              : BillingCycle.oneTime),
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
    String? nameEs,
    String? description,
    ServiceType? type,
    List<String>? details,
    List<String>? team,
    List<String>? deliverables,
    List<String>? includes,
    List<String>? excludes,
    String? execution,
    String? price,
    double? basePrice,
    double? deliveryCost,
    double? targetMargin,
    String? frequency,
    BillingCycle? billingCycle,
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
      nameEs: nameEs ?? this.nameEs,
      description: description ?? this.description,
      type: type ?? this.type,
      details: details ?? this.details,
      team: team ?? this.team,
      deliverables: deliverables ?? this.deliverables,
      includes: includes ?? this.includes,
      excludes: excludes ?? this.excludes,
      execution: execution ?? this.execution,
      price: price ?? this.price,
      basePrice: basePrice ?? this.basePrice,
      deliveryCost: deliveryCost ?? this.deliveryCost,
      targetMargin: targetMargin ?? this.targetMargin,
      frequency: frequency ?? this.frequency,
      billingCycle: billingCycle ?? this.billingCycle,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      minAdSpend: minAdSpend ?? this.minAdSpend,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  // Profitability Helpers
  double get profit => basePrice - deliveryCost;
  double get margin => basePrice > 0 ? (profit / basePrice) * 100 : 0.0;
  bool get meetsTarget => margin >= targetMargin;


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
