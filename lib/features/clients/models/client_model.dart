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
    );
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      name: json['name'] as String,
      industry: json['industry'] as String,
      logoUrl: json['logoUrl'] as String?,
      campaignIds: (json['campaignIds'] as List? ?? []).cast<String>(),
      primaryContactEmail: json['primaryContactEmail'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
      size: json['size'] as String?,
      description: json['description'] as String?,
      contacts: (json['contacts'] as List? ?? [])
          .map((e) => ClientContact.fromJson(e as Map<String, dynamic>))
          .toList(),
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
  };
}
