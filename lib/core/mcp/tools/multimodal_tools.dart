import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../agent_tool.dart';
import 'image_generation_tool.dart';
import 'video_generation_tool.dart';
import 'audio_generation_tool.dart';
import 'notion_tool.dart';
import 'slack_tool.dart';
import 'ghl_tool.dart';
import '../../auth/secret_vault_service.dart';
import '../../services/notion_service.dart';
import '../../services/slack_service.dart';
import '../../services/ghl_service.dart';
import 'gmail_tool.dart';
import 'drive_tool.dart';

final multimodalToolsProvider = FutureProvider<List<AgentTool>>((ref) async {
  final vault = ref.read(secretVaultProvider);
  
  final imagenKey = await vault.getImagenKey();
  final bananaKey = await vault.getBananaKey();
  final veoKey = await vault.getVeoKey();
  final lyriaKey = await vault.getLyriaKey();
  final vertexKey = await vault.getVertexKey();

  return [
    ImageGenerationTool(ref, imagenKey: imagenKey, vertexKey: vertexKey),
    VideoGenerationTool(ref, veoKey: veoKey, vertexKey: vertexKey),
    AudioGenerationTool(lyriaKey: lyriaKey),
    NotionTool(NotionService(apiKey: await vault.getNotionKey())),
    SlackTool(SlackService(token: await vault.getSlackToken())),
    GHLTool(GHLService(apiKey: await vault.getGHLKey(), locationId: await vault.getGHLLocationId())),
    GmailTool(),
    DriveTool(),
  ];
});
