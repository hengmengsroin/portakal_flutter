import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/encoding.dart';
import 'package:portakal_core/src/errors.dart';
import 'package:portakal_core/src/lang/epl.dart';
import 'package:portakal_core/src/native/epl.dart';
import 'package:portakal_core/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('EplPrinter Native Builder', () {
    test('empty builder returns empty snapshot without mutating', () {
      final printer = EplPrinter();
      final bytes1 = printer.toBytes();
      final bytes2 = printer.toBytes();

      expect(bytes1, isEmpty);
      expect(bytes2, isEmpty);
    });

    test('reset clears accumulated buffer and restores encoding', () {
      final printer = EplPrinter()
        ..clear()
        ..text(x: 10, y: 10, text: 'Label')
        ..print(sets: 1);

      expect(printer.toBytes(), isNotEmpty);

      printer.reset();
      expect(printer.toBytes(), isEmpty);
    });

    group('Job Framing & Buffer Commands', () {
      test('emits N to clear image buffer and P to print', () {
        final printer = EplPrinter()
          ..clear()
          ..print(sets: 2, copies: 3);

        final text = ascii.decode(printer.toBytes());
        expect(text, equals('N\nP2,3\n'));
      });

      test('emits single sets print without copies parameter', () {
        final printer = EplPrinter()
          ..clear()
          ..print(sets: 1);

        final text = ascii.decode(printer.toBytes());
        expect(text, equals('N\nP1\n'));
      });

      test('emits C for cutter', () {
        final printer = EplPrinter()..cut();
        expect(ascii.decode(printer.toBytes()), equals('C\n'));
      });
    });

    group('Label Dimensions & Configuration', () {
      test('emits q, Q, S, D, R commands', () {
        final printer = EplPrinter()
          ..labelWidth(320)
          ..labelLength(240, gapDots: 24)
          ..speed(4)
          ..density(8)
          ..referencePoint(10, 20);

        final text = ascii.decode(printer.toBytes());
        expect(
          text,
          equals(
            'q320\n'
            'Q240,24\n'
            'S4\n'
            'D8\n'
            'R10,20\n',
          ),
        );
      });
    });

    group('Text & Encoding', () {
      test('emits text with font, rotation, multipliers, and reverse flag', () {
        final printer = EplPrinter()
          ..text(
            x: 10,
            y: 20,
            text: 'Hello EPL',
            font: EplFont.font3,
            rotation: EplRotation.rotated90,
            xMultiplier: 2,
            yMultiplier: 3,
            reverse: true,
          );

        final text = ascii.decode(printer.toBytes());
        expect(text, equals('A10,20,1,3,2,3,R,"Hello EPL"\n'));
      });

      test('escapes quotes and backslashes in text content', () {
        final printer = EplPrinter()..text(x: 10, y: 20, text: r'Item "A" \ 1');

        final text = ascii.decode(printer.toBytes());
        expect(
          text,
          equals(
            r'A10,20,0,2,1,1,N,"Item \"A\" \\ 1"'
            '\n',
          ),
        );
      });

      test('encodes extended characters in CP437 (Café)', () {
        final printer = EplPrinter()..text(x: 10, y: 10, text: 'Café');

        final expected = <int>[
          ...ascii.encode('A10,10,0,2,1,1,N,"Caf'),
          0x82, // 'é' in CP437
          0x22, // '"'
          0x0A, // '\n'
        ];

        expect(printer.toBytes(), equals(Uint8List.fromList(expected)));
      });

      test('emits I8 command on constructor when requested by encoding', () {
        final printer = EplPrinter(
          encoding: const EplEncoding.cp850(sendSetCharSetCommand: true),
        )..text(x: 10, y: 10, text: 'Test');

        final text = latin1.decode(printer.toBytes());
        expect(text, startsWith('I8,1,001\n'));
      });

      test('switches encoding mid-stream with encoding()', () {
        final printer = EplPrinter()
          ..text(x: 10, y: 10, text: 'First')
          ..encoding(const EplEncoding.cp1252(sendSetCharSetCommand: true))
          ..text(x: 10, y: 50, text: 'Second');

        final text = latin1.decode(printer.toBytes());
        expect(text, contains('I8,13,001\n'));
      });

      test(
        'throws UnsupportedCharacterException for unencodable characters',
        () {
          final printer = EplPrinter();
          expect(
            () => printer.text(x: 0, y: 0, text: 'Hello 你好'),
            throwsA(isA<UnsupportedCharacterException>()),
          );
        },
      );

      test(
        'replaces unsupported characters when replaceUnsupported is enabled',
        () {
          final printer = EplPrinter(
            encoding: const EplEncoding.legacy(replaceUnsupported: true),
          )..text(x: 0, y: 0, text: 'Hello 你好');

          final text = latin1.decode(printer.toBytes());
          expect(text, contains('"Hello ??"'));
        },
      );

      test('rejects literal newline characters in text', () {
        expect(
          () => EplPrinter().text(x: 0, y: 0, text: 'Line1\nLine2'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().text(x: 0, y: 0, text: 'Line1\rLine2'),
          throwsA(isA<InvalidConfigError>()),
        );
      });
    });

    group('Barcodes & QR Codes', () {
      test('emits Code128 and Code39 barcodes', () {
        final printer = EplPrinter()
          ..barcode(
            x: 10,
            y: 20,
            content: '123456',
            type: EplBarcodeType.code128,
            height: 40,
            narrowBarWidth: 2,
            wideBarWidth: 4,
            humanReadable: true,
          )
          ..barcode(
            x: 10,
            y: 80,
            content: 'CODE39',
            type: EplBarcodeType.code39,
            height: 40,
            humanReadable: false,
          );

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('B10,20,0,1,2,4,40,B,"123456"\n'));
        expect(text, contains('B10,80,0,3,2,4,40,N,"CODE39"\n'));
      });

      test('emits 2D QR Code', () {
        final printer = EplPrinter()
          ..qrCode(
            x: 10,
            y: 80,
            content: 'https://example.com',
            cellWidth: 4,
            ecc: EplQrEcc.q,
          );

        final text = ascii.decode(printer.toBytes());
        expect(text, equals('b10,80,"Q",m2,s4,eQ,"https://example.com"\n'));
      });
    });

    group('Drawing Primitives', () {
      test(
        'emits X for box rectangle with calculated bottom-right coordinates',
        () {
          final printer = EplPrinter()
            ..box(x: 5, y: 5, width: 310, height: 230, thickness: 2);

          final text = ascii.decode(printer.toBytes());
          expect(text, equals('X5,5,315,235,2\n'));
        },
      );

      test('emits LO for horizontal, vertical, and diagonal lines', () {
        final printer = EplPrinter()
          ..line(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2) // horizontal
          ..line(x1: 50, y1: 10, x2: 50, y2: 200, thickness: 3) // vertical
          ..lineDraw(x: 10, y: 10, width: 100, height: 20); // direct lineDraw

        final text = ascii.decode(printer.toBytes());
        expect(text, contains('LO10,50,290,2\n'));
        expect(text, contains('LO50,10,3,190\n'));
        expect(text, contains('LO10,10,100,20\n'));
      });

      test('emits LW for erase rectangle', () {
        final printer = EplPrinter()
          ..erase(x: 10, y: 10, width: 50, height: 30);
        final text = ascii.decode(printer.toBytes());
        expect(text, equals('LW10,10,50,30\n'));
      });
    });

    group('Graphics & Binary Safety', () {
      test(
        'GW raster image preserves high-byte binary values with bitwise inversion',
        () {
          // High-byte data: [0x00, 0x01, 0x7F, 0x80, 0x81, 0xFE, 0xFF]
          final rawData = Uint8List.fromList([
            0x00,
            0x01,
            0x7F,
            0x80,
            0x81,
            0xFE,
            0xFF,
          ]);
          final printer = EplPrinter()
            ..graphic(
              x: 10,
              y: 15,
              data: rawData,
              bytesPerRow: 7,
              height: 1,
              invert: true,
            );

          final output = printer.toBytes();
          final outputList = output.toList();

          final expectedHeader = ascii.encode('GW10,15,7,1\n');
          expect(
            outputList.sublist(0, expectedHeader.length),
            equals(expectedHeader),
          );

          // Inverted: [0xFF, 0xFE, 0x80, 0x7F, 0x7E, 0x01, 0x00]
          final expectedInverted = [0xFF, 0xFE, 0x80, 0x7F, 0x7E, 0x01, 0x00];
          final binaryPayload = outputList.sublist(
            expectedHeader.length,
            expectedHeader.length + 7,
          );
          expect(binaryPayload, equals(expectedInverted));
          expect(outputList.last, equals(0x0A));
        },
      );

      test('supports graphicFromMonochrome helper', () {
        final bmp = MonochromeBitmap(
          data: Uint8List.fromList([0xAA, 0x55]),
          width: 8,
          height: 2,
          bytesPerRow: 1,
        );

        final printer = EplPrinter()..graphicFromMonochrome(bmp, x: 5, y: 5);
        final output = printer.toBytes();
        final text = latin1.decode(output);
        expect(text, startsWith('GW5,5,1,2\n'));
      });
    });

    group('Raw Passthrough', () {
      test('emits rawBytes and rawAscii verbatim', () {
        final raw = Uint8List.fromList([0x4F, 0x44, 0x0A]); // OD\n
        final printer = EplPrinter()
          ..rawBytes(raw)
          ..rawAscii('UT', appendNewline: true);

        expect(
          printer.toBytes(),
          equals(Uint8List.fromList([...raw, ...ascii.encode('UT\n')])),
        );
      });
    });

    group('Validation & Boundary Rejection', () {
      test('validates negative coordinates and non-positive dimensions', () {
        expect(
          () => EplPrinter().text(x: -1, y: 0, text: 'a'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().text(x: 0, y: -1, text: 'a'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().labelWidth(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().labelLength(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().box(x: 0, y: 0, width: 0, height: 10),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().box(x: 0, y: 0, width: 10, height: 0),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates speed and density bounds', () {
        expect(() => EplPrinter().speed(0), throwsA(isA<InvalidConfigError>()));
        expect(() => EplPrinter().speed(7), throwsA(isA<InvalidConfigError>()));
        expect(
          () => EplPrinter().density(-1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().density(16),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates multipliers and QR cell width', () {
        expect(
          () => EplPrinter().text(x: 0, y: 0, text: 'a', xMultiplier: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().text(x: 0, y: 0, text: 'a', xMultiplier: 9),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().text(x: 0, y: 0, text: 'a', yMultiplier: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().text(x: 0, y: 0, text: 'a', yMultiplier: 10),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().qrCode(x: 0, y: 0, content: 'a', cellWidth: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => EplPrinter().qrCode(x: 0, y: 0, content: 'a', cellWidth: 10),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates graphic length', () {
        expect(
          () => EplPrinter().graphic(
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
                .text(
                  'SHIPPING LABEL',
                  const TextOptions(x: 10, y: 20, font: '3', size: 1),
                )
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

        final universalBytes = epl.compileBytes(labelBuilder);

        // Native equivalent:
        final nativePrinter = EplPrinter()
          ..clear()
          ..labelWidth(320)
          ..labelLength(240, gapDots: 24)
          ..speed(4)
          ..density(8)
          ..text(
            x: 10,
            y: 20,
            text: 'SHIPPING LABEL',
            font: EplFont.font3,
            rotation: EplRotation.unrotated,
            xMultiplier: 1,
            yMultiplier: 1,
          )
          ..box(x: 5, y: 5, width: 310, height: 230, thickness: 2)
          ..line(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2)
          ..barcode(
            x: 10,
            y: 100,
            type: EplBarcodeType.code128,
            height: 40,
            narrowBarWidth: 2,
            wideBarWidth: 4,
            humanReadable: false,
            content: '123456',
          )
          ..qrCode(
            x: 10,
            y: 160,
            cellWidth: 4,
            ecc: EplQrEcc.q,
            content: 'https://example.com',
          )
          ..print(sets: 2, copies: 1);

        expect(nativePrinter.toBytes(), equals(universalBytes));
      });
    });
  });
}
