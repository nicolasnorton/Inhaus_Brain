import 'package:flutter_riverpod/flutter_riverpod.dart';

class MCPTool {
  final String id;
  final String name;
  final String description;
  final String serverId;
  final Map<String, dynamic> schema;

  const MCPTool({
    required this.id,
    required this.name,
    required this.description,
    required this.serverId,
    required this.schema,
  });
}

class MCPServer {
  final String id;
  final String name;
  final String url;
  final bool isConnected;
  final List<MCPTool> tools;

  const MCPServer({
    required this.id,
    required this.name,
    required this.url,
    this.isConnected = false,
    this.tools = const [],
  });
}

final mcpServersProvider = StateNotifierProvider<MCPServerNotifier, List<MCPServer>>((ref) {
  return MCPServerNotifier();
});

class MCPServerNotifier extends StateNotifier<List<MCPServer>> {
  MCPServerNotifier() : super(_getMockServers());

  void addServer(String name, String url) {
    final newServer = MCPServer(
      id: 'mcp-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      url: url,
    );
    state = [...state, newServer];
  }

  void toggleConnection(String id) {
    state = [
      for (final server in state)
        if (server.id == id)
          MCPServer(
            id: server.id,
            name: server.name,
            url: server.url,
            isConnected: !server.isConnected,
            tools: server.isConnected ? [] : _getMockTools(server.id),
          )
        else
          server
    ];
  }

  static List<MCPServer> _getMockServers() {
    return [
      const MCPServer(id: 's1', name: 'Google Search MCP', url: 'http://localhost:8001'),
      const MCPServer(id: 's2', name: 'Filesystem MCP', url: 'http://localhost:8002'),
    ];
  }

  static List<MCPTool> _getMockTools(String serverId) {
    if (serverId == 's1') {
      return [
        const MCPTool(id: 'google_search', name: 'Google Search', description: 'Search the web using Google', serverId: 's1', schema: {}),
      ];
    }
    return [
      const MCPTool(id: 'read_file', name: 'Read File', description: 'Read content from a local file', serverId: 's2', schema: {}),
      const MCPTool(id: 'write_file', name: 'Write File', description: 'Write content to a local file', serverId: 's2', schema: {}),
    ];
  }
}

final availableToolsProvider = Provider<List<MCPTool>>((ref) {
  final servers = ref.watch(mcpServersProvider);
  return servers.expand((s) => s.tools).toList();
});
