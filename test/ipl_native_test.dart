import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/encoding.dart';
import 'package:portakal_flutter/src/errors.dart';
import 'package:portakal_flutter/src/lang/ipl.dart';
import 'package:portakal_flutter/src/native/ipl.dart';
import 'package:portakal_flutter/src/parsers/ipl.dart';
import 'package:portakal_flutter/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('IplPrinter Native Builder', () {
    test('empty builder returns empty snapshot without mutating', () {
      final printer = IplPrinter();
      final bytes1 = printer.toBytes();
      final bytes2 = printer.toBytes();

      expect(bytes1, isEmpty);
      expect(bytes2, isEmpty);
    });

    test(
      'reset clears accumulated buffer, resets counter, and restores encoding',
      () {
        final printer = IplPrinter()
          ..createFormat(1)
          ..text(x: 10, y: 10, text: 'Label')
          ..endFormat(1);

        expect(printer.toBytes(), isNotEmpty);

        printer.reset();
        expect(printer.toBytes(), isEmpty);
      },
    );

    group('Lifecycle & Control Framing', () {
      test(
        'emits exact binary STX, ETX, ESC control sequences for format lifecycle',
        () {
          final printer = IplPrinter()
            ..createFormat(1)
            ..programMode()
            ..copies(3)
            ..endFormat(1)
            ..print();

          final output = printer.toBytes().toList();

          // <STX><ESC>C1<ETX> -> [0x02, 0x1B, 0x43, 0x31, 0x03]
          expect(
            _findSequence(output, [0x02, 0x1B, 0x43, 0x31, 0x03]),
            greaterThan(-1),
          );

          // <STX><ESC>P<ETX> -> [0x02, 0x1B, 0x50, 0x03]
          expect(
            _findSequence(output, [0x02, 0x1B, 0x50, 0x03]),
            greaterThan(-1),
          );

          // <STX><ESC>M3<ETX> -> [0x02, 0x1B, 0x4D, 0x33, 0x03]
          expect(
            _findSequence(output, [0x02, 0x1B, 0x4D, 0x33, 0x03]),
            greaterThan(-1),
          );

          // <STX><ESC>E1<ETX> -> [0x02, 0x1B, 0x45, 0x31, 0x03]
          expect(
            _findSequence(output, [0x02, 0x1B, 0x45, 0x31, 0x03]),
            greaterThan(-1),
          );

          // <STX>R<ETX> -> [0x02, 0x52, 0x03]
          expect(_findSequence(output, [0x02, 0x52, 0x03]), greaterThan(-1));
        },
      );
    });

    group('SI-Based Media & Configuration Commands', () {
      test(
        'emits exact binary SI (0x0F) control bytes inside STX/ETX frames',
        () {
          final printer = IplPrinter()
            ..labelLength(240)
            ..labelWidth(320)
            ..speed(6)
            ..density(10);

          final output = printer.toBytes().toList();

          // <STX><SI>L240<ETX> -> [0x02, 0x0F, 0x4C, 0x32, 0x34, 0x30, 0x03]
          expect(
            _findSequence(output, [0x02, 0x0F, 0x4C, 0x32, 0x34, 0x30, 0x03]),
            greaterThan(-1),
          );

          // <STX><SI>W320<ETX> -> [0x02, 0x0F, 0x57, 0x33, 0x32, 0x30, 0x03]
          expect(
            _findSequence(output, [0x02, 0x0F, 0x57, 0x33, 0x32, 0x30, 0x03]),
            greaterThan(-1),
          );

          // <STX><SI>S60<ETX> -> [0x02, 0x0F, 0x53, 0x36, 0x30, 0x03]
          expect(
            _findSequence(output, [0x02, 0x0F, 0x53, 0x36, 0x30, 0x03]),
            greaterThan(-1),
          );

          // <STX><SI>d10<ETX> -> [0x02, 0x0F, 0x64, 0x31, 0x30, 0x03]
          expect(
            _findSequence(output, [0x02, 0x0F, 0x64, 0x31, 0x30, 0x03]),
            greaterThan(-1),
          );
        },
      );

      test(
        'regression: never emits literal printable placeholder text for SI/STX/ETX/ESC',
        () {
          final printer = IplPrinter()
            ..createFormat(1)
            ..labelLength(240)
            ..endFormat(1);

          final output = printer.toBytes().toList();
          expect(_findSequence(output, ascii.encode('<SI>')), equals(-1));
          expect(_findSequence(output, ascii.encode('<STX>')), equals(-1));
          expect(_findSequence(output, ascii.encode('<ETX>')), equals(-1));
          expect(_findSequence(output, ascii.encode('<ESC>')), equals(-1));
        },
      );
    });

    group('Text & Encoding', () {
      test('emits H text fields with font dimensions and rotation', () {
        final printer = IplPrinter()
          ..text(
            x: 50,
            y: 30,
            text: 'Hello IPL',
            fieldNumber: 1,
            fontHeight: 24,
            fontWidth: 24,
            rotation: IplRotation.rotated90,
          );

        final text = latin1.decode(printer.toBytes());
        expect(text, equals('\x02H1;o50,30;f1;h24;w24;c26;d3,Hello IPL\x03'));
      });

      test('encodes extended characters in CP437 (Café)', () {
        final printer = IplPrinter()
          ..text(x: 10, y: 20, text: 'Café', fieldNumber: 1);

        final expected = <int>[
          ...ascii.encode('\x02H1;o10,20;f0;h12;w12;c26;d3,Caf'),
          0x82, // 'é' in CP437
          0x03, // ETX
        ];

        expect(printer.toBytes(), equals(Uint8List.fromList(expected)));
      });

      test('switches encoding mid-stream with encoding()', () {
        final printer = IplPrinter()
          ..text(x: 10, y: 10, text: 'First')
          ..encoding(const IplEncoding.cp1252())
          ..text(x: 10, y: 50, text: 'Second');

        expect(printer.toBytes(), isNotEmpty);
      });

      test(
        'rejects dangerous control characters in text (STX, ETX, ESC, SI)',
        () {
          expect(
            () => IplPrinter().text(x: 0, y: 0, text: 'Bad\x02STX'),
            throwsA(isA<UnsupportedCharacterException>()),
          );
          expect(
            () => IplPrinter().text(x: 0, y: 0, text: 'Bad\x03ETX'),
            throwsA(isA<UnsupportedCharacterException>()),
          );
          expect(
            () => IplPrinter().text(x: 0, y: 0, text: 'Bad\x1BESC'),
            throwsA(isA<UnsupportedCharacterException>()),
          );
          expect(
            () => IplPrinter().text(x: 0, y: 0, text: 'Bad\x0FSI'),
            throwsA(isA<UnsupportedCharacterException>()),
          );
        },
      );

      test(
        'replaces unsupported characters when replaceUnsupported is enabled',
        () {
          final printer = IplPrinter(
            encoding: const IplEncoding.legacy(replaceUnsupported: true),
          )..text(x: 0, y: 0, text: 'Break\x03Frame', fieldNumber: 1);

          final text = latin1.decode(printer.toBytes());
          expect(text, contains('d3,Break?Frame\x03'));
        },
      );
    });

    group('Barcodes & QR Codes', () {
      test('emits 1D barcode with format definition and data frame', () {
        final printer = IplPrinter()
          ..barcode(
            y: 20,
            content: '123456',
            fieldNumber: 1,
            height: 40,
            wideMultiplier: 2,
            type: IplBarcodeType.code128,
          );

        final text = latin1.decode(printer.toBytes());
        expect(
          text,
          equals('\x02B1;o0;f0;c0;h40;w2;d0,20;\x03\n\x02123456\x03\n'),
        );
      });

      test('emits 2D QR Code with c21 format definition and data frame', () {
        final printer = IplPrinter()
          ..qrCode(
            y: 80,
            content: 'https://example.com',
            fieldNumber: 2,
            cellWidth: 4,
          );

        final text = latin1.decode(printer.toBytes());
        expect(
          text,
          equals(
            '\x02B2;o0;f0;c21;w4;h4;d0,80;\x03\n\x02https://example.com\x03\n',
          ),
        );
      });
    });

    group('Drawing Primitives', () {
      test('emits W for box rectangle', () {
        final printer = IplPrinter()
          ..box(
            x: 10,
            y: 20,
            width: 200,
            height: 100,
            thickness: 2,
            fieldNumber: 2,
          );

        final text = latin1.decode(printer.toBytes());
        expect(text, equals('\x02W2;o10,20;f0;l200;h100;w2\x03'));
      });

      test('emits L for horizontal and vertical lines', () {
        final printer = IplPrinter()
          ..line(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2, fieldNumber: 3)
          ..line(x1: 50, y1: 10, x2: 50, y2: 200, thickness: 2, fieldNumber: 4);

        final text = latin1.decode(printer.toBytes());
        expect(text, contains('\x02L3;o10,50;f0;l290;w2\x03'));
        expect(text, contains('\x02L4;o50,10;f1;l190;w2\x03'));
      });
    });

    group('Raw Passthrough & Parser Compatibility', () {
      test('emits rawBytes verbatim', () {
        final raw = Uint8List.fromList([0x02, 0x54, 0x45, 0x53, 0x54, 0x03]);
        final printer = IplPrinter()..rawBytes(raw);

        expect(printer.toBytes(), equals(raw));
      });

      test('native output is parsed cleanly by parseIPL', () {
        final printer = IplPrinter()
          ..createFormat(1)
          ..programMode()
          ..labelLength(240)
          ..labelWidth(320)
          ..text(x: 10, y: 20, text: 'Parsed Text')
          ..box(x: 5, y: 5, width: 100, height: 50, thickness: 1)
          ..line(x1: 10, y1: 80, x2: 200, y2: 80, thickness: 2)
          ..endFormat(1)
          ..print();

        final parsed = parseIPL(latin1.decode(printer.toBytes()));

        expect(parsed.heightDots, equals(240));
        expect(parsed.widthDots, equals(320));
        expect(parsed.elements.length, equals(3));
        expect(parsed.elements[0], isA<TextElement>());
        expect(
          (parsed.elements[0] as TextElement).content,
          equals('Parsed Text'),
        );
        expect(parsed.elements[1], isA<BoxElement>());
        expect(parsed.elements[2], isA<LineElement>());
      });
    });

    group('Validation & Boundary Rejection', () {
      test('validates negative coordinates and non-positive dimensions', () {
        expect(
          () => IplPrinter().text(x: -1, y: 0, text: 'a'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => IplPrinter().text(x: 0, y: -1, text: 'a'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => IplPrinter().box(x: 0, y: 0, width: 0, height: 10),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => IplPrinter().box(x: 0, y: 0, width: 10, height: 0),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates media and configuration ranges', () {
        expect(
          () => IplPrinter().labelLength(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => IplPrinter().labelWidth(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(() => IplPrinter().speed(0), throwsA(isA<InvalidConfigError>()));
        expect(
          () => IplPrinter().density(-1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => IplPrinter().copies(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => IplPrinter().createFormat(0),
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

        final universalBytes = ipl.compileBytes(labelBuilder);

        // Native equivalent:
        final nativePrinter = IplPrinter()
          ..createFormat(1)
          ..programMode()
          ..labelLength(240)
          ..labelWidth(320)
          ..speed(4)
          ..density(8)
          ..text(
            x: 10,
            y: 20,
            text: 'SHIPPING LABEL',
            fontHeight: 12,
            fontWidth: 12,
            fieldNumber: 1,
          )
          ..box(
            x: 10,
            y: 10,
            width: 200,
            height: 100,
            thickness: 2,
            fieldNumber: 2,
          )
          ..line(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2, fieldNumber: 3)
          ..barcode(
            y: 100,
            type: IplBarcodeType.code128,
            height: 40,
            wideMultiplier: 2,
            content: '123456',
            fieldNumber: 1,
          )
          ..qrCode(
            y: 160,
            cellWidth: 4,
            content: 'https://example.com',
            fieldNumber: 2,
          )
          ..copies(2)
          ..endFormat(1)
          ..print();

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
