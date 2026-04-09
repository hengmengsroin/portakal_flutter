import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/src/validate.dart';

void main() {
  group('validate — TSC', () {
    test('valid TSC label passes', () {
      final r = validate('SIZE 40 mm,30 mm\nGAP 3 mm,0 mm\nCLS\nTEXT 10,10,"2",0,2,2,"Hello"\nPRINT 1', 'tsc');
      expect(r.valid, isTrue);
      expect(r.errors, equals(0));
    });

    test('warns when SIZE is not first', () {
      final r = validate('CLS\nSIZE 40 mm,30 mm\nTEXT 10,10,"2",0,1,1,"Hi"\nPRINT 1', 'tsc');
      expect(r.issues.any((i) => i.message.contains('SIZE should be the first')), isTrue);
    });

    test('errors when CLS missing before elements', () {
      final r = validate('SIZE 40 mm,30 mm\nTEXT 10,10,"2",0,1,1,"No CLS"\nPRINT 1', 'tsc');
      expect(r.errors, greaterThan(0));
      expect(r.issues.any((i) => i.message.contains('CLS must appear before')), isTrue);
    });

    test('warns when PRINT missing', () {
      final r = validate('SIZE 40 mm,30 mm\nCLS\nTEXT 10,10,"2",0,1,1,"No print"', 'tsc');
      expect(r.issues.any((i) => i.message.contains('No PRINT')), isTrue);
    });

    test('errors on DENSITY out of range', () {
      final r = validate('SIZE 40 mm,30 mm\nDENSITY 20\nCLS\nPRINT 1', 'tsc');
      expect(r.issues.any((i) => i.message.contains('DENSITY value 20 out of range')), isTrue);
    });

    test('warns on unknown commands', () {
      final r = validate('SIZE 40 mm,30 mm\nCLS\nFOOBAR\nPRINT 1', 'tsc');
      expect(r.issues.any((i) => i.message.contains('Unrecognized command')), isTrue);
    });

    test('errors on empty input', () {
      final r = validate('', 'tsc');
      expect(r.valid, isFalse);
      expect(r.errors, equals(1));
    });
  });

  group('validate — ZPL', () {
    test('valid ZPL passes', () {
      final r = validate('^XA^FO10,10^A0N,30,30^FDHello^FS^XZ', 'zpl');
      expect(r.valid, isTrue);
    });

    test('errors when ^XA missing', () {
      final r = validate('^FO10,10^FDHello^FS^XZ', 'zpl');
      expect(r.errors, greaterThan(0));
      expect(r.issues.any((i) => i.message.contains('^XA')), isTrue);
    });

    test('errors when ^XZ missing', () {
      final r = validate('^XA^FO10,10^FDHello^FS', 'zpl');
      expect(r.errors, greaterThan(0));
      expect(r.issues.any((i) => i.message.contains('^XZ')), isTrue);
    });

    test('warns on ^FD without ^FO', () {
      final r = validate('^XA^FDNo origin^FS^XZ', 'zpl');
      expect(r.issues.any((i) => i.message.contains('^FD without preceding ^FO')), isTrue);
    });

    test('errors on ^PW out of range', () {
      final r = validate('^XA^PW0^XZ', 'zpl');
      expect(r.issues.any((i) => i.message.contains('^PW value')), isTrue);
    });
  });

  group('validate — other languages', () {
    test('provides info message for unsupported validation', () {
      final r = validate('some code', 'dpl');
      expect(r.issues.any((i) => i.level == 'info'), isTrue);
    });
  });
}
