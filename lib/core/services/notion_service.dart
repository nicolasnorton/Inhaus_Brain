import 'dart:convert';
import 'package:http/http.dart' as http;

class NotionService {
  final String? apiKey;

  NotionService({this.apiKey});

  Future<Map<String, dynamic>> search(String query) async {
    if (apiKey == null) throw Exception("Notion API Key not provided");

    final response = await http.post(
      Uri.parse('https://api.notion.com/v1/search'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Notion-Version': '2022-06-28',
      },
      body: jsonEncode({
        'query': query,
        'sort': {
          'direction': 'descending',
          'timestamp': 'last_edited_time',
        },
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search Notion: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getPage(String pageId) async {
    if (apiKey == null) throw Exception("Notion API Key not provided");

    final response = await http.get(
      Uri.parse('https://api.notion.com/v1/pages/$pageId'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Notion-Version': '2022-06-28',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get Notion page: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createPage(String parentId, String title, {List<Map<String, dynamic>>? children}) async {
    if (apiKey == null) throw Exception("Notion API Key not provided");

    final response = await http.post(
      Uri.parse('https://api.notion.com/v1/pages'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Notion-Version': '2022-06-28',
      },
      body: jsonEncode({
        'parent': {'database_id': parentId},
        'properties': {
          'title': {
            'title': [
              {'text': {'content': title}}
            ]
          }
        },
        if (children != null) 'children': children,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create Notion page: ${response.body}');
    }
  }
}
