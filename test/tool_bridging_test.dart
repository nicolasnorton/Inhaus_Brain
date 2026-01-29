import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:inhaus_brain/core/models/mcp_models.dart';
import 'package:inhaus_brain/core/mcp/tools/multimodal_tools.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize dotenv for SecretVaultService
    dotenv.testLoad(fileInput: '');
    
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        return null; // Return null for all keys to simulate empty vault
      }
      return null;
    });
  });

  test('availableToolsProvider includes internal bridged tools', () async {
    final container = ProviderContainer();
    
    // Wait for internal tools to load (mock/async)
    await container.read(multimodalToolsProvider.future);
    
    final tools = container.read(availableToolsProvider);
    
    final toolIds = tools.map((t) => t.id).toList();
    
    // Check for new tools
    expect(toolIds, contains('notion_tool'));
    expect(toolIds, contains('slack_tool'));
    expect(toolIds, contains('ghl_tool'));
    expect(toolIds, contains('gmail_tool'));
    expect(toolIds, contains('drive_tool'));
    
    // Check for existing multimodal tools
    expect(toolIds, contains('image_generation'));
    expect(toolIds, contains('video_generation'));
    expect(toolIds, contains('audio_generation'));
  });
}
