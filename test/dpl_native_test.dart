import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/encoding.dart';
import 'package:portakal_flutter/src/errors.dart';
import 'package:portakal_flutter/src/lang/dpl.dart';
import 'package:portakal_flutter/src/native/dpl.dart';
import 'package:portakal_flutter/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('DplPrinter Native Builder', () {
    test('empty builder returns empty snapshot without mutating', () {
      final printer = DplPrinter();
      final bytes1 = printer.toBytes();
      final bytes2 = printer.toBytes();

      expect(bytes1, isEmpty);
      expect(bytes2, isEmpty);
    });

    test(
      'reset clears accumulated buffer, resets inLabel, and restores encoding',
      () {
        final printer = DplPrinter()
          ..startLabel()
          ..text(x: 10, y: 10, text: 'Label')
          ..endLabel();

        expect(printer.toBytes(), isNotEmpty);
        expect(printer.inLabel, isFalse);

        printer.reset();
        expect(printer.toBytes(), isEmpty);
        expect(printer.inLabel, isFalse);
      },
    );

    group('Label Formatting Lifecycle & Control Bytes', () {
      test('emits literal STX (0x02), L, LF at start and E, LF at end', () {
        final printer = DplPrinter()
          ..startLabel()
          ..endLabel();

        final output = printer.toBytes();

        // Exact byte checks
        expect(output[0], equals(0x02)); // STX
        expect(output[1], equals(0x4C)); // 'L'
        expect(output[2], equals(0x0A)); // '\n' (LF)
        expect(output[3], equals(0x45)); // 'E'
        expect(output[4], equals(0x0A)); // '\n' (LF)
      });

      test(
        'validates format lifecycle and prevents nested start or premature end',
        () {
          final p1 = DplPrinter()..startLabel();
          expect(() => p1.startLabel(), throwsA(isA<InvalidConfigError>()));

          final p2 = DplPrinter();
          expect(() => p2.endLabel(), throwsA(isA<InvalidConfigError>()));
        },
      );
    });

    group('Configuration Records', () {
      test('emits exact D, S, A, Q header records', () {
        final printer = DplPrinter()
          ..startLabel()
          ..heat(8)
          ..speed(4)
          ..labelWidth(320)
          ..copies(3)
          ..endLabel();

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('\x02L\n'));
        expect(text, contains('D08\n'));
        expect(text, contains('S04\n'));
        expect(text, contains('A0320\n'));
        expect(text, contains('Q0003\n'));
        expect(text, endsWith('E\n'));
      });
    });

    group('Text & Encoding', () {
      test('emits text with zero-padded coordinates, font, and multipliers', () {
        final printer = DplPrinter()
          ..startLabel()
          ..text(
            x: 50,
            y: 30,
            text: 'Hello DPL',
            font: '0',
            xMultiplier: 2,
            yMultiplier: 2,
            rotation: DplRotation.rotated90,
          )
          ..endLabel();

        final text = ascii.decode(printer.toBytes());
        // Rotation 90 -> '2', Y: 30 -> '0030', X: 50 -> '0050', font '0', scale '0202'
        expect(text, contains('20030005000202Hello DPL\n'));
      });

      test('encodes extended characters in CP437 (Café)', () {
        final printer = DplPrinter()
          ..startLabel()
          ..text(x: 10, y: 20, text: 'Café')
          ..endLabel();

        final expected = <int>[
          ...ascii.encode('\x02L\n10020001000101Caf'),
          0x82, // 'é' in CP437
          0x0A, // '\n'
          ...ascii.encode('E\n'),
        ];

        expect(printer.toBytes(), equals(Uint8List.fromList(expected)));
      });

      test('switches encoding mid-stream with encoding()', () {
        final printer = DplPrinter()
          ..startLabel()
          ..text(x: 10, y: 10, text: 'First')
          ..encoding(const DplEncoding.cp1252())
          ..text(x: 10, y: 50, text: 'Second')
          ..endLabel();

        expect(printer.toBytes(), isNotEmpty);
      });

      test(
        'throws UnsupportedCharacterException for unencodable characters',
        () {
          final printer = DplPrinter()..startLabel();
          expect(
            () => printer.text(x: 0, y: 0, text: 'Hello 你好'),
            throwsA(isA<UnsupportedCharacterException>()),
          );
        },
      );

      test(
        'replaces unsupported characters when replaceUnsupported is enabled',
        () {
          final printer =
              DplPrinter(
                  encoding: const DplEncoding.legacy(replaceUnsupported: true),
                )
                ..startLabel()
                ..text(x: 0, y: 0, text: 'Hello 你好')
                ..endLabel();

          final text = latin1.decode(printer.toBytes());
          expect(text, contains('Hello ??\n'));
        },
      );

      test(
        'rejects structural control characters in text (LF, CR, STX, SOH, ESC)',
        () {
          expect(
            () => DplPrinter().text(x: 0, y: 0, text: 'Line\nBreak'),
            throwsA(isA<InvalidConfigError>()),
          );
          expect(
            () => DplPrinter().text(x: 0, y: 0, text: 'Line\rBreak'),
            throwsA(isA<InvalidConfigError>()),
          );
          expect(
            () => DplPrinter().text(x: 0, y: 0, text: 'Bad\x02STX'),
            throwsA(isA<InvalidConfigError>()),
          );
          expect(
            () => DplPrinter().text(x: 0, y: 0, text: 'Bad\x01SOH'),
            throwsA(isA<InvalidConfigError>()),
          );
          expect(
            () => DplPrinter().text(x: 0, y: 0, text: 'Bad\x1BESC'),
            throwsA(isA<InvalidConfigError>()),
          );
        },
      );
    });

    group('Barcodes & QR Codes', () {
      test('emits Code128 and Code39 barcodes', () {
        final printer = DplPrinter()
          ..startLabel()
          ..barcode(
            x: 10,
            y: 20,
            content: 'CODE39',
            type: DplBarcodeType.code39,
            height: 40,
            wideMultiplier: 2,
          )
          ..barcode(
            x: 10,
            y: 80,
            content: '123456',
            type: DplBarcodeType.code128,
            height: 50,
            wideMultiplier: 3,
          )
          ..endLabel();

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('1A20040000000100020CODE39\n'));
        expect(text, contains('1E30050000000100080123456\n'));
      });

      test('emits 2D QR Code (1W1c)', () {
        final printer = DplPrinter()
          ..startLabel()
          ..qrCode(x: 10, y: 80, content: 'https://example.com', cellWidth: 4)
          ..endLabel();

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('1W1c004000000100080https://example.com\n'));
      });
    });

    group('Drawing Primitives', () {
      test('emits 1e for box rectangle', () {
        final printer = DplPrinter()
          ..startLabel()
          ..box(x: 10, y: 20, width: 200, height: 100, thickness: 3)
          ..endLabel();

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('1e00200010020001000003\n'));
      });

      test('emits 1X for horizontal and vertical lines', () {
        final printer = DplPrinter()
          ..startLabel()
          ..line(x1: 10, y1: 50, x2: 250, y2: 50, thickness: 2) // horizontal
          ..line(x1: 50, y1: 10, x2: 50, y2: 210, thickness: 3) // vertical
          ..endLabel();

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('1X00500010L02402\n'));
        expect(text, contains('1X00100050L02003\n'));
      });
    });

    group('Raw Passthrough', () {
      test('emits rawBytes and rawAscii verbatim', () {
        final raw = Uint8List.fromList([0x01, 0x41, 0x0A]); // SOH A \n
        final printer = DplPrinter()
          ..rawBytes(raw)
          ..rawAscii('CUSTOM_DPL_RAW', appendNewline: true);

        expect(
          printer.toBytes(),
          equals(
            Uint8List.fromList([...raw, ...ascii.encode('CUSTOM_DPL_RAW\n')]),
          ),
        );
      });
    });

    group('Validation & Boundary Rejection', () {
      test('validates negative coordinates and overflow bounds', () {
        expect(
          () => DplPrinter().text(x: -1, y: 0, text: 'a'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => DplPrinter().text(x: 10000, y: 0, text: 'a'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => DplPrinter().labelWidth(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => DplPrinter().labelWidth(10000),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => DplPrinter().box(x: 0, y: 0, width: 0, height: 10),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates heat, speed, and copies bounds', () {
        expect(() => DplPrinter().heat(-1), throwsA(isA<InvalidConfigError>()));
        expect(() => DplPrinter().heat(31), throwsA(isA<InvalidConfigError>()));
        expect(() => DplPrinter().speed(0), throwsA(isA<InvalidConfigError>()));
        expect(
          () => DplPrinter().speed(15),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => DplPrinter().copies(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => DplPrinter().copies(10000),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates multipliers and QR cell width', () {
        expect(
          () => DplPrinter().text(x: 0, y: 0, text: 'a', xMultiplier: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => DplPrinter().text(x: 0, y: 0, text: 'a', xMultiplier: 100),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => DplPrinter().qrCode(x: 0, y: 0, content: 'a', cellWidth: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => DplPrinter().qrCode(x: 0, y: 0, content: 'a', cellWidth: 1000),
          throwsA(isA<InvalidConfigError>()),
        );
      });
    });

    group('Universal AST vs Native Builder Equivalence', () {
      test('produces identical byte stream for standard label layout', () {
        final labelBuilder =
            label(
                  const LabelConfig(
                    width: 40,
                    height: 30,
                    speed: 4,
                    density: 8,
                    copies: 2,
                  ),
                )
                .text('SHIPPING LABEL', const TextOptions(x: 10, y: 20))
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
                )
                .qrcode(
                  'https://example.com',
                  const QRCodeOptions(x: 10, y: 160, cellWidth: 4),
                );

        final universalBytes = dpl.compileBytes(labelBuilder);

        // Native equivalent:
        final nativePrinter = DplPrinter()
          ..startLabel()
          ..heat(8)
          ..speed(4)
          ..labelWidth(320)
          ..copies(2)
          ..text(
            x: 10,
            y: 20,
            text: 'SHIPPING LABEL',
            font: '0',
            xMultiplier: 1,
            yMultiplier: 1,
          )
          ..box(x: 10, y: 10, width: 200, height: 100, thickness: 2)
          ..line(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2)
          ..barcode(
            x: 10,
            y: 100,
            type: DplBarcodeType.code128,
            height: 40,
            wideMultiplier: 2,
            content: '123456',
          )
          ..qrCode(x: 10, y: 160, cellWidth: 4, content: 'https://example.com')
          ..endLabel();

        expect(nativePrinter.toBytes(), equals(universalBytes));
      });
    });
  });
}
