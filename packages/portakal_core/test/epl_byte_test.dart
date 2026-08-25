import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/encoding.dart';
import 'package:portakal_core/src/lang/epl.dart';
import 'package:portakal_core/src/languages/epl.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('EPL Byte-Native Compiler', () {
    test(
      'ASCII output is byte-for-byte identical to legacy string baseline',
      () {
        final builder = label(const LabelConfig(width: 40, height: 30))
            .text(
              'Hello EPL',
              const TextOptions(x: 10, y: 20, font: '3', size: 2),
            )
            .box(
              const BoxOptions(
                x: 5,
                y: 5,
                width: 310,
                height: 230,
                thickness: 2,
              ),
            )
            .line(
              const LineOptions(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2),
            )
            .barcode(
              '123456',
              const BarcodeOptions(x: 10, y: 100, type: '128', height: 40),
            );

        final byteOutput = epl.compileBytes(builder);
        final canonicalOutput = epl.compile(builder);

        // Verify that compile and compileBytes outputs match exactly
        expect(byteOutput, equals(canonicalOutput));
      },
    );

    test('Session framing generates exact N, q, Q, S, D, P commands', () {
      final builder = label(
        const LabelConfig(
          width: 40,
          height: 30,
          speed: 4,
          density: 8,
          copies: 2,
        ),
      );
      final output = epl.compileBytes(builder);
      final text = ascii.decode(output);

      expect(
        text,
        equals(
          'N\n'
          'q320\n'
          'Q240,24\n'
          'S4\n'
          'D8\n'
          'P2\n',
        ),
      );
    });

    test(
      'GW raster image preserves high-byte binary data without corruption',
      () {
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

        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).image(bitmap, const ImageOptions(x: 10, y: 15));

        final output = epl.compileBytes(builder);

        // Expected inverted bytes: ~byte & 0xFF
        // 0x00 -> 0xFF
        // 0x01 -> 0xFE
        // 0x7F -> 0x80
        // 0x80 -> 0x7F
        // 0x81 -> 0x7E
        // 0xFE -> 0x01
        // 0xFF -> 0x00
        final expectedInverted = <int>[
          0xFF,
          0xFE,
          0x80,
          0x7F,
          0x7E,
          0x01,
          0x00,
        ];

        // Header: "GW10,15,7,1\n"
        final expectedHeader = ascii.encode('GW10,15,7,1\n');
        final outputList = output.toList();

        final headerIdx = _findSequence(outputList, expectedHeader);
        expect(
          headerIdx,
          greaterThan(-1),
          reason: 'GW header must exist in output',
        );

        // The binary bytes must follow the header immediately
        final binaryStart = headerIdx + expectedHeader.length;
        final actualBinaryBytes = outputList.sublist(
          binaryStart,
          binaryStart + 7,
        );
        expect(actualBinaryBytes, equals(expectedInverted));

        // Followed by '\n' (0x0A)
        expect(outputList[binaryStart + 7], equals(0x0A));
      },
    );

    test('Extended character set: encodes "Café" in CP437 with byte 0x82', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café', const TextOptions(x: 10, y: 10));

      final output = epl.compileBytes(builder);

      // Expected: A10,10,0,2,1,1,N,"Caf\x82"\n
      final expectedTextBytes = <int>[
        ...ascii.encode('A10,10,0,2,1,1,N,"Caf'),
        0x82, // 'é' in CP437
        0x22, // '"'
        0x0A, // '\n'
      ];

      expect(
        _findSequence(output.toList(), expectedTextBytes),
        greaterThan(-1),
      );
    });

    test('Character set command: emits I8,1,001 for CP850 when requested', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Test', const TextOptions(x: 10, y: 10));

      final output = epl.compileBytes(
        builder,
        encoding: const EplEncoding.cp850(sendSetCharSetCommand: true),
      );

      final text = latin1.decode(output);
      expect(text, contains('I8,1,001\n'));
    });

    test(
      'Character set command: emits I8,13,001 for CP1252 when requested',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).text('Test', const TextOptions(x: 10, y: 10));

        final output = epl.compileBytes(
          builder,
          encoding: const EplEncoding.cp1252(sendSetCharSetCommand: true),
        );

        final text = latin1.decode(output);
        expect(text, contains('I8,13,001\n'));
      },
    );

    test(
      'Throws UnsupportedCharacterException for unencodable Unicode by default',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).text('Hello 你好', const TextOptions(x: 10, y: 10));

        expect(
          () => epl.compileBytes(builder),
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
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Hello 你好', const TextOptions(x: 10, y: 10));

      final output = epl.compileBytes(
        builder,
        encoding: const EplEncoding.legacy(replaceUnsupported: true),
      );

      final text = latin1.decode(output);
      expect(text, contains('"Hello ??"'));
    });

    test('Barcode and QR elements generate exact EPL command syntax', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .barcode(
            'CODE39',
            const BarcodeOptions(x: 10, y: 20, type: '39', height: 40),
          )
          .qrcode(
            'https://example.com',
            const QRCodeOptions(x: 10, y: 80, cellWidth: 4),
          );

      final output = epl.compileBytes(builder);
      final text = ascii.decode(output);

      expect(text, contains('B10,20,0,3,2,4,40,N,"CODE39"\n'));
      expect(text, contains('b10,80,"Q",m2,s4,eQ,"https://example.com"\n'));
    });

    test('Raw element passes through unescaped command strings and bytes', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .rawAscii('OD\n')
          .rawBytes(Uint8List.fromList([0x55, 0x54, 0x0A])); // UT\n

      final output = epl.compileBytes(builder);
      final text = ascii.decode(output);

      expect(text, contains('OD\n'));
      expect(text, contains('UT\n'));
    });

    test('String wrapper compileToEPL decodes 1:1 via latin1', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café', const TextOptions(x: 10, y: 10));

      final stringOutput = compileToEPL(builder.resolve());
      expect(stringOutput, isA<String>());
      expect(
        stringOutput.codeUnits.contains(0x82),
        isTrue,
      ); // 0x82 byte preserved in char code
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
