import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent_tool.dart';
import '../../services/figma_service.dart';

/// MCP Tool: Fetch a Figma file's structure as JSON.
///
/// Parameters:
///   fileKey (String, required) — Figma file key
///   token   (String, required) — Figma Personal Access Token
class FigmaGetFileTool extends AgentTool {
  final Ref _ref;

  FigmaGetFileTool(this._ref)
      : super(
          name: 'figma_get_file',
          description:
              'Fetch a Figma file\'s structure including frames, components, and styles. '
              'Returns the full document tree as JSON.',
          inputSchema: {
            'fileKey': {
              'type': 'string',
              'description': 'The Figma file key (from the URL)',
            },
            'token': {
              'type': 'string',
              'description': 'Figma Personal Access Token',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters,
      {dynamic ref}) async {
    try {
      final fileKey = parameters['fileKey'] as String? ?? '';
      final token = parameters['token'] as String? ?? '';
      if (fileKey.isEmpty || token.isEmpty) {
        return ToolResult.failure('fileKey and token are required');
      }

      final figma = _ref.read(figmaServiceProvider);
      final file = await figma.getFile(fileKey, token: token);
      return ToolResult.success(file.toJson());
    } catch (e) {
      return ToolResult.failure('figma_get_file failed: $e');
    }
  }
}

/// MCP Tool: Export Figma frames/components as image URLs.
///
/// Parameters:
///   fileKey (String, required)
///   nodeIds (List of String, required) — comma-separated node IDs
///   format  (String, optional) — 'png', 'svg', 'pdf' (default: 'png')
///   token   (String, required)
class FigmaExportNodesTool extends AgentTool {
  final Ref _ref;

  FigmaExportNodesTool(this._ref)
      : super(
          name: 'figma_export_nodes',
          description:
              'Export specific Figma frames or components as PNG, SVG, or PDF image URLs.',
          inputSchema: {
            'fileKey': {
              'type': 'string',
              'description': 'The Figma file key',
            },
            'nodeIds': {
              'type': 'string',
              'description':
                  'Comma-separated list of node IDs to export',
            },
            'format': {
              'type': 'string',
              'description':
                  'Export format: png, svg, or pdf (default: png)',
            },
            'token': {
              'type': 'string',
              'description': 'Figma Personal Access Token',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters,
      {dynamic ref}) async {
    try {
      final fileKey = parameters['fileKey'] as String? ?? '';
      final nodeIdsStr = parameters['nodeIds'] as String? ?? '';
      final format = parameters['format'] as String? ?? 'png';
      final token = parameters['token'] as String? ?? '';

      if (fileKey.isEmpty || nodeIdsStr.isEmpty || token.isEmpty) {
        return ToolResult.failure(
            'fileKey, nodeIds, and token are required');
      }

      final nodeIds =
          nodeIdsStr.split(',').map((s) => s.trim()).toList();
      final figma = _ref.read(figmaServiceProvider);
      final urls = await figma.exportNodes(
        fileKey,
        nodeIds,
        format: format,
        token: token,
      );

      return ToolResult.success({
        'imageUrls': urls,
        'format': format,
        'nodeCount': nodeIds.length,
      });
    } catch (e) {
      return ToolResult.failure('figma_export_nodes failed: $e');
    }
  }
}

/// MCP Tool: List all projects and files in a Figma team.
///
/// Parameters:
///   teamId (String, required) — Figma team ID
///   token  (String, required)
class FigmaListProjectsTool extends AgentTool {
  final Ref _ref;

  FigmaListProjectsTool(this._ref)
      : super(
          name: 'figma_list_projects',
          description:
              'List all projects and their files in a Figma team for discovery.',
          inputSchema: {
            'teamId': {
              'type': 'string',
              'description': 'Figma team ID',
            },
            'token': {
              'type': 'string',
              'description': 'Figma Personal Access Token',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters,
      {dynamic ref}) async {
    try {
      final teamId = parameters['teamId'] as String? ?? '';
      final token = parameters['token'] as String? ?? '';
      if (teamId.isEmpty || token.isEmpty) {
        return ToolResult.failure('teamId and token are required');
      }

      final figma = _ref.read(figmaServiceProvider);
      final projects =
          await figma.listTeamProjects(teamId, token: token);

      return ToolResult.success({
        'projects': projects
            .map((p) => {'id': p.id, 'name': p.name})
            .toList(),
        'count': projects.length,
      });
    } catch (e) {
      return ToolResult.failure('figma_list_projects failed: $e');
    }
  }
}

/// MCP Tool: Post a review comment on a Figma file.
///
/// Parameters:
///   fileKey  (String, required)
///   message  (String, required)
///   nodeId   (String, optional) — attach comment to a specific node
///   imageUrl (String, optional) — embed image URL in the comment
///   token    (String, required)
class FigmaPostCommentTool extends AgentTool {
  final Ref _ref;

  FigmaPostCommentTool(this._ref)
      : super(
          name: 'figma_post_comment',
          description:
              'Post a review comment on a Figma file, optionally targeting a specific node '
              'and embedding an image URL.',
          inputSchema: {
            'fileKey': {
              'type': 'string',
              'description': 'The Figma file key',
            },
            'message': {
              'type': 'string',
              'description': 'Comment message text',
            },
            'nodeId': {
              'type': 'string',
              'description': 'Optional node ID to attach comment to',
            },
            'imageUrl': {
              'type': 'string',
              'description':
                  'Optional image URL to embed in the comment',
            },
            'token': {
              'type': 'string',
              'description': 'Figma Personal Access Token',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters,
      {dynamic ref}) async {
    try {
      final fileKey = parameters['fileKey'] as String? ?? '';
      final message = parameters['message'] as String? ?? '';
      final token = parameters['token'] as String? ?? '';

      if (fileKey.isEmpty || message.isEmpty || token.isEmpty) {
        return ToolResult.failure(
            'fileKey, message, and token are required');
      }

      final figma = _ref.read(figmaServiceProvider);
      await figma.postComment(
        fileKey,
        message,
        nodeId: parameters['nodeId'] as String?,
        imageUrl: parameters['imageUrl'] as String?,
        token: token,
      );

      return ToolResult.success({
        'posted': true,
        'fileKey': fileKey,
      });
    } catch (e) {
      return ToolResult.failure('figma_post_comment failed: $e');
    }
  }
}
