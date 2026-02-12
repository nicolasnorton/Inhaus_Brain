import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/stitch_service.dart';
import '../agent_tool.dart';
import '../../../config/feature_flags.dart';

// ─── Base Stitch Tool ────────────────────────────────────────────────────────

abstract class StitchTool extends AgentTool {
  final Ref ref;

  StitchTool(this.ref, {
    required String name,
    required String description,
    required Map<String, dynamic> inputSchema,
  }) : super(
         name: name,
         description: description,
         inputSchema: inputSchema,
       );

  void _checkFeature() {
    if (!FeatureFlags.enableStitch) {
      throw Exception('Stitch integration is disabled.');
    }
  }

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      _checkFeature();
      return await executeStitch(parameters);
    } catch (e) {
      return ToolResult.failure('Stitch Error: $e');
    }
  }

  Future<ToolResult> executeStitch(Map<String, dynamic> parameters);
}

// ─── Concrete Tools ──────────────────────────────────────────────────────────

class StitchCreateProjectTool extends StitchTool {
  StitchCreateProjectTool(super.ref)
      : super(
          name: 'stitch_create_project',
          description: 'Create a new Stitch project for UI/web design.',
          inputSchema: {
            'name': {'type': 'string', 'description': 'Display name of the project.'},
            'description': {'type': 'string', 'description': 'Description of the project.'},
          },
        );

  @override
  Future<ToolResult> executeStitch(Map<String, dynamic> parameters) async {
    final name = parameters['name'] as String;
    final description = parameters['description'] as String?;

    final project = await ref.read(stitchServiceProvider).createProject(
      name: name,
      description: description,
    );

    return ToolResult.success({
      'project_id': project.id,
      'name': project.displayName,
      'status': 'created',
    });
  }
}

class StitchListProjectsTool extends StitchTool {
  StitchListProjectsTool(super.ref)
      : super(
          name: 'stitch_list_projects',
          description: 'List recent Stitch projects.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> executeStitch(Map<String, dynamic> parameters) async {
    final projects = await ref.read(stitchServiceProvider).listProjects();
    
    return ToolResult.success({
      'projects': projects.map((p) => {
        'id': p.id,
        'name': p.displayName,
        'description': p.description,
      }).toList(),
    });
  }
}

class StitchGenerateScreenTool extends StitchTool {
  StitchGenerateScreenTool(super.ref)
      : super(
          name: 'stitch_generate_screen',
          description: 'Generate or refine a UI screen design from a text prompt.',
          inputSchema: {
            'project_id': {'type': 'string', 'description': 'ID of the project.'},
            'prompt': {'type': 'string', 'description': 'Description of the UI to generate.'},
            'screen_id': {'type': 'string', 'description': 'Optional. ID of existing screen to refine.'},
          },
        );

  @override
  Future<ToolResult> executeStitch(Map<String, dynamic> parameters) async {
    final projectId = parameters['project_id'] as String;
    final prompt = parameters['prompt'] as String;
    final screenId = parameters['screen_id'] as String?;

    final screen = await ref.read(stitchServiceProvider).generateScreen(
      projectId: projectId,
      prompt: prompt,
      screenId: screenId,
    );

    return ToolResult.success({
      'screen_id': screen.id,
      'image_url': screen.imageUrl ?? '',
      'status': 'generated',
    });
  }
}

class StitchGetScreenCodeTool extends StitchTool {
  StitchGetScreenCodeTool(super.ref)
      : super(
          name: 'stitch_get_code',
          description: 'Get the code for a specific screen.',
          inputSchema: {
            'project_id': {'type': 'string', 'description': 'ID of the project.'},
            'screen_id': {'type': 'string', 'description': 'ID of the screen.'},
          },
        );

  @override
  Future<ToolResult> executeStitch(Map<String, dynamic> parameters) async {
    final projectId = parameters['project_id'] as String;
    final screenId = parameters['screen_id'] as String;

    final code = await ref.read(stitchServiceProvider).getScreenCode(
      projectId: projectId,
      screenId: screenId,
    );

    return ToolResult.success({
      'screen_id': screenId,
      'code': code,
    });
  }
}

class StitchExtractDesignContextTool extends StitchTool {
  StitchExtractDesignContextTool(super.ref)
      : super(
          name: 'stitch_extract_design',
          description: 'Extract design tokens (colors, fonts) and components from a screen.',
          inputSchema: {
            'project_id': {'type': 'string', 'description': 'ID of the project.'},
            'screen_id': {'type': 'string', 'description': 'ID of the screen.'},
          },
        );

  @override
  Future<ToolResult> executeStitch(Map<String, dynamic> parameters) async {
    final projectId = parameters['project_id'] as String;
    final screenId = parameters['screen_id'] as String;

    final context = await ref.read(stitchServiceProvider).extractDesignContext(
      projectId: projectId,
      screenId: screenId,
    );

    return ToolResult.success({
      'styles': context.styles,
      'components': context.components,
    });
  }
}

class StitchBuildSiteTool extends StitchTool {
  StitchBuildSiteTool(super.ref)
      : super(
          name: 'stitch_build_site',
          description: 'Build and deploy a site from project screens.',
          inputSchema: {
            'project_id': {'type': 'string', 'description': 'ID of the project.'},
            'routes': {
              'type': 'array',
              'description': 'List of screen IDs to include in the build.',
              'items': {'type': 'string'}
            },
          },
        );

  @override
  Future<ToolResult> executeStitch(Map<String, dynamic> parameters) async {
    final projectId = parameters['project_id'] as String;
    final routes = (parameters['routes'] as List).cast<String>();

    final build = await ref.read(stitchServiceProvider).buildSite(
      projectId: projectId,
      routeScreenIds: routes,
    );

    return ToolResult.success({
      'operation': build.operationName,
      'status': build.status,
      'site_url': build.siteUrl,
    });
  }
}
