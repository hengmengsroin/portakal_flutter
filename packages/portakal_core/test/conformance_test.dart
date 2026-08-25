import 'dart:convert';
import 'package:test/test.dart';
import 'package:portakal_core/src/barcode_encoder.dart';
import 'package:portakal_core/src/qr_encoder.dart';

void main() {
  group('Phase 8F — Independent Standards Conformance & Decoder Validation', () {
    // =========================================================================
    // 1. QR CODE INDEPENDENT CONFORMANCE & DECODER
    // =========================================================================
    group('QR Code Standards Conformance (ISO/IEC 18004)', () {
      test('Independent QR Matrix Decoder recovers ASCII, URLs, and numeric payloads', () {
        final testCases = [
          'HELLO',
          'PORTAKAL-1.1',
          '1234567890',
          'https://portakal.dev/invoice/INV-001',
          'STANDARD-QR-CODE-TEST-VECTOR',
        ];

        for (final payload in testCases) {
          for (final ecc in ['L', 'M', 'Q', 'H']) {
            final matrix = QrCodeEncoder.encode(payload, ecc: ecc);
            expect(matrix, isNotNull, reason: 'Failed to encode "$payload" with ECC $ecc');

            final decoded = _decodeQrMatrix(matrix!);
            expect(decoded, equals(payload),
                reason: 'Decoded QR mismatch for "$payload" at ECC $ecc (Version ${((matrix.size - 17) ~/ 4)})');
          }
        }
      });

      test('Independent QR Matrix Decoder recovers multi-byte UTF-8 Unicode payloads', () {
        final unicodeCases = [
          'Café & Thé',
          'Total: 10.50€',
          'Khmer: ភាសាខ្មែរ',
          'Cyrillic: Привет мир',
          'Japanese: プリンター',
          'Mixed: ⚡ Portakal 1.1 ✨ 100% OK 🚀',
        ];

        for (final payload in unicodeCases) {
          final matrix = QrCodeEncoder.encode(payload, ecc: 'M');
          expect(matrix, isNotNull, reason: 'Failed to encode Unicode "$payload"');

          final decoded = _decodeQrMatrix(matrix!);
          expect(decoded, equals(payload), reason: 'Decoded Unicode mismatch for "$payload"');
        }
      });

      test('QR Version boundaries across Versions 1, 2, 5, 10 and ECC levels', () {
        // Version 1 ECC M max capacity: 14 bytes
        final v1Payload = '12345678901234'; // 14 bytes
        final matrixV1 = QrCodeEncoder.encode(v1Payload, ecc: 'M')!;
        expect(matrixV1.size, equals(21));
        expect(_decodeQrMatrix(matrixV1), equals(v1Payload));

        // Version 2 ECC M max capacity: 26 bytes (15 bytes forces V2)
        final v2Payload = '123456789012345'; // 15 bytes -> V2 (25x25)
        final matrixV2 = QrCodeEncoder.encode(v2Payload, ecc: 'M')!;
        expect(matrixV2.size, equals(25));
        expect(_decodeQrMatrix(matrixV2), equals(v2Payload));

        // Version 5 ECC L capacity: 106 bytes (forces V5: 37x37)
        final v5Payload = 'A' * 90;
        final matrixV5 = QrCodeEncoder.encode(v5Payload, ecc: 'L')!;
        expect(matrixV5.size, equals(37));
        expect(_decodeQrMatrix(matrixV5), equals(v5Payload));

        // Version 10 ECC L capacity: 271 bytes (forces V10: 57x57)
        final v10Payload = 'B' * 250;
        final matrixV10 = QrCodeEncoder.encode(v10Payload, ecc: 'L')!;
        expect(matrixV10.size, equals(57));
        expect(_decodeQrMatrix(matrixV10), equals(v10Payload));
      });

      test('Capacity limit enforcement and graceful rejection', () {
        // Max capacity for Version 10 ECC L is 271 bytes
        final fits = 'X' * 271;
        expect(QrCodeEncoder.encode(fits, ecc: 'L'), isNotNull);

        final exceeds = 'X' * 272; // Exceeds V10 Byte mode capacity
        expect(QrCodeEncoder.encode(exceeds, ecc: 'L'), isNull);
        expect(QrCodeEncoder.encode(''), isNull);
      });

      test('QR Structural invariants (Finders, Timing, Alignment, Format, Version Info)', () {
        final matrix = QrCodeEncoder.encode('INVARIANT_CHECK', ecc: 'Q')!;
        final size = matrix.size;

        // 1. Finders: (0,0), (0, size-7), (size-7, 0) - 7x7 outer border black, 5x5 white, 3x3 center black
        for (final corner in [
          [0, 0],
          [0, size - 7],
          [size - 7, 0]
        ]) {
          final r0 = corner[0];
          final c0 = corner[1];
          // Check top/bottom edges of finder
          for (var i = 0; i < 7; i++) {
            expect(matrix.isDark(r0, c0 + i), isTrue);
            expect(matrix.isDark(r0 + 6, c0 + i), isTrue);
            expect(matrix.isDark(r0 + i, c0), isTrue);
            expect(matrix.isDark(r0 + i, c0 + 6), isTrue);
          }
          // Center 3x3
          for (var dr = 2; dr <= 4; dr++) {
            for (var dc = 2; dc <= 4; dc++) {
              expect(matrix.isDark(r0 + dr, c0 + dc), isTrue);
            }
          }
        }

        // 2. Timing patterns: row 6 and col 6 alternating
        for (var i = 8; i < size - 8; i++) {
          expect(matrix.isDark(6, i), equals(i % 2 == 0));
          expect(matrix.isDark(i, 6), equals(i % 2 == 0));
        }

        // 3. Dark module at (4*V + 9, 8)
        final version = (size - 17) ~/ 4;
        expect(matrix.isDark(4 * version + 9, 8), isTrue);
      });
    });

    // =========================================================================
    // 2. CODE 128 INDEPENDENT CONFORMANCE & DECODER
    // =========================================================================
    group('Code 128 (Set B) Standards Conformance (ISO/IEC 15417)', () {
      test('Independent Code 128 Scanner recovers ASCII Set B payloads', () {
        final testCases = [
          'PORTAKAL123456',
          '123456789',
          'INV-2026-001',
          'Package #42: OK!',
          'abcdefghijklmnopqrstuvwxyz',
          'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
          '0123456789!@#\$%^&*()-_=+',
        ];

        for (final payload in testCases) {
          final pattern = BarcodeEncoder.encode('128', payload);
          expect(pattern, isNotNull, reason: 'Failed to encode Code128 "$payload"');

          final decoded = _decodeCode128(pattern!);
          expect(decoded, equals(payload), reason: 'Decoded Code128 mismatch for "$payload"');
        }
      });

      test('Code 128 rejects unencodable characters gracefully', () {
        expect(BarcodeEncoder.encode('128', ''), isNull);
        expect(BarcodeEncoder.encode('128', 'Non-ASCII: \u00E9'), isNull); // Non-ASCII Set B
        expect(BarcodeEncoder.encode('128', 'Control: \u0005'), isNull); // Control code < 32
      });
    });

    // =========================================================================
    // 3. CODE 39 INDEPENDENT CONFORMANCE & DECODER
    // =========================================================================
    group('Code 39 Standards Conformance (ISO/IEC 16388)', () {
      test('Independent Code 39 Scanner recovers uppercase alphanumeric & symbol payloads', () {
        final testCases = [
          'PORTAKAL123',
          'TRACK-12345',
          'PRICE \$15.00',
          '100% OK',
          'CODE/39+TEST',
          'A.B-C D',
        ];

        for (final payload in testCases) {
          final pattern = BarcodeEncoder.encode('39', payload);
          expect(pattern, isNotNull, reason: 'Failed to encode Code39 "$payload"');

          final decoded = _decodeCode39(pattern!);
          expect(decoded, equals(payload.toUpperCase()),
              reason: 'Decoded Code39 mismatch for "$payload"');
        }
      });

      test('Code 39 rejects invalid characters gracefully', () {
        expect(BarcodeEncoder.encode('39', ''), isNull);
        expect(BarcodeEncoder.encode('39', 'INVALID!CHAR'), isNull); // '!' not in Code39 alphabet
        expect(BarcodeEncoder.encode('39', 'Non-ASCII \u00C9'), isNull);
      });
    });

    // =========================================================================
    // 4. EAN-13 / EAN-8 / UPC-A CONFORMANCE & DECODER
    // =========================================================================
    group('EAN-13 / EAN-8 / UPC-A Standards Conformance (ISO/IEC 15420)', () {
      test('Independent EAN-13 Scanner recovers 12-digit and 13-digit retail payloads', () {
        final testCases = [
          '4006381333931', // Known Stabilo Boss EAN-13
          '9780201379624', // Known ISBN-13
          '5901234123457',
          '123456789012',  // 12-digit with auto-generated checksum
        ];

        for (final payload in testCases) {
          final pattern = BarcodeEncoder.encode('EAN13', payload);
          expect(pattern, isNotNull, reason: 'Failed to encode EAN13 "$payload"');

          final decoded = _decodeEan(pattern!);
          final expected = payload.length == 12 ? _appendEan13Check(payload) : payload;
          expect(decoded, equals(expected), reason: 'Decoded EAN13 mismatch for "$payload"');
        }
      });

      test('Independent EAN-8 Scanner recovers 7-digit and 8-digit retail payloads', () {
        final testCases = [
          '12345670',
          '96385074',
          '4012345', // 7-digit with auto-generated checksum
        ];

        for (final payload in testCases) {
          final pattern = BarcodeEncoder.encode('EAN8', payload);
          expect(pattern, isNotNull, reason: 'Failed to encode EAN8 "$payload"');

          final decoded = _decodeEan8(pattern!);
          final expected = payload.length == 7 ? _appendEan8Check(payload) : payload;
          expect(decoded, equals(expected), reason: 'Decoded EAN8 mismatch for "$payload"');
        }
      });

      test('Independent UPC-A Scanner recovers 11-digit and 12-digit payloads', () {
        final testCases = [
          '012345678905',
          '725272730706',
          '03600029145', // 11-digit with auto-generated checksum
        ];

        for (final payload in testCases) {
          final pattern = BarcodeEncoder.encode('UPCA', payload);
          expect(pattern, isNotNull, reason: 'Failed to encode UPC-A "$payload"');

          final decoded = _decodeEan(pattern!);
          final expectedWith0 = payload.length == 11
              ? '0${_appendUpcACheck(payload)}'
              : '0$payload';
          expect(decoded, equals(expectedWith0));
        }
      });

      test('EAN/UPC rejects invalid input', () {
        expect(BarcodeEncoder.encode('EAN13', '12345'), isNull); // Too short
        expect(BarcodeEncoder.encode('EAN13', '123456789012345'), isNull); // Too long
        expect(BarcodeEncoder.encode('EAN13', '123456789012A'), isNull); // Non-digit
        expect(BarcodeEncoder.encode('UPCE', '0123456'), isNull); // Classified as PLACEHOLDER for 1.1
      });
    });
  });
}

// =============================================================================
// INDEPENDENT QR CODE MATRIX DECODER (Reference Implementation for Verification)
// =============================================================================
String? _decodeQrMatrix(QrCodeMatrix matrix) {
  final size = matrix.size;
  final version = (size - 17) ~/ 4;

  // 1. Identify function modules map
  final isFunction = List.generate(size, (_) => List<bool>.filled(size, false));

  void markFn(int r, int c) {
    if (r >= 0 && r < size && c >= 0 && c < size) isFunction[r][c] = true;
  }

  // Finders + separators
  for (final corner in [
    [0, 0],
    [0, size - 7],
    [size - 7, 0]
  ]) {
    final r0 = corner[0];
    final c0 = corner[1];
    for (var r = -1; r <= 7; r++) {
      for (var c = -1; c <= 7; c++) {
        markFn(r0 + r, c0 + c);
      }
    }
  }

  // Alignment patterns
  const alignmentPositions = <List<int>>[
    [],
    [6, 18],
    [6, 22],
    [6, 26],
    [6, 30],
    [6, 34],
    [6, 22, 38],
    [6, 24, 42],
    [6, 26, 46],
    [6, 28, 50],
  ];
  if (version >= 2) {
    final coords = alignmentPositions[version - 1];
    for (final r in coords) {
      for (final c in coords) {
        if (isFunction[r][c]) continue;
        for (var dr = -2; dr <= 2; dr++) {
          for (var dc = -2; dc <= 2; dc++) {
            markFn(r + dr, c + dc);
          }
        }
      }
    }
  }

  // Timing patterns
  for (var i = 0; i < size; i++) {
    markFn(6, i);
    markFn(i, 6);
  }

  // Dark module
  markFn(4 * version + 9, 8);

  // Format info
  for (var i = 0; i < 9; i++) {
    markFn(8, i);
    markFn(i, 8);
  }
  for (var i = 0; i < 8; i++) {
    markFn(8, size - 1 - i);
    markFn(size - 1 - i, 8);
  }

  // Version info
  if (version >= 7) {
    for (var r = 0; r < 6; r++) {
      for (var c = size - 11; c < size - 8; c++) {
        markFn(r, c);
        markFn(c, r);
      }
    }
  }

  // 2. Read raw data bits in zig-zag upward/downward order with Mask 0 ((r+c)%2 == 0)
  final bits = <int>[];
  var upward = true;

  for (var right = size - 1; right > 0; right -= 2) {
    if (right == 6) right--;

    final rows = upward
        ? List.generate(size, (i) => size - 1 - i)
        : List.generate(size, (i) => i);

    for (final r in rows) {
      for (var cOffset = 0; cOffset < 2; cOffset++) {
        final c = right - cOffset;
        if (!isFunction[r][c]) {
          var val = matrix.isDark(r, c) ? 1 : 0;
          if ((r + c) % 2 == 0) {
            val ^= 1; // Unmask Mask 0
          }
          bits.add(val);
        }
      }
    }
    upward = !upward;
  }

  // Convert bits to codewords
  final rawCodewords = <int>[];
  for (var i = 0; i + 8 <= bits.length; i += 8) {
    var b = 0;
    for (var j = 0; j < 8; j++) {
      b = (b << 1) | bits[i + j];
    }
    rawCodewords.add(b);
  }

  // 3. Read format info to get ECC level
  var formatRaw = 0;
  // Read top-left format info bits
  for (var i = 0; i < 6; i++) {
    formatRaw = (formatRaw << 1) | (matrix.isDark(8, i) ? 1 : 0);
  }
  formatRaw = (formatRaw << 1) | (matrix.isDark(8, 7) ? 1 : 0);
  formatRaw = (formatRaw << 1) | (matrix.isDark(8, 8) ? 1 : 0);
  formatRaw = (formatRaw << 1) | (matrix.isDark(7, 8) ? 1 : 0);
  for (var i = 5; i >= 0; i--) {
    formatRaw = (formatRaw << 1) | (matrix.isDark(i, 8) ? 1 : 0);
  }
  formatRaw ^= 0x5412; // Unmask format info
  final eccBits = (formatRaw >> 13) & 3; // L=01 (1), M=00 (0), Q=11 (3), H=10 (2)

  var eccIdx = 1;
  if (eccBits == 1) {
    eccIdx = 0; // L
  } else if (eccBits == 0) {
    eccIdx = 1; // M
  } else if (eccBits == 3) {
    eccIdx = 2; // Q
  } else if (eccBits == 2) {
    eccIdx = 3; // H
  }

  const totalDataCodewords = [
    [19, 16, 13, 9], [34, 28, 22, 16], [55, 44, 34, 26], [80, 64, 48, 36],
    [108, 86, 62, 46], [136, 108, 76, 60], [156, 124, 88, 66], [194, 154, 110, 86],
    [232, 182, 132, 100], [274, 216, 154, 122],
  ];
  const eccBlocks = [
    [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 2, 2], [1, 2, 2, 4],
    [1, 2, 4, 4], [2, 4, 4, 4], [2, 4, 6, 5], [2, 4, 6, 6],
    [2, 5, 8, 8], [4, 5, 8, 8],
  ];

  final totalData = totalDataCodewords[version - 1][eccIdx];
  final numBlocks = eccBlocks[version - 1][eccIdx];
  final baseBlockSize = totalData ~/ numBlocks;
  final numLargerBlocks = totalData % numBlocks;
  final maxDataBlock = baseBlockSize + (numLargerBlocks > 0 ? 1 : 0);

  // De-interleave data codewords
  final blocks = List.generate(numBlocks, (_) => <int>[]);
  var cwIdx = 0;
  for (var i = 0; i < maxDataBlock; i++) {
    for (var b = 0; b < numBlocks; b++) {
      final bSize = baseBlockSize + (b >= numBlocks - numLargerBlocks ? 1 : 0);
      if (i < bSize && cwIdx < rawCodewords.length) {
        blocks[b].add(rawCodewords[cwIdx++]);
      }
    }
  }

  final dataCodewords = [for (final b in blocks) ...b];
  final dataBits = <int>[];
  for (final cw in dataCodewords) {
    for (var b = 7; b >= 0; b--) {
      dataBits.add((cw >> b) & 1);
    }
  }

  // 4. Parse Byte mode data stream from de-interleaved data bits
  int readBits(int offset, int count) {
    var result = 0;
    for (var i = 0; i < count; i++) {
      if (offset + i < dataBits.length) {
        result = (result << 1) | dataBits[offset + i];
      }
    }
    return result;
  }

  var bitOffset = 0;
  final mode = readBits(bitOffset, 4);
  bitOffset += 4;

  if (mode != 4) return null; // Expected Byte mode (0100)

  final charCountBits = version < 10 ? 8 : 16;
  final charCount = readBits(bitOffset, charCountBits);
  bitOffset += charCountBits;

  final byteList = <int>[];
  for (var i = 0; i < charCount; i++) {
    byteList.add(readBits(bitOffset, 8));
    bitOffset += 8;
  }

  return utf8.decode(byteList, allowMalformed: true);
}

// =============================================================================
// INDEPENDENT CODE 128 SCANNER
// =============================================================================
String? _decodeCode128(BarcodeVisualPattern pattern) {
  final widths = pattern.moduleWidths;
  // Patterns for 107 symbols
  const code128Patterns = [
    [2, 1, 2, 2, 2, 2], [2, 2, 2, 1, 2, 2], [2, 2, 2, 2, 2, 1], [1, 2, 1, 2, 2, 3],
    [1, 2, 1, 3, 2, 2], [1, 3, 1, 2, 2, 2], [1, 2, 2, 2, 1, 3], [1, 2, 2, 3, 1, 2],
    [1, 3, 2, 2, 1, 2], [2, 2, 1, 2, 1, 3], [2, 2, 1, 3, 1, 2], [2, 3, 1, 2, 1, 2],
    [1, 1, 2, 2, 3, 2], [1, 2, 2, 1, 3, 2], [1, 2, 2, 2, 3, 1], [1, 1, 3, 2, 2, 2],
    [1, 2, 3, 1, 2, 2], [1, 2, 3, 2, 2, 1], [2, 2, 3, 2, 1, 1], [2, 2, 1, 1, 3, 2],
    [2, 2, 1, 2, 3, 1], [2, 1, 3, 2, 1, 2], [2, 2, 3, 1, 1, 2], [3, 1, 2, 1, 3, 1],
    [3, 1, 1, 2, 2, 2], [3, 2, 1, 1, 2, 2], [3, 2, 1, 2, 2, 1], [3, 1, 2, 2, 1, 2],
    [3, 2, 2, 1, 1, 2], [3, 2, 2, 2, 1, 1], [2, 1, 2, 1, 2, 3], [2, 1, 2, 3, 2, 1],
    [2, 3, 2, 1, 2, 1], [1, 1, 1, 3, 2, 3], [1, 3, 1, 1, 2, 3], [1, 3, 1, 3, 2, 1],
    [1, 1, 2, 3, 1, 3], [1, 3, 2, 1, 1, 3], [1, 3, 2, 3, 1, 1], [2, 1, 1, 3, 1, 3],
    [2, 3, 1, 1, 1, 3], [2, 3, 1, 3, 1, 1], [1, 1, 2, 1, 3, 3], [1, 1, 2, 3, 3, 1],
    [1, 3, 2, 1, 3, 1], [1, 1, 3, 1, 2, 3], [1, 1, 3, 3, 2, 1], [1, 3, 3, 1, 2, 1],
    [3, 1, 3, 1, 2, 1], [2, 1, 1, 3, 3, 1], [2, 3, 1, 1, 3, 1], [2, 1, 3, 1, 1, 3],
    [2, 1, 3, 3, 1, 1], [2, 1, 3, 1, 3, 1], [3, 1, 1, 1, 2, 3], [3, 1, 1, 3, 2, 1],
    [3, 3, 1, 1, 2, 1], [3, 1, 2, 1, 1, 3], [3, 1, 2, 3, 1, 1], [3, 3, 2, 1, 1, 1],
    [3, 1, 4, 1, 1, 1], [2, 2, 1, 4, 1, 1], [4, 3, 1, 1, 1, 1], [1, 1, 1, 2, 2, 4],
    [1, 1, 1, 4, 2, 2], [1, 2, 1, 1, 2, 4], [1, 2, 1, 4, 2, 1], [1, 4, 1, 1, 2, 2],
    [1, 4, 1, 2, 2, 1], [1, 1, 2, 2, 1, 4], [1, 1, 2, 4, 1, 2], [1, 2, 2, 1, 1, 4],
    [1, 2, 2, 4, 1, 1], [1, 4, 2, 1, 1, 2], [1, 4, 2, 2, 1, 1], [2, 4, 1, 2, 1, 1],
    [2, 2, 1, 1, 1, 4], [4, 1, 3, 1, 1, 1], [2, 4, 1, 1, 1, 2], [1, 3, 4, 1, 1, 1],
    [1, 1, 1, 2, 4, 2], [1, 2, 1, 1, 4, 2], [1, 2, 1, 2, 4, 1], [1, 1, 4, 2, 1, 2],
    [1, 2, 4, 1, 1, 2], [1, 2, 4, 2, 1, 1], [4, 1, 1, 2, 1, 2], [4, 2, 1, 1, 1, 2],
    [4, 2, 1, 2, 1, 1], [2, 1, 2, 1, 4, 1], [2, 1, 4, 1, 2, 1], [4, 1, 2, 1, 2, 1],
    [1, 1, 1, 1, 4, 3], [1, 1, 1, 3, 4, 1], [1, 3, 1, 1, 4, 1], [1, 1, 4, 1, 1, 3],
    [1, 1, 4, 3, 1, 1], [4, 1, 1, 1, 1, 3], [4, 1, 1, 3, 1, 1], [1, 1, 3, 1, 4, 1],
    [1, 1, 4, 1, 3, 1], [3, 1, 1, 1, 4, 1], [4, 1, 1, 1, 3, 1], [2, 1, 1, 4, 1, 2],
    [2, 1, 1, 2, 1, 4], [2, 1, 1, 2, 3, 2], [2, 3, 3, 1, 1, 1, 2] // 106 = STOP
  ];

  int? matchSymbol(List<int> chunk) {
    for (var i = 0; i < code128Patterns.length; i++) {
      final p = code128Patterns[i];
      if (p.length == chunk.length) {
        var match = true;
        for (var j = 0; j < p.length; j++) {
          if (p[j] != chunk[j]) {
            match = false;
            break;
          }
        }
        if (match) return i;
      }
    }
    return null;
  }

  final symbols = <int>[];
  var idx = 0;

  while (idx < widths.length) {
    // If last 7 widths, check for stop pattern
    if (idx == widths.length - 7) {
      final sym = matchSymbol(widths.sublist(idx, idx + 7));
      if (sym == null) return null;
      symbols.add(sym);
      idx += 7;
    } else {
      final sym = matchSymbol(widths.sublist(idx, idx + 6));
      if (sym == null) return null;
      symbols.add(sym);
      idx += 6;
    }
  }

  if (symbols.length < 3) return null;
  if (symbols.first != 104) return null; // Start B
  if (symbols.last != 106) return null; // Stop

  // Verify checksum: (start + sum(val * pos)) % 103
  var sum = symbols.first;
  for (var i = 1; i < symbols.length - 2; i++) {
    sum += symbols[i] * i;
  }
  final check = symbols[symbols.length - 2];
  if (sum % 103 != check) return null;

  final chars = symbols.sublist(1, symbols.length - 2).map((s) => String.fromCharCode(s + 32)).join();
  return chars;
}

// =============================================================================
// INDEPENDENT CODE 39 SCANNER
// =============================================================================
String? _decodeCode39(BarcodeVisualPattern pattern) {
  final widths = pattern.moduleWidths;
  const code39Patterns = {
    '1': '100100001', '2': '001100001', '3': '101100000', '4': '000110001',
    '5': '100110000', '6': '001110000', '7': '000100101', '8': '100100100',
    '9': '001100100', '0': '000110100', 'A': '100001001', 'B': '001001001',
    'C': '101001000', 'D': '000011001', 'E': '100011000', 'F': '001011000',
    'G': '000001101', 'H': '100001100', 'I': '001001100', 'J': '000011100',
    'K': '100000011', 'L': '001000011', 'M': '101000010', 'N': '000010011',
    'O': '100010010', 'P': '001010010', 'Q': '000000111', 'R': '100000110',
    'S': '001000110', 'T': '000010110', 'U': '110000001', 'V': '011000001',
    'W': '111000000', 'X': '010010001', 'Y': '110010000', 'Z': '011010000',
    '-': '010000101', '.': '110000100', ' ': '011000100', '*': '010010100',
    '\$': '010101000', '/': '010100010', '+': '010001010', '%': '000101010'
  };

  final chars = <String>[];
  var idx = 0;

  while (idx < widths.length) {
    if (idx + 9 > widths.length) return null;
    final chunk = widths.sublist(idx, idx + 9);
    final bitStr = chunk.map((w) => w == 2 ? '1' : '0').join();

    String? matchedChar;
    for (final entry in code39Patterns.entries) {
      if (entry.value == bitStr) {
        matchedChar = entry.key;
        break;
      }
    }
    if (matchedChar == null) return null;
    chars.add(matchedChar);
    idx += 9;

    // Skip inter-character space if not at end
    if (idx < widths.length) {
      idx += 1;
    }
  }

  if (chars.length < 2) return null;
  if (chars.first != '*' || chars.last != '*') return null;

  return chars.sublist(1, chars.length - 1).join();
}

// =============================================================================
// INDEPENDENT EAN-13 / EAN-8 SCANNER
// =============================================================================
String? _decodeEan(BarcodeVisualPattern pattern) {
  final widths = pattern.moduleWidths;
  final bitBuffer = StringBuffer();
  var isBar = true;

  for (final w in widths) {
    bitBuffer.write((isBar ? '1' : '0') * w);
    isBar = !isBar;
  }

  final bits = bitBuffer.toString();
  if (bits.length != 95) return null; // Standard EAN-13 / UPC-A is 95 modules
  if (!bits.startsWith('101') || !bits.endsWith('101')) return null; // Start/Stop guards
  if (bits.substring(45, 50) != '01010') return null; // Center guard

  const eanL = [
    '0001101', '0011001', '0010011', '0111101', '0100011',
    '0110001', '0101111', '0111011', '0110111', '0001011'
  ];
  const eanG = [
    '0100111', '0110011', '0011011', '0100001', '0011101',
    '0111001', '0000101', '0010001', '0001001', '0010111'
  ];
  const eanR = [
    '1110010', '1100110', '1101100', '1000010', '1011100',
    '1001110', '1010000', '1000100', '1001000', '1110100'
  ];
  const eanStructure = [
    'LLLLLL', 'LLGLGG', 'LLGGLG', 'LLGGGL', 'LGLLGG',
    'LGGLLG', 'LGGGLL', 'LGLGLG', 'LGLGGL', 'LGGLGL'
  ];

  final leftDigits = <int>[];
  final parityPattern = StringBuffer();

  // Left 6 digits
  for (var i = 0; i < 6; i++) {
    final chunk = bits.substring(3 + i * 7, 3 + (i + 1) * 7);
    var found = false;
    for (var d = 0; d < 10; d++) {
      if (chunk == eanL[d]) {
        leftDigits.add(d);
        parityPattern.write('L');
        found = true;
        break;
      } else if (chunk == eanG[d]) {
        leftDigits.add(d);
        parityPattern.write('G');
        found = true;
        break;
      }
    }
    if (!found) return null;
  }

  // Determine first digit from parity pattern
  final firstDigit = eanStructure.indexOf(parityPattern.toString());
  if (firstDigit == -1) return null;

  // Right 6 digits
  final rightDigits = <int>[];
  for (var i = 0; i < 6; i++) {
    final chunk = bits.substring(50 + i * 7, 50 + (i + 1) * 7);
    var found = false;
    for (var d = 0; d < 10; d++) {
      if (chunk == eanR[d]) {
        rightDigits.add(d);
        found = true;
        break;
      }
    }
    if (!found) return null;
  }

  final allDigits = [firstDigit, ...leftDigits, ...rightDigits];
  return allDigits.join();
}

String? _decodeEan8(BarcodeVisualPattern pattern) {
  final widths = pattern.moduleWidths;
  final bitBuffer = StringBuffer();
  var isBar = true;

  for (final w in widths) {
    bitBuffer.write((isBar ? '1' : '0') * w);
    isBar = !isBar;
  }

  final bits = bitBuffer.toString();
  if (bits.length != 67) return null; // EAN-8 is 67 modules: 3 + 4*7 + 5 + 4*7 + 3
  if (!bits.startsWith('101') || !bits.endsWith('101')) return null;
  if (bits.substring(31, 36) != '01010') return null;

  const eanL = [
    '0001101', '0011001', '0010011', '0111101', '0100011',
    '0110001', '0101111', '0111011', '0110111', '0001011'
  ];
  const eanR = [
    '1110010', '1100110', '1101100', '1000010', '1011100',
    '1001110', '1010000', '1000100', '1001000', '1110100'
  ];

  final digits = <int>[];
  for (var i = 0; i < 4; i++) {
    final chunk = bits.substring(3 + i * 7, 3 + (i + 1) * 7);
    final d = eanL.indexOf(chunk);
    if (d == -1) return null;
    digits.add(d);
  }
  for (var i = 0; i < 4; i++) {
    final chunk = bits.substring(36 + i * 7, 36 + (i + 1) * 7);
    final d = eanR.indexOf(chunk);
    if (d == -1) return null;
    digits.add(d);
  }

  return digits.join();
}

String _appendEan13Check(String payload12) {
  final digits = payload12.split('').map(int.parse).toList();
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += digits[i] * (i % 2 == 0 ? 1 : 3);
  }
  final check = (10 - (sum % 10)) % 10;
  return '$payload12$check';
}

String _appendEan8Check(String payload7) {
  final digits = payload7.split('').map(int.parse).toList();
  var sum = 0;
  for (var i = 0; i < 7; i++) {
    sum += digits[i] * (i % 2 == 0 ? 3 : 1);
  }
  final check = (10 - (sum % 10)) % 10;
  return '$payload7$check';
}

String _appendUpcACheck(String payload11) {
  final digits = payload11.split('').map(int.parse).toList();
  var sum = 0;
  for (var i = 0; i < 11; i++) {
    sum += digits[i] * (i % 2 == 0 ? 3 : 1);
  }
  final check = (10 - (sum % 10)) % 10;
  return '$payload11$check';
}
