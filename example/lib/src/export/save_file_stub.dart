import 'svg_export.dart';

/// Fallback platform file saver when neither dart:html nor dart:io is available.
Future<SvgDownloadResult> saveFilePlatform(String filename, String content) async {
  return SvgDownloadResult.failure(
    filename: filename,
    errorMessage: 'File saving is not supported on this platform.',
  );
}
