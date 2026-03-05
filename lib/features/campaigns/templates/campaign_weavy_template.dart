import 'package:uuid/uuid.dart';
import '../../../core/adk/models/pipeline_models.dart';
import '../../../core/config/feature_flags.dart';

/// Pre-built workflow templates for the Creative Campaign Canvas.
///
/// Each function returns a list of PipelineStep with proper nodeType, config,
/// dependencies, and uiPosition pre-wired so the canvas renders them
/// as a connected graph immediately.
class CampaignWeavyTemplates {
  CampaignWeavyTemplates._();
  static const _uuid = Uuid();

  // ─── Template 1: Default Campaign Workflow ──────────────────────────────

  /// 7-node base chain:
  /// Moodboard Agent → BrainWeave Guardrails → Hero ImageGen →
  /// Inpaint Variations → Video Teaser → Compositing → Approval Gate
  static List<PipelineStep> defaultCampaignWorkflow() {
    final idMoodboard = _uuid.v4();
    final idBrainweave = _uuid.v4();
    final idHeroImage = _uuid.v4();
    final idInpaint = _uuid.v4();
    final idVideo = _uuid.v4();
    final idComposite = _uuid.v4();
    final idApproval = _uuid.v4();

    return [
      PipelineStep(
        id: idMoodboard,
        nodeType: WorkflowNodeType.agent,
        instruction: 'Generate a moodboard based on campaign brief and brand guidelines.',
        config: {'agentRole': 'moodboard_curator', 'outputFormat': 'gallery'},
        uiPosition: {'x': 100, 'y': 200},
      ),
      PipelineStep(
        id: idBrainweave,
        nodeType: WorkflowNodeType.brainweavePipeline,
        instruction: 'Run brand guardrails check via BrainWeave 6R Pipeline.',
        config: {'rawInput': '{{moodboard_output}}', 'clientId': '{{campaign_client}}'},
        dependencies: [idMoodboard],
        uiPosition: {'x': 380, 'y': 200},
      ),
      PipelineStep(
        id: idHeroImage,
        nodeType: WorkflowNodeType.creativeImageGen,
        instruction: 'Generate hero campaign image from approved moodboard direction.',
        config: {'prompt': '{{approved_direction}}', 'aspectRatio': '16:9', 'model': 'imagen'},
        dependencies: [idBrainweave],
        uiPosition: {'x': 660, 'y': 200},
      ),
      PipelineStep(
        id: idInpaint,
        nodeType: WorkflowNodeType.creativeInpaintOutpaint,
        instruction: 'Create 3 variations by inpainting different product placements.',
        config: {'sourceImageUrl': '{{hero_image}}', 'mode': 'inpaint', 'prompt': 'product placement variation'},
        dependencies: [idHeroImage],
        uiPosition: {'x': 940, 'y': 200},
      ),
      PipelineStep(
        id: idVideo,
        nodeType: WorkflowNodeType.creativeVideoLipsync,
        instruction: 'Generate a 5-second video teaser from the hero image.',
        config: {'sourceImageUrl': '{{hero_image}}', 'model': 'veo', 'script': 'Introducing the new collection.'},
        dependencies: [idHeroImage],
        uiPosition: {'x': 940, 'y': 400},
      ),
      PipelineStep(
        id: idComposite,
        nodeType: WorkflowNodeType.creativeCompositingLayers,
        instruction: 'Composite final deliverable with text overlay and brand watermark.',
        config: {
          'layerUrls': ['{{inpaint_result}}', '{{brand_logo}}'],
          'blendMode': 'normal',
          'textOverlay': '{{campaign_tagline}}',
          'outputFormat': 'png',
        },
        dependencies: [idInpaint, idVideo],
        uiPosition: {'x': 1220, 'y': 300},
      ),
      PipelineStep(
        id: idApproval,
        nodeType: WorkflowNodeType.answer,
        instruction: 'Submit composite for client approval.',
        requiresApproval: true,
        config: {'approvalType': 'client_review'},
        dependencies: [idComposite],
        uiPosition: {'x': 1500, 'y': 300},
      ),
      if (FeatureFlags.enableFigmaIntegration)
        PipelineStep(
          id: _uuid.v4(),
          nodeType: WorkflowNodeType.creativeFigmaSync,
          instruction: 'Sync final composite to Figma for design team review.',
          config: {
            'direction': 'export',
            'figmaFileKey': '', // To be filled by user
            'exportMessage': 'Auto-synced from Designer Canvas',
          },
          dependencies: [idComposite],
          uiPosition: {'x': 1500, 'y': 100},
        ),
    ];
  }

  // ─── Template 2: Hero Product Relight ───────────────────────────────────

  /// Focused on product photography with relighting.
  /// Product Upload → Relight (Studio) → Relight (Dramatic) → Compositing → Output
  static List<PipelineStep> heroProductRelightPreset() {
    final idUpload = _uuid.v4();
    final idRelightStudio = _uuid.v4();
    final idRelightDramatic = _uuid.v4();
    final idComposite = _uuid.v4();
    final idOutput = _uuid.v4();

    return [
      PipelineStep(
        id: idUpload,
        nodeType: WorkflowNodeType.userInput,
        instruction: 'Upload product photo for relighting.',
        config: {'inputType': 'image', 'label': 'Product Photo'},
        uiPosition: {'x': 100, 'y': 250},
      ),
      PipelineStep(
        id: idRelightStudio,
        nodeType: WorkflowNodeType.creativeRelightProduct,
        instruction: 'Apply studio lighting to product.',
        config: {'productImageUrl': '{{upload_image}}', 'lightingPreset': 'studio'},
        dependencies: [idUpload],
        uiPosition: {'x': 400, 'y': 150},
      ),
      PipelineStep(
        id: idRelightDramatic,
        nodeType: WorkflowNodeType.creativeRelightProduct,
        instruction: 'Apply dramatic lighting to product.',
        config: {'productImageUrl': '{{upload_image}}', 'lightingPreset': 'dramatic'},
        dependencies: [idUpload],
        uiPosition: {'x': 400, 'y': 350},
      ),
      PipelineStep(
        id: idComposite,
        nodeType: WorkflowNodeType.creativeCompositingLayers,
        instruction: 'Create side-by-side comparison composite.',
        config: {
          'layerUrls': ['{{studio_result}}', '{{dramatic_result}}'],
          'blendMode': 'normal',
          'outputFormat': 'png',
        },
        dependencies: [idRelightStudio, idRelightDramatic],
        uiPosition: {'x': 700, 'y': 250},
      ),
      PipelineStep(
        id: idOutput,
        nodeType: WorkflowNodeType.output,
        instruction: 'Final relit product images.',
        dependencies: [idComposite],
        uiPosition: {'x': 1000, 'y': 250},
      ),
    ];
  }

  // ─── Template 3: Social Media Variations ────────────────────────────────

  /// Generates 3 aspect ratio variations for social platforms.
  /// Prompt → ImageGen (9:16) → ImageGen (1:1) → ImageGen (4:5) → Output
  static List<PipelineStep> socialMediaVariationsPreset() {
    final idPrompt = _uuid.v4();
    final idStory = _uuid.v4();
    final idSquare = _uuid.v4();
    final idPortrait = _uuid.v4();
    final idOutput = _uuid.v4();

    return [
      PipelineStep(
        id: idPrompt,
        nodeType: WorkflowNodeType.userInput,
        instruction: 'Enter your social media campaign prompt.',
        config: {'inputType': 'text', 'label': 'Campaign Prompt'},
        uiPosition: {'x': 100, 'y': 250},
      ),
      PipelineStep(
        id: idStory,
        nodeType: WorkflowNodeType.creativeImageGen,
        instruction: 'Generate Stories/Reels format (9:16).',
        config: {'prompt': '{{user_prompt}}', 'aspectRatio': '9:16', 'model': 'imagen'},
        dependencies: [idPrompt],
        uiPosition: {'x': 400, 'y': 100},
      ),
      PipelineStep(
        id: idSquare,
        nodeType: WorkflowNodeType.creativeImageGen,
        instruction: 'Generate Feed Square format (1:1).',
        config: {'prompt': '{{user_prompt}}', 'aspectRatio': '1:1', 'model': 'imagen'},
        dependencies: [idPrompt],
        uiPosition: {'x': 400, 'y': 250},
      ),
      PipelineStep(
        id: idPortrait,
        nodeType: WorkflowNodeType.creativeImageGen,
        instruction: 'Generate Feed Portrait format (4:5).',
        config: {'prompt': '{{user_prompt}}', 'aspectRatio': '4:5', 'model': 'imagen'},
        dependencies: [idPrompt],
        uiPosition: {'x': 400, 'y': 400},
      ),
      PipelineStep(
        id: idOutput,
        nodeType: WorkflowNodeType.output,
        instruction: 'All social media variations ready.',
        dependencies: [idStory, idSquare, idPortrait],
        uiPosition: {'x': 700, 'y': 250},
      ),
    ];
  }

  // ─── Template 4: Video Ad with Lip-sync ─────────────────────────────────

  /// Image → Video with lip-sync + text overlay.
  /// ImageGen → Video Lipsync → Compositing (text overlay) → Stitch Preview
  static List<PipelineStep> videoAdLipsyncPreset() {
    final idFigmaImport = _uuid.v4();
    final idImageGen = _uuid.v4();
    final idVideo = _uuid.v4();
    final idComposite = _uuid.v4();
    final idStitch = _uuid.v4();

    return [
      if (FeatureFlags.enableFigmaIntegration)
        PipelineStep(
          id: idFigmaImport,
          nodeType: WorkflowNodeType.creativeFigmaSync,
          instruction: 'Import initial mockup frames from Figma.',
          config: {
            'direction': 'import',
            'figmaFileKey': '',
            'exportFormat': 'png',
          },
          uiPosition: {'x': -200, 'y': 200},
        ),
      PipelineStep(
        id: idImageGen,
        nodeType: WorkflowNodeType.creativeImageGen,
        instruction: 'Generate the key frame for the video ad.',
        config: {'prompt': '{{ad_concept}}', 'aspectRatio': '16:9', 'model': 'imagen'},
        dependencies: FeatureFlags.enableFigmaIntegration ? [idFigmaImport] : [],
        uiPosition: {'x': 100, 'y': 200},
      ),
      PipelineStep(
        id: idVideo,
        nodeType: WorkflowNodeType.creativeVideoLipsync,
        instruction: 'Animate key frame with lip-sync narration.',
        config: {
          'sourceImageUrl': '{{keyframe_image}}',
          'script': '{{ad_script}}',
          'model': 'veo',
        },
        dependencies: [idImageGen],
        uiPosition: {'x': 400, 'y': 200},
      ),
      PipelineStep(
        id: idComposite,
        nodeType: WorkflowNodeType.creativeCompositingLayers,
        instruction: 'Add branding text overlay and CTA.',
        config: {
          'layerUrls': ['{{video_thumbnail}}'],
          'textOverlay': '{{cta_text}}',
          'outputFormat': 'png',
        },
        dependencies: [idVideo],
        uiPosition: {'x': 700, 'y': 200},
      ),
      PipelineStep(
        id: idStitch,
        nodeType: WorkflowNodeType.creativeStitchDesign,
        instruction: 'Generate Stitch UI preview for the ad landing page.',
        config: {'prompt': 'Landing page for ad: {{ad_concept}}'},
        dependencies: [idComposite],
        uiPosition: {'x': 1000, 'y': 200},
      ),
    ];
  }

  // ─── Template 5: Multi-Angle 360° ──────────────────────────────────────

  /// Multi-angle product rotation via ControlNet.
  /// Upload → ControlNet (front) → ControlNet (45°) → ControlNet (side) →
  /// ControlNet (back) → Compositing
  static List<PipelineStep> multiAngle360Preset() {
    final idUpload = _uuid.v4();
    final idFront = _uuid.v4();
    final id45 = _uuid.v4();
    final idSide = _uuid.v4();
    final idBack = _uuid.v4();
    final idComposite = _uuid.v4();

    return [
      PipelineStep(
        id: idUpload,
        nodeType: WorkflowNodeType.userInput,
        instruction: 'Upload product reference photo.',
        config: {'inputType': 'image', 'label': 'Product Reference'},
        uiPosition: {'x': 100, 'y': 250},
      ),
      PipelineStep(
        id: idFront,
        nodeType: WorkflowNodeType.creativeControlNet,
        instruction: 'Generate front view.',
        config: {
          'referenceImageUrl': '{{upload_image}}',
          'prompt': 'front view, product photography, studio lighting',
          'controlType': 'structure',
        },
        dependencies: [idUpload],
        uiPosition: {'x': 400, 'y': 80},
      ),
      PipelineStep(
        id: id45,
        nodeType: WorkflowNodeType.creativeControlNet,
        instruction: 'Generate 45° angle view.',
        config: {
          'referenceImageUrl': '{{upload_image}}',
          'prompt': '45 degree angle view, product photography, studio lighting',
          'controlType': 'structure',
        },
        dependencies: [idUpload],
        uiPosition: {'x': 400, 'y': 220},
      ),
      PipelineStep(
        id: idSide,
        nodeType: WorkflowNodeType.creativeControlNet,
        instruction: 'Generate side view.',
        config: {
          'referenceImageUrl': '{{upload_image}}',
          'prompt': 'side view, product photography, studio lighting',
          'controlType': 'structure',
        },
        dependencies: [idUpload],
        uiPosition: {'x': 400, 'y': 360},
      ),
      PipelineStep(
        id: idBack,
        nodeType: WorkflowNodeType.creativeControlNet,
        instruction: 'Generate back view.',
        config: {
          'referenceImageUrl': '{{upload_image}}',
          'prompt': 'back view, product photography, studio lighting',
          'controlType': 'structure',
        },
        dependencies: [idUpload],
        uiPosition: {'x': 400, 'y': 500},
      ),
      PipelineStep(
        id: idComposite,
        nodeType: WorkflowNodeType.creativeCompositingLayers,
        instruction: 'Create 360° composite grid of all angles.',
        config: {
          'layerUrls': ['{{front}}', '{{angle45}}', '{{side}}', '{{back}}'],
          'blendMode': 'normal',
          'outputFormat': 'png',
        },
        dependencies: [idFront, id45, idSide, idBack],
        uiPosition: {'x': 750, 'y': 280},
      ),
    ];
  }

  /// Returns all templates as a named map for the template picker UI.
  static Map<String, List<PipelineStep> Function()> get all => {
        'Default Campaign Workflow': defaultCampaignWorkflow,
        'Hero Product Relight': heroProductRelightPreset,
        'Social Media Variations': socialMediaVariationsPreset,
        'Video Ad with Lip-sync': videoAdLipsyncPreset,
        'Multi-Angle 360°': multiAngle360Preset,
      };
}
