import 'package:portakal_flutter/portakal_flutter.dart';
import '../examples/example_case.dart';

import 'save_file_stub.dart'
    if (dart.library.js_interop) 'save_file_web.dart'
    if (dart.library.io) 'save_file_io.dart';

/// Signature for platform file saving functions, allowing injection in tests.
typedef SvgFileSaver = Future<SvgDownloadResult> Function(String filename, String content);

/// Deterministically sanitizes an example/template name into a valid, safe SVG filename.
///
/// Transformations applied:
/// 1. Converted to lowercase.
/// 2. Spaces, slashes, and special characters replaced with underscores.
/// 3. Non-alphanumeric and non-underscore characters removed.
/// 4. Consecutive underscores collapsed into a single underscore.
/// 5. Leading and trailing underscores stripped.
/// 6. Appends `.svg` extension if not already present.
String sanitizeSvgFilename(String name) {
  var base = name.trim();
  while (base.toLowerCase().endsWith('.svg')) {
    base = base.substring(0, base.length - 4).trim();
  }
  var sanitized = base
      .toLowerCase()
      .replaceAll(RegExp(r'[\s/\\:\*\?"<>\|]+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_]'), '')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  if (sanitized.isEmpty) {
    sanitized = 'label';
  }

  return '$sanitized.svg';
}

/// Immutable SVG export payload containing the target filename and pure SVG content.
final class SvgExport {
  /// The sanitized, safe SVG filename (e.g. `customer_receipt.svg`).
  final String filename;

  /// The raw XML SVG string rendered from the canonical [ResolvedLabel].
  final String content;

  const SvgExport({
    required this.filename,
    required this.content,
  });

  /// Constructs an [SvgExport] directly from a raw name and resolved label.
  factory SvgExport.create({
    required String name,
    required ResolvedLabel job,
  }) {
    final filename = sanitizeSvgFilename(name);
    final content = renderPreview(job);
    return SvgExport(filename: filename, content: content);
  }

  /// Constructs an [SvgExport] from an [ExampleCase] and its exact [ResolvedLabel].
  ///
  /// Guarantees that the export uses the same resolved label instance without
  /// rebuilding or re-resolving mutable AST state.
  factory SvgExport.fromCase(ExampleCase exampleCase, ResolvedLabel job) {
    final name = exampleCase.id.isNotEmpty ? exampleCase.id : exampleCase.title;
    return SvgExport.create(name: name, job: job);
  }

  /// Dispatches saving this SVG to the host platform (or a [customSaver] in tests).
  Future<SvgDownloadResult> save({SvgFileSaver? customSaver}) {
    final saver = customSaver ?? saveFilePlatform;
    return saver(filename, content);
  }
}

/// Result of an SVG download or save operation.
final class SvgDownloadResult {
  /// Whether the file was successfully downloaded or saved.
  final bool isSuccess;

  /// Whether the user canceled the Save As dialog.
  final bool isCancelled;

  /// The target filename.
  final String filename;

  /// The absolute path, directory description, or method used for storage (e.g. 'Browser downloads').
  final String? savedLocation;

  /// Diagnostic error message if the download failed.
  final String? errorMessage;

  const SvgDownloadResult.success({
    required this.filename,
    this.savedLocation,
  })  : isSuccess = true,
        isCancelled = false,
        errorMessage = null;

  const SvgDownloadResult.cancelled({
    required this.filename,
  })  : isSuccess = false,
        isCancelled = true,
        savedLocation = null,
        errorMessage = null;

  const SvgDownloadResult.failure({
    required this.filename,
    required this.errorMessage,
  })  : isSuccess = false,
        isCancelled = false,
        savedLocation = null;
}
