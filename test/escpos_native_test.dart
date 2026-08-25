import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/encoding.dart';
import 'package:portakal_flutter/src/errors.dart';
import 'package:portakal_flutter/src/lang/escpos.dart';
import 'package:portakal_flutter/src/native/escpos.dart';
import 'package:portakal_flutter/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('EscPosPrinter Native Builder', () {
    test('empty builder returns empty snapshot without mutating', () {
      final printer = EscPosPrinter(
        encoding: const EscPosEncoding.cp437(sendTableSelect: false),
      );
      final bytes1 = printer.toBytes();
      final bytes2 = printer.toBytes();

      expect(bytes1, isEmpty);
      expect(bytes2, isEmpty);
    });

    test('reset clears accumulated buffer and restores initial encoding', () {
      final printer =
          EscPosPrinter(
              encoding: const EscPosEncoding.cp437(sendTableSelect: false),
            )
            ..align(EscPosAlignment.center)
            ..textLine('Receipt');

      expect(printer.toBytes(), isNotEmpty);
      printer.reset();
      expect(printer.toBytes(), isEmpty);
    });

    group('Initialization & Encoding', () {
      test('emits ESC @ on initialize', () {
        final printer = EscPosPrinter(
          encoding: const EscPosEncoding.cp437(sendTableSelect: false),
        )..initialize();

        expect(printer.toBytes(), equals(Uint8List.fromList([0x1B, 0x40])));
      });

      test(
        'emits ESC @ followed by ESC t when active encoding requires table select',
        () {
          final printer = EscPosPrinter(encoding: const EscPosEncoding.cp858())
            ..initialize();

          // Initial constructor emits ESC t 19, then initialize emits ESC @ followed by ESC t 19
          expect(
            printer.toBytes(),
            equals(
              Uint8List.fromList([
                0x1B, 0x74, 19, // Constructor table select
                0x1B, 0x40, // ESC @
                0x1B, 0x74, 19, // Re-emitted table select
              ]),
            ),
          );
        },
      );

      test('emits ESC t when characterTable is explicitly called', () {
        final printer = EscPosPrinter(
          encoding: const EscPosEncoding.cp437(sendTableSelect: false),
        )..characterTable(16);

        expect(printer.toBytes(), equals(Uint8List.fromList([0x1B, 0x74, 16])));
      });

      test('switches encoding mid-stream', () {
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..text('CP437: Café') // 'é' in CP437 is 0x82
              ..encoding(const EscPosEncoding.cp1252()) // emits ESC t 16
              ..text('CP1252: Café €'); // 'é' in CP1252 is 0xE9, '€' is 0x80

        final bytes = printer.toBytes();
        expect(bytes, contains(0x82)); // CP437 'é'
        expect(bytes, contains(0xE9)); // CP1252 'é'
        expect(bytes, contains(0x80)); // CP1252 '€'
      });

      test(
        'throws UnsupportedCharacterException for unencodable runes by default',
        () {
          final printer = EscPosPrinter(
            encoding: const EscPosEncoding.cp437(sendTableSelect: false),
          );

          expect(
            () => printer.text('Hello 你好'),
            throwsA(isA<UnsupportedCharacterException>()),
          );
        },
      );

      test(
        'replaces unencodable runes with ? when replaceUnsupported is true',
        () {
          final printer = EscPosPrinter(
            encoding: const EscPosEncoding.cp437(
              sendTableSelect: false,
              replaceUnsupported: true,
            ),
          )..text('Item: 你好');

          expect(printer.toBytes(), containsAllInOrder([0x3F, 0x3F]));
        },
      );
    });

    group('Text & Feed Commands', () {
      test('text does not append LF, while textLine appends 0x0A', () {
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..text('Subtotal: ')
              ..textLine(r'$10.00');

        final expected = [
          ...ascii.encode('Subtotal: '),
          ...ascii.encode(r'$10.00'),
          0x0A,
        ];
        expect(printer.toBytes(), equals(Uint8List.fromList(expected)));
      });

      test('lineFeed emits single and multiple LFs', () {
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..lineFeed()
              ..lineFeed(3);

        expect(
          printer.toBytes(),
          equals(Uint8List.fromList([0x0A, 0x0A, 0x0A, 0x0A])),
        );
      });

      test('feedLines emits ESC d n', () {
        final printer = EscPosPrinter(
          encoding: const EscPosEncoding.cp437(sendTableSelect: false),
        )..feedLines(4);

        expect(
          printer.toBytes(),
          equals(Uint8List.fromList([0x1B, 0x64, 0x04])),
        );
      });

      test('feedDots emits ESC J n', () {
        final printer = EscPosPrinter(
          encoding: const EscPosEncoding.cp437(sendTableSelect: false),
        )..feedDots(40);

        expect(printer.toBytes(), equals(Uint8List.fromList([0x1B, 0x4A, 40])));
      });
    });

    group('Formatting State Commands', () {
      test('emits ESC a n for alignment', () {
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..align(EscPosAlignment.left)
              ..align(EscPosAlignment.center)
              ..align(EscPosAlignment.right);

        expect(
          printer.toBytes(),
          equals(
            Uint8List.fromList([
              0x1B, 0x61, 0, // left
              0x1B, 0x61, 1, // center
              0x1B, 0x61, 2, // right
            ]),
          ),
        );
      });

      test('emits ESC E n for bold', () {
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..bold(true)
              ..bold(false);

        expect(
          printer.toBytes(),
          equals(
            Uint8List.fromList([
              0x1B, 0x45, 1, // bold on
              0x1B, 0x45, 0, // bold off
            ]),
          ),
        );
      });

      test('emits ESC - n for underline', () {
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..underline(EscPosUnderline.single)
              ..underline(EscPosUnderline.doubleThickness)
              ..underline(EscPosUnderline.none);

        expect(
          printer.toBytes(),
          equals(
            Uint8List.fromList([
              0x1B, 0x2D, 1, // single
              0x1B, 0x2D, 2, // double
              0x1B, 0x2D, 0, // off
            ]),
          ),
        );
      });

      test('emits GS B n for reverse white-on-black', () {
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..invert(true)
              ..invert(false);

        expect(
          printer.toBytes(),
          equals(
            Uint8List.fromList([
              0x1D, 0x42, 1, // invert on
              0x1D, 0x42, 0, // invert off
            ]),
          ),
        );
      });

      test('emits ESC M n for font selection', () {
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..font(EscPosFont.fontA)
              ..font(EscPosFont.fontB)
              ..font(EscPosFont.fontC);

        expect(
          printer.toBytes(),
          equals(
            Uint8List.fromList([
              0x1B, 0x4D, 0, // font A
              0x1B, 0x4D, 1, // font B
              0x1B, 0x4D, 2, // font C
            ]),
          ),
        );
      });

      test('emits GS ! n with packed width/height multipliers', () {
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..textSize(width: 1, height: 1) // 0x00
              ..textSize(width: 2, height: 3) // ((2-1)<<4)|(3-1) = 0x12
              ..textSize(width: 8, height: 8); // ((8-1)<<4)|(8-1) = 0x77

        expect(
          printer.toBytes(),
          equals(
            Uint8List.fromList([
              0x1D,
              0x21,
              0x00,
              0x1D,
              0x21,
              0x12,
              0x1D,
              0x21,
              0x77,
            ]),
          ),
        );
      });
    });

    group('Barcodes & QR Codes', () {
      test('emits Code128 barcode with height, width, HRI, and font', () {
        final printer =
            EscPosPrinter(
              encoding: const EscPosEncoding.cp437(sendTableSelect: false),
            )..barcode(
              content: '123456',
              type: EscPosBarcodeType.code128,
              height: 80,
              width: 3,
              hri: EscPosBarcodeHri.below,
              hriFont: EscPosBarcodeFont.fontB,
            );

        expect(
          printer.toBytes(),
          equals(
            Uint8List.fromList([
              0x1D, 0x68, 80, // GS h (height)
              0x1D, 0x77, 3, // GS w (width)
              0x1D, 0x48, 2, // GS H (HRI below)
              0x1D, 0x66, 1, // GS f (HRI font B)
              0x1D, 0x6B, 73, 6, // GS k 73 6
              0x31, 0x32, 0x33, 0x34, 0x35, 0x36, // "123456"
            ]),
          ),
        );
      });

      test('emits Code39 and EAN13 barcodes', () {
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..barcode(content: 'CODE39', type: EscPosBarcodeType.code39)
              ..barcode(content: '123456789012', type: EscPosBarcodeType.ean13);

        final bytes = printer.toBytes();
        expect(bytes, contains(69)); // Code39 type byte
        expect(bytes, contains(67)); // EAN13 type byte
      });

      test('emits 5-step GS ( k QR code sequence', () {
        final printer =
            EscPosPrinter(
              encoding: const EscPosEncoding.cp437(sendTableSelect: false),
            )..qrCode(
              'https://example.com',
              size: 5,
              ecc: EscPosQrEcc.h,
              model: EscPosQrModel.model2,
            );

        final bytes = printer.toBytes();
        // Model 2: 0x32
        expect(
          bytes,
          containsAllInOrder([
            0x1D,
            0x28,
            0x6B,
            0x04,
            0x00,
            0x31,
            0x41,
            0x32,
            0x00,
          ]),
        );
        // Size 5:
        expect(
          bytes,
          containsAllInOrder([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 5]),
        );
        // ECC H: 0x33
        expect(
          bytes,
          containsAllInOrder([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x33]),
        );
        // Print command:
        expect(
          bytes,
          containsAllInOrder([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]),
        );
      });
    });

    group('Raster Graphics', () {
      test('preserves exact high-byte binary data 0x00..0xFF', () {
        final rawData = Uint8List.fromList([
          0x00,
          0x01,
          0x7F,
          0x80,
          0x81,
          0xFE,
          0xFF,
        ]);

        final printer =
            EscPosPrinter(
              encoding: const EscPosEncoding.cp437(sendTableSelect: false),
            )..raster(
              data: rawData,
              bytesPerRow: 7,
              height: 1,
              mode: EscPosImageMode.normal,
            );

        final expected = [
          0x1D, 0x76, 0x30, 0, // GS v 0 0
          7, 0, // xL, xH (7 bytesPerRow)
          1, 0, // yL, yH (1 height)
          ...rawData,
        ];

        expect(printer.toBytes(), equals(Uint8List.fromList(expected)));
      });

      test('supports rasterFromMonochrome helper', () {
        final bitmap = MonochromeBitmap(
          data: Uint8List.fromList([0xAA, 0x55]),
          width: 8,
          height: 2,
          bytesPerRow: 1,
        );

        final printer = EscPosPrinter(
          encoding: const EscPosEncoding.cp437(sendTableSelect: false),
        )..rasterFromMonochrome(bitmap);

        final expected = [
          0x1D, 0x76, 0x30, 0, // GS v 0 0
          1, 0, // xL, xH
          2, 0, // yL, yH
          0xAA, 0x55,
        ];

        expect(printer.toBytes(), equals(Uint8List.fromList(expected)));
      });
    });

    group('Hardware Actuators', () {
      test('emits GS V for cut with feedLines', () {
        final printer1 = EscPosPrinter(
          encoding: const EscPosEncoding.cp437(sendTableSelect: false),
        )..cut(mode: EscPosCutMode.partial, feedLines: 3);

        expect(
          printer1.toBytes(),
          equals(Uint8List.fromList([0x1D, 0x56, 0x42, 3])),
        );

        final printer2 = EscPosPrinter(
          encoding: const EscPosEncoding.cp437(sendTableSelect: false),
        )..cut(mode: EscPosCutMode.full, feedLines: 0);

        expect(printer2.toBytes(), equals(Uint8List.fromList([0x1D, 0x56, 0])));
      });

      test(
        'emits ESC p for cash drawer pulse with exact millisecond timings',
        () {
          final printer =
              EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )..pulseDrawer(
                pin: EscPosDrawerPin.pin2,
                onTimeMs: 60,
                offTimeMs: 120,
              );

          // onTimeMs: 60 ~/ 2 = 30; offTimeMs: 120 ~/ 2 = 60
          expect(
            printer.toBytes(),
            equals(Uint8List.fromList([0x1B, 0x70, 0, 30, 60])),
          );
        },
      );

      test('emits DLE EOT status query', () {
        final printer = EscPosPrinter(
          encoding: const EscPosEncoding.cp437(sendTableSelect: false),
        )..requestStatus(EscPosStatusType.paper);

        expect(printer.toBytes(), equals(Uint8List.fromList([0x10, 0x04, 4])));
      });
    });

    group('Raw Passthrough', () {
      test('emits rawBytes and rawAscii verbatim', () {
        final raw = Uint8List.fromList([0x1B, 0x33, 24]);
        final printer =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..rawBytes(raw)
              ..rawAscii('TEST', appendNewline: true);

        expect(
          printer.toBytes(),
          equals(Uint8List.fromList([...raw, ...ascii.encode('TEST'), 0x0A])),
        );
      });
    });

    group('Validation & Boundary Checking', () {
      test('validates text size multipliers (1..8)', () {
        expect(
          () => EscPosPrinter().textSize(width: 0, height: 1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EscPosPrinter().textSize(width: 1, height: 9),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates feed lines and dots (0..255)', () {
        expect(
          () => EscPosPrinter().feedLines(-1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EscPosPrinter().feedLines(256),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EscPosPrinter().feedDots(-1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EscPosPrinter().feedDots(256),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates drawer pulse durations (even ms, off >= on, <= 510)', () {
        // Odd ms
        expect(
          () => EscPosPrinter().pulseDrawer(onTimeMs: 51, offTimeMs: 100),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EscPosPrinter().pulseDrawer(onTimeMs: 50, offTimeMs: 101),
          throwsA(isA<InvalidConfigError>()),
        );
        // off < on
        expect(
          () => EscPosPrinter().pulseDrawer(onTimeMs: 100, offTimeMs: 50),
          throwsA(isA<InvalidConfigError>()),
        );
        // > 510
        expect(
          () => EscPosPrinter().pulseDrawer(onTimeMs: 512, offTimeMs: 512),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates barcode parameters', () {
        expect(
          () => EscPosPrinter().barcode(
            content: '',
            type: EscPosBarcodeType.code128,
          ),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EscPosPrinter().barcode(
            content: '123',
            type: EscPosBarcodeType.code128,
            height: 0,
          ),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EscPosPrinter().barcode(
            content: '123',
            type: EscPosBarcodeType.code128,
            width: 1,
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates QR code parameters', () {
        expect(
          () => EscPosPrinter().qrCode(''),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EscPosPrinter().qrCode('test', size: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EscPosPrinter().qrCode('test', size: 17),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates raster payload length', () {
        expect(
          () => EscPosPrinter().raster(
            data: Uint8List.fromList([0xFF]),
            bytesPerRow: 2,
            height: 2, // expects 4 bytes
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });
    });

    group('Universal AST vs Native Equivalence', () {
      test('produces identical output for standard formatted receipt block', () {
        final labelBuilder = label(const LabelConfig(width: 80))
            .text(
              'STORE HEADER',
              const TextOptions(align: 'center', bold: true),
            )
            .text('Item 1: \$10.00');

        final universalBytes = escpos.compile(
          labelBuilder,
          encoding: const EscPosEncoding.cp437(sendTableSelect: false),
        );

        // Native equivalent:
        // 1. Initialize (ESC @)
        // 2. align center, bold true, textLine 'STORE HEADER', bold false, align left
        // 3. textLine 'Item 1: $10.00'
        // 4. cut partial (feed 3)
        final nativePrinter =
            EscPosPrinter(
                encoding: const EscPosEncoding.cp437(sendTableSelect: false),
              )
              ..initialize()
              ..align(EscPosAlignment.center)
              ..bold(true)
              ..textLine('STORE HEADER')
              ..bold(false)
              ..align(EscPosAlignment.left)
              ..textLine(r'Item 1: $10.00')
              ..cut(mode: EscPosCutMode.partial, feedLines: 3);

        expect(nativePrinter.toBytes(), equals(universalBytes));
      });
    });
  });
}
