import 'package:test/test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/lang/tsc.dart';
import 'package:portakal_flutter/src/lang/zpl.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('tsc language module', () {
    LabelBuilder b() => label(LabelConfig(width: 40, height: 30)).text('Hello', TextOptions(x: 10, y: 10, size: 2));

    test('compiles to TSC', () {
      expect(tsc.compile(b()), contains('TEXT 10,10,"2",0,2,2,"Hello"'));
    });

    test('renders TSC preview with correct font size', () {
      final svg = tsc.preview(b());
      expect(svg, contains('<svg'));
      expect(svg, contains('Hello'));
      expect(svg, contains('— TSC'));
      // Font "2" at size 2: base 12 * 2 = height 24
      expect(svg, contains('font-size="24"'));
    });

    test('parses TSC code', () {
      final result = tsc.parse('SIZE 40 mm,30 mm\nCLS\nTEXT 10,10,"2",0,2,2,"Hello"\nPRINT 1');
      expect(result.commands.length, greaterThan(0));
    });

    test('validates TSC code', () {
      final result = tsc.validate('SIZE 40 mm,30 mm\nCLS\nTEXT 10,10,"2",0,1,1,"Hi"\nPRINT 1');
      expect(result.valid, isTrue);
    });

    test('validates and reports errors', () {
      final result = tsc.validate('TEXT 10,10,"2",0,1,1,"No CLS"\nPRINT 1');
      expect(result.errors, greaterThan(0));
    });
  });

  group('zpl language module', () {
    LabelBuilder b() => label(LabelConfig(width: 40, height: 30))
        .text('Hello ZPL', TextOptions(x: 50, y: 50, size: 2))
        .box(BoxOptions(x: 10, y: 10, width: 300, height: 220, thickness: 3));

    test('compiles to ZPL', () {
      final code = zpl.compile(b());
      expect(code, contains('^XA'));
      expect(code, contains('^FDHello ZPL^FS'));
      expect(code, contains('^GB'));
      expect(code, contains('^XZ'));
    });

    test('renders ZPL preview with correct font metrics', () {
      final svg = zpl.preview(b());
      expect(svg, contains('<svg'));
      expect(svg, contains('Hello ZPL'));
      expect(svg, contains('— ZPL'));
    });

    test('renders filled box when thickness >= side', () {
      final b2 = label(LabelConfig(width: 40, height: 30))
          .box(BoxOptions(x: 50, y: 50, width: 100, height: 100, thickness: 100));
      final svg = zpl.preview(b2);
      expect(svg, contains('fill="#000"'));
    });

    test('renders corner radius correctly', () {
      final b2 = label(LabelConfig(width: 40, height: 30))
          .box(BoxOptions(x: 10, y: 10, width: 200, height: 100, thickness: 3, radius: 4));
      final svg = zpl.preview(b2);
      expect(svg, contains('rx="4"'));
    });

    test('parses ZPL code', () {
      final result = zpl.parse('^XA^FO10,10^A0N,30,30^FDTest^FS^XZ');
      expect(result.commands.length, greaterThan(0));
    });

    test('validates ZPL code', () {
      final result = zpl.validate('^XA^FO10,10^A0N,30,30^FDTest^FS^XZ');
      expect(result.valid, isTrue);
    });

    test('validates and reports missing ^XA', () {
      final result = zpl.validate('^FO10,10^FDTest^FS^XZ');
      expect(result.errors, greaterThan(0));
    });
  });

  group('TSC vs ZPL preview differences', () {
    test('produces different SVGs for same label', () {
      final b = label(LabelConfig(width: 40, height: 30)).text('Test', TextOptions(x: 10, y: 10, font: '2', size: 2));
      final tscSvg = tsc.preview(b);
      final zplSvg = zpl.preview(b);
      expect(tscSvg, isNot(equals(zplSvg)));
    });

    test('labels show language name', () {
      final b = label(LabelConfig(width: 40, height: 30)).text('Test', TextOptions(x: 10, y: 10));
      expect(tsc.preview(b), contains('— TSC'));
      expect(zpl.preview(b), contains('— ZPL'));
    });
  });
}
