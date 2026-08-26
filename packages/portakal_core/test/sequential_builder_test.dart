import 'package:test/test.dart';
import 'package:portakal_core/portakal_core.dart';

void main() {
  group('Legacy label() builder compatibility', () {
    test('label() creates un-positioned TextElement with null x/y by default', () {
      final b = label(const LabelConfig(width: 80, height: 40));
      b.text('Header');
      b.text('Subheader', const TextOptions(size: 2, bold: true));

      final resolved = b.resolve();
      expect(resolved.elements.length, equals(2));

      final el1 = resolved.elements[0] as TextElement;
      expect(el1.content, equals('Header'));
      expect(el1.options.x, isNull);
      expect(el1.options.y, isNull);

      final el2 = resolved.elements[1] as TextElement;
      expect(el2.content, equals('Subheader'));
      expect(el2.options.x, isNull);
      expect(el2.options.y, isNull);
      expect(el2.options.size, equals(2));
      expect(el2.options.bold, isTrue);
    });

    test('calling sequential helpers on legacy label() throws InvalidConfigError', () {
      final b = label(const LabelConfig(width: 80, height: 40));

      expect(() => b.space(10), throwsA(isA<InvalidConfigError>()));
      expect(() => b.divider(), throwsA(isA<InvalidConfigError>()));
      expect(() => b.row('Left', 'Right'), throwsA(isA<InvalidConfigError>()));
      expect(
        () => b.rowCells(children: [LabelCell.flex(1, text: 'Cell')]),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => b.table(columns: [LabelColumn.flex(1)]),
        throwsA(isA<InvalidConfigError>()),
      );
    });
  });

  group('sequentialLabel() initialization & unit resolution', () {
    test('initializes default margin and lineAdvance at 203 DPI (mm)', () {
      // 80mm @ 203 DPI = 640 dots (rounded from 639.37)
      // margin: 2.5mm @ 203 DPI = 20 dots
      // lineAdvance: 3.5mm @ 203 DPI = 28 dots
      final b = sequentialLabel(const LabelConfig(width: 80, height: 40));
      b.text('First line');

      final resolved = b.resolve();
      final el = resolved.elements[0] as TextElement;
      expect(el.options.x, equals(toDots(2.5, Unit.mm, 203)));
      expect(el.options.y, equals(toDots(2.5, Unit.mm, 203)));
    });

    test('initializes with custom dpi and explicit margin/lineAdvance in dots', () {
      final b = sequentialLabel(
        const LabelConfig(width: 100, height: 50, dpi: 300),
        margin: 30,
        lineAdvance: 40,
      );
      b.text('Line 1');
      b.text('Line 2');

      final resolved = b.resolve();
      final el1 = resolved.elements[0] as TextElement;
      final el2 = resolved.elements[1] as TextElement;

      expect(el1.options.x, equals(30));
      expect(el1.options.y, equals(30));
      expect(el2.options.x, equals(30));
      expect(el2.options.y, equals(70)); // 30 + 40
    });

    test('throws InvalidConfigError when margin < 0 or lineAdvance <= 0', () {
      expect(
        () => sequentialLabel(
          const LabelConfig(width: 80, height: 40),
          margin: -1,
        ),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => sequentialLabel(
          const LabelConfig(width: 80, height: 40),
          lineAdvance: 0,
        ),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => sequentialLabel(
          const LabelConfig(width: 80, height: 40),
          lineAdvance: -5,
        ),
        throwsA(isA<InvalidConfigError>()),
      );
    });

    test('throws InvalidConfigError when label width minus 2*margin is <= 0', () {
      // 10mm @ 203 DPI = 80 dots. 2 * 50 = 100 dots > 80 dots.
      expect(
        () => sequentialLabel(
          const LabelConfig(width: 10, height: 40),
          margin: 50,
        ),
        throwsA(isA<InvalidConfigError>()),
      );
    });
  });

  group('Sequential text progression and escape hatch', () {
    test('sequential text advances Y by lineAdvance for each line', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );
      b.text('Line 1');
      b.text('Line 2');
      b.text('Line 3');

      final resolved = b.resolve();
      expect(resolved.elements.length, equals(3));

      expect((resolved.elements[0] as TextElement).options.x, equals(20));
      expect((resolved.elements[0] as TextElement).options.y, equals(20));

      expect((resolved.elements[1] as TextElement).options.x, equals(20));
      expect((resolved.elements[1] as TextElement).options.y, equals(50));

      expect((resolved.elements[2] as TextElement).options.x, equals(20));
      expect((resolved.elements[2] as TextElement).options.y, equals(80));
    });

    test('sequential text preserves all style-only TextOptions fields', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );
      b.text(
        'Styled Header',
        const TextOptions(
          font: '0',
          size: 2,
          xScale: 2,
          yScale: 3,
          rotation: 90,
          bold: true,
          underline: true,
          reverse: true,
          align: 'center',
          maxWidth: 400,
        ),
      );

      final resolved = b.resolve();
      final el = resolved.elements[0] as TextElement;

      expect(el.content, equals('Styled Header'));
      expect(el.options.x, equals(20));
      expect(el.options.y, equals(20));
      expect(el.options.font, equals('0'));
      expect(el.options.size, equals(2));
      expect(el.options.xScale, equals(2));
      expect(el.options.yScale, equals(3));
      expect(el.options.rotation, equals(90));
      expect(el.options.bold, isTrue);
      expect(el.options.underline, isTrue);
      expect(el.options.reverse, isTrue);
      expect(el.options.align, equals('center'));
      expect(el.options.maxWidth, equals(400));
    });

    test('text size: 2 does not change vertical lineAdvance', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );
      b.text('Large Title', const TextOptions(size: 2));
      b.text('Next Line');

      final resolved = b.resolve();
      final el1 = resolved.elements[0] as TextElement;
      final el2 = resolved.elements[1] as TextElement;

      expect(el1.options.y, equals(20));
      expect(el2.options.y, equals(50)); // exactly 20 + 30
    });

    test('exact coordinate text acts as escape hatch without advancing sequential Y', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );
      b.text('Line 1'); // y = 20 -> next Y = 50

      // Exact escape hatch with x only:
      b.text('Corner Stamp', const TextOptions(x: 500));
      // Exact escape hatch with y only:
      b.text('Fixed Y', const TextOptions(y: 300));
      // Exact escape hatch with both x and y:
      b.text('Absolute', const TextOptions(x: 100, y: 150));

      // Next sequential text should still receive y = 50!
      b.text('Line 2');

      final resolved = b.resolve();
      expect(resolved.elements.length, equals(5));

      expect((resolved.elements[0] as TextElement).options.y, equals(20));
      expect((resolved.elements[1] as TextElement).options.x, equals(500));
      expect((resolved.elements[1] as TextElement).options.y, isNull);

      expect((resolved.elements[2] as TextElement).options.x, isNull);
      expect((resolved.elements[2] as TextElement).options.y, equals(300));

      expect((resolved.elements[3] as TextElement).options.x, equals(100));
      expect((resolved.elements[3] as TextElement).options.y, equals(150));

      expect((resolved.elements[4] as TextElement).options.x, equals(20));
      expect((resolved.elements[4] as TextElement).options.y, equals(50));
    });

    test('exact drawing primitives do not advance sequential Y', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );
      b.text('Line 1'); // y = 20 -> next Y = 50
      b.barcode(
        '123456',
        const BarcodeOptions(x: 20, y: 100, height: 50, type: '128'),
      );
      b.box(const BoxOptions(x: 10, y: 10, width: 200, height: 100));
      b.text('Line 2'); // should still be at y = 50!

      final resolved = b.resolve();
      expect((resolved.elements[0] as TextElement).options.y, equals(20));
      expect((resolved.elements[3] as TextElement).options.y, equals(50));
    });
  });

  group('space() helper', () {
    test('advances sequential Y without emitting AST elements', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );
      b.text('Line 1'); // y = 20 -> next Y = 50
      b.space(25); // next Y = 75
      b.space(0); // valid, next Y = 75
      b.text('Line 2'); // y = 75

      final resolved = b.resolve();
      expect(resolved.elements.length, equals(2));
      expect((resolved.elements[0] as TextElement).options.y, equals(20));
      expect((resolved.elements[1] as TextElement).options.y, equals(75));
    });

    test('throws InvalidConfigError on negative space amount', () {
      final b = sequentialLabel(const LabelConfig(width: 80, height: 40));
      expect(() => b.space(-1), throwsA(isA<InvalidConfigError>()));
    });
  });

  group('divider() helper', () {
    test('emits DividerElement spanning sequential content area and advances Y', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );
      b.text('Header'); // y = 20 -> next Y = 50
      b.divider(thickness: 2); // y = 50 -> next Y = 80
      b.text('Body'); // y = 80

      final resolved = b.resolve();
      expect(resolved.elements.length, equals(3));

      final div = resolved.elements[1] as DividerElement;
      final widthDots = toDots(80, Unit.mm, 203);
      final expectedUsable = widthDots - 40;

      expect(div.y, equals(50));
      expect(div.thickness, equals(2));
      expect(div.startX, equals(20));
      expect(div.width, equals(expectedUsable));

      expect((resolved.elements[2] as TextElement).options.y, equals(80));
    });

    test('divider with extra margin insets startX and narrows width', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );
      b.divider(margin: 15, advance: 40);

      final resolved = b.resolve();
      final div = resolved.elements[0] as DividerElement;
      final widthDots = toDots(80, Unit.mm, 203);
      final expectedUsable = widthDots - 40;

      expect(div.startX, equals(20 + 15));
      expect(div.width, equals(expectedUsable - 30));

      b.text('Next');
      final resolved2 = b.resolve();
      expect((resolved2.elements[1] as TextElement).options.y, equals(20 + 40));
    });

    test('throws InvalidConfigError on invalid divider arguments', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
      );

      expect(() => b.divider(thickness: 0), throwsA(isA<InvalidConfigError>()));
      expect(() => b.divider(advance: 0), throwsA(isA<InvalidConfigError>()));
      expect(() => b.divider(margin: -1), throwsA(isA<InvalidConfigError>()));

      // Usable width is widthDots - 40. Extra margin = 400 collapses width:
      expect(() => b.divider(margin: 400), throwsA(isA<InvalidConfigError>()));
    });
  });

  group('row() and rowCells() helpers', () {
    test('row() creates single RowElement with default 3:1 flex allocation', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );
      b.row('Latte', r'$4.50', bold: true);
      b.text('Footer');

      final resolved = b.resolve();
      expect(resolved.elements.length, equals(2));

      final row = resolved.elements[0] as RowElement;
      final widthDots = toDots(80, Unit.mm, 203);
      final usable = widthDots - 40;

      expect(row.y, equals(20));
      expect(row.startX, equals(20));
      expect(row.width, equals(usable));
      expect(row.size, equals(1));
      expect(row.cells.length, equals(2));

      // Cell 1: flex 3
      expect(row.cells[0].text, equals('Latte'));
      expect(row.cells[0].x, equals(20));
      expect(row.cells[0].width, equals((3 * usable) ~/ 4));
      expect(row.cells[0].align, equals(LabelTextAlign.left));
      expect(row.cells[0].style.bold, isTrue);

      // Cell 2: flex 1 (last flex receives exact remainder)
      expect(row.cells[1].text, equals(r'$4.50'));
      expect(row.cells[1].x, equals(20 + row.cells[0].width));
      expect(row.cells[1].width, equals(usable - row.cells[0].width));
      expect(row.cells[1].align, equals(LabelTextAlign.right));
      expect(row.cells[1].style.bold, isTrue);

      // Next element advances by lineAdvance
      expect((resolved.elements[1] as TextElement).options.y, equals(50));
    });

    test('rowCells() creates RowElement with fixed + flex cells and gaps', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );
      b.rowCells(
        children: [
          LabelCell.fixed(100, text: 'QTY', align: LabelTextAlign.center),
          LabelCell.flex(2, text: 'Item Description'),
          LabelCell.flex(1, text: 'Price', align: LabelTextAlign.right),
        ],
        gap: 10,
        size: 2,
        advance: 45,
      );

      final resolved = b.resolve();
      final row = resolved.elements[0] as RowElement;

      expect(row.size, equals(2));
      expect(row.cells.length, equals(3));
      expect(row.cells[0].text, equals('QTY'));
      expect(row.cells[0].width, equals(100));
      expect(row.cells[0].align, equals(LabelTextAlign.center));

      b.text('After rowCells');
      final resolved2 = b.resolve();
      expect((resolved2.elements[1] as TextElement).options.y, equals(20 + 45));
    });

    test('rowCells() preserves empty text cells for structural column positioning', () {
      final b = sequentialLabel(const LabelConfig(width: 80, height: 40));
      b.rowCells(
        children: [
          LabelCell.flex(1, text: ''),
          LabelCell.flex(1, text: 'TOTAL'),
          LabelCell.flex(1, text: r'$12.00', align: LabelTextAlign.right),
        ],
      );

      final resolved = b.resolve();
      final row = resolved.elements[0] as RowElement;
      expect(row.cells.length, equals(3));
      expect(row.cells[0].text, equals(''));
      expect(row.cells[1].text, equals('TOTAL'));
      expect(row.cells[2].text, equals(r'$12.00'));
    });

    test('throws InvalidConfigError on invalid rowCells arguments', () {
      final b = sequentialLabel(const LabelConfig(width: 80, height: 40));

      expect(
        () => b.rowCells(children: []),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => b.rowCells(
          children: [LabelCell.flex(1, text: 'A')],
          size: 0,
        ),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => b.rowCells(
          children: [LabelCell.flex(1, text: 'A')],
          gap: -1,
        ),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => b.rowCells(
          children: [LabelCell.flex(1, text: 'A')],
          advance: 0,
        ),
        throwsA(isA<InvalidConfigError>()),
      );
    });
  });
}
