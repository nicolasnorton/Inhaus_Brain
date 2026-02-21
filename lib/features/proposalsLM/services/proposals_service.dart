import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/package.dart';
import '../models/quote.dart';
import '../models/proforma_style.dart';
import '../models/section.dart';

/// Service that mirrors the Express REST API in the web Cotizador.
///
/// All endpoints match the routes defined in `server/routes.ts`:
///   - Quotes  : GET / POST / DELETE  /api/quotes
///   - Packages: GET / POST / PUT / DELETE /api/packages
///   - Styles  : GET / POST / PUT / DELETE /api/styles
///   - Tuneador: POST /api/tune-proforma
///   - Import  : POST /api/import-packages
///   - Upload  : POST /api/upload-document
class ProposalsService {
  final String baseUrl;
  final http.Client _client;

  ProposalsService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // Quotes
  // ---------------------------------------------------------------------------

  Future<List<Quote>> getQuotes() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/quotes'));
    _assertOk(res);
    final List<dynamic> body = json.decode(res.body);
    return body.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Quote> createQuote(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/quotes'),
      headers: _jsonHeaders,
      body: json.encode(data),
    );
    _assertOk(res);
    return Quote.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteQuote(int id) async {
    final res = await _client.delete(Uri.parse('$baseUrl/api/quotes/$id'));
    _assertOk(res);
  }

  // ---------------------------------------------------------------------------
  // Packages
  // ---------------------------------------------------------------------------

  Future<List<Package>> getPackages() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/packages'));
    _assertOk(res);
    final List<dynamic> body = json.decode(res.body);
    return body.map((e) => Package.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Package> createPackage(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/packages'),
      headers: _jsonHeaders,
      body: json.encode(data),
    );
    _assertOk(res);
    return Package.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  Future<void> updatePackage(String slug, Map<String, dynamic> data) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/api/packages/$slug'),
      headers: _jsonHeaders,
      body: json.encode(data),
    );
    _assertOk(res);
  }

  Future<void> deletePackage(String slug, String masterKey, String deletedBy) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/api/packages/$slug'),
      headers: _jsonHeaders,
      body: json.encode({'masterKey': masterKey, 'deletedBy': deletedBy}),
    );
    _assertOk(res);
  }

  Future<List<Package>> getDeletedPackages() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/packages/deleted'));
    _assertOk(res);
    final List<dynamic> body = json.decode(res.body);
    return body.map((e) => Package.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> restorePackage(String slug) async {
    final res = await _client.post(Uri.parse('$baseUrl/api/packages/$slug/restore'));
    _assertOk(res);
  }

  // ---------------------------------------------------------------------------
  // Styles
  // ---------------------------------------------------------------------------

  Future<List<ProformaStyle>> getStyles() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/styles'));
    _assertOk(res);
    final List<dynamic> body = json.decode(res.body);
    return body.map((e) => ProformaStyle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createStyle(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/styles'),
      headers: _jsonHeaders,
      body: json.encode(data),
    );
    _assertOk(res);
  }

  Future<void> updateStyle(int id, Map<String, dynamic> data) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/api/styles/$id'),
      headers: _jsonHeaders,
      body: json.encode(data),
    );
    _assertOk(res);
  }

  Future<void> deleteStyle(int id) async {
    final res = await _client.delete(Uri.parse('$baseUrl/api/styles/$id'));
    _assertOk(res);
  }

  // ---------------------------------------------------------------------------
  // Tuneador (AI text-to-quote)
  // ---------------------------------------------------------------------------

  /// Sends raw proforma text to the Claude-powered back-end and returns the
  /// parsed result (client, discount, applyIva, items[]).
  Future<Map<String, dynamic>> tuneProforma(String text) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/tune-proforma'),
      headers: _jsonHeaders,
      body: json.encode({'text': text}),
    );
    _assertOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Import packages (AI-powered text analysis)
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> importPackages(String text) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/import-packages'),
      headers: _jsonHeaders,
      body: json.encode({'text': text}),
    );
    _assertOk(res);
    final List<dynamic> body = json.decode(res.body);
    return body.cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  void _assertOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }
}
