import 'dart:io';
import 'package:test/test.dart';
import '../tool/generate_api_snapshot.dart';

void main() {
  group('ApiSnapshotGenerator Structural Precision & Change Detection', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('portakal_api_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    String generateForSource(String coreSource) {
      final coreDir = Directory('${tempDir.path}/packages/portakal_core/lib');
      coreDir.createSync(recursive: true);

      final barrelFile = File('${coreDir.path}/portakal_core.dart');
      barrelFile.writeAsStringSync("export 'src/api.dart';\n");

      final srcDir = Directory('${coreDir.path}/src');
      srcDir.createSync(recursive: true);

      final apiFile = File('${srcDir.path}/api.dart');
      apiFile.writeAsStringSync(coreSource);

      final gen = ApiSnapshotGenerator(rootDir: tempDir.path);
      return gen.generate();
    }

    test('A. Detects added optional named parameter', () {
      const v1 = 'Uint8List compile(Label l);';
      const v2 = 'Uint8List compile(Label l, {int? charsPerLine});';

      final snap1 = generateForSource(v1);
      final snap2 = generateForSource(v2);

      expect(snap1, isNot(equals(snap2)));
      expect(snap1, contains('function Uint8List compile(Label l)'));
      expect(snap2, contains('function Uint8List compile(Label l, {int? charsPerLine})'));
    });

    test('B. Detects required to optional parameter change', () {
      const v1 = 'void printLabel({required int copies});';
      const v2 = 'void printLabel({int copies = 1});';

      final snap1 = generateForSource(v1);
      final snap2 = generateForSource(v2);

      expect(snap1, isNot(equals(snap2)));
      expect(snap1, contains('{required int copies}'));
      expect(snap2, contains('{int copies = 1}'));
    });

    test('C. Detects parameter type change', () {
      const v1 = 'Uint8List compile(Label l, {int? charsPerLine});';
      const v2 = 'Uint8List compile(Label l, {String? charsPerLine});';

      final snap1 = generateForSource(v1);
      final snap2 = generateForSource(v2);

      expect(snap1, isNot(equals(snap2)));
      expect(snap1, contains('int? charsPerLine'));
      expect(snap2, contains('String? charsPerLine'));
    });

    test('D. Detects return type change', () {
      const v1 = 'int computeWidth();';
      const v2 = 'double computeWidth();';

      final snap1 = generateForSource(v1);
      final snap2 = generateForSource(v2);

      expect(snap1, isNot(equals(snap2)));
      expect(snap1, contains('function int computeWidth()'));
      expect(snap2, contains('function double computeWidth()'));
    });

    test('E. Detects constructor parameter change', () {
      const v1 = '''
class LabelCell {
  const LabelCell({required String text});
}
''';
      const v2 = '''
class LabelCell {
  const LabelCell({required String text, bool bold = false});
}
''';

      final snap1 = generateForSource(v1);
      final snap2 = generateForSource(v2);

      expect(snap1, isNot(equals(snap2)));
      expect(snap1, contains('constructor const LabelCell({required String text})'));
      expect(snap2, contains('constructor const LabelCell({required String text, bool bold = false})'));
    });

    test('F. Detects method parameter and return type change', () {
      const v1 = '''
class LabelBuilder {
  LabelBuilder row(String left, String right);
}
''';
      const v2 = '''
class LabelBuilder {
  LabelBuilder row(String left, String right, {int size = 1});
}
''';

      final snap1 = generateForSource(v1);
      final snap2 = generateForSource(v2);

      expect(snap1, isNot(equals(snap2)));
      expect(snap1, contains('method LabelBuilder LabelBuilder.row(String left, String right)'));
      expect(snap2, contains('method LabelBuilder LabelBuilder.row(String left, String right, {int size = 1})'));
    });

    test('G. Handles multiline declarations cleanly onto normalized single-line signatures', () {
      const multiline = '''
Uint8List compileToESCPOS(
  ResolvedLabel label, {
  EscPosEncoding? encoding,
  int? charsPerLine,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) => Uint8List(0);
''';

      final snap = generateForSource(multiline);
      expect(
        snap,
        contains(
          'function Uint8List compileToESCPOS(ResolvedLabel label, {EscPosEncoding? encoding, int? charsPerLine, UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError})',
        ),
      );
    });

    test('H. Detects abstract / interface / sealed modifier changes', () {
      const v1 = 'class LabelTable {}';
      const v2 = 'abstract interface class LabelTable {}';
      const v3 = 'sealed class LabelTable {}';

      final snap1 = generateForSource(v1);
      final snap2 = generateForSource(v2);
      final snap3 = generateForSource(v3);

      expect(snap1, isNot(equals(snap2)));
      expect(snap2, isNot(equals(snap3)));

      expect(snap1, contains('class LabelTable (in /packages/portakal_core/lib/src/api.dart)'));
      expect(snap2, contains('abstract interface class LabelTable (in /packages/portakal_core/lib/src/api.dart)'));
      expect(snap3, contains('sealed class LabelTable (in /packages/portakal_core/lib/src/api.dart)'));
    });

    test('I. Detects default value changes', () {
      const v1 = 'void setGap({int gap = 0});';
      const v2 = 'void setGap({int gap = 2});';

      final snap1 = generateForSource(v1);
      final snap2 = generateForSource(v2);

      expect(snap1, isNot(equals(snap2)));
      expect(snap1, contains('{int gap = 0}'));
      expect(snap2, contains('{int gap = 2}'));
    });

    test('Breaking-Change Proof: int? charsPerLine to String? charsPerLine', () {
      const vCurrent = '''
Uint8List compileToESCPOS(
  ResolvedLabel label, {
  EscPosEncoding? encoding,
  int? charsPerLine,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) => Uint8List(0);
''';

      const vAltered = '''
Uint8List compileToESCPOS(
  ResolvedLabel label, {
  EscPosEncoding? encoding,
  String? charsPerLine,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) => Uint8List(0);
''';

      final snapCurrent = generateForSource(vCurrent);
      final snapAltered = generateForSource(vAltered);

      expect(snapCurrent, isNot(equals(snapAltered)));
      expect(snapCurrent, contains('int? charsPerLine'));
      expect(snapAltered, contains('String? charsPerLine'));
    });

    test('Respects export show and hide combinators', () {
      final coreDir = Directory('${tempDir.path}/packages/portakal_core/lib');
      coreDir.createSync(recursive: true);

      final barrelFile = File('${coreDir.path}/portakal_core.dart');
      barrelFile.writeAsStringSync("""
export 'src/layout.dart' show PublicClass, PublicEnum;
export 'src/hidden.dart' hide SecretClass;
""");

      final srcDir = Directory('${coreDir.path}/src');
      srcDir.createSync(recursive: true);

      File('${srcDir.path}/layout.dart').writeAsStringSync('''
class PublicClass {}
class InternalClass {}
enum PublicEnum { a, b }
''');

      File('${srcDir.path}/hidden.dart').writeAsStringSync('''
class SecretClass {}
class VisibleClass {}
''');

      final gen = ApiSnapshotGenerator(rootDir: tempDir.path);
      final snap = gen.generate();

      expect(snap, contains('class PublicClass'));
      expect(snap, contains('enum PublicEnum'));
      expect(snap, contains('class VisibleClass'));
      expect(snap, isNot(contains('class InternalClass')));
      expect(snap, isNot(contains('class SecretClass')));
    });
  });
}
