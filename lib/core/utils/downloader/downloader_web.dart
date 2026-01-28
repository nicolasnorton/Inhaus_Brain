import 'dart:convert';
import 'package:universal_html/html.dart' as html;

void downloadJson(String jsonString, String fileName) {
  final bytes = utf8.encode(jsonString);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  
  html.Url.revokeObjectUrl(url);
}
