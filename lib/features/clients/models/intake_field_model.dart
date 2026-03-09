/// Defines the type of input expected for an intake field.
enum IntakeFieldType {
  text,
  selection,
  date,
}

/// Defines which client type a field applies to.
enum IntakeFieldScope {
  corporate,
  independent,
  both,
}

/// A single field definition in the conversational intake flow.
class IntakeFormField {
  final String key;
  final String label;
  final String question;
  final IntakeFieldType type;
  final bool isRequired;
  final List<String> options;
  final IntakeFieldScope scope;
  final String? hint;

  const IntakeFormField({
    required this.key,
    required this.label,
    required this.question,
    this.type = IntakeFieldType.text,
    this.isRequired = false,
    this.options = const [],
    this.scope = IntakeFieldScope.both,
    this.hint,
  });

  /// The full ordered field list for corporate clients.
  static List<IntakeFormField> get corporateFields => _allFields
      .where((f) =>
          f.scope == IntakeFieldScope.both ||
          f.scope == IntakeFieldScope.corporate)
      .toList();

  /// The full ordered field list for independent clients.
  static List<IntakeFormField> get independentFields => _allFields
      .where((f) =>
          f.scope == IntakeFieldScope.both ||
          f.scope == IntakeFieldScope.independent)
      .toList();

  static const List<IntakeFormField> _allFields = [
    // ── Basic Info ───────────────────────────────────────────────
    IntakeFormField(
      key: 'name',
      label: 'Company Name',
      question:
          "Great! Let's start with the basics. What's the **company name**?",
      isRequired: true,
      scope: IntakeFieldScope.corporate,
    ),
    IntakeFormField(
      key: 'name',
      label: 'Full Name',
      question:
          "Great! Let's start with the basics. What's the **full name** of this professional?",
      isRequired: true,
      scope: IntakeFieldScope.independent,
    ),
    IntakeFormField(
      key: 'industry',
      label: 'Industry',
      question:
          'What **industry** does this company operate in? (e.g. Technology, Healthcare, Finance)',
      isRequired: true,
      scope: IntakeFieldScope.corporate,
    ),
    IntakeFormField(
      key: 'industry',
      label: 'Profession',
      question:
          "What's their **profession or title**? (e.g. Photographer, Consultant, Designer)",
      isRequired: true,
      scope: IntakeFieldScope.independent,
    ),

    // ── Legal & Fiscal ──────────────────────────────────────────
    IntakeFormField(
      key: 'legalName',
      label: 'Legal Name (Razón Social)',
      question: "What's the **legal name** (Razón Social)?",
      isRequired: true,
      scope: IntakeFieldScope.corporate,
    ),
    IntakeFormField(
      key: 'legalName',
      label: 'Legal Full Name',
      question: "What's their **legal full name** (as it appears on official documents)?",
      isRequired: true,
      scope: IntakeFieldScope.independent,
    ),
    IntakeFormField(
      key: 'taxId',
      label: 'Tax ID (RUC)',
      question: "What's the **Tax ID (RUC)**?",
      isRequired: true,
      scope: IntakeFieldScope.corporate,
    ),
    IntakeFormField(
      key: 'taxId',
      label: 'Personal Tax ID',
      question: "What's their **personal Tax ID** (Cédula or RUC)?",
      isRequired: true,
      scope: IntakeFieldScope.independent,
    ),
    IntakeFormField(
      key: 'fiscalAddress',
      label: 'Fiscal Address',
      question: "What's the **fiscal address**? You can skip this if you don't have it right now.",
      scope: IntakeFieldScope.both,
    ),

    // ── Contact & Profile ───────────────────────────────────────
    IntakeFormField(
      key: 'email',
      label: 'Primary Email',
      question: "What's the **primary contact email**?",
      hint: 'e.g. hello@company.com',
      scope: IntakeFieldScope.both,
    ),
    IntakeFormField(
      key: 'website',
      label: 'Website',
      question: "Do they have a **website**? Drop the URL here, or skip.",
      scope: IntakeFieldScope.corporate,
    ),
    IntakeFormField(
      key: 'address',
      label: 'Office Address',
      question: "What's the **office address**?",
      scope: IntakeFieldScope.corporate,
    ),
    IntakeFormField(
      key: 'size',
      label: 'Company Size',
      question: 'How large is the company? Pick the closest range:',
      type: IntakeFieldType.selection,
      options: [
        '1-10',
        '11-50',
        '51-200',
        '201-500',
        '500+',
      ],
      scope: IntakeFieldScope.corporate,
    ),
    IntakeFormField(
      key: 'portfolioUrl',
      label: 'Portfolio URL',
      question: "Do they have a **portfolio** link?",
      scope: IntakeFieldScope.independent,
    ),
    IntakeFormField(
      key: 'linkedinUrl',
      label: 'LinkedIn',
      question: "What about their **LinkedIn** profile URL?",
      scope: IntakeFieldScope.independent,
    ),

    // ── Description ─────────────────────────────────────────────
    IntakeFormField(
      key: 'description',
      label: 'Notes',
      question:
          'Almost done! Any **additional notes or description** for this client? (or skip)',
      scope: IntakeFieldScope.both,
    ),
  ];
}
