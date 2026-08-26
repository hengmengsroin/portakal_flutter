import 'package:test/test.dart';
import 'package:portakal_core/portakal_core.dart';

void main() {
  group('LabelTable initialization & immutability', () {
    test('defensively copies column definitions against external mutation', () {
      final columns = <LabelColumn>[
        LabelColumn.flex(3),
        LabelColumn.flex(1, align: LabelTextAlign.right),
      ];

      final b = sequentialLabel(const LabelConfig(width: 80, height: 40));
      final table = b.table(columns: columns);

      columns.clear();

      // Table row still requires exactly 2 cells from original definition:
      table.row(['Item', r'$10.00']);
      final resolved = b.resolve();
      expect(resolved.elements.length, equals(1));
      final row = resolved.elements[0] as RowElement;
      expect(row.cells.length, equals(2));
    });

    test('throws InvalidConfigError on invalid table parameters', () {
      final b = sequentialLabel(const LabelConfig(width: 80, height: 40));

      expect(
        () => b.table(columns: []),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => b.table(
          columns: [LabelColumn.flex(1)],
          gap: -1,
        ),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => b.table(
          columns: [LabelColumn.flex(1)],
          defaultAdvance: 0,
        ),
        throwsA(isA<InvalidConfigError>()),
      );
    });
  });

  group('LabelTable.row() execution', () {
    test('creates RowElement matching column definitions and alignment', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );

      final table = b.table(
        columns: [
          LabelColumn.fixed(100, align: LabelTextAlign.center),
          LabelColumn.flex(3, align: LabelTextAlign.left),
          LabelColumn.flex(1, align: LabelTextAlign.right),
        ],
        gap: 10,
      );

      table.row(['1x', 'Espresso Macchiato', r'$3.50'], bold: true);

      final resolved = b.resolve();
      expect(resolved.elements.length, equals(1));

      final row = resolved.elements[0] as RowElement;
      expect(row.y, equals(20));
      expect(row.size, equals(1));
      expect(row.cells.length, equals(3));

      expect(row.cells[0].text, equals('1x'));
      expect(row.cells[0].width, equals(100));
      expect(row.cells[0].align, equals(LabelTextAlign.center));
      expect(row.cells[0].style.bold, isTrue);

      expect(row.cells[1].text, equals('Espresso Macchiato'));
      expect(row.cells[1].align, equals(LabelTextAlign.left));
      expect(row.cells[1].style.bold, isTrue);

      expect(row.cells[2].text, equals(r'$3.50'));
      expect(row.cells[2].align, equals(LabelTextAlign.right));
      expect(row.cells[2].style.bold, isTrue);
    });

    test('preserves empty cell strings for column structure', () {
      final b = sequentialLabel(const LabelConfig(width: 80, height: 40));
      final table = b.table(
        columns: [
          LabelColumn.flex(1),
          LabelColumn.flex(1),
          LabelColumn.flex(1),
        ],
      );

      table.row(['', 'SUBTOTAL', r'$25.00']);
      final resolved = b.resolve();
      final row = resolved.elements[0] as RowElement;
      expect(row.cells[0].text, equals(''));
      expect(row.cells[1].text, equals('SUBTOTAL'));
      expect(row.cells[2].text, equals(r'$25.00'));
    });

    test('throws InvalidConfigError when cell count does not match column count', () {
      final b = sequentialLabel(const LabelConfig(width: 80, height: 40));
      final table = b.table(
        columns: [
          LabelColumn.flex(1),
          LabelColumn.flex(1),
        ],
      );

      expect(
        () => table.row(['Only One']),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => table.row(['One', 'Two', 'Three']),
        throwsA(isA<InvalidConfigError>()),
      );
    });

    test('throws InvalidConfigError on invalid row size or advance', () {
      final b = sequentialLabel(const LabelConfig(width: 80, height: 40));
      final table = b.table(columns: [LabelColumn.flex(1)]);

      expect(
        () => table.row(['A'], size: 0),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => table.row(['A'], advance: 0),
        throwsA(isA<InvalidConfigError>()),
      );
    });
  });

  group('LabelTable shared document state with parent builder', () {
    test('table rows and divider advance parent builder cursor for subsequent elements', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );

      b.text('Header'); // y = 20 -> next Y = 50

      final table = b.table(
        columns: [
          LabelColumn.flex(2),
          LabelColumn.flex(1, align: LabelTextAlign.right),
        ],
      );

      table.row(['Item 1', r'$5.00']); // y = 50 -> next Y = 80
      table.row(['Item 2', r'$10.00']); // y = 80 -> next Y = 110
      table.divider(); // y = 110 -> next Y = 140
      table.space(20); // next Y = 160

      b.text('Footer'); // y = 160

      final resolved = b.resolve();
      expect(resolved.elements.length, equals(5));

      expect((resolved.elements[0] as TextElement).options.y, equals(20));
      expect((resolved.elements[1] as RowElement).y, equals(50));
      expect((resolved.elements[2] as RowElement).y, equals(80));
      expect((resolved.elements[3] as DividerElement).y, equals(110));
      expect((resolved.elements[4] as TextElement).options.y, equals(160));
    });

    test('multiple tables interleave and advance shared document cursor deterministically', () {
      final b = sequentialLabel(
        const LabelConfig(width: 80, height: 40),
        margin: 20,
        lineAdvance: 30,
      );

      final tableA = b.table(
        columns: [LabelColumn.flex(1)],
      );
      final tableB = b.table(
        columns: [LabelColumn.flex(1), LabelColumn.flex(1)],
      );

      tableA.row(['A1']); // y = 20 -> next Y = 50
      tableB.row(['B1', 'B2']); // y = 50 -> next Y = 80
      tableA.row(['A2']); // y = 80 -> next Y = 110

      final resolved = b.resolve();
      expect(resolved.elements.length, equals(3));
      expect((resolved.elements[0] as RowElement).y, equals(20));
      expect((resolved.elements[1] as RowElement).y, equals(50));
      expect((resolved.elements[2] as RowElement).y, equals(80));
    });
  });
}
