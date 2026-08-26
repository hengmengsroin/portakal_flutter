import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'svg_export.dart';

/// Desktop & IO platform file saver using native "Save As" file dialogs.
///
/// On macOS, Windows, and Linux desktop environments, prompts the user with a native
/// Save As dialog (NSSavePanel on macOS) allowing them to select their destination.
/// If dialog interaction is unavailable or fails, falls back to direct filesystem write.
Future<SvgDownloadResult> saveFilePlatform(String filename, String content) async {
  try {
    const typeGroup = XTypeGroup(
      label: 'Scalable Vector Graphics (*.svg)',
      extensions: <String>['svg'],
      mimeTypes: <String>['image/svg+xml'],
    );

    final FileSaveLocation? saveLocation = await getSaveLocation(
      suggestedName: filename,
      acceptedTypeGroups: const <XTypeGroup>[typeGroup],
    );

    // User dismissed/canceled the Save As dialog
    if (saveLocation == null) {
      return SvgDownloadResult.cancelled(filename: filename);
    }

    final Uint8List bytes = Uint8List.fromList(utf8.encode(content));
    final file = XFile.fromData(
      bytes,
      name: filename,
      mimeType: 'image/svg+xml',
    );

    await file.saveTo(saveLocation.path);

    return SvgDownloadResult.success(
      filename: filename,
      savedLocation: saveLocation.path,
    );
  } catch (e) {
    // If native dialog is not supported in current environment, fallback to direct filesystem write
    return _fallbackDirectSave(filename, content, originalError: e);
  }
}

Future<SvgDownloadResult> _fallbackDirectSave(
  String filename,
  String content, {
  Object? originalError,
}) async {
  try {
    final candidateDirs = <String>[];

    // Check user Downloads directory
    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        candidateDirs.add('$home/Downloads');
      }
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        candidateDirs.add('$userProfile\\Downloads');
      }
    }

    // Add fallback directories in order of preference
    if (Directory.current.existsSync()) {
      candidateDirs.add(Directory.current.path);
    }
    candidateDirs.add(Directory.systemTemp.path);

    final separator = Platform.pathSeparator;
    Object? lastError = originalError;

    for (final dirPath in candidateDirs) {
      try {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final filePath = '$dirPath$separator$filename';
        final file = File(filePath);
        await file.writeAsString(content);

        return SvgDownloadResult.success(
          filename: filename,
          savedLocation: filePath,
        );
      } catch (e) {
        lastError = e;
        continue;
      }
    }

    return SvgDownloadResult.failure(
      filename: filename,
      errorMessage: lastError?.toString() ?? 'Unable to write to any target directory.',
    );
  } catch (e) {
    return SvgDownloadResult.failure(
      filename: filename,
      errorMessage: e.toString(),
    );
  }
}
