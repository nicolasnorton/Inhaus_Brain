
import 'package:firebase_ai/firebase_ai.dart';

/// Helper to map our custom AgentTool schemas to Firebase AI Schemas
class FunctionSchemaMapper {
  
  static Schema map(Map<String, dynamic> jsonSchema) {
    if (jsonSchema.isEmpty) {
      // Default to string if empty, or object
      return Schema.string(); 
    }

    final type = jsonSchema['type'] as String?;
    
    switch (type) {
      case 'string':
        if (jsonSchema.containsKey('enum')) {
           final enumValues = (jsonSchema['enum'] as List).map((e) => e.toString()).toList();
           return Schema.enumString(enumValues: enumValues, description: jsonSchema['description']);
        }
        return Schema.string(description: jsonSchema['description'], nullable: jsonSchema['nullable'] == true);
        
      case 'integer':
      case 'int':
        return Schema.integer(description: jsonSchema['description'], nullable: jsonSchema['nullable'] == true);
        
      case 'number':
      case 'double':
        return Schema.number(description: jsonSchema['description'], nullable: jsonSchema['nullable'] == true);
        
      case 'boolean':
      case 'bool':
        return Schema.boolean(description: jsonSchema['description'], nullable: jsonSchema['nullable'] == true);
        
      case 'array':
      case 'list':
        final items = jsonSchema['items'];
        if (items != null && items is Map<String, dynamic>) {
           return Schema.array(
             items: map(items),
             description: jsonSchema['description'],
             nullable: jsonSchema['nullable'] == true
           );
        }
        // Default to array of strings if items not specified
        return Schema.array(items: Schema.string(), description: jsonSchema['description']);
        
      case 'object':
      case 'map':
        final properties = jsonSchema['properties'] as Map<String, dynamic>? ?? {};
        final required = (jsonSchema['required'] as List?)?.map((e) => e.toString()).toList() ?? [];
        
        final mappedProps = <String, Schema>{};
        properties.forEach((key, value) {
           if (value is Map<String, dynamic>) {
             mappedProps[key] = map(value);
           }
        });
        
        final allProps = mappedProps.keys.toList();
        final optional = allProps.where((key) => !required.contains(key)).toList();
        
        return Schema.object(
          properties: mappedProps,
          optionalProperties: optional,
          description: jsonSchema['description'],
          nullable: jsonSchema['nullable'] == true
        );
        
      default:
        // Fallback for unknown types or null
        return Schema.string(description: jsonSchema['description']);
    }
  }
}
