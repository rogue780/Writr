import 'dart:typed_data';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

void downloadBytes(List<int> bytes, String filename) {
  final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS);
  final url = web.URL.createObjectURL(blob);

  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();

  web.URL.revokeObjectURL(url);
}

void downloadString(String content, String filename) {
  final bytes = utf8.encode(content);
  downloadBytes(bytes, filename);
}
