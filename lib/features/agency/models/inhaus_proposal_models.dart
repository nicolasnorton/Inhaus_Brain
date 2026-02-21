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

/// Line item for per-service pricing in one-page quote
class InhausLineItem {
  final String serviceName;            // e.g., "PAQUETE STARTER"
  final String price;                  // e.g., "$1,500.00"
  final String? paymentType;           // e.g., "Pago mensual", "Precio", "Pago único"
  final String? description;           // Brief description of deliverables

  InhausLineItem({
    required this.serviceName,
    required this.price,
    this.paymentType,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'service_name': serviceName,
    'price': price,
    'payment_type': paymentType,
    'description': description,
  };

  factory InhausLineItem.fromJson(Map<String, dynamic> json) {
    return InhausLineItem(
      serviceName: json['service_name'] ?? json['serviceName'] ?? '',
      price: json['price'] ?? '\$0.00',
      paymentType: json['payment_type'] ?? json['paymentType'],
      description: json['description'],
    );
  }
}

/// Section for detailed multi-page proposal
class InhausProposalSection {
  final String title;                  // e.g., "RRSS / FACEBOOK INSTAGRAM"
  final String? introParagraph;        // AI-generated intro paragraph
  final String? ejecucion;             // Execution timeline/process
  final List<String>? incluye;         // "Incluye:" items (what's included)
  final List<String>? noIncluye;       // "No incluye:" items (what's NOT included)
  final List<String>? equipo;          // Team members assigned
  final List<String>? entregables;     // Deliverables list
  final InhausPrice price;             // Price box
  
  // Legacy fields for backwards compatibility
  final String? description;           // Deprecated: use introParagraph
  final List<String> bullets;          // Deprecated: use specific sections
  final List<String>? includes;        // Deprecated: use incluye
  final List<String>? excludes;        // Deprecated: use noIncluye

  InhausProposalSection({
    required this.title,
    this.introParagraph,
    this.ejecucion,
    this.incluye,
    this.noIncluye,
    this.equipo,
    this.entregables,
    required this.price,
    // Legacy fields
    this.description,
    this.bullets = const [],
    this.includes,
    this.excludes,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'intro_paragraph': introParagraph,
    'ejecucion': ejecucion,
    'incluye': incluye,
    'no_incluye': noIncluye,
    'equipo': equipo,
    'entregables': entregables,
    'price': price.toJson(),
    // Legacy fields
    'description': description,
    'bullets': bullets,
    'includes': includes,
    'excludes': excludes,
  };

  factory InhausProposalSection.fromJson(Map<String, dynamic> json) {
    return InhausProposalSection(
      title: json['title'] ?? '',
      introParagraph: json['intro_paragraph'],
      ejecucion: json['ejecucion'],
      incluye: (json['incluye'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      noIncluye: (json['no_incluye'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      equipo: (json['equipo'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      entregables: (json['entregables'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      price: InhausPrice.fromJson(json['price'] ?? {}),
      // Legacy fields for backwards compatibility
      description: json['description'],
      bullets: (json['bullets'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      includes: (json['includes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      excludes: (json['excludes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
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
  final String introParagraph;         // AI-generated intro paragraph
  final String? ejecucion;             // Execution timeline/process
  final List<String> incluye;          // What's included
  final List<String> noIncluye;        // What's NOT included
  final List<String> equipo;           // Team members
  final List<String> entregables;      // Deliverables
  final InhausPrice precio;            // Total price
  
  // Pricing breakdown (cotizador parity)
  final List<InhausLineItem> lineItems;  // Per-service pricing
  final String? subtotal;                // e.g. "$3,000.00"
  final String? descuento;               // e.g. "— $300.00"
  final double? descuentoPct;            // e.g. 10.0
  final String? ivaAmount;               // e.g. "$405.00"
  final bool applyIva;                   // Whether IVA is applied
  
  // Legacy fields for backwards compatibility
  final String intro;                  // Deprecated: use introParagraph
  final List<String> keyServices;      // Deprecated: use incluye
  final InhausPrice totalPrice;        // Deprecated: use precio
  final String cta;                    // Call to action (still used)

  InhausQuoteSummary({
    required this.introParagraph,
    this.ejecucion,
    this.incluye = const [],
    this.noIncluye = const [],
    this.equipo = const [],
    this.entregables = const [],
    required this.precio,
    // Pricing breakdown
    this.lineItems = const [],
    this.subtotal,
    this.descuento,
    this.descuentoPct,
    this.ivaAmount,
    this.applyIva = false,
    // Legacy fields
    String? intro,
    List<String>? keyServices,
    InhausPrice? totalPrice,
    this.cta = '',
  }) : intro = intro ?? introParagraph,
       keyServices = keyServices ?? incluye,
       totalPrice = totalPrice ?? precio;

  Map<String, dynamic> toJson() => {
    'intro_paragraph': introParagraph,
    'ejecucion': ejecucion,
    'incluye': incluye,
    'no_incluye': noIncluye,
    'equipo': equipo,
    'entregables': entregables,
    'precio': precio.toJson(),
    'line_items': lineItems.map((e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'descuento': descuento,
    'descuento_pct': descuentoPct,
    'iva_amount': ivaAmount,
    'apply_iva': applyIva,
    'cta': cta,
    // Legacy fields
    'intro': intro,
    'key_services': keyServices,
    'total_price': totalPrice.toJson(),
  };

  factory InhausQuoteSummary.fromJson(Map<String, dynamic> json) {
    final introParagraph = json['intro_paragraph'] ?? json['intro'] ?? '';
    final precio = InhausPrice.fromJson(json['precio'] ?? json['total_price'] ?? {});
    
    return InhausQuoteSummary(
      introParagraph: introParagraph,
      ejecucion: json['ejecucion'],
      incluye: (json['incluye'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      noIncluye: (json['no_incluye'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      equipo: (json['equipo'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      entregables: (json['entregables'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      precio: precio,
      // Pricing breakdown
      lineItems: (json['line_items'] as List<dynamic>?)?.map((e) => InhausLineItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      subtotal: json['subtotal'],
      descuento: json['descuento'],
      descuentoPct: (json['descuento_pct'] as num?)?.toDouble(),
      ivaAmount: json['iva_amount'],
      applyIva: json['apply_iva'] ?? false,
      cta: json['cta'] ?? '',
      // Legacy fields
      intro: json['intro'],
      keyServices: (json['key_services'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      totalPrice: json['total_price'] != null ? InhausPrice.fromJson(json['total_price']) : null,
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
