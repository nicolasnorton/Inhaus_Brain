/// Represents the 7-property color theme for a proforma PDF.
class StyleColors {
  final String background;
  final String cardBg;
  final String accent;
  final String textPrimary;
  final String textSecondary;
  final String textMuted;
  final String border;

  const StyleColors({
    required this.background,
    required this.cardBg,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
  });

  /// Default INHAUS Clásico palette.
  static const defaultColors = StyleColors(
    background: '#111111',
    cardBg: '#1a1a1a',
    accent: '#E8006A',
    textPrimary: '#ffffff',
    textSecondary: '#cccccc',
    textMuted: '#888888',
    border: '#2a2a2a',
  );

  factory StyleColors.fromJson(Map<String, dynamic> json) {
    return StyleColors(
      background: json['background'] as String? ?? '#111111',
      cardBg: json['cardBg'] as String? ?? '#1a1a1a',
      accent: json['accent'] as String? ?? '#E8006A',
      textPrimary: json['textPrimary'] as String? ?? '#ffffff',
      textSecondary: json['textSecondary'] as String? ?? '#cccccc',
      textMuted: json['textMuted'] as String? ?? '#888888',
      border: json['border'] as String? ?? '#2a2a2a',
    );
  }

  Map<String, dynamic> toJson() => {
    'background': background,
    'cardBg': cardBg,
    'accent': accent,
    'textPrimary': textPrimary,
    'textSecondary': textSecondary,
    'textMuted': textMuted,
    'border': border,
  };

  StyleColors copyWith({
    String? background,
    String? cardBg,
    String? accent,
    String? textPrimary,
    String? textSecondary,
    String? textMuted,
    String? border,
  }) {
    return StyleColors(
      background: background ?? this.background,
      cardBg: cardBg ?? this.cardBg,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
    );
  }
}

/// A user-created proforma style stored in the `proformaStyles` Firestore collection.
class ProformaStyle {
  final String id;
  final String name;
  final StyleColors colors;
  final List<String> referenceImages;
  final bool isDefault;
  final DateTime createdAt;

  const ProformaStyle({
    required this.id,
    required this.name,
    required this.colors,
    required this.referenceImages,
    required this.isDefault,
    required this.createdAt,
  });

  factory ProformaStyle.fromJson(Map<String, dynamic> json) {
    return ProformaStyle(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      colors: StyleColors.fromJson(
          json['colors'] is Map<String, dynamic> ? json['colors'] as Map<String, dynamic> : {}),
      referenceImages: (json['referenceImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'colors': colors.toJson(),
    'referenceImages': referenceImages,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
  };

  ProformaStyle copyWith({
    String? id,
    String? name,
    StyleColors? colors,
    List<String>? referenceImages,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return ProformaStyle(
      id: id ?? this.id,
      name: name ?? this.name,
      colors: colors ?? this.colors,
      referenceImages: referenceImages ?? this.referenceImages,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
