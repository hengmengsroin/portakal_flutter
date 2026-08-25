import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:portakal_core/src/convert.dart';

void main() {
  group('convert — cross-compilation', () {
    final tscCode =
        'SIZE 40 mm,30 mm\nGAP 3 mm,0 mm\nCLS\nTEXT 10,10,"2",0,2,2,"Hello World"\nBOX 5,5,315,235,2\nPRINT 1';

    test('TSC → ZPL', () {
      final result = convert(tscCode, 'tsc', 'zpl');
      expect(result.output, isA<String>());
      final output = result.output as String;
      expect(output, contains('^XA'));
      expect(output, contains('^FDHello World^FS'));
      expect(output, contains('^XZ'));
    });

    test('TSC → EPL', () {
      final result = convert(tscCode, 'tsc', 'epl');
      final output = result.output as String;
      expect(output, contains('N'));
      expect(output, contains('"Hello World"'));
      expect(output, contains('P1'));
    });

    test('TSC → CPCL', () {
      final result = convert(tscCode, 'tsc', 'cpcl');
      final output = result.output as String;
      expect(output, contains('! 0 203 203'));
      expect(output, contains('Hello World'));
      expect(output, contains('PRINT'));
    });

    test('TSC → ESC/POS (binary)', () {
      final result = convert(tscCode, 'tsc', 'escpos');
      expect(result.output, isA<Uint8List>());
      final bytes = result.output as Uint8List;
      expect(bytes[0], equals(0x1b)); // ESC
      expect(bytes[1], equals(0x40)); // @
    });

    test('TSC → DPL', () {
      final result = convert(tscCode, 'tsc', 'dpl');
      expect(result.output, isA<String>());
      expect(result.output as String, contains('Hello World'));
    });

    test('TSC → Star PRNT (binary)', () {
      final result = convert(tscCode, 'tsc', 'starprnt');
      expect(result.output, isA<Uint8List>());
    });

    test('ZPL → TSC', () {
      final zplCode = '^XA^PW320^LL240^FO10,10^A0N,30,30^FDHello ZPL^FS^XZ';
      final result = convert(zplCode, 'zpl', 'tsc');
      final output = result.output as String;
      expect(output, contains('SIZE'));
      expect(output, contains('"Hello ZPL"'));
      expect(output, contains('PRINT'));
    });

    test('preserves elements through conversion', () {
      final result = convert(tscCode, 'tsc', 'zpl');
      expect(result.elements.length, greaterThanOrEqualTo(1));
      expect(result.widthDots, equals(320));
      expect(result.heightDots, equals(240));
    });

    test('EPL → TSC', () {
      final eplCode = 'N\nq320\nQ240,24\nA10,10,0,2,2,2,N,"Hello EPL"\nP1';
      final result = convert(eplCode, 'epl', 'tsc');
      expect(result.output as String, contains('"Hello EPL"'));
    });
  });
}
