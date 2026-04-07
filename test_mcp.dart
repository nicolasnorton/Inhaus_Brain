import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://brainweave-mcp-1096509611056.us-central1.run.app';
  final endpoint = 'brainweave_graph_data';
  
  print('Testing MCP endpoint: $baseUrl/$endpoint');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    ).timeout(const Duration(seconds: 10));

    print('Status: ${response.statusCode}');
    print('Body: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final nodes = data['nodes'] ?? [];
      final edges = data['edges'] ?? [];
      print('Nodes count: ${nodes.length}');
      print('Edges count: ${edges.length}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
