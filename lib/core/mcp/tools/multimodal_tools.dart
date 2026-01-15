import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../agent_tool.dart';
import 'image_generation_tool.dart';
import 'video_generation_tool.dart';
import 'audio_generation_tool.dart';
import '../../auth/secret_vault_service.dart';

final multimodalToolsProvider = FutureProvider<List<AgentTool>>((ref) async {
  final vault = ref.read(secretVaultProvider);
  
  final imagenKey = await vault.getImagenKey();
  final bananaKey = await vault.getBananaKey();
  final veoKey = await vault.getVeoKey();
  final lyriaKey = await vault.getLyriaKey();

  return [
    ImageGenerationTool(imagenKey: imagenKey, bananaKey: bananaKey),
    VideoGenerationTool(veoKey: veoKey),
    AudioGenerationTool(lyriaKey: lyriaKey),
  ];
});
