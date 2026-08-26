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
    test('instantiates with defaults (false) and custom boolean flags', () {
      const defaultStyle = LabelTextStyle();
      expect(defaultStyle.bold, isFalse);
      expect(defaultStyle.underline, isFalse);

      const boldUnderline = LabelTextStyle(
        bold: true,
        underline: true,
      );
      expect(boldUnderline.bold, isTrue);
      expect(boldUnderline.underline, isTrue);
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
      expect(cell.style.underline, isFalse);
    });
  });

  group('RowElement', () {
    test('preserves row coordinates, width, default size, and cell order', () {
      const cell1 = RowCellElement(text: 'Latte', x: 20, width: 400);
      const cell2 = RowCellElement(
        text: r'$2.50',
        x: 430,
        width: 150,
        align: LabelTextAlign.right,
      );

      final row = RowElement(
        y: 100,
        startX: 20,
        width: 560,
        cells: [cell1, cell2],
      );

      expect(row.type, equals('row'));
      expect(row.y, equals(100));
      expect(row.startX, equals(20));
      expect(row.width, equals(560));
      expect(row.size, equals(1));
      expect(row.cells.length, equals(2));
      expect(row.cells[0].text, equals('Latte'));
      expect(row.cells[1].text, equals(r'$2.50'));
    });

    test('preserves explicit row-level size and rejects size < 1', () {
      final row = RowElement(
        y: 100,
        startX: 20,
        width: 560,
        size: 2,
        cells: const [RowCellElement(text: 'Large Header', x: 20, width: 560)],
      );
      expect(row.size, equals(2));

      expect(
        () => RowElement(
          y: 100,
          startX: 20,
          width: 560,
          size: 0,
          cells: const [],
        ),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => RowElement(
          y: 100,
          startX: 20,
          width: 560,
          size: -1,
          cells: const [],
        ),
        throwsA(isA<InvalidConfigError>()),
      );
    });

    test('enforces immutability: defends against external list mutations', () {
      final sourceList = <RowCellElement>[
        const RowCellElement(text: 'Latte', x: 20, width: 400),
      ];

      final row = RowElement(
        y: 100,
        startX: 20,
        width: 560,
        cells: sourceList,
      );

      sourceList.clear();
      expect(row.cells.length, equals(1));
      expect(row.cells[0].text, equals('Latte'));

      expect(
        () => row.cells.add(
          const RowCellElement(text: 'Cappuccino', x: 420, width: 100),
        ),
        throwsA(isA<UnsupportedError>()),
      );
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

  group('LabelCell runtime validation', () {
    test('creates fixed cell correctly', () {
      final cell = LabelCell.fixed(
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
      final cell = LabelCell.flex(
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

    test('throws InvalidConfigError when width <= 0 for fixed cell', () {
      expect(
        () => LabelCell.fixed(0, text: 'Test'),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => LabelCell.fixed(-5, text: 'Test'),
        throwsA(isA<InvalidConfigError>()),
      );
    });

    test('throws InvalidConfigError when flex <= 0 for flex cell', () {
      expect(
        () => LabelCell.flex(0, text: 'Test'),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => LabelCell.flex(-1, text: 'Test'),
        throwsA(isA<InvalidConfigError>()),
      );
    });
  });

  group('LabelColumn runtime validation', () {
    test('creates fixed column correctly', () {
      final col = LabelColumn.fixed(100, align: LabelTextAlign.right);
      expect(col.align, equals(LabelTextAlign.right));
    });

    test('creates flex column correctly', () {
      final col = LabelColumn.flex(2, align: LabelTextAlign.center);
      expect(col.align, equals(LabelTextAlign.center));
    });

    test('throws InvalidConfigError when width <= 0 for fixed column', () {
      expect(
        () => LabelColumn.fixed(0),
        throwsA(isA<InvalidConfigError>()),
      );
    });

    test('throws InvalidConfigError when flex <= 0 for flex column', () {
      expect(
        () => LabelColumn.flex(0),
        throwsA(isA<InvalidConfigError>()),
      );
    });
  });

  group('Intermediate Slice 1 safety stubs across compilers & preview', () {
    const testResolvedLabel = ResolvedLabel(
      widthDots: 600,
      heightDots: 400,
      dpi: 203,
      speed: 4,
      density: 8,
      direction: 0,
      copies: 1,
      gap: 0,
      gapOffset: 0,
      unit: Unit.mm,
      elements: [
        DividerElement(y: 100, startX: 20, width: 560),
      ],
    );

    test('Stream compilers throw UnsupportedFeatureError on unlowered RowElement/DividerElement in Slice 3', () {
      expect(
        () => compileToESCPOSBytes(testResolvedLabel),
        throwsA(isA<UnsupportedFeatureError>()),
      );
      expect(
        () => compileToStarPRNTBytes(testResolvedLabel),
        throwsA(isA<UnsupportedFeatureError>()),
      );
    });

    test('Page compilers and PreviewScene successfully process RowElement/DividerElement in Slice 3', () {
      expect(compileToTSCBytes(testResolvedLabel), isNotEmpty);
      expect(compileToZPLBytes(testResolvedLabel), isNotEmpty);
      expect(compileToEPLBytes(testResolvedLabel), isNotEmpty);
      expect(compileToCPCLBytes(testResolvedLabel), isNotEmpty);
      expect(compileToDPLBytes(testResolvedLabel), isNotEmpty);
      expect(compileToIPLBytes(testResolvedLabel), isNotEmpty);
      expect(compileToSBPLBytes(testResolvedLabel), isNotEmpty);
      expect(PreviewScene.fromResolved(testResolvedLabel).items, isNotEmpty);
    });
  });
}
