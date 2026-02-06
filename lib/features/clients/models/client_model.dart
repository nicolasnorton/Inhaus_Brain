import 'client_contact_model.dart';

enum ClientType {
  corporate,
  independent,
}

class Client {
  final String id;
  final String name;
  final ClientType clientType;
  final String industry;
  final String? logoUrl;
  final List<String> campaignIds;
  final String? primaryContactEmail;
  
  // Shared / Corporate Fields
  final String? website;
  final String? address; // Physical address
  final String? fiscalAddress; // Tax address
  final String? size; // e.g. "10-50 employees"
  final String? description;
  final String? legalName; // Razón Social
  final String? taxId; // RUC

  // Independent Fields
  final String? profession;
  final String? personalTaxId; // Cédula/RUC
  final String? portfolioUrl;
  final String? linkedinUrl;
  final DateTime? birthDate;

  final List<ClientContact> contacts;
  final Map<String, dynamic> customFields;

  Client({
    required this.id,
    required this.name,
    this.clientType = ClientType.corporate, // Default for migration
    required this.industry,
    this.logoUrl,
    this.campaignIds = const [],
    this.primaryContactEmail,
    this.website,
    this.address,
    this.fiscalAddress,
    this.size,
    this.description,
    this.legalName,
    this.taxId,
    this.profession,
    this.personalTaxId,
    this.portfolioUrl,
    this.linkedinUrl,
    this.birthDate,
    this.contacts = const [],
    this.customFields = const {},
  });

  Client copyWith({
    String? name,
    ClientType? clientType,
    String? industry,
    String? logoUrl,
    List<String>? campaignIds,
    String? primaryContactEmail,
    String? website,
    String? address,
    String? fiscalAddress,
    String? size,
    String? description,
    String? legalName,
    String? taxId,
    String? profession,
    String? personalTaxId,
    String? portfolioUrl,
    String? linkedinUrl,
    DateTime? birthDate,
    List<ClientContact>? contacts,
    Map<String, dynamic>? customFields,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      clientType: clientType ?? this.clientType,
      industry: industry ?? this.industry,
      logoUrl: logoUrl ?? this.logoUrl,
      campaignIds: campaignIds ?? this.campaignIds,
      primaryContactEmail: primaryContactEmail ?? this.primaryContactEmail,
      website: website ?? this.website,
      address: address ?? this.address,
      fiscalAddress: fiscalAddress ?? this.fiscalAddress,
      size: size ?? this.size,
      description: description ?? this.description,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      profession: profession ?? this.profession,
      personalTaxId: personalTaxId ?? this.personalTaxId,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      birthDate: birthDate ?? this.birthDate,
      contacts: contacts ?? this.contacts,
      customFields: customFields ?? this.customFields,
    );
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id']?.toString() ?? 'unknown-client',
      name: json['name']?.toString() ?? 'Unnamed Client',
      clientType: json['clientType'] != null
          ? ClientType.values.firstWhere(
              (e) => e.toString().split('.').last == json['clientType'],
              orElse: () => ClientType.corporate,
            )
          : ClientType.corporate,
      industry: json['industry']?.toString() ?? 'Other',
      logoUrl: json['logoUrl']?.toString(),
      campaignIds: (json['campaignIds'] as List? ?? []).map((e) => e.toString()).toList(),
      primaryContactEmail: json['primaryContactEmail']?.toString(),
      website: json['website']?.toString(),
      address: json['address']?.toString(),
      fiscalAddress: json['fiscalAddress']?.toString(),
      size: json['size']?.toString(),
      description: json['description']?.toString(),
      legalName: json['legalName']?.toString(),
      taxId: json['taxId']?.toString(),
      profession: json['profession']?.toString(),
      personalTaxId: json['personalTaxId']?.toString(),
      portfolioUrl: json['portfolioUrl']?.toString(),
      linkedinUrl: json['linkedinUrl']?.toString(),
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'].toString()) : null,
      contacts: (json['contacts'] as List? ?? [])
          .map((e) => ClientContact.fromJson(Map<String, dynamic>.from(e as Map? ?? {})))
          .toList(),
      customFields: Map<String, dynamic>.from(json['customFields'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'clientType': clientType.toString().split('.').last,
    'industry': industry,
    'logoUrl': logoUrl,
    'campaignIds': campaignIds,
    'primaryContactEmail': primaryContactEmail,
    'website': website,
    'address': address,
    'fiscalAddress': fiscalAddress,
    'size': size,
    'description': description,
    'legalName': legalName,
    'taxId': taxId,
    'profession': profession,
    'personalTaxId': personalTaxId,
    'portfolioUrl': portfolioUrl,
    'linkedinUrl': linkedinUrl,
    'birthDate': birthDate?.toIso8601String(),
    'contacts': contacts.map((e) => e.toJson()).toList(),
    'customFields': customFields,
  };
}
