import 'dart:convert';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void downloadJson(String jsonString, String fileName) {
  final bytes = utf8.encode(jsonString);
  // Convert Uint8List to JS ArrayBuffer/Uint8Array for Blob
  // package:web way:
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  
  web.URL.revokeObjectURL(url);
}
