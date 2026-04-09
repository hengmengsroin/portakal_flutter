import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/src/parsers/zpl.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('parseZPL', () {
    test('returns empty for empty input', () {
      final result = parseZPL('');
      expect(result.commands, isEmpty);
      expect(result.elements, isEmpty);
    });

    test('parses ^XA and ^XZ commands', () {
      final result = parseZPL('^XA^XZ');
      expect(result.commands.any((c) => c.code == '^XA'), isTrue);
      expect(result.commands.any((c) => c.code == '^XZ'), isTrue);
    });

    test('parses ^PW (print width)', () {
      final result = parseZPL('^XA^PW800^XZ');
      expect(result.widthDots, equals(800));
    });

    test('parses ^LL (label length)', () {
      final result = parseZPL('^XA^LL600^XZ');
      expect(result.heightDots, equals(600));
    });

    test('parses text fields (^FO + ^FD + ^FS)', () {
      final result = parseZPL('^XA^FO50,100^FDHello World^FS^XZ');
      final textElements = result.elements.whereType<TextElement>().toList();
      expect(textElements, hasLength(1));
      expect(textElements[0].content, equals('Hello World'));
      expect(textElements[0].options.x, equals(50));
      expect(textElements[0].options.y, equals(100));
    });

    test('parses multiple text fields', () {
      final result = parseZPL('^XA^FO10,10^FDLine 1^FS^FO10,50^FDLine 2^FS^XZ');
      expect(result.elements.length, equals(2));
    });

    test('parses ^GB (box)', () {
      final result = parseZPL('^XA^FO10,20^GB300,200,3,B,0^FS^XZ');
      final boxes = result.elements.whereType<BoxElement>().toList();
      expect(boxes, hasLength(1));
      expect(boxes[0].options.x, equals(10));
      expect(boxes[0].options.y, equals(20));
      expect(boxes[0].options.width, equals(300));
      expect(boxes[0].options.height, equals(200));
      expect(boxes[0].options.thickness, equals(3));
    });

    test('parses ^GC (circle)', () {
      final result = parseZPL('^XA^FO100,100^GC60,2,B^FS^XZ');
      final circles = result.elements.whereType<CircleElement>().toList();
      expect(circles, hasLength(1));
      expect(circles[0].options.x, equals(100));
      expect(circles[0].options.y, equals(100));
      expect(circles[0].options.diameter, equals(60));
      expect(circles[0].options.thickness, equals(2));
    });

    test('parses ^GD (diagonal line)', () {
      final result = parseZPL('^XA^FO10,20^GD300,200,2,B,R^FS^XZ');
      final lines = result.elements.whereType<LineElement>().toList();
      expect(lines, hasLength(1));
    });

    test('handles ^FR (field reverse)', () {
      final result = parseZPL('^XA^FO10,10^FR^FDReversed^FS^XZ');
      final textElements = result.elements.whereType<TextElement>().toList();
      expect(textElements, hasLength(1));
      expect(textElements[0].options.reverse, isTrue);
    });

    test('handles multi-line input', () {
      final code = '''
^XA
^PW800
^LL600
^FO50,50
^A0N,30,30
^FDMulti Line^FS
^XZ
''';
      final result = parseZPL(code);
      expect(result.widthDots, equals(800));
      expect(result.heightDots, equals(600));
    });

    test('parses complex label', () {
      final code = '''
^XA
^CI28
^PW812
^LL1218
^PR4
~SD08
^FO50,50^A0N,30,30^FDProduct Label^FS
^FO50,100^GB712,0,3^FS
^FO50,120^A0N,24,24^FDSKU: 12345^FS
^FO50,160^A0N,24,24^FDPrice: \$19.99^FS
^PQ1
^XZ
''';
      final result = parseZPL(code);
      expect(result.widthDots, equals(812));
      expect(result.heightDots, equals(1218));
      expect(result.elements.length, greaterThanOrEqualTo(3));
    });
  });
}
