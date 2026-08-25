import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/encoding.dart';
import 'package:portakal_core/src/lang/escpos.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('ESC/POS Explicit Encoding Tests', () {
    test('ASCII output is byte-for-byte identical with legacy baseline', () {
      final builder = label(
        const LabelConfig(width: 80),
      ).text('ABC 123', const TextOptions(align: 'center', bold: true));

      final output = escpos.compile(builder);

      final expected = <int>[
        0x1B, 0x40, // ESC @ (initialize)
        0x1B, 0x61, 0x01, // ESC a 1 (center align)
        0x1B, 0x45, 0x01, // ESC E 1 (bold on)
        0x41, 0x42, 0x43, 0x20, 0x31, 0x32, 0x33, // "ABC 123"
        0x0A, // LF
        0x1B, 0x45, 0x00, // ESC E 0 (bold off)
        0x1B, 0x61, 0x00, // ESC a 0 (reset align)
        0x1D, 0x56, 0x42, 0x03, // GS V B 3 (partial cut)
      ];

      expect(output, equals(Uint8List.fromList(expected)));
    });

    test('Western European CP437 encodes accented text correctly', () {
      final builder = label(const LabelConfig(width: 80)).text('Café');

      final output = escpos.compile(
        builder,
        encoding: const EscPosEncoding.cp437(sendTableSelect: true),
      );

      // In CP437: 'C' = 0x43, 'a' = 0x61, 'f' = 0x66, 'é' = 0x82
      final expected = <int>[
        0x1B, 0x40, // ESC @
        0x1B, 0x74, 0x00, // ESC t 0 (CP437)
        0x43, 0x61, 0x66, 0x82, // "Café"
        0x0A, // LF
        0x1D, 0x56, 0x42, 0x03, // Cut
      ];

      expect(output, equals(Uint8List.fromList(expected)));
    });

    test('Western European CP858 encodes Euro sign (€) at 0xD5', () {
      final builder = label(const LabelConfig(width: 80)).text('Total: 10€');

      final output = escpos.compile(
        builder,
        encoding: const EscPosEncoding.cp858(),
      );

      // In CP858: '€' is byte 0xD5, table selector is 19 (0x13)
      final expected = <int>[
        0x1B, 0x40, // ESC @
        0x1B, 0x74, 19, // ESC t 19 (CP858)
        ...ascii.encode('Total: 10'),
        0xD5, // '€'
        0x0A, // LF
        0x1D, 0x56, 0x42, 0x03, // Cut
      ];

      expect(output, equals(Uint8List.fromList(expected)));
    });

    test('Windows CP1252 encodes Euro sign (€) at 0x80 and table 16', () {
      final builder = label(const LabelConfig(width: 80)).text('Price: €25');

      final output = escpos.compile(
        builder,
        encoding: const EscPosEncoding.cp1252(),
      );

      // In CP1252: '€' is byte 0x80, table selector is 16 (0x10)
      final expected = <int>[
        0x1B, 0x40, // ESC @
        0x1B, 0x74, 16, // ESC t 16 (CP1252)
        ...ascii.encode('Price: '),
        0x80, // '€'
        ...ascii.encode('25'),
        0x0A, // LF
        0x1D, 0x56, 0x42, 0x03, // Cut
      ];

      expect(output, equals(Uint8List.fromList(expected)));
    });

    test('Turkish CP857 encodes Ğ, ş, İ, ı, ü, ç correctly with table 13', () {
      final builder = label(const LabelConfig(width: 80)).text('Türkçe Ğşİı');

      final output = escpos.compile(
        builder,
        encoding: const EscPosEncoding.cp857(),
      );

      // In CP857:
      // 'T' = 0x54, 'ü' = 0x81, 'r' = 0x72, 'k' = 0x6B, 'ç' = 0x87, 'e' = 0x65, ' ' = 0x20
      // 'Ğ' = 0xA6, 'ş' = 0x9F, 'İ' = 0x98, 'ı' = 0x8D
      final expectedTextBytes = <int>[
        0x54,
        0x81,
        0x72,
        0x6B,
        0x87,
        0x65,
        0x20,
        0xA6,
        0x9F,
        0x98,
        0x8D,
      ];

      final expected = <int>[
        0x1B, 0x40, // ESC @
        0x1B, 0x74, 13, // ESC t 13 (CP857)
        ...expectedTextBytes,
        0x0A, // LF
        0x1D, 0x56, 0x42, 0x03, // Cut
      ];

      expect(output, equals(Uint8List.fromList(expected)));
    });

    test('Cyrillic CP866 encodes "Привет" with table 17', () {
      final builder = label(const LabelConfig(width: 80)).text('Привет');

      final output = escpos.compile(
        builder,
        encoding: const EscPosEncoding.cp866(),
      );

      // In CP866:
      // 'П' = 0x8F, 'р' = 0xE0, 'и' = 0xA8, 'в' = 0xA2, 'е' = 0xA5, 'т' = 0xE2
      final expectedCyrillicBytes = <int>[0x8F, 0xE0, 0xA8, 0xA2, 0xA5, 0xE2];

      final expected = <int>[
        0x1B, 0x40, // ESC @
        0x1B, 0x74, 17, // ESC t 17 (CP866)
        ...expectedCyrillicBytes,
        0x0A, // LF
        0x1D, 0x56, 0x42, 0x03, // Cut
      ];

      expect(output, equals(Uint8List.fromList(expected)));
    });

    test('Custom table selector sends exact configured ESC t value', () {
      final builder = label(const LabelConfig(width: 80)).text('Custom Table');

      final output = escpos.compile(
        builder,
        encoding: const EscPosEncoding.custom(
          codePage: PrinterCodePage.cp1252,
          tableId: 32, // Non-standard table ID on custom printer
        ),
      );

      expect(output[2], equals(0x1B));
      expect(output[3], equals(0x74));
      expect(output[4], equals(32));
    });

    test('Raw encoding mode does not emit ESC t command', () {
      final builder = label(const LabelConfig(width: 80)).text('Raw Mode');

      final output = escpos.compile(
        builder,
        encoding: const EscPosEncoding.raw(codePage: PrinterCodePage.cp437),
      );

      // Output starts with ESC @ immediately followed by text
      expect(output[0], equals(0x1B));
      expect(output[1], equals(0x40));
      expect(output[2], equals(0x52)); // 'R' in "Raw Mode"
    });
  });

  group('Unsupported Character Policy', () {
    test('Throws UnsupportedCharacterException by default', () {
      final builder = label(const LabelConfig(width: 80)).text('Hello 你好');

      expect(
        () => escpos.compile(builder, encoding: const EscPosEncoding.cp437()),
        throwsA(
          isA<UnsupportedCharacterException>()
              .having((e) => e.character, 'character', '你')
              .having((e) => e.codePoint, 'codePoint', 0x4F60)
              .having((e) => e.codePage, 'codePage', PrinterCodePage.cp437),
        ),
      );
    });

    test(
      'Throws UnsupportedCharacterException when Cyrillic is passed to CP437',
      () {
        final builder = label(const LabelConfig(width: 80)).text('Привет');

        expect(
          () => escpos.compile(builder, encoding: const EscPosEncoding.cp437()),
          throwsA(isA<UnsupportedCharacterException>()),
        );
      },
    );

    test(
      'Replaces unsupported characters with "?" when replaceUnsupported is true',
      () {
        final builder = label(
          const LabelConfig(width: 80),
        ).text('Item: 你好 \$10');

        final output = escpos.compile(
          builder,
          encoding: const EscPosEncoding.cp437(
            sendTableSelect: false,
            replaceUnsupported: true,
          ),
        );

        final expected = <int>[
          0x1B, 0x40, // ESC @
          ...ascii.encode('Item: '),
          0x3F, 0x3F, // '?' '?' for "你好"
          ...ascii.encode(' \$10'),
          0x0A, // LF
          0x1D, 0x56, 0x42, 0x03, // Cut
        ];

        expect(output, equals(Uint8List.fromList(expected)));
      },
    );
  });

  group('ESC/POS Command & Control Byte Separation', () {
    test('Control bytes are never modified by text encoding', () {
      final builder = label(const LabelConfig(width: 80))
          .text('Line 1', const TextOptions(bold: true, align: 'center'))
          .text('Line 2', const TextOptions(size: 2));

      final output = escpos.compile(
        builder,
        encoding: const EscPosEncoding.cp858(),
      );

      // Verify that initialization, alignment, bold, size, LFs, and cut exist intact
      expect(output.sublist(0, 2), equals([0x1B, 0x40])); // ESC @
      expect(output.sublist(2, 5), equals([0x1B, 0x74, 19])); // ESC t 19
      expect(output.sublist(5, 8), equals([0x1B, 0x61, 1])); // ESC a 1
      expect(output.sublist(8, 11), equals([0x1B, 0x45, 1])); // ESC E 1
      expect(output.contains(0x0A), isTrue); // LF
      expect(
        output.sublist(output.length - 4),
        equals([0x1D, 0x56, 0x42, 0x03]),
      ); // GS V B 3
    });
  });
}
