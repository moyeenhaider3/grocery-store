import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../network/api_client.dart';

/// Saves [content] as a file download in the browser (Blob + anchor).
void downloadTextFile(String filename, String content, {String mimeType = 'text/csv;charset=utf-8'}) {
  final blob = web.Blob([content.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

class PickedTextFile {
  final String name;
  final int size;
  final String text;
  const PickedTextFile(this.name, this.size, this.text);
}

/// Opens the browser file picker. Returns null when the user cancels.
Future<PickedTextFile?> pickTextFile({String accept = '.csv,text/csv', int maxBytes = 1048576}) async {
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = accept;
  final completer = Completer<web.File?>();
  input.addEventListener(
    'change',
    ((web.Event _) {
      if (!completer.isCompleted) completer.complete(input.files?.item(0));
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!completer.isCompleted) completer.complete(null);
    }).toJS,
  );
  input.click();
  final file = await completer.future;
  if (file == null) return null;
  if (file.size > maxBytes) {
    throw const ApiException('The file is too large. The limit is 1 MB.');
  }
  final text = (await file.text().toDart).toDart;
  return PickedTextFile(file.name, file.size, text);
}
