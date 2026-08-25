import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/encoding.dart';
import 'package:portakal_flutter/src/lang/ipl.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('IPL Byte-Native Compiler', () {
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
                .text('Hello IPL', const TextOptions(x: 50, y: 30))
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
                );

        final byteOutput = ipl.compileBytes(builder);
        final stringOutput = ipl.compile(builder);

        // Verify exact byte equivalence with legacy string output
        expect(
          byteOutput,
          equals(Uint8List.fromList(ascii.encode(stringOutput))),
        );
      },
    );

    test(
      'Mode control and framing verification: exact STX, ETX, and ESC sequences',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30, copies: 3),
        );
        final output = ipl.compileBytes(builder);
        final outputList = output.toList();

        // <STX><ESC>C1<ETX> -> [0x02, 0x1B, 0x43, 0x31, 0x03]
        expect(
          _findSequence(outputList, [0x02, 0x1B, 0x43, 0x31, 0x03]),
          greaterThan(-1),
        );

        // <STX><ESC>P<ETX> -> [0x02, 0x1B, 0x50, 0x03]
        expect(
          _findSequence(outputList, [0x02, 0x1B, 0x50, 0x03]),
          greaterThan(-1),
        );

        // <STX><ESC>M3<ETX> -> [0x02, 0x1B, 0x4D, 0x33, 0x03]
        expect(
          _findSequence(outputList, [0x02, 0x1B, 0x4D, 0x33, 0x03]),
          greaterThan(-1),
        );

        // <STX><ESC>E1<ETX> -> [0x02, 0x1B, 0x45, 0x31, 0x03]
        expect(
          _findSequence(outputList, [0x02, 0x1B, 0x45, 0x31, 0x03]),
          greaterThan(-1),
        );

        // <STX>R<ETX> -> [0x02, 0x52, 0x03]
        expect(_findSequence(outputList, [0x02, 0x52, 0x03]), greaterThan(-1));
      },
    );

    test(
      'Session metrics framing generates exact <SI> records wrapped in STX/ETX',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30, speed: 6, density: 10),
        );
        final output = ipl.compileBytes(builder);
        final text = latin1.decode(output);

        expect(text, contains('\x02<SI>L240\x03'));
        expect(text, contains('\x02<SI>W320\x03'));
        expect(text, contains('\x02<SI>S60\x03'));
        expect(text, contains('\x02<SI>d10\x03'));
      },
    );

    test('Field record framing for Text, Box, and Line', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .text(
            'Hello IPL',
            const TextOptions(x: 50, y: 30, size: 2, rotation: 90),
          )
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
            const LineOptions(x1: 50, y1: 10, x2: 50, y2: 200, thickness: 2),
          );

      final output = ipl.compileBytes(builder);
      final text = latin1.decode(output);

      // Text field: H1;o50,30;f1;h24;w24;c26;d3,Hello IPL
      expect(text, contains('\x02H1;o50,30;f1;h24;w24;c26;d3,Hello IPL\x03'));

      // Box field: W2;o10,20;f0;l200;h100;w2
      expect(text, contains('\x02W2;o10,20;f0;l200;h100;w2\x03'));

      // Horizontal line: L3;o10,50;f0;l290;w2
      expect(text, contains('\x02L3;o10,50;f0;l290;w2\x03'));

      // Vertical line: L4;o50,10;f1;l190;w2
      expect(text, contains('\x02L4;o50,10;f1;l190;w2\x03'));
    });

    test('Extended character set: encodes "Café" in CP437 with byte 0x82', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café', const TextOptions(x: 10, y: 20));

      final output = ipl.compileBytes(builder);

      final expectedField = <int>[
        ...ascii.encode('\x02H1;o10,20;f0;h12;w12;c26;d3,Caf'),
        0x82, // 'é' in CP437
        0x03, // ETX
      ];

      expect(_findSequence(output.toList(), expectedField), greaterThan(-1));
    });

    test('Guards against dangerous control bytes inside user text', () {
      // Text containing ETX (0x03) which would prematurely terminate field frame
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Break\x03Frame', const TextOptions(x: 10, y: 10));

      expect(
        () => ipl.compileBytes(builder),
        throwsA(
          isA<UnsupportedCharacterException>().having(
            (e) => e.codePoint,
            'codePoint',
            0x03,
          ),
        ),
      );
    });

    test(
      'Replaces dangerous control characters when replaceUnsupported is true',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).text('Break\x03Frame', const TextOptions(x: 10, y: 10));

        final output = ipl.compileBytes(
          builder,
          encoding: const IplEncoding.legacy(replaceUnsupported: true),
        );

        final text = latin1.decode(output);
        expect(text, contains('d3,Break?Frame\x03'));
      },
    );

    test(
      'Throws UnsupportedCharacterException for unencodable Unicode by default',
      () {
        final builder = label(
          const LabelConfig(width: 40, height: 30),
        ).text('Hello 你好', const TextOptions(x: 10, y: 10));

        expect(
          () => ipl.compileBytes(builder),
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

      final output = ipl.compileBytes(
        builder,
        encoding: const IplEncoding.legacy(replaceUnsupported: true),
      );

      final text = latin1.decode(output);
      expect(text, contains('d3,Hello ??\x03'));
    });

    test('Barcode and QR elements use real STX and ETX control framing', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .barcode(
            '123456',
            const BarcodeOptions(x: 10, y: 20, type: '128', height: 40),
          )
          .qrcode(
            'https://example.com',
            const QRCodeOptions(x: 10, y: 80, cellWidth: 4),
          );

      final output = ipl.compileBytes(builder);
      final text = latin1.decode(output);

      expect(
        text,
        contains('\x02B1;o0;f0;c0;h40;w2;d0,20;\x03\n\x02123456\x03\n'),
      );
      expect(
        text,
        contains(
          '\x02B2;o0;f0;c21;w4;h4;d0,80;\x03\n\x02https://example.com\x03\n',
        ),
      );
    });

    test('Raw element passes through unescaped command strings and bytes', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .raw('\x02CUSTOM_CMD\x03')
          .raw(Uint8List.fromList([0x02, 0x54, 0x45, 0x53, 0x54, 0x03]));

      final output = ipl.compileBytes(builder);
      final text = latin1.decode(output);

      expect(text, contains('\x02CUSTOM_CMD\x03'));
      expect(text, contains('\x02TEST\x03'));
    });

    test('String wrapper decodes 1:1 via latin1', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café', const TextOptions(x: 10, y: 20));

      final stringOutput = ipl.compile(builder);
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
