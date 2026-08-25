import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/encoding.dart';
import 'package:portakal_flutter/src/errors.dart';
import 'package:portakal_flutter/src/lang/cpcl.dart';
import 'package:portakal_flutter/src/native/cpcl.dart';
import 'package:portakal_flutter/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('CpclPrinter Native Builder', () {
    test('empty builder returns empty snapshot without mutating', () {
      final printer = CpclPrinter();
      final bytes1 = printer.toBytes();
      final bytes2 = printer.toBytes();

      expect(bytes1, isEmpty);
      expect(bytes2, isEmpty);
    });

    test('reset clears accumulated buffer and restores encoding', () {
      final printer = CpclPrinter()
        ..startPage(heightDots: 240, copies: 1)
        ..text(x: 10, y: 10, text: 'Label')
        ..print();

      expect(printer.toBytes(), isNotEmpty);

      printer.reset();
      expect(printer.toBytes(), isEmpty);
    });

    group('Page Framing & Session Commands', () {
      test('emits exact header, PAGE-WIDTH, FORM, and PRINT', () {
        final printer = CpclPrinter()
          ..startPage(
            offset: 0,
            hDpi: 203,
            vDpi: 203,
            heightDots: 240,
            copies: 3,
          )
          ..pageWidth(320)
          ..form()
          ..print();

        final text = ascii.decode(printer.toBytes());
        expect(
          text,
          equals(
            '! 0 203 203 240 3\r\n'
            'PAGE-WIDTH 320\r\n'
            'FORM\r\n'
            'PRINT\r\n',
          ),
        );
      });

      test('emits SPEED, TONE, and SETMAG configuration', () {
        final printer = CpclPrinter()
          ..speed(4)
          ..tone(2)
          ..setMag(2, 3);

        final text = ascii.decode(printer.toBytes());
        expect(
          text,
          equals(
            'SPEED 4\r\n'
            'TONE 2\r\n'
            'SETMAG 2 3\r\n',
          ),
        );
      });
    });

    group('Text & Encoding', () {
      test('emits text with font, size, rotation orientations', () {
        final printer = CpclPrinter()
          ..text(
            x: 10,
            y: 20,
            text: 'Horizontal Text',
            font: '2',
            size: 0,
            rotation: CpclRotation.unrotated,
          )
          ..text(
            x: 10,
            y: 60,
            text: 'Vertical Text',
            font: '4',
            size: 1,
            rotation: CpclRotation.rotated90,
          );

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('TEXT 2 0 10 20\r\nHorizontal Text\r\n'));
        expect(text, contains('TEXT90 4 1 10 60\r\nVertical Text\r\n'));
      });

      test('encodes extended characters in CP437 (Café)', () {
        final printer = CpclPrinter()..text(x: 10, y: 20, text: 'Café');

        final expected = <int>[
          ...ascii.encode('TEXT 2 0 10 20\r\nCaf'),
          0x82, // 'é' in CP437
          0x0D, 0x0A, // '\r\n'
        ];

        expect(printer.toBytes(), equals(Uint8List.fromList(expected)));
      });

      test(
        'emits COUNTRY command on constructor when requested by encoding',
        () {
          final printer = CpclPrinter(
            encoding: const CpclEncoding.cp850(sendCountryCommand: true),
          )..text(x: 10, y: 10, text: 'Test');

          final text = latin1.decode(printer.toBytes());
          expect(text, startsWith('COUNTRY CP850\r\n'));
        },
      );

      test('switches encoding mid-stream with encoding()', () {
        final printer = CpclPrinter()
          ..text(x: 10, y: 10, text: 'First')
          ..encoding(const CpclEncoding.cp1252(sendCountryCommand: true))
          ..text(x: 10, y: 50, text: 'Second');

        final text = latin1.decode(printer.toBytes());
        expect(text, contains('COUNTRY CP1252\r\n'));
      });

      test(
        'throws UnsupportedCharacterException for unencodable characters',
        () {
          final printer = CpclPrinter();
          expect(
            () => printer.text(x: 0, y: 0, text: 'Hello 你好'),
            throwsA(isA<UnsupportedCharacterException>()),
          );
        },
      );

      test(
        'replaces unsupported characters when replaceUnsupported is enabled',
        () {
          final printer = CpclPrinter(
            encoding: const CpclEncoding.legacy(replaceUnsupported: true),
          )..text(x: 0, y: 0, text: 'Hello 你好');

          final text = latin1.decode(printer.toBytes());
          expect(text, contains('Hello ??\r\n'));
        },
      );

      test('rejects literal newline characters in text', () {
        expect(
          () => CpclPrinter().text(x: 0, y: 0, text: 'Line1\nLine2'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => CpclPrinter().text(x: 0, y: 0, text: 'Line1\rLine2'),
          throwsA(isA<InvalidConfigError>()),
        );
      });
    });

    group('Barcodes & QR Codes', () {
      test('emits Code128 and Code39 barcodes with human readable options', () {
        final printer = CpclPrinter()
          ..barcode(
            x: 10,
            y: 20,
            content: '123456',
            type: CpclBarcodeType.code128,
            height: 40,
            narrowBarWidth: 1,
            wideRatio: 2,
            humanReadable: true,
          )
          ..barcode(
            x: 10,
            y: 80,
            content: 'CODE39',
            type: CpclBarcodeType.code39,
            height: 40,
            humanReadable: false,
          );

        final text = ascii.decode(printer.toBytes());
        expect(
          text,
          contains(
            'BARCODE-TEXT 7 0 5\r\n'
            'BARCODE 128 1 2 40 10 20 123456\r\n'
            'BARCODE-TEXT OFF\r\n',
          ),
        );
        expect(text, contains('BARCODE 39 1 2 40 10 80 CODE39\r\n'));
      });

      test('emits 2D QR Code', () {
        final printer = CpclPrinter()
          ..qrCode(x: 10, y: 80, content: 'https://example.com', cellWidth: 4);

        final text = ascii.decode(printer.toBytes());
        expect(
          text,
          equals(
            'BARCODE QR 10 80 M 2 U 4\r\n'
            'MA,https://example.com\r\n'
            'ENDQR\r\n',
          ),
        );
      });
    });

    group('Drawing Primitives', () {
      test('emits BOX with calculated bottom-right coordinates', () {
        final printer = CpclPrinter()
          ..box(x: 5, y: 5, width: 310, height: 230, thickness: 2);

        final text = ascii.decode(printer.toBytes());
        expect(text, equals('BOX 5 5 315 235 2\r\n'));
      });

      test('emits LINE segment', () {
        final printer = CpclPrinter()
          ..line(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2);

        final text = ascii.decode(printer.toBytes());
        expect(text, equals('LINE 10 50 300 50 2\r\n'));
      });
    });

    group('Graphics & EG Hex Encoding', () {
      test(
        'EG expanded graphics encodes binary data into uppercase ASCII hex bytes',
        () {
          // Binary source: [0x00, 0x7F, 0x80, 0xFF]
          final rawData = Uint8List.fromList([0x00, 0x7F, 0x80, 0xFF]);
          final printer = CpclPrinter()
            ..graphic(x: 10, y: 15, data: rawData, bytesPerRow: 2, height: 2);

          final output = printer.toBytes();
          final text = ascii.decode(output);

          expect(text, equals('EG 2 2 10 15 007F80FF\r\n'));

          // Verify exact on-wire ASCII byte representation:
          // '0' (0x30), '0' (0x30), '7' (0x37), 'F' (0x46), '8' (0x38), '0' (0x30), 'F' (0x46), 'F' (0x46)
          final expectedHexAsciiBytes = [
            0x30,
            0x30,
            0x37,
            0x46,
            0x38,
            0x30,
            0x46,
            0x46,
          ];
          expect(
            output.sublist(13, 21),
            equals(Uint8List.fromList(expectedHexAsciiBytes)),
          );
        },
      );

      test('supports graphicFromMonochrome helper', () {
        final bmp = MonochromeBitmap(
          data: Uint8List.fromList([0xAA, 0x55]),
          width: 8,
          height: 2,
          bytesPerRow: 1,
        );

        final printer = CpclPrinter()..graphicFromMonochrome(bmp, x: 5, y: 5);
        final output = printer.toBytes();
        final text = ascii.decode(output);
        expect(text, equals('EG 1 2 5 5 AA55\r\n'));
      });
    });

    group('Raw Passthrough', () {
      test('emits rawBytes and rawAscii verbatim', () {
        final raw = Uint8List.fromList([
          0x4A,
          0x4F,
          0x55,
          0x52,
          0x0D,
          0x0A,
        ]); // JOUR\r\n
        final printer = CpclPrinter()
          ..rawBytes(raw)
          ..rawAscii('STATUS', appendNewline: true);

        expect(
          printer.toBytes(),
          equals(Uint8List.fromList([...raw, ...ascii.encode('STATUS\r\n')])),
        );
      });
    });

    group('Validation & Boundary Rejection', () {
      test('validates negative coordinates and non-positive dimensions', () {
        expect(
          () => CpclPrinter().text(x: -1, y: 0, text: 'a'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => CpclPrinter().text(x: 0, y: -1, text: 'a'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => CpclPrinter().pageWidth(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => CpclPrinter().box(x: 0, y: 0, width: 0, height: 10),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => CpclPrinter().box(x: 0, y: 0, width: 10, height: 0),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates speed and SETMAG bounds', () {
        expect(
          () => CpclPrinter().speed(-1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => CpclPrinter().speed(6),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => CpclPrinter().setMag(0, 1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => CpclPrinter().setMag(17, 1),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates QR cell width', () {
        expect(
          () => CpclPrinter().qrCode(x: 0, y: 0, content: 'a', cellWidth: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => CpclPrinter().qrCode(x: 0, y: 0, content: 'a', cellWidth: 33),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates graphic length', () {
        expect(
          () => CpclPrinter().graphic(
            x: 0,
            y: 0,
            data: Uint8List.fromList([0xFF]),
            bytesPerRow: 2,
            height: 2,
          ),
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
                )
                .qrcode(
                  'https://example.com',
                  const QRCodeOptions(x: 10, y: 160, cellWidth: 4),
                );

        final universalBytes = cpcl.compileBytes(labelBuilder);

        // Native equivalent:
        final nativePrinter = CpclPrinter()
          ..startPage(
            offset: 0,
            hDpi: 203,
            vDpi: 203,
            heightDots: 240,
            copies: 2,
          )
          ..tone(1) // density 8 -> tone 1
          ..speed(4)
          ..pageWidth(320)
          ..text(x: 10, y: 20, text: 'SHIPPING LABEL', font: '2', size: 0)
          ..box(x: 5, y: 5, width: 310, height: 230, thickness: 2)
          ..line(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2)
          ..barcode(
            x: 10,
            y: 100,
            type: CpclBarcodeType.code128,
            height: 40,
            narrowBarWidth: 1,
            wideRatio: 2,
            humanReadable: false,
            content: '123456',
          )
          ..qrCode(x: 10, y: 160, cellWidth: 4, content: 'https://example.com')
          ..print();

        expect(nativePrinter.toBytes(), equals(universalBytes));
      });
    });
  });
}
