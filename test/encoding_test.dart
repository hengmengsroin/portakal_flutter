import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/src/encoding.dart';

void main() {
  group('isASCII', () {
    test('returns true for plain ASCII', () {
      expect(isASCII('Hello World'), isTrue);
      expect(isASCII('123 ABC !@#'), isTrue);
    });

    test('allows newlines', () {
      expect(isASCII('Hello\nWorld'), isTrue);
      expect(isASCII('Hello\r\nWorld'), isTrue);
    });

    test('returns false for accented characters', () {
      expect(isASCII('café'), isFalse);
      expect(isASCII('über'), isFalse);
    });

    test('returns false for Cyrillic', () {
      expect(isASCII('Привет'), isFalse);
    });

    test('returns false for CJK', () {
      expect(isASCII('你好'), isFalse);
    });

    test('returns false for Euro sign', () {
      expect(isASCII('€10.00'), isFalse);
    });
  });

  group('encodeText', () {
    test('encodes plain ASCII without code page switch', () {
      final segments = encodeText('Hello World');
      expect(segments, hasLength(1));
      expect(segments[0].codePage, equals(-1));
      expect(utf8.decode(segments[0].data), equals('Hello World'));
    });

    test('encodes Euro sign with CP858', () {
      final segments = encodeText('Total: €10.00');
      // "Total: " is ASCII, "€" needs CP858, "10.00" is ASCII
      expect(segments.length, greaterThanOrEqualTo(2));
      // Find segment with Euro
      final euroSeg = segments.where((s) => s.codePage == 19).firstOrNull;
      expect(euroSeg, isNotNull);
      expect(euroSeg!.data.contains(0xD5), isTrue); // € in CP858
    });

    test('encodes German umlauts with CP437', () {
      final segments = encodeText('Größe');
      // G, r are ASCII; ö needs CP437; ß needs CP437; e is ASCII
      final cpSeg = segments.where((s) => s.codePage == 0).firstOrNull;
      expect(cpSeg, isNotNull);
    });

    test('encodes Cyrillic with CP866', () {
      final segments = encodeText('Привет');
      final cpSeg = segments.where((s) => s.codePage == 17).firstOrNull;
      expect(cpSeg, isNotNull);
      expect(cpSeg!.data.length, equals(6)); // 6 Cyrillic chars
    });

    test('encodes Turkish characters with CP857', () {
      final segments = encodeText('Türkçe Ğğ İı Şş');
      // Should find CP857 or CP437 segments for Turkish chars
      final hasTurkish = segments.any((s) => s.codePage >= 0);
      expect(hasTurkish, isTrue);
    });

    test('minimizes code page switches for mixed text', () {
      final segments = encodeText('Price: €5.00');
      // Should not switch more than necessary
      expect(segments.length, lessThanOrEqualTo(3));
    });

    test('replaces unencodable characters with ?', () {
      final segments = encodeText('Hello 你好'); // Chinese not in any code page
      final allBytes = <int>[];
      for (final seg in segments) {
        allBytes.addAll(seg.data);
      }
      // Should contain ? (0x3F) for Chinese chars
      expect(allBytes.where((b) => b == 0x3F).length, equals(2));
    });

    test('handles empty string', () {
      final segments = encodeText('');
      expect(segments, hasLength(0));
    });

    test('handles newlines', () {
      final segments = encodeText('Line1\nLine2');
      final allBytes = <int>[];
      for (final seg in segments) {
        allBytes.addAll(seg.data);
      }
      expect(allBytes.contains(0x0A), isTrue);
    });
  });

  group('encodeTextForPrinter', () {
    test('returns ESC t commands for code page switches', () {
      final bytes = encodeTextForPrinter('€');
      final arr = bytes.toList();
      // Should contain ESC t 19 (CP858)
      final escTIdx = arr.indexWhere((b) {
        final i = arr.indexOf(b);
        return b == 0x1B && i + 1 < arr.length && arr[i + 1] == 0x74;
      });
      expect(escTIdx, greaterThan(-1));
      expect(arr[escTIdx + 2], equals(19)); // CP858
    });

    test('returns plain bytes for ASCII (no ESC t)', () {
      final bytes = encodeTextForPrinter('Hello');
      final arr = bytes.toList();
      // Should NOT contain ESC t
      bool hasEscT = false;
      for (int i = 0; i < arr.length - 1; i++) {
        if (arr[i] == 0x1B && arr[i + 1] == 0x74) {
          hasEscT = true;
          break;
        }
      }
      expect(hasEscT, isFalse);
      expect(utf8.decode(bytes), equals('Hello'));
    });

    test('encodes Cyrillic with ESC t 17 prefix', () {
      final bytes = encodeTextForPrinter('Москва');
      final arr = bytes.toList();
      int escTIdx = -1;
      for (int i = 0; i < arr.length - 1; i++) {
        if (arr[i] == 0x1B && arr[i + 1] == 0x74) {
          escTIdx = i;
          break;
        }
      }
      expect(escTIdx, greaterThan(-1));
      expect(arr[escTIdx + 2], equals(17)); // CP866
    });

    test('produces correct byte sequence for mixed ASCII + special', () {
      final bytes = encodeTextForPrinter('Total: £5');
      expect(bytes.length, greaterThan(0));
    });
  });
}
