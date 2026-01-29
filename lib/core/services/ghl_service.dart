import 'dart:convert';
import 'package:http/http.dart' as http;

class GHLService {
  final String? apiKey;
  final String? locationId;

  GHLService({this.apiKey, this.locationId});

  Future<Map<String, dynamic>> listContacts({int limit = 20}) async {
    if (apiKey == null || locationId == null) throw Exception("GHL API Key or Location ID not provided");

    final response = await http.get(
      Uri.parse('https://rest.gohighlevel.com/v1/contacts/?locationId=$locationId&limit=$limit'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to list GHL contacts: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getOpportunities() async {
    if (apiKey == null || locationId == null) throw Exception("GHL API Key or Location ID not provided");

    final response = await http.get(
      Uri.parse('https://rest.gohighlevel.com/v1/pipelines/'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get GHL opportunities: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createContact(Map<String, dynamic> contactData) async {
    if (apiKey == null || locationId == null) throw Exception("GHL API Key or Location ID not provided");

    final response = await http.post(
      Uri.parse('https://rest.gohighlevel.com/v1/contacts/'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        ...contactData,
        'locationId': locationId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create GHL contact: ${response.body}');
    }
  }
}
