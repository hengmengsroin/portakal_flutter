import 'package:portakal_core/portakal_core.dart';
import 'package:test/test.dart';

ResolvedLabel makeLabel(
  List<LabelElement> elements, {
  int widthDots = 800,
  int heightDots = 1200,
}) {
  return ResolvedLabel(
    widthDots: widthDots,
    heightDots: heightDots,
    dpi: 203,
    unit: Unit.mm,
    speed: 4,
    density: 8,
    direction: 0,
    copies: 1,
    gap: 3,
    gapOffset: 0,
    elements: elements,
  );
}

void main() {
  const config = LabelConfig(
    width: 100,
    height: 150,
    dpi: 203,
    unit: Unit.mm,
  );

  group('Universal RowElement & DividerElement PreviewScene Lowering', () {
    test('converts RowElement into PreviewTextItems with exact geometry and alignment', () {
      final label = makeLabel([
        RowElement(
          y: 100,
          startX: 20,
          width: 760,
          size: 2,
          cells: [
            RowCellElement(
              text: 'Item A',
              x: 20,
              width: 300,
              align: LabelTextAlign.left,
              style: const LabelTextStyle(bold: false, underline: false),
            ),
            RowCellElement(
              text: 'x2',
              x: 330,
              width: 100,
              align: LabelTextAlign.center,
              style: const LabelTextStyle(bold: false, underline: false),
            ),
            RowCellElement(
              text: r'$24.50',
              x: 440,
              width: 340,
              align: LabelTextAlign.right,
              style: const LabelTextStyle(bold: true, underline: true),
            ),
          ],
        ),
      ]);

      final scene = PreviewScene.fromResolved(label);
      expect(scene.items.length, equals(3));

      // Left cell
      final item0 = scene.items[0] as PreviewTextItem;
      expect(item0.text, equals('Item A'));
      expect(item0.x, equals(20.0));
      expect(item0.y, equals(100.0));
      expect(item0.maxWidth, equals(300));
      expect(item0.align, equals('left'));
      expect(item0.svgAnchor, equals('start'));
      expect(item0.textAnchorX, equals(20.0));
      expect(item0.bold, isFalse);
      expect(item0.underline, isFalse);
      expect(item0.fontSize, equals(24)); // size 2 * 12

      // Center cell
      final item1 = scene.items[1] as PreviewTextItem;
      expect(item1.text, equals('x2'));
      expect(item1.x, equals(330.0));
      expect(item1.y, equals(100.0));
      expect(item1.maxWidth, equals(100));
      expect(item1.align, equals('center'));
      expect(item1.svgAnchor, equals('middle'));
      expect(item1.textAnchorX, equals(330.0 + 50.0)); // 380.0
      expect(item1.bold, isFalse);
      expect(item1.underline, isFalse);

      // Right cell
      final item2 = scene.items[2] as PreviewTextItem;
      expect(item2.text, equals(r'$24.50'));
      expect(item2.x, equals(440.0));
      expect(item2.y, equals(100.0));
      expect(item2.maxWidth, equals(340));
      expect(item2.align, equals('right'));
      expect(item2.svgAnchor, equals('end'));
      expect(item2.textAnchorX, equals(440.0 + 340.0)); // 780.0
      expect(item2.bold, isTrue);
      expect(item2.underline, isTrue);
    });

    test('skips empty cells while keeping paint order and following cell properties', () {
      final label = makeLabel([
        RowElement(
          y: 150,
          startX: 20,
          width: 600,
          size: 1,
          cells: [
            RowCellElement(text: '', x: 20, width: 200),
            RowCellElement(text: 'TOTAL', x: 220, width: 180),
            RowCellElement(text: r'$50.00', x: 400, width: 220, align: LabelTextAlign.right),
          ],
        ),
      ]);

      final scene = PreviewScene.fromResolved(label);
      expect(scene.items.length, equals(2));

      final item0 = scene.items[0] as PreviewTextItem;
      expect(item0.text, equals('TOTAL'));
      expect(item0.x, equals(220.0));

      final item1 = scene.items[1] as PreviewTextItem;
      expect(item1.text, equals(r'$50.00'));
      expect(item1.x, equals(400.0));
      expect(item1.textAnchorX, equals(400.0 + 220.0));
    });

    test('converts DividerElement into PreviewLineItem', () {
      final label = makeLabel([
        DividerElement(
          y: 85,
          thickness: 3,
          startX: 25,
          width: 750,
        ),
      ]);

      final scene = PreviewScene.fromResolved(label);
      expect(scene.items.length, equals(1));

      final line = scene.items[0] as PreviewLineItem;
      expect(line.x1, equals(25.0));
      expect(line.y1, equals(85.0));
      expect(line.x2, equals(775.0)); // 25 + 750
      expect(line.y2, equals(85.0));
      expect(line.thickness, equals(3.0));
      expect(line.color, equals(PreviewColor.black));
    });

    test('preserves strict sequential painter order in mixed document', () {
      final builder = sequentialLabel(config, margin: 20, lineAdvance: 30)
          .text('STORE HEADER')
          .divider(thickness: 2)
          .row('Latte', r'$4.50')
          .text('THANK YOU FOR SHOPPING');

      final scene = PreviewScene.fromBuilder(builder);

      // Expected items in order:
      // 1. TextItem: 'STORE HEADER'
      // 2. LineItem: divider
      // 3. TextItem: 'Latte'
      // 4. TextItem: '$4.50'
      // 5. TextItem: 'THANK YOU FOR SHOPPING'
      expect(scene.items.length, equals(5));

      expect(scene.items[0], isA<PreviewTextItem>());
      expect((scene.items[0] as PreviewTextItem).text, equals('STORE HEADER'));

      expect(scene.items[1], isA<PreviewLineItem>());
      expect((scene.items[1] as PreviewLineItem).thickness, equals(2.0));

      expect(scene.items[2], isA<PreviewTextItem>());
      expect((scene.items[2] as PreviewTextItem).text, equals('Latte'));

      expect(scene.items[3], isA<PreviewTextItem>());
      expect((scene.items[3] as PreviewTextItem).text, equals(r'$4.50'));

      expect(scene.items[4], isA<PreviewTextItem>());
      expect((scene.items[4] as PreviewTextItem).text, equals('THANK YOU FOR SHOPPING'));
    });
  });
}
