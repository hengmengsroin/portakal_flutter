import 'package:test/test.dart';
import 'package:portakal_core/src/parsers/cpcl.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('parseCPCL', () {
    test('parses session header', () {
      final code = '! 0 200 200 400 1\r\nPRINT\r\n';
      final result = parseCPCL(code);
      expect(result.heightDots, equals(400));
      expect(result.dpi, equals(200));
    });

    test('parses PAGE-WIDTH', () {
      final code = '! 0 200 200 400 1\r\nPAGE-WIDTH 384\r\nPRINT\r\n';
      final result = parseCPCL(code);
      expect(result.widthDots, equals(384));
    });

    test('parses TEXT with content on next line', () {
      final code =
          '! 0 200 200 400 1\r\nTEXT 0 3 50 100\r\nHello World\r\nPRINT\r\n';
      final result = parseCPCL(code);
      final texts = result.elements.whereType<TextElement>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].content, equals('Hello World'));
      expect(texts[0].options.x, equals(50));
      expect(texts[0].options.y, equals(100));
    });

    test('parses BOX', () {
      final code = '! 0 200 200 400 1\r\nBOX 10 20 300 200 2\r\nPRINT\r\n';
      final result = parseCPCL(code);
      final boxes = result.elements.whereType<BoxElement>().toList();
      expect(boxes, hasLength(1));
      expect(boxes[0].options.x, equals(10));
      expect(boxes[0].options.y, equals(20));
      expect(boxes[0].options.width, equals(290));
      expect(boxes[0].options.height, equals(180));
    });

    test('parses LINE', () {
      final code = '! 0 200 200 400 1\r\nLINE 10 50 300 50 2\r\nPRINT\r\n';
      final result = parseCPCL(code);
      final lines = result.elements.whereType<LineElement>().toList();
      expect(lines, hasLength(1));
      expect(lines[0].options.x1, equals(10));
      expect(lines[0].options.y1, equals(50));
      expect(lines[0].options.x2, equals(300));
      expect(lines[0].options.y2, equals(50));
    });

    test('parses complete label', () {
      final code = '''! 0 200 200 400 1\r
PAGE-WIDTH 384\r
SPEED 4\r
TEXT 0 3 50 20\r
Product Name\r
TEXT 0 0 50 80\r
SKU: 12345\r
BOX 5 5 379 395 1\r
LINE 5 60 379 60 1\r
PRINT\r
''';
      final result = parseCPCL(code);
      expect(result.widthDots, equals(384));
      expect(result.elements.length, greaterThanOrEqualTo(4));
    });
  });
}
