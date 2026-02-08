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
  Future<Map<String, dynamic>> updateContact(String contactId, Map<String, dynamic> updateData) async {
    if (apiKey == null || locationId == null) throw Exception("GHL API Key or Location ID not provided");

    final response = await http.put(
      Uri.parse('https://rest.gohighlevel.com/v1/contacts/$contactId'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update GHL contact: ${response.body}');
    }
  }

  Future<void> addTag(String contactId, String tag) async {
    if (apiKey == null || locationId == null) throw Exception("GHL API Key or Location ID not provided");

    final response = await http.post(
      Uri.parse('https://rest.gohighlevel.com/v1/contacts/$contactId/tags'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tags': [tag]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add tag to GHL contact: ${response.body}');
    }
  }

  Future<void> addNote(String contactId, String noteContent) async {
    if (apiKey == null || locationId == null) throw Exception("GHL API Key or Location ID not provided");

    final response = await http.post(
      Uri.parse('https://rest.gohighlevel.com/v1/contacts/$contactId/notes'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'body': noteContent,
        'userId': '' // Optional: ID of the user creating the note
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add note to GHL contact: ${response.body}');
    }
  }

  Future<void> deleteContact(String contactId) async {
    if (apiKey == null || locationId == null) throw Exception("GHL API Key or Location ID not provided");

    final response = await http.delete(
      Uri.parse('https://rest.gohighlevel.com/v1/contacts/$contactId'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete GHL contact: ${response.body}');
    }
  }
}
