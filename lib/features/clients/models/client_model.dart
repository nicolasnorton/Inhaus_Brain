import 'client_contact_model.dart';

class Client {
  final String id;
  final String name;
  final String industry;
  final String? logoUrl;
  final List<String> campaignIds;
  final String? primaryContactEmail;
  
  // New Fields for Full Company Profile
  final String? website;
  final String? address;
  final String? size; // e.g. "10-50 employees"
  final String? description;
  final List<ClientContact> contacts;
  final Map<String, dynamic> customFields;

  Client({
    required this.id,
    required this.name,
    required this.industry,
    this.logoUrl,
    this.campaignIds = const [],
    this.primaryContactEmail,
    this.website,
    this.address,
    this.size,
    this.description,
    this.contacts = const [],
    this.customFields = const {},
  });

  Client copyWith({
    String? name,
    String? industry,
    String? logoUrl,
    List<String>? campaignIds,
    String? primaryContactEmail,
    String? website,
    String? address,
    String? size,
    String? description,
    List<ClientContact>? contacts,
    Map<String, dynamic>? customFields,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      logoUrl: logoUrl ?? this.logoUrl,
      campaignIds: campaignIds ?? this.campaignIds,
      primaryContactEmail: primaryContactEmail ?? this.primaryContactEmail,
      website: website ?? this.website,
      address: address ?? this.address,
      size: size ?? this.size,
      description: description ?? this.description,
      contacts: contacts ?? this.contacts,
      customFields: customFields ?? this.customFields,
    );
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id']?.toString() ?? 'unknown-client',
      name: json['name']?.toString() ?? 'Unnamed Client',
      industry: json['industry']?.toString() ?? 'Other',
      logoUrl: json['logoUrl']?.toString(),
      campaignIds: (json['campaignIds'] as List? ?? []).map((e) => e.toString()).toList(),
      primaryContactEmail: json['primaryContactEmail']?.toString(),
      website: json['website']?.toString(),
      address: json['address']?.toString(),
      size: json['size']?.toString(),
      description: json['description']?.toString(),
      contacts: (json['contacts'] as List? ?? [])
          .map((e) => ClientContact.fromJson(Map<String, dynamic>.from(e as Map? ?? {})))
          .toList(),
      customFields: Map<String, dynamic>.from(json['customFields'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'industry': industry,
    'logoUrl': logoUrl,
    'campaignIds': campaignIds,
    'primaryContactEmail': primaryContactEmail,
    'website': website,
    'address': address,
    'size': size,
    'description': description,
    'contacts': contacts.map((e) => e.toJson()).toList(),
    'customFields': customFields,
  };
}
