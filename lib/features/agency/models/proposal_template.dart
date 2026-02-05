enum ProposalTemplateType {
  onePager,
  multiPage,
  custom,
}

enum ProposalTemplateStyle {
  brian,      // Premium Gold/Dark
  classic,    // Original Pink/Purple
  minimal,    // Clean White/Grey
  custom,     // User-defined
}

class ProposalTemplate {
  final String id;
  final String name;
  final String description;
  final ProposalTemplateType type;
  final ProposalTemplateStyle style;
  final bool isDefault;
  final bool isCustom;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Template Configuration
  final TemplateConfig config;
  
  // Optional: Reference to custom template file (for uploaded templates)
  final String? customTemplateUrl;
  final String? thumbnailUrl;

  ProposalTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.style,
    this.isDefault = false,
    this.isCustom = false,
    required this.createdAt,
    required this.updatedAt,
    required this.config,
    this.customTemplateUrl,
    this.thumbnailUrl,
  });

  ProposalTemplate copyWith({
    String? id,
    String? name,
    String? description,
    ProposalTemplateType? type,
    ProposalTemplateStyle? style,
    bool? isDefault,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? updatedAt,
    TemplateConfig? config,
    String? customTemplateUrl,
    String? thumbnailUrl,
  }) {
    return ProposalTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      style: style ?? this.style,
      isDefault: isDefault ?? this.isDefault,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      config: config ?? this.config,
      customTemplateUrl: customTemplateUrl ?? this.customTemplateUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'style': style.name,
      'isDefault': isDefault,
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'config': config.toJson(),
      'customTemplateUrl': customTemplateUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory ProposalTemplate.fromJson(Map<String, dynamic> json) {
    return ProposalTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: ProposalTemplateType.values.firstWhere((e) => e.name == json['type']),
      style: ProposalTemplateStyle.values.firstWhere((e) => e.name == json['style']),
      isDefault: json['isDefault'] ?? false,
      isCustom: json['isCustom'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      config: TemplateConfig.fromJson(json['config']),
      customTemplateUrl: json['customTemplateUrl'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
}

class TemplateConfig {
  // Color Scheme
  final ColorScheme colors;
  
  // Typography
  final TypographyConfig typography;
  
  // Layout
  final LayoutConfig layout;
  
  // Branding
  final BrandingConfig branding;

  TemplateConfig({
    required this.colors,
    required this.typography,
    required this.layout,
    required this.branding,
  });

  Map<String, dynamic> toJson() {
    return {
      'colors': colors.toJson(),
      'typography': typography.toJson(),
      'layout': layout.toJson(),
      'branding': branding.toJson(),
    };
  }

  factory TemplateConfig.fromJson(Map<String, dynamic> json) {
    return TemplateConfig(
      colors: ColorScheme.fromJson(json['colors']),
      typography: TypographyConfig.fromJson(json['typography']),
      layout: LayoutConfig.fromJson(json['layout']),
      branding: BrandingConfig.fromJson(json['branding']),
    );
  }
}

class ColorScheme {
  final String background;
  final String surface;
  final String accent;
  final String textPrimary;
  final String textSecondary;

  ColorScheme({
    required this.background,
    required this.surface,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
  });

  Map<String, dynamic> toJson() {
    return {
      'background': background,
      'surface': surface,
      'accent': accent,
      'textPrimary': textPrimary,
      'textSecondary': textSecondary,
    };
  }

  factory ColorScheme.fromJson(Map<String, dynamic> json) {
    return ColorScheme(
      background: json['background'],
      surface: json['surface'],
      accent: json['accent'],
      textPrimary: json['textPrimary'],
      textSecondary: json['textSecondary'],
    );
  }
}

class TypographyConfig {
  final String headingFont;
  final String bodyFont;
  final double headingSize;
  final double bodySize;
  final double letterSpacing;

  TypographyConfig({
    required this.headingFont,
    required this.bodyFont,
    required this.headingSize,
    required this.bodySize,
    required this.letterSpacing,
  });

  Map<String, dynamic> toJson() {
    return {
      'headingFont': headingFont,
      'bodyFont': bodyFont,
      'headingSize': headingSize,
      'bodySize': bodySize,
      'letterSpacing': letterSpacing,
    };
  }

  factory TypographyConfig.fromJson(Map<String, dynamic> json) {
    return TypographyConfig(
      headingFont: json['headingFont'],
      bodyFont: json['bodyFont'],
      headingSize: json['headingSize'],
      bodySize: json['bodySize'],
      letterSpacing: json['letterSpacing'],
    );
  }
}

class LayoutConfig {
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;
  final double sectionSpacing;
  final bool showClientLogo;
  final bool showAgencyLogo;
  final String headerAlignment; // 'left', 'center', 'right'
  final bool showDividers;

  LayoutConfig({
    required this.marginTop,
    required this.marginBottom,
    required this.marginLeft,
    required this.marginRight,
    required this.sectionSpacing,
    this.showClientLogo = true,
    this.showAgencyLogo = true,
    this.headerAlignment = 'left',
    this.showDividers = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'marginTop': marginTop,
      'marginBottom': marginBottom,
      'marginLeft': marginLeft,
      'marginRight': marginRight,
      'sectionSpacing': sectionSpacing,
      'showClientLogo': showClientLogo,
      'showAgencyLogo': showAgencyLogo,
      'headerAlignment': headerAlignment,
      'showDividers': showDividers,
    };
  }

  factory LayoutConfig.fromJson(Map<String, dynamic> json) {
    return LayoutConfig(
      marginTop: json['marginTop'],
      marginBottom: json['marginBottom'],
      marginLeft: json['marginLeft'],
      marginRight: json['marginRight'],
      sectionSpacing: json['sectionSpacing'],
      showClientLogo: json['showClientLogo'] ?? true,
      showAgencyLogo: json['showAgencyLogo'] ?? true,
      headerAlignment: json['headerAlignment'] ?? 'left',
      showDividers: json['showDividers'] ?? true,
    );
  }
}

class BrandingConfig {
  final String agencyName;
  final String agencyTagline;
  final String contactEmail;
  final String contactPhone;
  final String website;
  final String footerText;

  BrandingConfig({
    required this.agencyName,
    required this.agencyTagline,
    required this.contactEmail,
    required this.contactPhone,
    required this.website,
    required this.footerText,
  });

  Map<String, dynamic> toJson() {
    return {
      'agencyName': agencyName,
      'agencyTagline': agencyTagline,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'website': website,
      'footerText': footerText,
    };
  }

  factory BrandingConfig.fromJson(Map<String, dynamic> json) {
    return BrandingConfig(
      agencyName: json['agencyName'],
      agencyTagline: json['agencyTagline'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      website: json['website'],
      footerText: json['footerText'],
    );
  }
}
