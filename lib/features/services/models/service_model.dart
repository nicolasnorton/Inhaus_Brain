import 'service_enums.dart';

class Service {
  final String id;
  final String name;
  final String nameEs; // Spanish name
  final ServiceType type;
  final double basePrice;
  final double deliveryCost;
  final double targetMargin; 

  // Execution details
  final String execution;
  final List<String> team;
  final List<String> deliverables;
  final List<String> includes;
  final List<String> excludes;

  // For bundles
  final List<String>? includedServiceIds;

  // Billing
  final BillingCycle billingCycle;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Service({
    required this.id,
    required this.name,
    required this.nameEs,
    required this.type,
    required this.basePrice,
    required this.deliveryCost,
    required this.targetMargin,
    required this.execution,
    this.team = const [],
    this.deliverables = const [],
    this.includes = const [],
    this.excludes = const [],
    this.includedServiceIds,
    required this.billingCycle,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  double get profit => basePrice - deliveryCost;
  double get margin => (profit / basePrice) * 100;
  bool get meetsTarget => margin >= targetMargin;

  Service copyWith({
    String? name,
    String? nameEs,
    ServiceType? type,
    double? basePrice,
    double? deliveryCost,
    double? targetMargin,
    String? execution,
    List<String>? team,
    List<String>? deliverables,
    List<String>? includes,
    List<String>? excludes,
    List<String>? includedServiceIds,
    BillingCycle? billingCycle,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Service(
      id: id,
      name: name ?? this.name,
      nameEs: nameEs ?? this.nameEs,
      type: type ?? this.type,
      basePrice: basePrice ?? this.basePrice,
      deliveryCost: deliveryCost ?? this.deliveryCost,
      targetMargin: targetMargin ?? this.targetMargin,
      execution: execution ?? this.execution,
      team: team ?? this.team,
      deliverables: deliverables ?? this.deliverables,
      includes: includes ?? this.includes,
      excludes: excludes ?? this.excludes,
      includedServiceIds: includedServiceIds ?? this.includedServiceIds,
      billingCycle: billingCycle ?? this.billingCycle,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEs: json['nameEs'] as String,
      type: ServiceType.values.byName(json['type'] as String),
      basePrice: (json['basePrice'] as num).toDouble(),
      deliveryCost: (json['deliveryCost'] as num).toDouble(),
      targetMargin: (json['targetMargin'] as num).toDouble(),
      execution: json['execution'] as String,
      team: List<String>.from(json['team'] as List),
      deliverables: List<String>.from(json['deliverables'] as List),
      includes: List<String>.from(json['includes'] as List),
      excludes: List<String>.from(json['excludes'] as List),
      includedServiceIds: json['includedServiceIds'] != null 
          ? List<String>.from(json['includedServiceIds'] as List)
          : null,
      billingCycle: BillingCycle.values.byName(json['billingCycle'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameEs': nameEs,
    'type': type.name,
    'basePrice': basePrice,
    'deliveryCost': deliveryCost,
    'targetMargin': targetMargin,
    'execution': execution,
    'team': team,
    'deliverables': deliverables,
    'includes': includes,
    'excludes': excludes,
    'includedServiceIds': includedServiceIds,
    'billingCycle': billingCycle.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
  };
}
