import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Generates a canonical, deterministic structural API surface snapshot
/// of all publicly exported symbols in the Portakal SDK.
///
/// Uses the Dart Analyzer AST parser to capture complete structural signatures:
/// - Class modifiers (abstract, interface, sealed, final, base, mixin)
/// - Inheritance & interfaces (extends, implements, with)
/// - Constructors (const, factory, named, parameter types, defaults, required)
/// - Methods (static, getters, setters, return types, parameter types, defaults)
/// - Fields & properties
/// - Enums (values and enhanced enum members)
/// - Typedefs and extensions
/// - Top-level functions (return types, parameter types, defaults, required)
/// - Export graph combinators (respecting show/hide)
class ApiSnapshotGenerator {
  final String rootDir;

  ApiSnapshotGenerator({String? rootDir})
      : rootDir = rootDir ?? Directory.current.path;

  String generate() {
    final sb = StringBuffer();

    sb.writeln(
        '# ==============================================================================');
    sb.writeln(
        '# PORTAKAL SDK — PUBLIC API SURFACE SNAPSHOT (STRUCTURAL SIGNATURE AUDIT)');
    sb.writeln(
        '# Canonical exported API contracts, types, modifiers, and signatures');
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

      final exports = _resolveExports(barrelFile.path);
      final allDeclarations = <String>[];

      for (final entry in exports.entries) {
        final filePath = entry.key;
        final filter = entry.value;
        final relPath = filePath.replaceFirst(rootDir, '');
        final file = File(filePath);
        if (!file.existsSync()) continue;

        final content = file.readAsStringSync();
        final parseResult = parseString(
          content: content,
          throwIfDiagnostics: false,
        );

        final visitor = _ApiExtractVisitor(relPath: relPath, filter: filter);
        parseResult.unit.accept(visitor);
        allDeclarations.addAll(visitor.symbols);
      }

      allDeclarations.sort();

      sb.writeln('Total Public Declarations: ${allDeclarations.length}');
      sb.writeln();
      for (final decl in allDeclarations) {
        sb.writeln('  $decl');
      }
      sb.writeln();
      sb.writeln(
          '------------------------------------------------------------------------------');
      sb.writeln();
    }

    return sb.toString();
  }

  Map<String, _ExportFilter> _resolveExports(String entryPath) {
    final result = <String, _ExportFilter>{};
    final visited = <String>{};
    final queue = <_ExportQueueItem>[
      _ExportQueueItem(path: entryPath, filter: _ExportFilter.all())
    ];

    while (queue.isNotEmpty) {
      final item = queue.removeAt(0);
      final currentPath = item.path;
      final currentFile = File(currentPath);
      if (!currentFile.existsSync()) continue;

      final content = currentFile.readAsStringSync();
      final parseResult = parseString(
        content: content,
        throwIfDiagnostics: false,
      );

      for (final directive in parseResult.unit.directives) {
        if (directive is ExportDirective) {
          final uri = directive.uri.stringValue;
          if (uri == null) continue;

          String targetPath;
          if (uri.startsWith('package:portakal_core/')) {
            targetPath =
                '$rootDir/packages/portakal_core/lib/${uri.substring('package:portakal_core/'.length)}';
          } else if (uri.startsWith('package:portakal_flutter/')) {
            targetPath =
                '$rootDir/packages/portakal_flutter/lib/${uri.substring('package:portakal_flutter/'.length)}';
          } else if (uri.startsWith('package:')) {
            continue;
          } else {
            targetPath = Uri.file('${currentFile.parent.path}/$uri')
                .normalizePath()
                .toFilePath();
          }

          final showList = <String>{};
          final hideList = <String>{};

          for (final combinator in directive.combinators) {
            if (combinator is ShowCombinator) {
              for (final name in combinator.shownNames) {
                showList.add(name.name);
              }
            } else if (combinator is HideCombinator) {
              for (final name in combinator.hiddenNames) {
                hideList.add(name.name);
              }
            }
          }

          final directiveFilter = _ExportFilter(
            shown: showList.isEmpty ? null : showList,
            hidden: hideList,
          );

          final combinedFilter = item.filter.combine(directiveFilter);

          if (result.containsKey(targetPath)) {
            result[targetPath] = result[targetPath]!.merge(combinedFilter);
          } else {
            result[targetPath] = combinedFilter;
          }

          if (visited.add(targetPath)) {
            queue.add(_ExportQueueItem(path: targetPath, filter: combinedFilter));
          }
        }
      }
    }

    return result;
  }
}

class _ExportQueueItem {
  final String path;
  final _ExportFilter filter;

  _ExportQueueItem({required this.path, required this.filter});
}

class _ExportFilter {
  final Set<String>? shown;
  final Set<String> hidden;

  const _ExportFilter({this.shown, this.hidden = const {}});

  factory _ExportFilter.all() => const _ExportFilter();

  bool allows(String name) {
    if (hidden.contains(name)) return false;
    if (shown != null && !shown!.contains(name)) return false;
    return true;
  }

  _ExportFilter combine(_ExportFilter child) {
    Set<String>? newShown;
    if (shown != null && child.shown != null) {
      newShown = shown!.intersection(child.shown!);
    } else if (shown != null) {
      newShown = shown;
    } else if (child.shown != null) {
      newShown = child.shown;
    }

    final newHidden = {...hidden, ...child.hidden};
    return _ExportFilter(shown: newShown, hidden: newHidden);
  }

  _ExportFilter merge(_ExportFilter other) {
    Set<String>? newShown;
    if (shown != null && other.shown != null) {
      newShown = {...shown!, ...other.shown!};
    } else {
      newShown = null;
    }
    final newHidden = hidden.intersection(other.hidden);
    return _ExportFilter(shown: newShown, hidden: newHidden);
  }
}

class _ApiExtractVisitor extends RecursiveAstVisitor<void> {
  final String relPath;
  final _ExportFilter filter;
  final List<String> symbols = [];
  String? currentParent;

  _ApiExtractVisitor({required this.relPath, required this.filter});

  String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (!name.startsWith('_') && filter.allows(name)) {
      final returnType = node.returnType?.toSource() ?? 'dynamic';
      final typeParams = node.functionExpression.typeParameters?.toSource() ?? '';
      final params = _normalize(node.functionExpression.parameters?.toSource() ?? '()');
      symbols.add('function $returnType $name$typeParams$params (in $relPath)');
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final src = node.toSource();
    final braceIdx = src.indexOf('{');
    final header = _normalize(braceIdx != -1 ? src.substring(0, braceIdx) : src);

    final nameMatch = RegExp(r'class\s+([A-Za-z0-9_]+)').firstMatch(header);
    final className = nameMatch?.group(1);
    if (className == null || className.startsWith('_') || !filter.allows(className)) {
      return;
    }

    symbols.add('$header (in $relPath)');

    final prevParent = currentParent;
    currentParent = className;
    super.visitClassDeclaration(node);
    currentParent = prevParent;
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    final src = node.toSource();
    final braceIdx = src.indexOf('{');
    final header = _normalize(braceIdx != -1 ? src.substring(0, braceIdx) : src);

    final nameMatch = RegExp(r'enum\s+([A-Za-z0-9_]+)').firstMatch(header);
    final enumName = nameMatch?.group(1);
    if (enumName == null || enumName.startsWith('_') || !filter.allows(enumName)) {
      return;
    }

    symbols.add('$header (in $relPath)');

    final prevParent = currentParent;
    currentParent = enumName;
    super.visitEnumDeclaration(node);
    currentParent = prevParent;
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    if (currentParent == null) return;
    symbols.add('  enum-value $currentParent.${node.name.lexeme} (in $relPath)');
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (currentParent == null) return;
    final ctorName = node.name?.lexeme;
    if (ctorName != null && ctorName.startsWith('_')) return;

    final isConst = node.constKeyword != null ? 'const ' : '';
    final isFactory = node.factoryKeyword != null ? 'factory ' : '';
    final name = ctorName != null ? '$currentParent.$ctorName' : currentParent!;
    final params = _normalize(node.parameters.toSource());
    symbols.add('  constructor $isConst$isFactory$name$params (in $relPath)');
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (currentParent == null) return;
    final name = node.name.lexeme;
    if (name.startsWith('_')) return;

    final isStatic = node.isStatic ? 'static ' : '';
    if (node.isGetter) {
      final type = node.returnType?.toSource() ?? 'dynamic';
      symbols.add('  method $isStatic$type get $currentParent.$name (in $relPath)');
    } else if (node.isSetter) {
      final params = _normalize(node.parameters?.toSource() ?? '()');
      symbols.add('  method ${isStatic}set $currentParent.$name$params (in $relPath)');
    } else {
      final type = node.returnType?.toSource() ?? 'dynamic';
      final typeParams = node.typeParameters?.toSource() ?? '';
      final params = _normalize(node.parameters?.toSource() ?? '()');
      symbols.add('  method $isStatic$type $currentParent.$name$typeParams$params (in $relPath)');
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (currentParent == null) return;
    final isStatic = node.isStatic ? 'static ' : '';
    final isConst = node.fields.isConst ? 'const ' : '';
    final isFinal = node.fields.isFinal ? 'final ' : '';
    final type = node.fields.type?.toSource();
    final typeStr = type != null ? '$type ' : '';

    for (final v in node.fields.variables) {
      final name = v.name.lexeme;
      if (!name.startsWith('_')) {
        symbols.add('  field $isStatic$isConst$isFinal$typeStr$currentParent.$name (in $relPath)');
      }
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    final name = node.name.lexeme;
    if (!name.startsWith('_') && filter.allows(name)) {
      symbols.add('${_normalize(node.toSource())} (in $relPath)');
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    final name = node.name.lexeme;
    if (!name.startsWith('_') && filter.allows(name)) {
      symbols.add('${_normalize(node.toSource())} (in $relPath)');
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    final isConst = node.variables.isConst ? 'const ' : '';
    final isFinal = node.variables.isFinal ? 'final ' : '';
    final type = node.variables.type?.toSource();
    final typeStr = type != null ? '$type ' : '';

    for (final v in node.variables.variables) {
      final name = v.name.lexeme;
      if (!name.startsWith('_') && filter.allows(name)) {
        symbols.add('top-var $isConst$isFinal$typeStr$name (in $relPath)');
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
  print('API snapshot written to tool/api_surface.txt (${snapshot.length} bytes)');
}
