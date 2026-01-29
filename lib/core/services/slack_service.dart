import 'dart:convert';
import 'package:http/http.dart' as http;

class SlackService {
  final String? token;

  SlackService({this.token});

  Future<Map<String, dynamic>> listChannels() async {
    if (token == null) throw Exception("Slack token not provided");

    final response = await http.get(
      Uri.parse('https://slack.com/api/conversations.list'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (data['ok'] == true) {
      return data;
    } else {
      throw Exception('Failed to list Slack channels: ${data['error']}');
    }
  }

  Future<Map<String, dynamic>> postMessage(String channel, String text) async {
    if (token == null) throw Exception("Slack token not provided");

    final response = await http.post(
      Uri.parse('https://slack.com/api/chat.postMessage'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'channel': channel,
        'text': text,
      }),
    );

    final data = jsonDecode(response.body);
    if (data['ok'] == true) {
      return data;
    } else {
      throw Exception('Failed to post Slack message: ${data['error']}');
    }
  }

  Future<Map<String, dynamic>> getHistory(String channel, {int limit = 10}) async {
    if (token == null) throw Exception("Slack token not provided");

    final response = await http.get(
      Uri.parse('https://slack.com/api/conversations.history?channel=$channel&limit=$limit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (data['ok'] == true) {
      return data;
    } else {
      throw Exception('Failed to get Slack history: ${data['error']}');
    }
  }
}
