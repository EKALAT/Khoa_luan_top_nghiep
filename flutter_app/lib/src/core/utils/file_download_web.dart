import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadFile({
  required List<int> bytes,
  required String filename,
  String mimeType = 'application/octet-stream',
}) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
