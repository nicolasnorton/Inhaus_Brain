import 'dart:async';

enum ResearchToolType {
  webSearch,
  pageScraper,
  trendAnalysis,
  socialListening
}

class ResearchToolResult {
  final String query;
  final String result;
  final ResearchToolType type;

  ResearchToolResult({
    required this.query,
    required this.result,
    required this.type,
  });
}

class WebResearchService {
  static final _statusController = StreamController<String>.broadcast();
  static Stream<String> get statusStream => _statusController.stream;

  static Future<ResearchToolResult> performSearch(String query) async {
    _statusController.add('Searching the web for "$query"...');
    await Future.delayed(const Duration(seconds: 2));
    
    _statusController.add('Analyzing search results for market fit...');
    await Future.delayed(const Duration(milliseconds: 1500));

    String mockResult = 'Synthesized trends for "$query": High demand for eco-friendly packaging in the Gen-Z segment. Competitors are moving towards minimalist design and transparent supply chains.';
    
    _statusController.add('Search complete.');
    return ResearchToolResult(
      query: query,
      result: mockResult,
      type: ResearchToolType.webSearch,
    );
  }

  static Future<ResearchToolResult> scrapeCompetitor(String url) async {
    _statusController.add('Navigating to $url...');
    await Future.delayed(const Duration(seconds: 2));

    _statusController.add('Extracting value propositions and visual styles...');
    await Future.delayed(const Duration(milliseconds: 1800));

    String mockResult = 'Competitor at $url uses high-contrast typography and emphasizes fast delivery. Their "About Us" section prioritizes ethical sourcing.';

    _statusController.add('Scraping complete.');
    return ResearchToolResult(
      query: url,
      result: mockResult,
      type: ResearchToolType.pageScraper,
    );
  }
}
