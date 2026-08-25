import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/encoding.dart';
import 'package:portakal_core/src/lang/starprnt.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('Star PRNT Byte-Native Compiler', () {
    test('Initialization (ESC @) and Partial Cut (ESC d 1) framing', () {
      final builder = label(const LabelConfig(width: 80));
      final output = starprnt.compile(builder);

      // Must start with ESC @ [0x1B, 0x40]
      expect(output.sublist(0, 2), equals([0x1B, 0x40]));

      // Must end with ESC d 1 [0x1B, 0x64, 0x01]
      expect(output.sublist(output.length - 3), equals([0x1B, 0x64, 0x01]));
    });

    test('ASCII text, alignment, bold, and size commands', () {
      final builder = label(const LabelConfig(width: 80)).text(
        'Hello Star',
        const TextOptions(align: 'center', bold: true, size: 2),
      );

      final output = starprnt.compile(builder);
      final outputList = output.toList();

      // ESC GS a 1 (center alignment)
      expect(
        _findSequence(outputList, [0x1B, 0x1D, 0x61, 0x01]),
        greaterThan(-1),
      );
      // ESC E (bold on)
      expect(_findSequence(outputList, [0x1B, 0x45]), greaterThan(-1));
      // ESC i 2 2 (character expansion 2x2)
      expect(
        _findSequence(outputList, [0x1B, 0x69, 0x02, 0x02]),
        greaterThan(-1),
      );

      // Text "Hello Star\n"
      expect(
        _findSequence(outputList, [...ascii.encode('Hello Star'), 0x0A]),
        greaterThan(-1),
      );

      // ESC i 1 1 (reset size)
      expect(
        _findSequence(outputList, [0x1B, 0x69, 0x01, 0x01]),
        greaterThan(-1),
      );
      // ESC F (bold off)
      expect(_findSequence(outputList, [0x1B, 0x46]), greaterThan(-1));
      // ESC GS a 0 (reset alignment)
      expect(
        _findSequence(outputList, [0x1B, 0x1D, 0x61, 0x00]),
        greaterThan(-1),
      );
    });

    test('Extended character set: encodes "Café" in CP437 with byte 0x82', () {
      final builder = label(const LabelConfig(width: 80)).text('Café');

      final output = starprnt.compile(builder);

      final expectedSequence = <int>[
        ...ascii.encode('Caf'),
        0x82, // 'é' in CP437
        0x0A, // LF
      ];

      expect(_findSequence(output.toList(), expectedSequence), greaterThan(-1));
    });

    test(
      'Character table command: emits ESC GS t 3 for CP858 with Euro sign (€ at 0xD5)',
      () {
        final builder = label(const LabelConfig(width: 80)).text('Total: 10 €');

        final output = starprnt.compile(
          builder,
          encoding: const StarPrntEncoding.cp858(sendCodePageCommand: true),
        );

        final outputList = output.toList();

        // ESC GS t 3 [0x1B, 0x1D, 0x74, 0x03]
        expect(
          _findSequence(outputList, [0x1B, 0x1D, 0x74, 0x03]),
          greaterThan(-1),
        );

        // "Total: 10 \xD5\n"
        final expectedTextBytes = <int>[
          ...ascii.encode('Total: 10 '),
          0xD5, // '€' in CP858
          0x0A,
        ];
        expect(_findSequence(outputList, expectedTextBytes), greaterThan(-1));
      },
    );

    test(
      'Character table command: emits ESC GS t 16 for CP1252 with Euro sign (€ at 0x80)',
      () {
        final builder = label(const LabelConfig(width: 80)).text('Total: 10 €');

        final output = starprnt.compile(
          builder,
          encoding: const StarPrntEncoding.cp1252(sendCodePageCommand: true),
        );

        final outputList = output.toList();

        // ESC GS t 16 [0x1B, 0x1D, 0x74, 0x10]
        expect(
          _findSequence(outputList, [0x1B, 0x1D, 0x74, 0x10]),
          greaterThan(-1),
        );

        // "Total: 10 \x80\n"
        final expectedTextBytes = <int>[
          ...ascii.encode('Total: 10 '),
          0x80, // '€' in CP1252
          0x0A,
        ];
        expect(_findSequence(outputList, expectedTextBytes), greaterThan(-1));
      },
    );

    test(
      'Throws UnsupportedCharacterException for unencodable Unicode by default',
      () {
        final builder = label(const LabelConfig(width: 80)).text('Hello 你好');

        expect(
          () => starprnt.compile(builder),
          throwsA(
            isA<UnsupportedCharacterException>()
                .having((e) => e.character, 'character', '你')
                .having((e) => e.codePoint, 'codePoint', 0x4F60)
                .having((e) => e.codePage, 'codePage', PrinterCodePage.cp437),
          ),
        );
      },
    );

    test('Replaces unsupported characters when replaceUnsupported is true', () {
      final builder = label(const LabelConfig(width: 80)).text('Hello 你好');

      final output = starprnt.compile(
        builder,
        encoding: const StarPrntEncoding.legacy(replaceUnsupported: true),
      );

      final expectedSequence = ascii.encode('Hello ??\n');
      expect(_findSequence(output.toList(), expectedSequence), greaterThan(-1));
    });

    test('Raster image preserves high-byte binary data without corruption', () {
      // 7 bytes containing high values: [0x00, 0x01, 0x7F, 0x80, 0x81, 0xFE, 0xFF]
      final rawData = Uint8List.fromList([
        0x00,
        0x01,
        0x7F,
        0x80,
        0x81,
        0xFE,
        0xFF,
      ]);
      final bitmap = MonochromeBitmap(
        data: rawData,
        width: 56,
        height: 1,
        bytesPerRow: 7,
      );

      final builder = label(const LabelConfig(width: 80)).image(bitmap);
      final output = starprnt.compile(builder);
      final outputList = output.toList();

      // Enter raster mode: ESC * r A [0x1B, 0x2A, 0x72, 0x41]
      final enterIdx = _findSequence(outputList, [0x1B, 0x2A, 0x72, 0x41]);
      expect(enterIdx, greaterThan(-1));

      // Row command: 'b' (0x62), nL (0x07), nH (0x00)
      final rowHeaderIdx = _findSequence(outputList, [0x62, 0x07, 0x00]);
      expect(rowHeaderIdx, greaterThan(enterIdx));

      // Actual raw binary bytes must follow immediately
      final binaryStart = rowHeaderIdx + 3;
      final actualBinaryBytes = outputList.sublist(
        binaryStart,
        binaryStart + 7,
      );
      expect(
        actualBinaryBytes,
        equals([0x00, 0x01, 0x7F, 0x80, 0x81, 0xFE, 0xFF]),
      );

      // Exit raster mode: ESC * r B [0x1B, 0x2A, 0x72, 0x42]
      final exitIdx = _findSequence(outputList, [0x1B, 0x2A, 0x72, 0x42]);
      expect(exitIdx, greaterThan(binaryStart));
    });

    test('Barcode and QR elements generate exact Star PRNT command syntax', () {
      final builder = label(const LabelConfig(width: 80))
          .barcode(
            '123456',
            const BarcodeOptions(x: 0, y: 0, type: '128', height: 40),
          )
          .qrcode(
            'https://example.com',
            const QRCodeOptions(x: 0, y: 0, cellWidth: 4),
          );

      final output = starprnt.compile(builder);
      final outputList = output.toList();

      // Barcode: ESC b 5 1 2 40 "123456" RS (0x1E)
      final expectedBarcodeHeader = [0x1B, 0x62, 0x05, 0x01, 0x02, 0x28];
      final bIdx = _findSequence(outputList, expectedBarcodeHeader);
      expect(bIdx, greaterThan(-1));
      expect(
        outputList[bIdx + 6 + 6],
        equals(0x1E),
      ); // RS terminator after "123456"

      // QR Code: ESC GS y S 0 4, ESC GS y S 1 1, ESC GS y S 2 2, ESC GS y D 1 0 ... ESC GS y P
      expect(
        _findSequence(outputList, [0x1B, 0x1D, 0x79, 0x53, 0x30, 0x04]),
        greaterThan(-1),
      );
      expect(
        _findSequence(outputList, [0x1B, 0x1D, 0x79, 0x50]),
        greaterThan(-1),
      );
    });

    test('Raw element passes through unescaped command bytes and strings', () {
      final builder = label(const LabelConfig(width: 80))
          .raw(Uint8List.fromList([0x07])) // BEL (kick drawer)
          .raw('\x1b\x70\x00\x19\xfa'); // Pulse drawer

      final output = starprnt.compile(builder);
      final outputList = output.toList();

      expect(_findSequence(outputList, [0x07]), greaterThan(-1));
      expect(
        _findSequence(outputList, [0x1B, 0x70, 0x00, 0x19, 0xFA]),
        greaterThan(-1),
      );
    });

    test('compile and compileBytes return identical Uint8List', () {
      final builder = label(const LabelConfig(width: 80)).text('Test');
      final bytes1 = starprnt.compile(builder);
      final bytes2 = starprnt.compileBytes(builder);

      expect(bytes1, equals(bytes2));
    });
  });
}

int _findSequence(List<int> bytes, List<int> seq) {
  for (int i = 0; i <= bytes.length - seq.length; i++) {
    bool found = true;
    for (int j = 0; j < seq.length; j++) {
      if (bytes[i + j] != seq[j]) {
        found = false;
        break;
      }
    }
    if (found) return i;
  }
  return -1;
}
