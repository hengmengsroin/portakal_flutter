import 'dart:convert';
import 'package:portakal_core/portakal_core.dart';
import 'package:portakal_core/src/stream_row_formatter.dart';
import 'package:test/test.dart';

ResolvedLabel makeLabel({
  int widthDots = 576,
  int heightDots = 800,
  int dpi = 203,
  Unit unit = Unit.mm,
  List<LabelElement> elements = const [],
}) {
  return ResolvedLabel(
    widthDots: widthDots,
    heightDots: heightDots,
    dpi: dpi,
    unit: unit,
    speed: 0,
    density: 0,
    direction: 0,
    copies: 1,
    gap: 0,
    gapOffset: 0,
    elements: elements,
  );
}

void main() {
  group('StreamRowFormatter (Pure-Dart Grid Formatter)', () {
    test('classifies 58mm (<= 60mm) as 32 chars and 80mm (> 60mm) as 48 chars', () {
      // 58mm at 203 DPI: widthDots = 384 -> (384 / 203) * 25.4 = 48.04 mm <= 60
      final label58 = makeLabel(widthDots: 384, dpi: 203);
      expect(StreamRowFormatter.resolveBaseCharsPerLine(label58), equals(32));

      // 80mm at 203 DPI: widthDots = 576 -> (576 / 203) * 25.4 = 72.07 mm > 60
      final label80 = makeLabel(widthDots: 576, dpi: 203);
      expect(StreamRowFormatter.resolveBaseCharsPerLine(label80), equals(48));
    });

    test('character capacity is DPI-independent for equivalent physical widths', () {
      // 58mm at 203 DPI vs 300 DPI
      final label58_203 = makeLabel(widthDots: 384, dpi: 203);
      final label58_300 = makeLabel(widthDots: 567, dpi: 300);
      expect(StreamRowFormatter.resolveBaseCharsPerLine(label58_203), equals(32));
      expect(StreamRowFormatter.resolveBaseCharsPerLine(label58_300), equals(32));

      // 80mm at 203 DPI vs 300 DPI
      final label80_203 = makeLabel(widthDots: 576, dpi: 203);
      final label80_300 = makeLabel(widthDots: 850, dpi: 300);
      expect(StreamRowFormatter.resolveBaseCharsPerLine(label80_203), equals(48));
      expect(StreamRowFormatter.resolveBaseCharsPerLine(label80_300), equals(48));
    });

    test('supports explicit charsPerLine override and rejects non-positive values', () {
      final label = makeLabel(widthDots: 576, dpi: 203);
      expect(StreamRowFormatter.resolveBaseCharsPerLine(label, 42), equals(42));
      expect(
        () => StreamRowFormatter.resolveBaseCharsPerLine(label, 0),
        throwsA(isA<InvalidConfigError>()),
      );
      expect(
        () => StreamRowFormatter.resolveBaseCharsPerLine(label, -5),
        throwsA(isA<InvalidConfigError>()),
      );
    });

    test('formats 2-cell receipt row (3:1) with exact 48 character budget', () {
      final label = makeLabel(widthDots: 576, dpi: 203);
      final row = RowElement(
        y: 100,
        startX: 0,
        width: 576,
        size: 1,
        cells: [
          const RowCellElement(text: 'Latte', x: 0, width: 432),
          const RowCellElement(
            text: r'$2.50',
            x: 432,
            width: 144,
            align: LabelTextAlign.right,
          ),
        ],
      );

      final plan = StreamRowFormatter.formatRow(label, row);
      expect(plan.size, equals(1));
      expect(plan.segments.length, equals(2));

      // Cell 0: 432/576 * 48 = 36 chars ("Latte" + 31 spaces)
      expect(plan.segments[0].text.length, equals(36));
      expect(plan.segments[0].text, equals('Latte'.padRight(36)));

      // Cell 1: 144/576 * 48 = 12 chars (7 spaces + "$2.50")
      expect(plan.segments[1].text.length, equals(12));
      expect(plan.segments[1].text, equals(r'$2.50'.padLeft(12)));

      final combined = plan.segments.map((s) => s.text).join();
      expect(combined.length, equals(48));
    });

    test('formats 3-column table row with derived gaps and alignment', () {
      final label = makeLabel(widthDots: 576, dpi: 203);
      // Cell 1: x 0, width 240 (20 chars)
      // Gap 1: x 240..264 -> 24 dots (2 chars)
      // Cell 2: x 264, width 120 (10 chars, center)
      // Gap 2: x 384..408 -> 24 dots (2 chars)
      // Cell 3: x 408, width 168 (14 chars, right)
      // Total: 20 + 2 + 10 + 2 + 14 = 48 chars
      final row = RowElement(
        y: 120,
        startX: 0,
        width: 576,
        size: 1,
        cells: [
          const RowCellElement(text: 'Special Burger', x: 0, width: 240),
          const RowCellElement(text: 'x2', x: 264, width: 120, align: LabelTextAlign.center),
          const RowCellElement(text: r'$18.00', x: 408, width: 168, align: LabelTextAlign.right),
        ],
      );

      final plan = StreamRowFormatter.formatRow(label, row);
      final combined = plan.segments.map((s) => s.text).join();

      expect(combined.length, equals(48));
      expect(combined, contains('Special Burger'));
      expect(combined, contains('x2'));
      expect(combined, contains(r'$18.00'));
    });

    test('preserves whitespace for empty leading and middle cells', () {
      final label = makeLabel(widthDots: 576, dpi: 203);
      final row = RowElement(
        y: 150,
        startX: 0,
        width: 576,
        size: 1,
        cells: [
          const RowCellElement(text: '', x: 0, width: 240),
          const RowCellElement(text: 'TOTAL', x: 240, width: 168),
          const RowCellElement(text: r'$165.00', x: 408, width: 168, align: LabelTextAlign.right),
        ],
      );

      final plan = StreamRowFormatter.formatRow(label, row);
      // Cell 0 text should be 20 spaces
      expect(plan.segments[0].text, equals(' ' * 20));
      // Cell 1 text: "TOTAL" left aligned in 14 chars
      expect(plan.segments[1].text, equals('TOTAL'.padRight(14)));
      // Cell 2 text: "$165.00" right aligned in 14 chars
      expect(plan.segments[2].text, equals(r'$165.00'.padLeft(14)));

      final combined = plan.segments.map((s) => s.text).join();
      expect(combined.length, equals(48));
    });

    test('truncates runes safely without splitting surrogate pairs', () {
      final label = makeLabel(widthDots: 576, dpi: 203);
      // Cell with emoji rocket (surrogate pair) in a 4-char region
      final row = RowElement(
        y: 100,
        startX: 0,
        width: 576,
        size: 1,
        cells: [
          const RowCellElement(text: '🚀LaunchPad', x: 0, width: 48), // 4 chars
          const RowCellElement(text: 'Tail', x: 48, width: 528),
        ],
      );

      final plan = StreamRowFormatter.formatRow(label, row);
      final cell0Text = plan.segments[0].text;
      // 4 runes: 🚀, L, a, u
      expect(cell0Text.runes.length, equals(4));
      expect(cell0Text, equals('🚀Lau'));
    });

    test('handles size = 2 by halving effective character capacity', () {
      final label = makeLabel(widthDots: 576, dpi: 203);
      final row = RowElement(
        y: 100,
        startX: 0,
        width: 576,
        size: 2,
        cells: [
          const RowCellElement(text: 'BIG', x: 0, width: 288),
          const RowCellElement(text: 'TEXT', x: 288, width: 288, align: LabelTextAlign.right),
        ],
      );

      final plan = StreamRowFormatter.formatRow(label, row);
      expect(plan.size, equals(2));
      // Effective capacity = 48 ~/ 2 = 24 chars
      final combined = plan.segments.map((s) => s.text).join();
      expect(combined.length, equals(24));
      expect(plan.segments[0].text, equals('BIG'.padRight(12)));
      expect(plan.segments[1].text, equals('TEXT'.padLeft(12)));
    });

    test('formats DividerElement with thickness 1 as hyphen and > 1 as equal sign', () {
      final label = makeLabel(widthDots: 576, dpi: 203);
      final div1 = DividerElement(y: 80, thickness: 1, startX: 0, width: 576);
      final plan1 = StreamRowFormatter.formatDivider(label, div1);
      expect(plan1.segments[0].text, equals('-' * 48));

      final div2 = DividerElement(y: 90, thickness: 2, startX: 24, width: 528);
      final plan2 = StreamRowFormatter.formatDivider(label, div2);
      // startX: 24/576 * 48 = 2 spaces, width: 528/576 * 48 = 44 chars
      expect(plan2.segments[0].text, equals(('  ') + ('=' * 44)));
    });

    test('rejects malformed row geometry deterministically', () {
      final label = makeLabel(widthDots: 576, dpi: 203);

      // Overlapping cells
      final overlappingRow = RowElement(
        y: 100,
        startX: 0,
        width: 576,
        size: 1,
        cells: [
          const RowCellElement(text: 'A', x: 0, width: 300),
          const RowCellElement(text: 'B', x: 250, width: 300), // overlaps at 250..300
        ],
      );
      expect(
        () => StreamRowFormatter.formatRow(label, overlappingRow),
        throwsA(isA<InvalidConfigError>()),
      );

      // Row too narrow for cell count (e.g. 2 chars for 3 cells)
      final tooNarrowRow = RowElement(
        y: 100,
        startX: 0,
        width: 24, // 24/576 * 48 = 2 chars
        size: 1,
        cells: [
          const RowCellElement(text: 'A', x: 0, width: 8),
          const RowCellElement(text: 'B', x: 8, width: 8),
          const RowCellElement(text: 'C', x: 16, width: 8),
        ],
      );
      expect(
        () => StreamRowFormatter.formatRow(label, tooNarrowRow),
        throwsA(isA<InvalidConfigError>()),
      );
    });
  });

  group('ESC/POS Stream Compiler Lowering', () {
    test('lowers RowElement to one line with exact single line feed (0x0A)', () {
      final row = RowElement(
        y: 100,
        startX: 0,
        width: 576,
        size: 1,
        cells: [
          const RowCellElement(text: 'Coffee', x: 0, width: 432),
          const RowCellElement(text: r'$5.00', x: 432, width: 144, align: LabelTextAlign.right),
        ],
      );
      final label = makeLabel(elements: [row]);
      final bytes = compileToESCPOS(label);

      // Verify exact line feed count:
      // Init (ESC @ = 2 bytes)
      // Row content (48 bytes ASCII) + 1 LF (0x0A)
      // Cut (GS V B 3 = 4 bytes)
      final lfCount = bytes.where((b) => b == 0x0A).length;
      expect(lfCount, equals(1)); // exactly ONE line feed

      final text = latin1.decode(bytes);
      expect(text, contains('Coffee'));
      expect(text, contains(r'$5.00'));
    });

    test('manages per-cell bold and underline styles and resets before LF and next element', () {
      final row = RowElement(
        y: 100,
        startX: 0,
        width: 576,
        size: 1,
        cells: [
          const RowCellElement(
            text: 'BOLD_CELL',
            x: 0,
            width: 288,
            style: LabelTextStyle(bold: true, underline: true),
          ),
          const RowCellElement(
            text: 'PLAIN_CELL',
            x: 288,
            width: 288,
            style: LabelTextStyle(bold: false, underline: false),
          ),
        ],
      );
      final label = makeLabel(elements: [
        row,
        const TextElement(content: 'Normal Footer', options: TextOptions(x: 0, y: 150)),
      ]);
      final bytes = compileToESCPOS(label);

      // Verify ESC E 1 (bold on), ESC - 1 (underline on), ESC - 0 (underline off), ESC E 0 (bold off)
      expect(bytes, containsAllInOrder([0x1B, 0x45, 0x01])); // Bold ON
      expect(bytes, containsAllInOrder([0x1B, 0x2D, 0x01])); // Underline ON
      expect(bytes, containsAllInOrder([0x1B, 0x2D, 0x00])); // Underline OFF
      expect(bytes, containsAllInOrder([0x1B, 0x45, 0x00])); // Bold OFF
    });

    test('lowers DividerElement with exact characters and single line feed', () {
      final divider = DividerElement(y: 80, thickness: 2, startX: 0, width: 576);
      final label = makeLabel(elements: [divider]);
      final bytes = compileToESCPOS(label);

      final text = latin1.decode(bytes);
      expect(text, contains('=' * 48));
      final lfCount = bytes.where((b) => b == 0x0A).length;
      expect(lfCount, equals(1));
    });

    test('handles row.size = 2 with GS ! and restores normal magnification', () {
      final row = RowElement(
        y: 100,
        startX: 0,
        width: 576,
        size: 2,
        cells: [
          const RowCellElement(text: 'BIG LEFT', x: 0, width: 288),
          const RowCellElement(text: 'BIG RIGHT', x: 288, width: 288),
        ],
      );
      final label = makeLabel(elements: [row]);
      final bytes = compileToESCPOS(label);

      // GS ! 0x11 (2x width, 2x height)
      expect(bytes, containsAllInOrder([0x1D, 0x21, 0x11]));
      // GS ! 0x00 (reset to 1x)
      expect(bytes, containsAllInOrder([0x1D, 0x21, 0x00]));
    });
  });

  group('Star PRNT Stream Compiler Lowering', () {
    test('lowers RowElement to one line with exact single line feed (0x0A)', () {
      final row = RowElement(
        y: 100,
        startX: 0,
        width: 576,
        size: 1,
        cells: [
          const RowCellElement(text: 'Coffee', x: 0, width: 432),
          const RowCellElement(text: r'$5.00', x: 432, width: 144, align: LabelTextAlign.right),
        ],
      );
      final label = makeLabel(elements: [row]);
      final bytes = compileToStarPRNT(label);

      // Exactly ONE line feed
      final lfCount = bytes.where((b) => b == 0x0A).length;
      expect(lfCount, equals(1));

      final text = latin1.decode(bytes);
      expect(text, contains('Coffee'));
      expect(text, contains(r'$5.00'));
    });

    test('manages per-cell bold and underline styles with ESC E/F and ESC -', () {
      final row = RowElement(
        y: 100,
        startX: 0,
        width: 576,
        size: 1,
        cells: [
          const RowCellElement(
            text: 'BOLD_CELL',
            x: 0,
            width: 288,
            style: LabelTextStyle(bold: true, underline: true),
          ),
          const RowCellElement(
            text: 'PLAIN_CELL',
            x: 288,
            width: 288,
            style: LabelTextStyle(bold: false, underline: false),
          ),
        ],
      );
      final label = makeLabel(elements: [
        row,
        const TextElement(content: 'Normal Footer', options: TextOptions(x: 0, y: 150)),
      ]);
      final bytes = compileToStarPRNT(label);

      // ESC E (bold on), ESC - 1 (underline on), ESC - 0 (underline off), ESC F (bold off)
      expect(bytes, containsAllInOrder([0x1B, 0x45])); // Bold ON
      expect(bytes, containsAllInOrder([0x1B, 0x2D, 0x01])); // Underline ON
      expect(bytes, containsAllInOrder([0x1B, 0x2D, 0x00])); // Underline OFF
      expect(bytes, containsAllInOrder([0x1B, 0x46])); // Bold OFF
    });

    test('lowers DividerElement with exact characters and single line feed', () {
      final divider = DividerElement(y: 80, thickness: 1, startX: 0, width: 576);
      final label = makeLabel(elements: [divider]);
      final bytes = compileToStarPRNT(label);

      final text = latin1.decode(bytes);
      expect(text, contains('-' * 48));
      final lfCount = bytes.where((b) => b == 0x0A).length;
      expect(lfCount, equals(1));
    });

    test('handles row.size = 2 with ESC i 2 2 and restores 1 1', () {
      final row = RowElement(
        y: 100,
        startX: 0,
        width: 576,
        size: 2,
        cells: [
          const RowCellElement(text: 'BIG LEFT', x: 0, width: 288),
          const RowCellElement(text: 'BIG RIGHT', x: 288, width: 288),
        ],
      );
      final label = makeLabel(elements: [row]);
      final bytes = compileToStarPRNT(label);

      // ESC i 2 2
      expect(bytes, containsAllInOrder([0x1B, 0x69, 0x02, 0x02]));
      // ESC i 1 1
      expect(bytes, containsAllInOrder([0x1B, 0x69, 0x01, 0x01]));
    });
  });
}
