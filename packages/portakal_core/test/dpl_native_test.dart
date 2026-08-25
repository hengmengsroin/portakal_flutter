import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/encoding.dart';
import 'package:portakal_core/src/errors.dart';
import 'package:portakal_core/src/lang/dpl.dart';
import 'package:portakal_core/src/native/dpl.dart';
import 'package:portakal_core/src/types.dart';
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

    group('Label Formatting Lifecycle & Control Bytes (CR Terminator)', () {
      test('emits literal STX (0x02), L, CR at start and E, CR at end', () {
        final printer = DplPrinter()
          ..startLabel()
          ..endLabel();

        final output = printer.toBytes();

        // Exact byte checks: start = 0x02, 0x4C, 0x0D; end = 0x45, 0x0D
        expect(output.length, equals(5));
        expect(output[0], equals(0x02)); // STX
        expect(output[1], equals(0x4C)); // 'L'
        expect(output[2], equals(0x0D)); // '\r' (CR)
        expect(output[3], equals(0x45)); // 'E'
        expect(output[4], equals(0x0D)); // '\r' (CR)
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
      test('emits exact D, S, A, Q header records terminated by CR', () {
        final printer = DplPrinter()
          ..startLabel()
          ..heat(8)
          ..speed(4)
          ..labelWidth(320)
          ..copies(3)
          ..endLabel();

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('\x02L\r'));
        expect(text, contains('D08\r'));
        expect(text, contains('S04\r'));
        expect(text, contains('A0320\r'));
        expect(text, contains('Q0003\r'));
        expect(text, endsWith('E\r'));
      });
    });

    group('Text & Encoding', () {
      test(
        'emits text with zero-padded coordinates, font, multipliers, and CR terminator',
        () {
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
          // Rotation 90 -> '2', Y: 30 -> '0030', X: 50 -> '0050', font '0', scale '0202', terminated by CR
          expect(text, contains('20030005000202Hello DPL\r'));
        },
      );

      test('encodes extended characters in CP437 (Café)', () {
        final printer = DplPrinter()
          ..startLabel()
          ..text(x: 10, y: 20, text: 'Café')
          ..endLabel();

        final expected = <int>[
          ...ascii.encode('\x02L\r10020001000101Caf'),
          0x82, // 'é' in CP437
          0x0D, // '\r' (CR)
          ...ascii.encode('E\r'),
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
          final printer = DplPrinter(
            encoding: const DplEncoding.legacy(replaceUnsupported: true),
          )
            ..startLabel()
            ..text(x: 0, y: 0, text: 'Hello 你好')
            ..endLabel();

          final text = latin1.decode(printer.toBytes());
          expect(text, contains('Hello ??\r'));
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
      test('emits Code128 and Code39 barcodes terminated by CR', () {
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
        expect(text, contains('1A20040000000100020CODE39\r'));
        expect(text, contains('1E30050000000100080123456\r'));
      });

      test('emits 2D QR Code (1W1c) terminated by CR', () {
        final printer = DplPrinter()
          ..startLabel()
          ..qrCode(x: 10, y: 80, content: 'https://example.com', cellWidth: 4)
          ..endLabel();

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('1W1c004000000100080https://example.com\r'));
      });
    });

    group('Drawing Primitives', () {
      test('emits 1e for box rectangle terminated by CR', () {
        final printer = DplPrinter()
          ..startLabel()
          ..box(x: 10, y: 20, width: 200, height: 100, thickness: 3)
          ..endLabel();

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('1e00200010020001000003\r'));
      });

      test('emits 1X for horizontal and vertical lines terminated by CR', () {
        final printer = DplPrinter()
          ..startLabel()
          ..line(x1: 10, y1: 50, x2: 250, y2: 50, thickness: 2) // horizontal
          ..line(x1: 50, y1: 10, x2: 50, y2: 210, thickness: 3) // vertical
          ..endLabel();

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('1X00500010L02402\r'));
        expect(text, contains('1X00100050L02003\r'));
      });
    });

    group('Raw Passthrough', () {
      test('emits rawBytes and rawAscii verbatim', () {
        final raw = Uint8List.fromList([0x01, 0x41, 0x0D]); // SOH A \r
        final printer = DplPrinter()
          ..rawBytes(raw)
          ..rawAscii('CUSTOM_DPL_RAW', appendNewline: true);

        expect(
          printer.toBytes(),
          equals(
            Uint8List.fromList([...raw, ...ascii.encode('CUSTOM_DPL_RAW\r')]),
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

    group('Universal AST vs Native Builder Divergence & Semantic Alignment',
        () {
      test(
        'confirms universal compiler preserves legacy LF (0x0A) record termination',
        () {
          final labelBuilder = label(
            const LabelConfig(width: 40, height: 30),
          ).text('Test', const TextOptions(x: 10, y: 20));

          final universalBytes = dpl.compileBytes(labelBuilder);
          final text = ascii.decode(universalBytes);

          // Universal output MUST preserve legacy LF (\n)
          expect(text, startsWith('\x02L\n'));
          expect(text, endsWith('E\n'));
          expect(universalBytes.contains(0x0A), isTrue);
          expect(universalBytes.contains(0x0D), isFalse);
        },
      );

      test(
        'semantically matches universal output when accounting for CR vs LF record termination',
        () {
          final labelBuilder = label(
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
                const BarcodeOptions(
                  x: 10,
                  y: 100,
                  type: '128',
                  height: 40,
                ),
              )
              .qrcode(
                'https://example.com',
                const QRCodeOptions(x: 10, y: 160, cellWidth: 4),
              );

          final universalBytes = dpl.compileBytes(labelBuilder);

          // Native equivalent (using standard CR record termination):
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
            ..qrCode(
              x: 10,
              y: 160,
              cellWidth: 4,
              content: 'https://example.com',
            )
            ..endLabel();

          final nativeBytes = nativePrinter.toBytes();

          // Verify native output uses CR (0x0D) and zero LF (0x0A)
          expect(nativeBytes.contains(0x0D), isTrue);
          expect(nativeBytes.contains(0x0A), isFalse);

          // Verify semantic equivalence of records after normalizing line terminators
          final universalNormalized =
              ascii.decode(universalBytes).replaceAll('\n', '\r');
          final nativeDecoded = ascii.decode(nativeBytes);
          expect(nativeDecoded, equals(universalNormalized));
        },
      );
    });
  });
}
