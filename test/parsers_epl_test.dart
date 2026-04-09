import 'package:test/test.dart';
import 'package:portakal_flutter/src/parsers/epl.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('parseEPL', () {
    test('parses N (clear buffer)', () {
      final result = parseEPL('N');
      expect(result.commands.any((c) => c.cmd == 'N'), isTrue);
    });

    test('parses q (width)', () {
      final result = parseEPL('q800');
      expect(result.widthDots, equals(800));
    });

    test('parses Q (height and gap)', () {
      final result = parseEPL('Q600,24');
      expect(result.heightDots, equals(600));
    });

    test('parses A (text field)', () {
      final code = 'A50,100,0,2,1,1,N,"Hello EPL"';
      final result = parseEPL(code);
      final texts = result.elements.whereType<TextElement>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].content, equals('Hello EPL'));
      expect(texts[0].options.x, equals(50));
      expect(texts[0].options.y, equals(100));
    });

    test('parses X (box)', () {
      final result = parseEPL('X10,20,300,200,3');
      final boxes = result.elements.whereType<BoxElement>().toList();
      expect(boxes, hasLength(1));
      expect(boxes[0].options.x, equals(10));
      expect(boxes[0].options.y, equals(20));
      expect(boxes[0].options.width, equals(290));
      expect(boxes[0].options.height, equals(180));
      expect(boxes[0].options.thickness, equals(3));
    });

    test('parses LO (line)', () {
      final result = parseEPL('LO10,50,290,2');
      final lines = result.elements.whereType<LineElement>().toList();
      expect(lines, hasLength(1));
      expect(lines[0].options.x1, equals(10));
      expect(lines[0].options.y1, equals(50));
    });

    test('parses complete label', () {
      final code = '''
N
q800
Q600,24
S4
D8
A50,50,0,2,1,1,N,"Product Label"
A50,100,0,1,1,1,N,"SKU: 12345"
X10,10,790,590,3
P1
''';
      final result = parseEPL(code);
      expect(result.widthDots, equals(800));
      expect(result.heightDots, equals(600));
      expect(result.elements, hasLength(3)); // 2 text + 1 box
    });
  });
}
