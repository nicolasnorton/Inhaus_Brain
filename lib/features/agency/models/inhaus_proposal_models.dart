/// INHAUS-Style Proposal Data Models
/// Exact replication of INHAUS proposal format with dark purple theme

enum ProposalType {
  onePageQuote,      // Condensed single-page summary
  detailedMultiPage, // Full multi-page INHAUS-style proposal
}

enum ProposalFormat {
  pdf,          // Portrait PDF (primary)
  googleSlides, // Landscape deck (secondary)
}

enum ProposalLanguage {
  spanish,      // Primary (Español)
  english,      // Optional (English)
}

/// Header for all INHAUS proposals
class InhausProposalHeader {
  final String agencyTitle;      // "INHAUS ESTUDIO CREATIVO"
  final String clientName;       // e.g., "Inhaus Client"
  final String? clientLogoUrl;   // Optional client logo
  final String date;             // e.g., "Febrero, 4 - 2026"

  InhausProposalHeader({
    required this.agencyTitle,
    required this.clientName,
    this.clientLogoUrl,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'agency_title': agencyTitle,
    'client_name': clientName,
    'client_logo_url': clientLogoUrl,
    'date': date,
  };

  factory InhausProposalHeader.fromJson(Map<String, dynamic> json) {
    return InhausProposalHeader(
      agencyTitle: json['agency_title'] ?? 'INHAUS ESTUDIO CREATIVO',
      clientName: json['client_name'] ?? '',
      clientLogoUrl: json['client_logo_url'],
      date: json['date'] ?? '',
    );
  }
}

/// Price information for a service
class InhausPrice {
  final String label;  // e.g., "PRECIO MENSUAL:"
  final String amount; // e.g., "$1500.00"

  InhausPrice({
    required this.label,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'amount': amount,
  };

  factory InhausPrice.fromJson(Map<String, dynamic> json) {
    return InhausPrice(
      label: json['label'] ?? 'PRECIO:',
      amount: json['amount'] ?? '\$0.00',
    );
  }
}

/// Section for detailed multi-page proposal
class InhausProposalSection {
  final String title;              // e.g., "RRSS / FACEBOOK INSTAGRAM"
  final String? description;       // Optional description text
  final List<String> bullets;      // Main bullet points
  final List<String>? includes;    // "Incluye:" items
  final List<String>? excludes;    // "No incluye:" items
  final InhausPrice price;           // Price box

  InhausProposalSection({
    required this.title,
    this.description,
    this.bullets = const [],
    this.includes,
    this.excludes,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'bullets': bullets,
    'includes': includes,
    'excludes': excludes,
    'price': price.toJson(),
  };

  factory InhausProposalSection.fromJson(Map<String, dynamic> json) {
    return InhausProposalSection(
      title: json['title'] ?? '',
      description: json['description'],
      bullets: (json['bullets'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      includes: (json['includes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      excludes: (json['excludes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      price: InhausPrice.fromJson(json['price'] ?? {}),
    );
  }
}

/// Detailed multi-page INHAUS proposal
class InhausDetailedProposal {
  final ProposalType type = ProposalType.detailedMultiPage;
  final ProposalFormat format;
  final InhausProposalHeader header;
  final List<InhausProposalSection> sections;
  final String footer;                    // e.g., "inhauscorp.com"
  final List<String> embeddedImages;      // Optional Creative Studio images

  InhausDetailedProposal({
    required this.format,
    required this.header,
    required this.sections,
    this.footer = 'inhauscorp.com',
    this.embeddedImages = const [],
  });

  Map<String, dynamic> toJson() => {
    'type': 'detailed',
    'format': format == ProposalFormat.pdf ? 'pdf' : 'slides',
    'header': header.toJson(),
    'sections': sections.map((s) => s.toJson()).toList(),
    'footer': footer,
    'embedded_images': embeddedImages,
  };

  factory InhausDetailedProposal.fromJson(Map<String, dynamic> json) {
    final formatStr = json['format'] ?? 'pdf';
    return InhausDetailedProposal(
      format: formatStr == 'slides' || formatStr == 'googleSlides' 
          ? ProposalFormat.googleSlides 
          : ProposalFormat.pdf,
      header: InhausProposalHeader.fromJson(json['header'] ?? {}),
      sections: (json['sections'] as List<dynamic>?)
          ?.map((s) => InhausProposalSection.fromJson(s))
          .toList() ?? [],
      footer: json['footer'] ?? 'inhauscorp.com',
      embeddedImages: (json['embedded_images'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}

/// Summary for one-page quote
class InhausQuoteSummary {
  final String intro;              // Brief introduction
  final List<String> keyServices;  // Key services list
  final InhausPrice totalPrice;      // Total price
  final String cta;                // Call to action

  InhausQuoteSummary({
    required this.intro,
    required this.keyServices,
    required this.totalPrice,
    required this.cta,
  });

  Map<String, dynamic> toJson() => {
    'intro': intro,
    'key_services': keyServices,
    'total_price': totalPrice.toJson(),
    'cta': cta,
  };

  factory InhausQuoteSummary.fromJson(Map<String, dynamic> json) {
    return InhausQuoteSummary(
      intro: json['intro'] ?? '',
      keyServices: (json['key_services'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      totalPrice: InhausPrice.fromJson(json['total_price'] ?? {}),
      cta: json['cta'] ?? '',
    );
  }
}

/// One-page quote INHAUS proposal
class InhausOnePageQuote {
  final ProposalType type = ProposalType.onePageQuote;
  final ProposalFormat format;
  final InhausProposalHeader header;
  final InhausQuoteSummary summary;
  final String footer;                    // e.g., "inhauscorp.com"
  final List<String> embeddedImages;      // Optional hero image

  InhausOnePageQuote({
    required this.format,
    required this.header,
    required this.summary,
    this.footer = 'inhauscorp.com',
    this.embeddedImages = const [],
  });

  Map<String, dynamic> toJson() => {
    'type': 'one_page',
    'format': format == ProposalFormat.pdf ? 'pdf' : 'slides',
    'header': header.toJson(),
    'summary': summary.toJson(),
    'footer': footer,
    'embedded_images': embeddedImages,
  };

  factory InhausOnePageQuote.fromJson(Map<String, dynamic> json) {
    final formatStr = json['format'] ?? 'pdf';
    return InhausOnePageQuote(
      format: formatStr == 'slides' || formatStr == 'googleSlides'
          ? ProposalFormat.googleSlides
          : ProposalFormat.pdf,
      header: InhausProposalHeader.fromJson(json['header'] ?? {}),
      summary: InhausQuoteSummary.fromJson(json['summary'] ?? {}),
      footer: json['footer'] ?? 'inhauscorp.com',
      embeddedImages: (json['embedded_images'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}

/// INHAUS Color Palette
class InhausColors {
  static const background = '#05050B';      // Dark/Black
  static const card = '#0F0F16';            // Subtle card elevation
  static const sectionHeader = '#1A1423';   // Rounded purple bars
  static const textPrimary = '#FFFFFF';     // White
  static const textSecondary = '#A0A0A0';   // Light Gray
  static const priceBox = '#1A1423';        // Match section header style
  static const divider = '#1A1423';         // Dark purple-black
}
