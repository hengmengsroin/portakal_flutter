import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/src/receipt.dart';

void main() {
  group('formatPair', () {
    test('formats left+right on same line', () {
      final result = formatPair('Hamburger', '\$12.99', 32);
      expect(result.length, equals(32));
      expect(result.startsWith('Hamburger'), isTrue);
      expect(result.endsWith('\$12.99'), isTrue);
    });

    test('pads with spaces between left and right', () {
      final result = formatPair('A', 'B', 10);
      expect(result, equals('A        B'));
    });

    test('handles exact fit', () {
      final result = formatPair('Left', 'Right', 9);
      expect(result, equals('LeftRight'));
    });

    test('truncates when right side is too long', () {
      final result = formatPair('A', 'Very Long Right', 10);
      expect(result.length, equals(10));
    });
  });

  group('formatRow', () {
    test('formats multi-column row', () {
      final cols = [
        Column(width: 20, align: 'left'),
        Column(width: 5, align: 'center'),
        Column(width: 7, align: 'right'),
      ];
      final result = formatRow(cols, ['Hamburger', 'x2', '\$25.98'], 32);
      expect(result.length, equals(32));
      expect(result.startsWith('Hamburger'), isTrue);
      expect(result.contains('\$25.98'), isTrue);
    });

    test('right-aligns column content', () {
      final cols = [Column(width: 10, align: 'right')];
      final result = formatRow(cols, ['Hi'], 10);
      expect(result, equals('        Hi'));
    });

    test('center-aligns column content', () {
      final cols = [Column(width: 10, align: 'center')];
      final result = formatRow(cols, ['Hi'], 10);
      expect(result, equals('    Hi    '));
    });

    test('truncates long content to column width', () {
      final cols = [Column(width: 5, align: 'left')];
      final result = formatRow(cols, ['VeryLongText'], 5);
      expect(result, equals('VeryL'));
    });

    test('handles empty values', () {
      final cols = [
        Column(width: 5, align: 'left'),
        Column(width: 5, align: 'left'),
      ];
      final result = formatRow(cols, ['A'], 10);
      expect(result.length, equals(10));
    });
  });

  group('formatTable', () {
    test('formats multiple rows', () {
      final cols = [
        Column(width: 20, align: 'left'),
        Column(width: 5, align: 'center'),
        Column(width: 7, align: 'right'),
      ];
      final rows = [
        ['Item', 'Qty', 'Price'],
        ['Hamburger', '2', '\$25.98'],
        ['Cola', '1', '\$3.50'],
      ];
      final result = formatTable(cols, rows, 32);
      expect(result, hasLength(3));
      for (final line in result) {
        expect(line.length, equals(32));
      }
    });
  });

  group('separator', () {
    test('creates line of repeated characters', () {
      expect(separator('=', 32), equals('=' * 32));
      expect(separator('-', 10), equals('-' * 10));
    });

    test('handles single char', () {
      expect(separator('*', 1), equals('*'));
    });
  });

  group('wordWrap', () {
    test('returns single line if text fits', () {
      expect(wordWrap('Hello World', 32), equals(['Hello World']));
    });

    test('wraps at word boundary', () {
      final result = wordWrap('The quick brown fox jumps over the lazy dog', 20);
      expect(result.length, greaterThan(1));
      for (final line in result) {
        expect(line.length, lessThanOrEqualTo(20));
      }
    });

    test('preserves all words', () {
      const text = 'Hello beautiful world';
      final result = wordWrap(text, 10);
      final joined = result.join(' ');
      expect(joined, equals(text));
    });

    test('handles single long word', () {
      final result = wordWrap('Superlongword', 5);
      expect(result, equals(['Superlongword'])); // can't break within word
    });

    test('handles empty string', () {
      expect(wordWrap('', 10), equals(['']));
    });
  });

  group('receipt integration', () {
    test('builds a complete receipt layout', () {
      const w = 32;
      final lines = <String>[];

      lines.add(separator('=', w));
      lines.add(formatPair('Hamburger x2', '\$25.98', w));
      lines.add(formatPair('Cola x1', '\$3.50', w));
      lines.add(separator('-', w));
      lines.add(formatPair('TOTAL', '\$29.48', w));
      lines.add(separator('=', w));

      expect(lines, hasLength(6));
      for (final line in lines) {
        expect(line.length, equals(w));
      }
      expect(lines[1], contains('Hamburger'));
      expect(lines[1], contains('\$25.98'));
      expect(lines[4], contains('TOTAL'));
      expect(lines[4], contains('\$29.48'));
    });
  });
}
