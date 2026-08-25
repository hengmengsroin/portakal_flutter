import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/encoding.dart';
import 'package:portakal_core/src/lang/dpl.dart';
import 'package:portakal_core/src/languages/dpl.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('DPL Byte-Native Compiler', () {
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
                .text('Hello DPL', const TextOptions(x: 50, y: 30))
                .box(
                  const BoxOptions(
                    x: 10,
                    y: 10,
                    width: 200,
                    height: 100,
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

        final byteOutput = dpl.compileBytes(builder);
        final canonicalOutput = dpl.compile(builder);

        // Verify exact byte equivalence between compile and compileBytes
        expect(byteOutput, equals(canonicalOutput));
      },
    );

    test('Control byte verification: starts with literal STX (0x02) and L', () {
      final builder = label(const LabelConfig(width: 40, height: 30));
      final output = dpl.compileBytes(builder);

      // Byte 0 must be STX (0x02), byte 1 must be 'L' (0x4C), byte 2 must be '\n' (0x0A)
      expect(output[0], equals(0x02));
      expect(output[1], equals(0x4C)); // 'L'
      expect(output[2], equals(0x0A)); // '\n'

      // Last 2 bytes must be 'E' (0x45) and '\n' (0x0A)
      expect(output[output.length - 2], equals(0x45)); // 'E'
      expect(output[output.length - 1], equals(0x0A)); // '\n'
    });

    test('Session framing generates exact D, S, A, Q header records', () {
      final builder = label(
        const LabelConfig(
          width: 40,
          height: 30,
          speed: 4,
          density: 8,
          copies: 3,
        ),
      );
      final output = dpl.compileBytes(builder);
      final text = ascii.decode(output);

      expect(text, contains('\x02L\n'));
      expect(text, contains('D08\n'));
      expect(text, contains('S04\n'));
      expect(text, contains('A0320\n'));
      expect(text, contains('Q0003\n'));
      expect(text, endsWith('E\n'));
    });

    test('Text record formatting and zero-padded coordinates', () {
      final builder = label(const LabelConfig(width: 40, height: 30)).text(
        'Hello DPL',
        const TextOptions(x: 50, y: 30, rotation: 90, size: 2),
      );

      final output = dpl.compileBytes(builder);
      final text = ascii.decode(output);

      // Rotation 90 -> '2', Y: 30 -> '0030', X: 50 -> '0050', font '0', scale '0202'
      expect(text, contains('20030005000202Hello DPL\n'));
    });

    test('Box and Line records generate exact DPL geometry records', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .box(
            const BoxOptions(
              x: 10,
              y: 20,
              width: 200,
              height: 100,
              thickness: 3,
            ),
          )
          .line(
            const LineOptions(x1: 10, y1: 50, x2: 250, y2: 50, thickness: 2),
          );

      final output = dpl.compileBytes(builder);
      final text = ascii.decode(output);

      // Box: 1e <y> <x> <w> <h> <t> -> 1e00200010020001000003\n
      expect(text, contains('1e00200010020001000003\n'));
      // Horizontal Line: 1X <y> <x> L <w> <t> -> 1X00500010L02402\n
      expect(text, contains('1X00500010L02402\n'));
    });

    test('Barcode and QR records generate exact DPL symbology records', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .barcode(
            'CODE39',
            const BarcodeOptions(x: 10, y: 20, type: '39', height: 40),
          )
          .qrcode(
            'https://example.com',
            const QRCodeOptions(x: 10, y: 80, cellWidth: 4),
          );

      final output = dpl.compileBytes(builder);
      final text = ascii.decode(output);

      expect(text, contains('1A20040000000100020CODE39\n'));
      expect(text, contains('1W1c004000000100080https://example.com\n'));
    });

    test('Extended character set: encodes "Café" in CP437 with byte 0x82', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café', const TextOptions(x: 10, y: 20));

      final output = dpl.compileBytes(builder);

      // Expected text line bytes: 10020001000101Caf\x82\n
      final expectedTextBytes = <int>[
        ...ascii.encode('10020001000101Caf'),
        0x82, // 'é' in CP437
        0x0A, // '\n'
      ];

      expect(
        _findSequence(output.toList(), expectedTextBytes),
        greaterThan(-1),
      );
    });

    test(
      'Throws UnsupportedCharacterException for unencodable Unicode by default',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).text('Hello 你好', const TextOptions(x: 10, y: 10));

        expect(
          () => dpl.compileBytes(builder),
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

      final output = dpl.compileBytes(
        builder,
        encoding: const DplEncoding.legacy(replaceUnsupported: true),
      );

      final text = latin1.decode(output);
      expect(text, contains('Hello ??\n'));
    });

    test('Raw element passes through unescaped command strings and bytes', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .rawAscii('CUSTOM_DPL_RAW\n')
          .rawBytes(Uint8List.fromList([0x01, 0x41, 0x0A])); // SOH A \n

      final output = dpl.compileBytes(builder);
      final text = latin1.decode(output);

      expect(text, contains('CUSTOM_DPL_RAW\n'));
      expect(text, contains('\x01A\n'));
    });

    test('String wrapper compileToDPL decodes 1:1 via latin1', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café', const TextOptions(x: 10, y: 20));

      final stringOutput = compileToDPL(builder.resolve());
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
