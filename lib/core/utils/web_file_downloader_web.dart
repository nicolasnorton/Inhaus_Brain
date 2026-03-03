import 'package:web/web.dart' as web;

void downloadWebFile(String url, String filename) {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
