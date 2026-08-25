import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/encoding.dart';
import 'package:portakal_core/src/lang/zpl.dart';
import 'package:portakal_core/src/languages/zpl.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('ZPL Byte-Native Compiler', () {
    test(
      'Historical default compatibility: implicit default emits ^CI28 and UTF-8',
      () {
        final builder = label(const LabelConfig(width: 40, height: 30))
            .text('HELLO 123', const TextOptions(x: 10, y: 10, size: 2))
            .box(
              const BoxOptions(
                x: 5,
                y: 5,
                width: 200,
                height: 100,
                thickness: 2,
              ),
            )
            .barcode(
              '123456',
              const BarcodeOptions(x: 10, y: 50, type: '128', height: 40),
            );

        final byteOutput = zpl.compileBytes(builder);
        final canonicalOutput = zpl.compile(builder);

        // Verify that compile and compileBytes outputs match exactly
        expect(byteOutput, equals(canonicalOutput));

        // Assert historical ^CI28 presence in default output
        final text = utf8.decode(byteOutput);
        expect(text, startsWith('^XA\n^CI28\n^PW320\n'));
      },
    );

    test('Explicit legacy mode omits ^CI28 header command', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Standard Label');
      final output = zpl.compileBytes(
        builder,
        encoding: const ZplEncoding.legacy(),
      );
      final text = ascii.decode(output);

      expect(text, startsWith('^XA\n^PW320\n'));
      expect(text, isNot(contains('^CI28')));
    });

    test('Explicit UTF-8 mode emits ^CI28 directly after ^XA', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('UTF-8 Label');
      final output = zpl.compileBytes(
        builder,
        encoding: const ZplEncoding.utf8(),
      );
      final text = utf8.decode(output);

      expect(text, startsWith('^XA\n^CI28\n^PW320\n'));
    });

    test('Constructor semantics: ZplEncoding has unambiguous default', () {
      expect(ZplEncoding.defaultEncoding.type, equals(ZplTextEncoding.utf8));
      expect(ZplEncoding.defaultEncoding.emitCiCommand, isTrue);

      const legacy = ZplEncoding.legacy();
      expect(legacy.type, equals(ZplTextEncoding.legacy));
      expect(legacy.emitCiCommand, isFalse);
    });

    test('String wrapper decodes UTF-8 and legacy modes strictly', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café €');

      // Default UTF-8 string output via deprecated compileToZPL
      final utf8Str = compileToZPL(builder.resolve());
      expect(utf8Str, contains('^FDCafé €^FS'));

      // Legacy string output
      final legacyBuilder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('ASCII ONLY');
      final legacyStr = compileToZPL(
        legacyBuilder.resolve(),
        encoding: const ZplEncoding.legacy(),
      );
      expect(legacyStr, contains('^FDASCII ONLY^FS'));
    });

    test('Explicit UTF-8 mode encodes Western European: "Café €"', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Café €', const TextOptions(x: 10, y: 10));

      final output = zpl.compileBytes(
        builder,
        encoding: const ZplEncoding.utf8(),
      );

      // Expected UTF-8 byte sequences:
      // 'é' -> 0xC3, 0xA9
      // '€' -> 0xE2, 0x82, 0xAC
      final expectedFdBytes = <int>[
        0x5E, 0x46, 0x44, // "^FD"
        0x43, 0x61, 0x66, // "Caf"
        0xC3, 0xA9, // "é" in UTF-8
        0x20, // " "
        0xE2, 0x82, 0xAC, // "€" in UTF-8
        0x5E, 0x46, 0x53, // "^FS"
      ];

      final outputList = output.toList();
      final idx = _findSequence(outputList, expectedFdBytes);
      expect(
        idx,
        greaterThan(-1),
        reason: 'Expected UTF-8 encoded bytes for "Café €" inside ^FD...^FS',
      );
    });

    test('Explicit UTF-8 mode encodes Turkish: "Türkçe Ğşİı"', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Türkçe Ğşİı', const TextOptions(x: 10, y: 10));

      final output = zpl.compileBytes(
        builder,
        encoding: const ZplEncoding.utf8(),
      );

      // Expected UTF-8 bytes:
      // 'ü' -> 0xC3, 0xBC
      // 'ç' -> 0xC3, 0xA7
      // 'Ğ' -> 0xC4, 0x9E
      // 'ş' -> 0xC5, 0x9F
      // 'İ' -> 0xC4, 0xB0
      // 'ı' -> 0xC4, 0xB1
      final expectedFdBytes = <int>[
        0x5E, 0x46, 0x44, // "^FD"
        0x54, 0xC3, 0xBC, 0x72, 0x6B, 0xC3, 0xA7, 0x65, 0x20, // "Türkçe "
        0xC4, 0x9E, 0xC5, 0x9F, 0xC4, 0xB0, 0xC4, 0xB1, // "Ğşİı"
        0x5E, 0x46, 0x53, // "^FS"
      ];

      final outputList = output.toList();
      final idx = _findSequence(outputList, expectedFdBytes);
      expect(
        idx,
        greaterThan(-1),
        reason: 'Expected UTF-8 encoded bytes for Turkish characters',
      );
    });

    test('Explicit UTF-8 mode encodes Cyrillic: "Привет"', () {
      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).text('Привет', const TextOptions(x: 10, y: 10));

      final output = zpl.compileBytes(
        builder,
        encoding: const ZplEncoding.utf8(),
      );

      // Expected UTF-8 bytes:
      // 'П' -> 0xD0, 0x9F
      // 'р' -> 0xD1, 0x80
      // 'и' -> 0xD0, 0xB8
      // 'в' -> 0xD0, 0xB2
      // 'е' -> 0xD0, 0xB5
      // 'т' -> 0xD1, 0x82
      final expectedFdBytes = <int>[
        0x5E, 0x46, 0x44, // "^FD"
        0xD0, 0x9F, 0xD1, 0x80, 0xD0, 0xB8, 0xD0, 0xB2, 0xD0, 0xB5, 0xD1, 0x82,
        0x5E, 0x46, 0x53, // "^FS"
      ];

      final outputList = output.toList();
      final idx = _findSequence(outputList, expectedFdBytes);
      expect(
        idx,
        greaterThan(-1),
        reason: 'Expected UTF-8 encoded bytes for Cyrillic characters',
      );
    });

    group('^FH Field Hex Escaping Edge Cases', () {
      String compileStr(LabelBuilder b) => utf8.decode(zpl.compile(b));

      test(
        'Literal underscore without control chars preserves plain ^FD and literal _',
        () {
          // "ABC_41" without ^ or ~ must not trigger ^FH
          final b1 = label(
            const LabelConfig(width: 40, height: 30),
          ).text('ABC_41');
          expect(compileStr(b1), contains('^FDABC_41^FS'));

          // "ABC_" without ^ or ~
          final b2 = label(
            const LabelConfig(width: 40, height: 30),
          ).text('ABC_');
          expect(compileStr(b2), contains('^FDABC_^FS'));

          // "___" without ^ or ~
          final b3 = label(
            const LabelConfig(width: 40, height: 30),
          ).text('___');
          expect(compileStr(b3), contains('^FD___^FS'));
        },
      );

      test(
        'When control chars are present, literal underscore is escaped to prevent hex collision',
        () {
          // "ABC_41^" contains '^', so ^FH is active and '_' must become '_5F' to avoid printer interpreting '_41' as 'A'
          final b1 = label(
            const LabelConfig(width: 40, height: 30),
          ).text('ABC_41^');
          expect(compileStr(b1), contains('^FH^FDABC_5F41_5E^FS'));

          // "ABC_^"
          final b2 = label(
            const LabelConfig(width: 40, height: 30),
          ).text('ABC_^');
          expect(compileStr(b2), contains('^FH^FDABC_5F_5E^FS'));

          // "___^"
          final b3 = label(
            const LabelConfig(width: 40, height: 30),
          ).text('___^');
          expect(compileStr(b3), contains('^FH^FD_5F_5F_5F_5E^FS'));

          // Single control chars
          final b4 = label(const LabelConfig(width: 40, height: 30)).text('^');
          expect(compileStr(b4), contains('^FH^FD_5E^FS'));

          final b5 = label(const LabelConfig(width: 40, height: 30)).text('~');
          expect(compileStr(b5), contains('^FH^FD_7E^FS'));

          final b6 = label(
            const LabelConfig(width: 40, height: 30),
          ).text('_^~');
          expect(compileStr(b6), contains('^FH^FD_5F_5E_7E^FS'));
        },
      );
    });

    test('Raster image generates exact ^GFA ASCII hex bytes', () {
      final bitmap = MonochromeBitmap(
        data: Uint8List.fromList([0x00, 0x7F, 0x80, 0xFF]),
        width: 16,
        height: 2,
        bytesPerRow: 2,
      );

      final builder = label(
        const LabelConfig(width: 40, height: 30),
      ).image(bitmap, const ImageOptions(x: 10, y: 10));

      final output = zpl.compileBytes(builder);
      final text = utf8.decode(output);

      expect(text, contains('^FO10,10^GFA,4,4,2,007F80FF^FS'));

      // Verify exact ASCII byte representation for hex payload:
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
    });

    test(
      'Barcode and QR code elements generate expected ZPL command syntax',
      () {
        final builder = label(const LabelConfig(width: 40, height: 30))
            .barcode(
              'CODE39',
              const BarcodeOptions(x: 10, y: 20, type: '39', height: 50),
            )
            .qrcode(
              'https://example.com',
              const QRCodeOptions(x: 10, y: 100, cellWidth: 5),
            );

        final output = zpl.compileBytes(builder);
        final text = utf8.decode(output);

        expect(text, contains('^B3N,50,N,N,N^FDCODE39^FS'));
        expect(text, contains('^BQN,2,5,Q,7^FDQA,https://example.com^FS'));
      },
    );

    test('Raw element passes through unescaped command strings and bytes', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
          .rawAscii('^FX Raw ZPL Comment ~SD25\n')
          .rawBytes(
            Uint8List.fromList([0x5E, 0x4A, 0x55, 0x53, 0x0A]),
          ); // ^JUS\n

      final output = zpl.compileBytes(builder);
      final text = utf8.decode(output);

      expect(text, contains('^FX Raw ZPL Comment ~SD25\n'));
      expect(text, contains('^JUS\n'));
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
