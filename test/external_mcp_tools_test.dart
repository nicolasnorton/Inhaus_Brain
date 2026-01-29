import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/core/mcp/tools/notion_tool.dart';
import 'package:inhaus_brain/core/mcp/tools/slack_tool.dart';
import 'package:inhaus_brain/core/mcp/tools/ghl_tool.dart';
import 'package:inhaus_brain/core/services/notion_service.dart';
import 'package:inhaus_brain/core/services/slack_service.dart';
import 'package:inhaus_brain/core/services/ghl_service.dart';

void main() {
  group('External MCP Tools Integration Tests', () {
    test('NotionTool schema is correct', () {
      final tool = NotionTool(NotionService());
      final schema = tool.toFunctionSchema();
      expect(schema['name'], 'notion_tool');
      expect(schema['parameters']['properties'].containsKey('action'), isTrue);
    });

    test('SlackTool schema is correct', () {
      final tool = SlackTool(SlackService());
      final schema = tool.toFunctionSchema();
      expect(schema['name'], 'slack_tool');
      expect(schema['parameters']['properties'].containsKey('action'), isTrue);
    });

    test('GHLTool schema is correct', () {
      final tool = GHLTool(GHLService());
      final schema = tool.toFunctionSchema();
      expect(schema['name'], 'ghl_tool');
      expect(schema['parameters']['properties'].containsKey('action'), isTrue);
    });
  });
}
