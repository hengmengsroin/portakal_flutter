import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/encoding.dart';
import 'package:portakal_flutter/src/errors.dart';
import 'package:portakal_flutter/src/lang/sbpl.dart';
import 'package:portakal_flutter/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('SBPL Byte-Native Compiler', () {
    test('ASCII output matches byte-for-byte with latin1 string wrapper', () {
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
              .text('Hello SATO', const TextOptions(x: 100, y: 50, size: 2))
              .box(
                const BoxOptions(
                  x: 10,
                  y: 20,
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
              );

      final byteOutput = sbpl.compileBytes(builder);
      final stringOutput = sbpl.compile(builder);

      // Verify exact byte equivalence with latin1 string output
      expect(
        byteOutput,
        equals(Uint8List.fromList(latin1.encode(stringOutput))),
      );
    });

    test(
      'Job framing and ESC verification: exact ESC A, ESC CS<speed>, ESC Q, ESC Z sequences',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30, speed: 4, copies: 3),
        );
        final output = sbpl.compileBytes(builder);
        final outputList = output.toList();

        // Starts with ESC A [0x1B, 0x41] and ESC CS4 [0x1B, 0x43, 0x53, 0x34]
        expect(
          outputList.sublist(0, 6),
          equals([0x1B, 0x41, 0x1B, 0x43, 0x53, 0x34]),
        );

        // ESC Q3 -> [0x1B, 0x51, 0x33]
        expect(_findSequence(outputList, [0x1B, 0x51, 0x33]), greaterThan(-1));

        // Ends with ESC Z -> [0x1B, 0x5A]
        expect(outputList.sublist(outputList.length - 2), equals([0x1B, 0x5A]));

        // Verify no printable debug placeholders exist on wire stream
        expect(_findSequence(outputList, ascii.encode('<ESC>')), equals(-1));
        expect(_findSequence(outputList, ascii.encode('<A>')), equals(-1));
        expect(_findSequence(outputList, ascii.encode('<Z>')), equals(-1));
        expect(_findSequence(outputList, ascii.encode('<Q>')), equals(-1));
      },
    );

    test('Omits ESC Q when copies is 1', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30, copies: 1),
      );
      final output = sbpl.compileBytes(builder);
      final outputList = output.toList();

      expect(_findSequence(outputList, [0x1B, 0x51]), equals(-1));
    });

    test('Positioning and Geometry: exact H, V, FW records', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .text('Hello SATO', const TextOptions(x: 100, y: 50, size: 2))
          .box(
            const BoxOptions(
              x: 10,
              y: 20,
              width: 200,
              height: 100,
              thickness: 2,
            ),
          )
          .line(
            const LineOptions(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2),
          )
          .line(
            const LineOptions(x1: 50, y1: 10, x2: 50, y2: 200, thickness: 1),
          );

      final output = sbpl.compileBytes(builder);
      final text = latin1.decode(output);

      // Text position: ESC H0100 ESC V0050 ESC L0202 ESC K9B
      expect(text, contains('\x1bH0100\x1bV0050\x1bL0202\x1bK9BHello SATO'));

      // Box: ESC H0010 ESC V0020 ESC FW02V0100H0200
      expect(text, contains('\x1bH0010\x1bV0020\x1bFW02V0100H0200'));

      // Horizontal line: ESC H0010 ESC V0050 ESC FW02H0290
      expect(text, contains('\x1bH0010\x1bV0050\x1bFW02H0290'));

      // Vertical line: ESC H0050 ESC V0010 ESC FW01V0190
      expect(text, contains('\x1bH0050\x1bV0010\x1bFW01V0190'));
    });

    test('Text rotation wraps in ESC % and resets with ESC %0', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Rotated', const TextOptions(x: 10, y: 20, rotation: 90));

      final output = sbpl.compileBytes(builder);
      final text = latin1.decode(output);

      expect(text, contains('\x1b%1\x1bL0101\x1bK9BRotated\x1b%0'));
    });

    test('Extended character set: encodes "Café" in CP437 with byte 0x82', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café', const TextOptions(x: 10, y: 20));

      final output = sbpl.compileBytes(builder);

      final expectedSequence = <int>[
        ...ascii.encode('\x1bK9BCaf'),
        0x82, // 'é' in CP437
      ];

      expect(_findSequence(output.toList(), expectedSequence), greaterThan(-1));
    });

    test('Guards against dangerous ESC (0x1B) inside user text', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Inject\x1bZ', const TextOptions(x: 10, y: 10));

      expect(
        () => sbpl.compileBytes(builder),
        throwsA(
          isA<UnsupportedCharacterException>().having(
            (e) => e.codePoint,
            'codePoint',
            0x1B,
          ),
        ),
      );
    });

    test(
      'Replaces dangerous ESC character when replaceUnsupported is true',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).text('Inject\x1bZ', const TextOptions(x: 10, y: 10));

        final output = sbpl.compileBytes(
          builder,
          encoding: const SbplEncoding.legacy(replaceUnsupported: true),
        );

        final text = latin1.decode(output);
        expect(text, contains('\x1bK9BInject?Z'));
      },
    );

    test(
      'Throws UnsupportedCharacterException for unencodable Unicode by default',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).text('Hello 你好', const TextOptions(x: 10, y: 10));

        expect(
          () => sbpl.compileBytes(builder),
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

      final output = sbpl.compileBytes(
        builder,
        encoding: const SbplEncoding.legacy(replaceUnsupported: true),
      );

      final text = latin1.decode(output);
      expect(text, contains('\x1bK9BHello ??'));
    });

    test('Throws UnsupportedFeatureError for ImageElement', () {
      final bitmap = MonochromeBitmap(
        data: Uint8List.fromList([0x00, 0x7F, 0x80, 0xFF]),
        width: 16,
        height: 2,
        bytesPerRow: 2,
      );

      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).image(bitmap, const ImageOptions(x: 10, y: 15));

      expect(
        () => sbpl.compileBytes(builder),
        throwsA(isA<UnsupportedFeatureError>()),
      );
    });

    test('Barcode and QR elements use real ESC control framing', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .barcode(
            '123456',
            const BarcodeOptions(x: 10, y: 20, type: '128', height: 40),
          )
          .qrcode(
            'https://example.com',
            const QRCodeOptions(x: 10, y: 80, cellWidth: 4),
          );

      final output = sbpl.compileBytes(builder);
      final text = latin1.decode(output);

      // Barcode: ESC V20 ESC H10 ESC BG20040123456
      expect(text, contains('\x1bV20\x1bH10\x1bBG20040123456'));

      // QR: ESC V80 ESC H10 ESC BQ04200https://example.com
      expect(text, contains('\x1bV80\x1bH10\x1bBQ04200https://example.com'));

      // Ensure no "<ESC>" string was emitted
      expect(text, isNot(contains('<ESC>')));
    });

    test('Raw element passes through unescaped command strings and bytes', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .raw('\x1bKC1')
          .raw(Uint8List.fromList([0x1B, 0x4B, 0x43, 0x32])); // ESC KC2

      final output = sbpl.compileBytes(builder);
      final text = latin1.decode(output);

      expect(text, contains('\x1bKC1'));
      expect(text, contains('\x1bKC2'));
    });

    test('String wrapper decodes 1:1 via latin1', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café', const TextOptions(x: 10, y: 20));

      final stringOutput = sbpl.compile(builder);
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
