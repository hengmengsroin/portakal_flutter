import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'svg_export.dart';

/// Web platform file saver utilizing standard browser Blob & Object URL download.
Future<SvgDownloadResult> saveFilePlatform(String filename, String content) async {
  try {
    final blobParts = [content.toJS].toJS;
    final blob = web.Blob(
      blobParts,
      web.BlobPropertyBag(type: 'image/svg+xml;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.style.display = 'none';

    final body = web.document.body;
    if (body != null) {
      body.appendChild(anchor);
      anchor.click();
      body.removeChild(anchor);
    } else {
      anchor.click();
    }

    web.URL.revokeObjectURL(url);

    return SvgDownloadResult.success(
      filename: filename,
      savedLocation: 'Browser downloads',
    );
  } catch (e) {
    return SvgDownloadResult.failure(
      filename: filename,
      errorMessage: e.toString(),
    );
  }
}
