
class SlideDeck {
  final String id;
  final String reportId;
  final String title;
  final SlideDeckFormat format;
  final String language;
  final SlideDeckLength length;
  final String prompt;
  final DateTime createdAt;
  final String? pdfUrl; // Mock URL for now

  SlideDeck({
    required this.id,
    required this.reportId,
    required this.title,
    required this.format,
    required this.language,
    required this.length,
    required this.prompt,
    required this.createdAt,
    this.pdfUrl,
  });
}

enum SlideDeckFormat {
  detailed,
  presenter,
}

enum SlideDeckLength {
  short,
  standard,
  long,
}
