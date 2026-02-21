import 'package:cloud_firestore/cloud_firestore.dart';

class ProposalStyle {
  final String id;
  final String name;
  final String fondoHex;
  final String tarjetasHex;
  final String acentoHex;
  final String textoPrincipalHex;
  final String textoSecundarioHex;
  final String textoSutilHex;
  final String bordesHex;
  final bool isDefault;

  const ProposalStyle({
    required this.id,
    required this.name,
    required this.fondoHex,
    required this.tarjetasHex,
    required this.acentoHex,
    required this.textoPrincipalHex,
    required this.textoSecundarioHex,
    required this.textoSutilHex,
    required this.bordesHex,
    this.isDefault = false,
  });

  // Default INHAUS Clásico style
  static const inhausClasico = ProposalStyle(
    id: 'inhaus-clasico',
    name: 'INHAUS Clásico',
    fondoHex: '#111111',
    tarjetasHex: '#1A1A1A',
    acentoHex: '#FF0055',
    textoPrincipalHex: '#FFFFFF',
    textoSecundarioHex: '#A0A0A0',
    textoSutilHex: '#666666',
    bordesHex: '#333333',
    isDefault: true,
  );

  factory ProposalStyle.fromJson(Map<String, dynamic> json, {String? id}) {
    return ProposalStyle(
      id: id ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Custom Style',
      fondoHex: json['fondoHex'] as String? ?? '#111111',
      tarjetasHex: json['tarjetasHex'] as String? ?? '#1A1A1A',
      acentoHex: json['acentoHex'] as String? ?? '#FF0055',
      textoPrincipalHex: json['textoPrincipalHex'] as String? ?? '#FFFFFF',
      textoSecundarioHex: json['textoSecundarioHex'] as String? ?? '#A0A0A0',
      textoSutilHex: json['textoSutilHex'] as String? ?? '#666666',
      bordesHex: json['bordesHex'] as String? ?? '#333333',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fondoHex': fondoHex,
      'tarjetasHex': tarjetasHex,
      'acentoHex': acentoHex,
      'textoPrincipalHex': textoPrincipalHex,
      'textoSecundarioHex': textoSecundarioHex,
      'textoSutilHex': textoSutilHex,
      'bordesHex': bordesHex,
      'isDefault': isDefault,
    };
  }

  factory ProposalStyle.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return inhausClasico;
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProposalStyle.fromJson(data, id: doc.id);
  }

  ProposalStyle copyWith({
    String? id,
    String? name,
    String? fondoHex,
    String? tarjetasHex,
    String? acentoHex,
    String? textoPrincipalHex,
    String? textoSecundarioHex,
    String? textoSutilHex,
    String? bordesHex,
    bool? isDefault,
  }) {
    return ProposalStyle(
      id: id ?? this.id,
      name: name ?? this.name,
      fondoHex: fondoHex ?? this.fondoHex,
      tarjetasHex: tarjetasHex ?? this.tarjetasHex,
      acentoHex: acentoHex ?? this.acentoHex,
      textoPrincipalHex: textoPrincipalHex ?? this.textoPrincipalHex,
      textoSecundarioHex: textoSecundarioHex ?? this.textoSecundarioHex,
      textoSutilHex: textoSutilHex ?? this.textoSutilHex,
      bordesHex: bordesHex ?? this.bordesHex,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
