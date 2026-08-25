import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/encoding.dart';
import 'package:portakal_core/src/errors.dart';
import 'package:portakal_core/src/lang/starprnt.dart';
import 'package:portakal_core/src/native/starprnt.dart';
import 'package:portakal_core/src/parsers/starprnt.dart';
import 'package:portakal_core/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('StarPrntPrinter Native Builder', () {
    test('empty builder returns empty snapshot without mutating', () {
      final printer = StarPrntPrinter();
      final bytes1 = printer.toBytes();
      final bytes2 = printer.toBytes();

      expect(bytes1, isEmpty);
      expect(bytes2, isEmpty);
    });

    test('reset clears accumulated buffer and restores encoding', () {
      final printer = StarPrntPrinter()
        ..initialize()
        ..textLine('Receipt Line')
        ..cut();

      expect(printer.toBytes(), isNotEmpty);

      printer.reset();
      expect(printer.toBytes(), isEmpty);
    });

    group('Initialization & Control Commands', () {
      test('initialize() emits exact ESC @ [0x1B, 0x40]', () {
        final printer = StarPrntPrinter()..initialize();
        expect(printer.toBytes(), equals(Uint8List.fromList([0x1B, 0x40])));
      });

      test('pulseDrawer() emits exact BEL [0x07]', () {
        final printer = StarPrntPrinter()..pulseDrawer();
        expect(printer.toBytes(), equals(Uint8List.fromList([0x07])));
      });
    });

    group('Encoding & Character Tables', () {
      test('emits ESC GS t 3 for CP858 with Euro sign (€ at 0xD5)', () {
        final printer = StarPrntPrinter(
          encoding: const StarPrntEncoding.cp858(sendCodePageCommand: true),
        )..textLine('Total: 10 €');

        final output = printer.toBytes().toList();

        // ESC GS t 3 [0x1B, 0x1D, 0x74, 0x03]
        expect(
          _findSequence(output, [0x1B, 0x1D, 0x74, 0x03]),
          greaterThan(-1),
        );

        // "Total: 10 \xD5\n"
        final expected = [
          ...ascii.encode('Total: 10 '),
          0xD5, // '€' in CP858
          0x0A, // LF
        ];
        expect(_findSequence(output, expected), greaterThan(-1));
      });

      test('emits ESC GS t 16 for CP1252 with Euro sign (€ at 0x80)', () {
        final printer = StarPrntPrinter(
          encoding: const StarPrntEncoding.cp1252(sendCodePageCommand: true),
        )..textLine('Total: 10 €');

        final output = printer.toBytes().toList();

        // ESC GS t 16 [0x1B, 0x1D, 0x74, 0x10]
        expect(
          _findSequence(output, [0x1B, 0x1D, 0x74, 0x10]),
          greaterThan(-1),
        );

        // "Total: 10 \x80\n"
        final expected = [
          ...ascii.encode('Total: 10 '),
          0x80, // '€' in CP1252
          0x0A, // LF
        ];
        expect(_findSequence(output, expected), greaterThan(-1));
      });

      test('switches encoding mid-stream with encoding()', () {
        final printer = StarPrntPrinter()
          ..textLine('First')
          ..encoding(const StarPrntEncoding.cp1252(sendCodePageCommand: true))
          ..textLine('Second');

        final output = printer.toBytes().toList();
        expect(
          _findSequence(output, [0x1B, 0x1D, 0x74, 0x10]),
          greaterThan(-1),
        );
      });

      test(
        'throws UnsupportedCharacterException for unencodable character by default',
        () {
          expect(
            () => StarPrntPrinter().text('Hello 你好'),
            throwsA(isA<UnsupportedCharacterException>()),
          );
        },
      );

      test(
        'replaces unsupported characters when replaceUnsupported is enabled',
        () {
          final printer = StarPrntPrinter(
            encoding: const StarPrntEncoding.legacy(replaceUnsupported: true),
          )..textLine('Hello 你好');

          final expected = [...ascii.encode('Hello ??'), 0x0A];
          expect(
            _findSequence(printer.toBytes().toList(), expected),
            greaterThan(-1),
          );
        },
      );
    });

    group('Text Formatting & Styles', () {
      test('alignment commands emit exact ESC GS a <n>', () {
        final printer = StarPrntPrinter()
          ..align(StarAlignment.left)
          ..align(StarAlignment.center)
          ..align(StarAlignment.right);

        final output = printer.toBytes().toList();
        expect(
          _findSequence(output, [0x1B, 0x1D, 0x61, 0x00]),
          greaterThan(-1),
        );
        expect(
          _findSequence(output, [0x1B, 0x1D, 0x61, 0x01]),
          greaterThan(-1),
        );
        expect(
          _findSequence(output, [0x1B, 0x1D, 0x61, 0x02]),
          greaterThan(-1),
        );
      });

      test('bold commands emit exact ESC E and ESC F', () {
        final printer = StarPrntPrinter()
          ..bold(true)
          ..text('Bold')
          ..bold(false);

        final output = printer.toBytes().toList();
        expect(_findSequence(output, [0x1B, 0x45]), greaterThan(-1));
        expect(_findSequence(output, [0x1B, 0x46]), greaterThan(-1));
      });

      test('underline commands emit exact ESC - 1 and ESC - 0', () {
        final printer = StarPrntPrinter()
          ..underline(true)
          ..text('Underline')
          ..underline(false);

        final output = printer.toBytes().toList();
        expect(_findSequence(output, [0x1B, 0x2D, 0x01]), greaterThan(-1));
        expect(_findSequence(output, [0x1B, 0x2D, 0x00]), greaterThan(-1));
      });

      test('invert commands emit exact ESC 4 and ESC 5', () {
        final printer = StarPrntPrinter()
          ..invert(true)
          ..text('Invert')
          ..invert(false);

        final output = printer.toBytes().toList();
        expect(_findSequence(output, [0x1B, 0x34]), greaterThan(-1));
        expect(_findSequence(output, [0x1B, 0x35]), greaterThan(-1));
      });

      test('size expansion emits exact ESC i <h> <w>', () {
        final printer = StarPrntPrinter()
          ..size(widthMultiplier: 2, heightMultiplier: 3)
          ..text('Expanded')
          ..size(widthMultiplier: 1, heightMultiplier: 1);

        final output = printer.toBytes().toList();
        expect(
          _findSequence(output, [0x1B, 0x69, 0x03, 0x02]),
          greaterThan(-1),
        );
        expect(
          _findSequence(output, [0x1B, 0x69, 0x01, 0x01]),
          greaterThan(-1),
        );
      });
    });

    group('Feeds & Auto-Cutter', () {
      test('feedLines and feedDots emit exact ESC a and ESC J sequences', () {
        final printer = StarPrntPrinter()
          ..feedLines(3)
          ..feedDots(24);

        final output = printer.toBytes().toList();
        expect(_findSequence(output, [0x1B, 0x61, 0x03]), greaterThan(-1));
        expect(_findSequence(output, [0x1B, 0x4A, 0x18]), greaterThan(-1));
      });

      test('cut modes emit exact ESC d <n> sequences', () {
        final printer = StarPrntPrinter()
          ..cut(StarCutMode.full)
          ..cut(StarCutMode.partial)
          ..cut(StarCutMode.feedThenFull)
          ..cut(StarCutMode.feedThenPartial);

        final output = printer.toBytes().toList();
        expect(_findSequence(output, [0x1B, 0x64, 0x00]), greaterThan(-1));
        expect(_findSequence(output, [0x1B, 0x64, 0x01]), greaterThan(-1));
        expect(_findSequence(output, [0x1B, 0x64, 0x02]), greaterThan(-1));
        expect(_findSequence(output, [0x1B, 0x64, 0x03]), greaterThan(-1));
      });
    });

    group('Barcodes & QR Codes', () {
      test('emits 1D barcode with ESC b and RS (0x1E) terminator', () {
        final printer = StarPrntPrinter()
          ..barcode(
            '123456',
            type: StarBarcodeType.code128,
            height: 40,
            wide: 2,
            readable: true,
          );

        final output = printer.toBytes().toList();
        final expectedHeader = [0x1B, 0x62, 0x05, 0x02, 0x02, 0x28];
        final idx = _findSequence(output, expectedHeader);
        expect(idx, greaterThan(-1));

        // RS terminator follows "123456"
        expect(output[idx + 6 + 6], equals(0x1E));
      });

      test(
        'QR Code emits exact configuration, data command, and print execution',
        () {
          final content = 'https://example.com';
          final printer = StarPrntPrinter()
            ..qrCode(
              content,
              cellWidth: 4,
              ecc: StarQrEcc.q,
              model: StarQrModel.model2,
            );

          final output = printer.toBytes().toList();

          // 1. Cell Width: ESC GS y S 0 4 [0x1B, 0x1D, 0x79, 0x53, 0x30, 0x04]
          expect(
            _findSequence(output, [0x1B, 0x1D, 0x79, 0x53, 0x30, 0x04]),
            greaterThan(-1),
          );

          // 2. ECC: ESC GS y S 1 2 [0x1B, 0x1D, 0x79, 0x53, 0x31, 0x02]
          expect(
            _findSequence(output, [0x1B, 0x1D, 0x79, 0x53, 0x31, 0x02]),
            greaterThan(-1),
          );

          // 3. Model: ESC GS y S 2 2 [0x1B, 0x1D, 0x79, 0x53, 0x32, 0x02]
          expect(
            _findSequence(output, [0x1B, 0x1D, 0x79, 0x53, 0x32, 0x02]),
            greaterThan(-1),
          );

          // 4. Data Transfer: ESC GS y D 1 0 <nL> <nH> <content>
          final len = content.length;
          final dataHeader = [
            0x1B,
            0x1D,
            0x79,
            0x44,
            0x31,
            0x30,
            len & 0xFF,
            (len >> 8) & 0xFF,
          ];
          expect(_findSequence(output, dataHeader), greaterThan(-1));

          // 5. Print Execution: ESC GS y P [0x1B, 0x1D, 0x79, 0x50]
          expect(
            _findSequence(output, [0x1B, 0x1D, 0x79, 0x50]),
            greaterThan(-1),
          );
        },
      );
    });

    group('Binary Raster Mode', () {
      test(
        'preserves exact high-byte binary data 0x00..0xFF without corruption',
        () {
          // 7 bytes: [0x00, 0x01, 0x7F, 0x80, 0x81, 0xFE, 0xFF]
          final rawData = Uint8List.fromList([
            0x00,
            0x01,
            0x7F,
            0x80,
            0x81,
            0xFE,
            0xFF,
          ]);

          final printer = StarPrntPrinter()
            ..raster(data: rawData, bytesPerRow: 7, height: 1);

          final output = printer.toBytes().toList();

          // Enter raster mode: ESC * r A [0x1B, 0x2A, 0x72, 0x41]
          final enterIdx = _findSequence(output, [0x1B, 0x2A, 0x72, 0x41]);
          expect(enterIdx, greaterThan(-1));

          // Row command: 'b' (0x62), nL (0x07), nH (0x00)
          final rowHeaderIdx = _findSequence(output, [0x62, 0x07, 0x00]);
          expect(rowHeaderIdx, greaterThan(enterIdx));

          // Actual raw binary bytes must follow immediately
          final binaryStart = rowHeaderIdx + 3;
          final actualBinaryBytes = output.sublist(
            binaryStart,
            binaryStart + 7,
          );
          expect(
            actualBinaryBytes,
            equals([0x00, 0x01, 0x7F, 0x80, 0x81, 0xFE, 0xFF]),
          );

          // Exit raster mode: ESC * r B [0x1B, 0x2A, 0x72, 0x42]
          final exitIdx = _findSequence(output, [0x1B, 0x2A, 0x72, 0x42]);
          expect(exitIdx, greaterThan(binaryStart));
        },
      );

      test('supports rasterFromMonochrome helper', () {
        final bitmap = MonochromeBitmap(
          data: Uint8List.fromList([0xFF, 0x00]),
          width: 8,
          height: 2,
          bytesPerRow: 1,
        );

        final printer = StarPrntPrinter()..rasterFromMonochrome(bitmap);
        final output = printer.toBytes().toList();

        expect(
          _findSequence(output, [0x1B, 0x2A, 0x72, 0x41]),
          greaterThan(-1),
        );
        expect(
          _findSequence(output, [0x1B, 0x2A, 0x72, 0x42]),
          greaterThan(-1),
        );
      });

      test('supports direct raster row primitives', () {
        final printer = StarPrntPrinter()
          ..enterRasterMode()
          ..rasterRow(Uint8List.fromList([0xAA, 0x55]))
          ..exitRasterMode();

        final output = printer.toBytes().toList();
        expect(
          _findSequence(output, [0x1B, 0x2A, 0x72, 0x41]),
          greaterThan(-1),
        );
        expect(
          _findSequence(output, [0x62, 0x02, 0x00, 0xAA, 0x55]),
          greaterThan(-1),
        );
        expect(
          _findSequence(output, [0x1B, 0x2A, 0x72, 0x42]),
          greaterThan(-1),
        );
      });
    });

    group('Raw Passthrough & Parser Compatibility', () {
      test('emits rawBytes and rawAscii verbatim', () {
        final raw = Uint8List.fromList([0x1B, 0x70, 0x00, 0x19, 0xFA]);
        final printer = StarPrntPrinter()
          ..rawBytes(raw)
          ..rawAscii('RAW_COMMAND');

        final output = printer.toBytes().toList();
        expect(
          _findSequence(output, [0x1B, 0x70, 0x00, 0x19, 0xFA]),
          greaterThan(-1),
        );
        expect(
          _findSequence(output, ascii.encode('RAW_COMMAND')),
          greaterThan(-1),
        );
      });

      test('native output is parsed cleanly by parseStarPRNT', () {
        final printer = StarPrntPrinter()
          ..initialize()
          ..bold(true)
          ..text('Parsed Text')
          ..bold(false)
          ..cut();

        final parsed = parseStarPRNT(printer.toBytes());

        expect(parsed.commands.length, greaterThanOrEqualTo(4));
        expect(parsed.elements.length, equals(1));
        expect(parsed.elements[0], isA<TextElement>());
        final textEl = parsed.elements[0] as TextElement;
        expect(textEl.content, equals('Parsed Text'));
        expect(textEl.options.bold, isTrue);
      });
    });

    group('Validation & Boundary Rejection', () {
      test('validates size multiplier bounds (1..6)', () {
        expect(
          () => StarPrntPrinter().size(widthMultiplier: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().size(widthMultiplier: 7),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().size(heightMultiplier: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().size(heightMultiplier: 7),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates feed bounds', () {
        expect(
          () => StarPrntPrinter().feedLines(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().feedLines(256),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().feedDots(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().feedDots(256),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates barcode parameters and empty content', () {
        expect(
          () => StarPrntPrinter().barcode(''),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().barcode('123', height: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().barcode('123', height: 256),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().barcode('123', wide: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().barcode('123', wide: 4),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates QR parameters and empty content', () {
        expect(
          () => StarPrntPrinter().qrCode(''),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().qrCode('123', cellWidth: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => StarPrntPrinter().qrCode('123', cellWidth: 17),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates raster buffer length match', () {
        expect(
          () => StarPrntPrinter().raster(
            data: Uint8List.fromList([0x00, 0x01]),
            bytesPerRow: 2,
            height: 2, // expects 4 bytes
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });
    });

    group('Universal AST vs Native Builder Equivalence', () {
      test('produces identical byte stream for standard receipt layout', () {
        final bitmap = MonochromeBitmap(
          data: Uint8List.fromList([0xFF, 0x00, 0xAA, 0x55]),
          width: 16,
          height: 2,
          bytesPerRow: 2,
        );

        final labelBuilder = label(const LabelConfig(width: 80))
            .text(
              'STAR RECEIPT',
              const TextOptions(align: 'center', bold: true, size: 2),
            )
            .image(bitmap)
            .barcode(
              '123456',
              const BarcodeOptions(x: 0, y: 0, type: '128', height: 40),
            )
            .qrcode(
              'https://example.com',
              const QRCodeOptions(x: 0, y: 0, cellWidth: 4),
            );

        final universalBytes = starprnt.compile(labelBuilder);

        // Native equivalent:
        final nativePrinter = StarPrntPrinter()
          ..initialize()
          ..align(StarAlignment.center)
          ..bold(true)
          ..size(widthMultiplier: 2, heightMultiplier: 2)
          ..text('STAR RECEIPT')
          ..lineFeed()
          ..size(widthMultiplier: 1, heightMultiplier: 1)
          ..bold(false)
          ..align(StarAlignment.left)
          ..rasterFromMonochrome(bitmap)
          ..barcode(
            '123456',
            type: StarBarcodeType.code128,
            height: 40,
            wide: 2,
          )
          ..qrCode(
            'https://example.com',
            cellWidth: 4,
            ecc: StarQrEcc.m,
            model: StarQrModel.model2,
          )
          ..cut(StarCutMode.partial);

        expect(nativePrinter.toBytes(), equals(universalBytes));
      });
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
