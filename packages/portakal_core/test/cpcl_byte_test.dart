import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/encoding.dart';
import 'package:portakal_core/src/lang/cpcl.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('CPCL Byte-Native Compiler', () {
    test(
      'ASCII output is byte-for-byte identical to legacy string baseline',
      () {
        final builder =
            label(
                  const LabelConfig(
                    width: 40,
                    height: 30,
                    speed: 4,
                    density: 8,
                    copies: 2,
                  ),
                )
                .text('Hello CPCL', const TextOptions(x: 10, y: 20))
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
                  const LineOptions(
                    x1: 10,
                    y1: 50,
                    x2: 300,
                    y2: 50,
                    thickness: 2,
                  ),
                )
                .barcode(
                  '123456',
                  const BarcodeOptions(x: 10, y: 100, type: '128', height: 40),
                );

        final byteOutput = cpcl.compileBytes(builder);
        final stringOutput = cpcl.compile(builder);

        // Verify exact byte equivalence with legacy string output
        expect(
          byteOutput,
          equals(Uint8List.fromList(ascii.encode(stringOutput))),
        );
      },
    );

    test(
      'Session framing generates exact CPCL header, PAGE-WIDTH, and PRINT commands',
      () {
        final builder = label(
          const LabelConfig(
            width: 40,
            height: 30,
            speed: 0,
            density: 0,
            copies: 3,
          ),
        );
        final output = cpcl.compileBytes(builder);
        final text = ascii.decode(output);

        expect(
          text,
          equals(
            '! 0 203 203 240 3\r\n'
            'PAGE-WIDTH 320\r\n'
            'PRINT\r\n',
          ),
        );
      },
    );

    test('Session framing includes TONE and SPEED when configured', () {
      final builder = label(
        const LabelConfig(
          width: 40,
          height: 30,
          speed: 4,
          density: 10,
          copies: 1,
        ),
      );
      final output = cpcl.compileBytes(builder);
      final text = ascii.decode(output);

      expect(text, contains('TONE 2\r\n'));
      expect(text, contains('SPEED 4\r\n'));
    });

    test(
      'EG expanded graphics encodes bitmap bytes into exact ASCII hex bytes',
      () {
        final bitmap = MonochromeBitmap(
          data: Uint8List.fromList([0x00, 0x7F, 0x80, 0xFF]),
          width: 16,
          height: 2,
          bytesPerRow: 2,
        );

        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).image(bitmap, const ImageOptions(x: 10, y: 15));

        final output = cpcl.compileBytes(builder);
        final text = ascii.decode(output);

        // Verify generated command header and hex data string
        expect(text, contains('EG 2 2 10 15 007F80FF\r\n'));

        // Verify exact ASCII byte values for hex payload:
        // '0' '0' '7' 'F' '8' '0' 'F' 'F' -> [0x30, 0x30, 0x37, 0x46, 0x38, 0x30, 0x46, 0x46]
        final expectedHexBytes = <int>[
          0x30,
          0x30,
          0x37,
          0x46,
          0x38,
          0x30,
          0x46,
          0x46,
        ];
        final outputList = output.toList();
        expect(_findSequence(outputList, expectedHexBytes), greaterThan(-1));
      },
    );

    test('Extended character set: encodes "Café" in CP437 with byte 0x82', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café', const TextOptions(x: 10, y: 20));

      final output = cpcl.compileBytes(builder);

      // Expected text line: "Caf\x82\r\n"
      final expectedTextBytes = <int>[
        ...ascii.encode('TEXT 2 0 10 20\r\nCaf'),
        0x82, // 'é' in CP437
        0x0D, 0x0A, // '\r\n'
      ];

      expect(
        _findSequence(output.toList(), expectedTextBytes),
        greaterThan(-1),
      );
    });

    test('COUNTRY selection: emits COUNTRY CP850 when requested', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Test', const TextOptions(x: 10, y: 10));

      final output = cpcl.compileBytes(
        builder,
        encoding: const CpclEncoding.cp850(sendCountryCommand: true),
      );

      final text = latin1.decode(output);
      expect(text, contains('COUNTRY CP850\r\n'));
    });

    test('COUNTRY selection: emits COUNTRY CP1252 when requested', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Test', const TextOptions(x: 10, y: 10));

      final output = cpcl.compileBytes(
        builder,
        encoding: const CpclEncoding.cp1252(sendCountryCommand: true),
      );

      final text = latin1.decode(output);
      expect(text, contains('COUNTRY CP1252\r\n'));
    });

    test(
      'Throws UnsupportedCharacterException for unencodable Unicode by default',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).text('Hello 你好', const TextOptions(x: 10, y: 10));

        expect(
          () => cpcl.compileBytes(builder),
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

      final output = cpcl.compileBytes(
        builder,
        encoding: const CpclEncoding.legacy(replaceUnsupported: true),
      );

      final text = latin1.decode(output);
      expect(text, contains('Hello ??\r\n'));
    });

    test('Barcode and QR elements generate exact CPCL command syntax', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .barcode(
            'CODE39',
            const BarcodeOptions(
              x: 10,
              y: 20,
              type: '39',
              height: 40,
              readable: 1,
            ),
          )
          .qrcode(
            'https://example.com',
            const QRCodeOptions(x: 10, y: 80, cellWidth: 4),
          );

      final output = cpcl.compileBytes(builder);
      final text = ascii.decode(output);

      expect(
        text,
        contains(
          'BARCODE-TEXT 7 0 5\r\nBARCODE 39 1 2 40 10 20 CODE39\r\nBARCODE-TEXT OFF\r\n',
        ),
      );
      expect(
        text,
        contains(
          'BARCODE QR 10 80 M 2 U 4\r\nMA,https://example.com\r\nENDQR\r\n',
        ),
      );
    });

    test('Raw element passes through unescaped command strings and bytes', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .raw('JOURNAL')
          .raw(
            Uint8List.fromList([
              0x53,
              0x54,
              0x41,
              0x54,
              0x55,
              0x53,
              0x0D,
              0x0A,
            ]),
          ); // STATUS\r\n

      final output = cpcl.compileBytes(builder);
      final text = ascii.decode(output);

      expect(text, contains('JOURNAL\r\n'));
      expect(text, contains('STATUS\r\n'));
    });

    test('String wrapper decodes 1:1 via latin1', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café', const TextOptions(x: 10, y: 20));

      final stringOutput = cpcl.compile(builder);
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
