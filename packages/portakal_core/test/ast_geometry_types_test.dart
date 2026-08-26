import 'package:test/test.dart';
import 'package:portakal_core/portakal_core.dart';

void main() {
  group('LabelTextAlign', () {
    test('has correct identifier mappings', () {
      expect(LabelTextAlign.left.identifier, equals('left'));
      expect(LabelTextAlign.center.identifier, equals('center'));
      expect(LabelTextAlign.right.identifier, equals('right'));
    });
  });

  group('LabelTextStyle', () {
    test('instantiates with defaults and custom properties', () {
      const defaultStyle = LabelTextStyle();
      expect(defaultStyle.font, isNull);
      expect(defaultStyle.bold, isNull);
      expect(defaultStyle.underline, isNull);
      expect(defaultStyle.reverse, isNull);

      const customStyle = LabelTextStyle(
        font: '0',
        xScale: 2,
        yScale: 2,
        rotation: 90,
        bold: true,
        underline: true,
        reverse: false,
      );
      expect(customStyle.font, equals('0'));
      expect(customStyle.xScale, equals(2));
      expect(customStyle.yScale, equals(2));
      expect(customStyle.rotation, equals(90));
      expect(customStyle.bold, isTrue);
      expect(customStyle.underline, isTrue);
      expect(customStyle.reverse, isFalse);
    });
  });

  group('RowCellElement', () {
    test('preserves exact geometry and style', () {
      const cell = RowCellElement(
        text: 'Latte',
        x: 20,
        width: 400,
        align: LabelTextAlign.center,
        style: LabelTextStyle(bold: true),
      );

      expect(cell.text, equals('Latte'));
      expect(cell.x, equals(20));
      expect(cell.width, equals(400));
      expect(cell.align, equals(LabelTextAlign.center));
      expect(cell.style.bold, isTrue);
    });
  });

  group('RowElement', () {
    test('preserves row coordinates, width, and cell order', () {
      const cell1 = RowCellElement(text: 'Latte', x: 20, width: 400);
      const cell2 = RowCellElement(
        text: r'$2.50',
        x: 430,
        width: 150,
        align: LabelTextAlign.right,
      );

      const row = RowElement(
        y: 100,
        startX: 20,
        width: 560,
        cells: [cell1, cell2],
      );

      expect(row.type, equals('row'));
      expect(row.y, equals(100));
      expect(row.startX, equals(20));
      expect(row.width, equals(560));
      expect(row.cells.length, equals(2));
      expect(row.cells[0].text, equals('Latte'));
      expect(row.cells[1].text, equals(r'$2.50'));
    });
  });

  group('DividerElement', () {
    test('preserves horizontal line geometry', () {
      const divider = DividerElement(
        y: 150,
        thickness: 2,
        startX: 20,
        width: 560,
      );

      expect(divider.type, equals('divider'));
      expect(divider.y, equals(150));
      expect(divider.thickness, equals(2));
      expect(divider.startX, equals(20));
      expect(divider.width, equals(560));
    });
  });

  group('LabelCell', () {
    test('creates fixed cell correctly', () {
      const cell = LabelCell.fixed(
        120,
        text: 'Qty',
        align: LabelTextAlign.center,
        bold: true,
        underline: false,
      );

      expect(cell.text, equals('Qty'));
      expect(cell.align, equals(LabelTextAlign.center));
      expect(cell.bold, isTrue);
      expect(cell.underline, isFalse);
    });

    test('creates flex cell correctly', () {
      const cell = LabelCell.flex(
        3,
        text: 'Description',
        align: LabelTextAlign.left,
        bold: false,
        underline: true,
      );

      expect(cell.text, equals('Description'));
      expect(cell.align, equals(LabelTextAlign.left));
      expect(cell.bold, isFalse);
      expect(cell.underline, isTrue);
    });

    test('asserts width > 0 for fixed cell', () {
      expect(
        () => LabelCell.fixed(0, text: 'Test'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => LabelCell.fixed(-5, text: 'Test'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts flex > 0 for flex cell', () {
      expect(
        () => LabelCell.flex(0, text: 'Test'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => LabelCell.flex(-1, text: 'Test'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('LabelColumn', () {
    test('creates fixed column correctly', () {
      const col = LabelColumn.fixed(100, align: LabelTextAlign.right);
      expect(col.align, equals(LabelTextAlign.right));
    });

    test('creates flex column correctly', () {
      const col = LabelColumn.flex(2, align: LabelTextAlign.center);
      expect(col.align, equals(LabelTextAlign.center));
    });

    test('asserts width > 0 for fixed column', () {
      expect(
        () => LabelColumn.fixed(0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts flex > 0 for flex column', () {
      expect(
        () => LabelColumn.flex(0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
