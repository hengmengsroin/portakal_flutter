import 'dart:io';

class ApiSnapshotGenerator {
  String generate() {
    final rootDir = Directory.current.path;
    final sb = StringBuffer();

    sb.writeln(
        '# ==============================================================================');
    sb.writeln(
        '# PORTAKAL SDK — PUBLIC API SURFACE SNAPSHOT (PHASE 5A / 1.0 FREEZE AUDIT)');
    sb.writeln(
        '# Generated for 1.0 contract verification & regression tracking');
    sb.writeln(
        '# ==============================================================================');
    sb.writeln();

    for (final pkg in ['portakal_core', 'portakal_flutter']) {
      final barrelPath = '$rootDir/packages/$pkg/lib/$pkg.dart';
      final barrelFile = File(barrelPath);
      if (!barrelFile.existsSync()) continue;

      sb.writeln('## PACKAGE: $pkg');
      sb.writeln('Entrypoint: packages/$pkg/lib/$pkg.dart');
      sb.writeln();

      final exportedFiles = _getRecursiveExports(barrelFile.path);
      final allSymbols = <String>[];

      for (final filePath in exportedFiles) {
        final relPath = filePath.replaceFirst(rootDir, '');
        final file = File(filePath);
        if (!file.existsSync()) continue;

        final lines = file.readAsLinesSync();
        _extractPublicSymbols(relPath, lines, allSymbols);
      }

      allSymbols.sort();

      sb.writeln('Total Public Declarations: ${allSymbols.length}');
      sb.writeln();
      for (final sym in allSymbols) {
        sb.writeln('  $sym');
      }
      sb.writeln();
      sb.writeln(
          '------------------------------------------------------------------------------');
      sb.writeln();
    }

    return sb.toString();
  }

  Set<String> _getRecursiveExports(String entryPath) {
    final visited = <String>{};
    final queue = <String>[entryPath];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!visited.add(current)) continue;

      final file = File(current);
      if (!file.existsSync()) continue;

      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final match =
            RegExp(r'''^\s*export\s+['"]([^'"]+)['"]''').firstMatch(line);
        if (match != null) {
          final uri = match.group(1)!;
          String target;
          if (uri.startsWith('package:portakal_core/')) {
            target =
                '${Directory.current.path}/packages/portakal_core/lib/${uri.substring('package:portakal_core/'.length)}';
          } else if (uri.startsWith('package:portakal_flutter/')) {
            target =
                '${Directory.current.path}/packages/portakal_flutter/lib/${uri.substring('package:portakal_flutter/'.length)}';
          } else if (uri.startsWith('package:')) {
            continue;
          } else {
            target = Uri.file('${file.parent.path}/$uri')
                .normalizePath()
                .toFilePath();
          }
          queue.add(target);
        }
      }
    }
    return visited;
  }

  void _extractPublicSymbols(
      String relPath, List<String> lines, List<String> output) {
    String? currentClass;
    bool inClass = false;

    for (int i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final line = rawLine.trim();

      if (line.startsWith('//') ||
          line.startsWith('/*') ||
          line.startsWith('*') ||
          line.startsWith('@') ||
          line.startsWith('import ') ||
          line.startsWith('export ') ||
          line.isEmpty) {
        continue;
      }

      // Detect top-level classes / sealed / abstract
      final classMatch = RegExp(
              r'''^(?:abstract\s+|sealed\s+|final\s+)?class\s+([A-Za-z0-9_]+)(?:<[^>]+>)?(?:\s+(?:extends|implements|with)\s+.*)?\s*\{?''')
          .firstMatch(line);
      if (classMatch != null &&
          !rawLine.startsWith(' ') &&
          !rawLine.startsWith('\t')) {
        final name = classMatch.group(1)!;
        if (!name.startsWith('_')) {
          output.add('class $name (in $relPath)');
          currentClass = name;
          inClass = true;
        }
        continue;
      }

      // Detect enums
      final enumMatch =
          RegExp(r'''^enum\s+([A-Za-z0-9_]+)\s*\{?''').firstMatch(line);
      if (enumMatch != null &&
          !rawLine.startsWith(' ') &&
          !rawLine.startsWith('\t')) {
        final name = enumMatch.group(1)!;
        if (!name.startsWith('_')) {
          output.add('enum $name (in $relPath)');
          currentClass = name;
          inClass = true;
        }
        continue;
      }

      // Detect typedefs
      final typedefMatch =
          RegExp(r'''^typedef\s+([A-Za-z0-9_]+)\s*=''').firstMatch(line);
      if (typedefMatch != null &&
          !rawLine.startsWith(' ') &&
          !rawLine.startsWith('\t')) {
        final name = typedefMatch.group(1)!;
        if (!name.startsWith('_')) {
          output.add('typedef $name (in $relPath)');
        }
        continue;
      }

      // Detect top-level variables / constants / singletons
      final topVarMatch = RegExp(
              r'''^(?:const|final)\s+(?:[A-Za-z0-9_<>,?]+\s+)?([a-zA-Z0-9_]+)\s*=''')
          .firstMatch(line);
      if (topVarMatch != null &&
          !rawLine.startsWith(' ') &&
          !rawLine.startsWith('\t')) {
        final name = topVarMatch.group(1)!;
        if (!name.startsWith('_')) {
          output.add('const/final $name (in $relPath)');
        }
        continue;
      }

      // Detect top-level functions
      if (!rawLine.startsWith(' ') && !rawLine.startsWith('\t')) {
        final funcMatch = RegExp(
                r'''^(?:[A-Za-z0-9_<>,?]+\s+)+([a-zA-Z0-9_]+)\s*\([^;{]*\)\s*(?:async\s*)?(?:=>|\{)''')
            .firstMatch(line);
        if (funcMatch != null) {
          final name = funcMatch.group(1)!;
          if (!name.startsWith('_') &&
              ![
                'if',
                'for',
                'while',
                'switch',
                'catch',
                'return',
                'class',
                'enum',
                'mixin',
                'typedef'
              ].contains(name)) {
            output.add('function $name() (in $relPath)');
          }
        }
      }

      // Class members
      if (inClass && currentClass != null) {
        if (line.startsWith('}')) {
          inClass = false;
          currentClass = null;
          continue;
        }

        // Public method / getter / setter / constructor in class
        if (rawLine.startsWith('  ') || rawLine.startsWith('\t')) {
          // Constructor
          final ctorMatch = RegExp(
                  r'''^\s*(?:const\s+)?([A-Za-z0-9_]+)(?:\.([a-zA-Z0-9_]+))?\s*\([^;{]*\)''')
              .firstMatch(rawLine);
          if (ctorMatch != null) {
            final cName = ctorMatch.group(1)!;
            final namedCtor = ctorMatch.group(2);
            if (cName == currentClass) {
              if (namedCtor == null || !namedCtor.startsWith('_')) {
                final fullCtor =
                    namedCtor == null ? '$cName()' : '$cName.$namedCtor()';
                output.add('  member $currentClass.$fullCtor (in $relPath)');
                continue;
              }
            }
          }

          // Method or getter
          final memberMatch = RegExp(
                  r'''^\s*(?:(?:static|final|const|abstract|override)\s+)*(?:[A-Za-z0-9_<>,?]+\s+)+([a-zA-Z0-9_]+)\s*(?:\([^;{]*\)|=>|;)''')
              .firstMatch(rawLine);
          if (memberMatch != null) {
            final mName = memberMatch.group(1)!;
            if (!mName.startsWith('_') &&
                ![
                  'if',
                  'for',
                  'while',
                  'switch',
                  'catch',
                  'return',
                  'super',
                  'this'
                ].contains(mName)) {
              output.add('  member $currentClass.$mName (in $relPath)');
            }
          }
        }
      }
    }
  }
}

void main() {
  final gen = ApiSnapshotGenerator();
  final snapshot = gen.generate();

  final outFile = File('${Directory.current.path}/tool/api_surface.txt');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(snapshot);
  print(
      'API snapshot written to tool/api_surface.txt (${snapshot.length} bytes)');
}
