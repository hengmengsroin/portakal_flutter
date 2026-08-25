import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/encoding.dart';
import 'package:portakal_flutter/src/errors.dart';
import 'package:portakal_flutter/src/lang/zpl.dart';
import 'package:portakal_flutter/src/native/zpl.dart';
import 'package:portakal_flutter/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('ZplPrinter Native Builder', () {
    test('empty builder returns empty snapshot without mutating', () {
      final printer = ZplPrinter();
      final bytes1 = printer.toBytes();
      final bytes2 = printer.toBytes();

      expect(bytes1, isEmpty);
      expect(bytes2, isEmpty);
    });

    test(
      'reset clears accumulated buffer, resets format state, and restores encoding',
      () {
        final printer = ZplPrinter()
          ..startFormat()
          ..text(x: 10, y: 10, text: 'Label')
          ..endFormat();

        expect(printer.toBytes(), isNotEmpty);
        expect(printer.inFormat, isFalse);

        printer.reset();
        expect(printer.toBytes(), isEmpty);
        expect(printer.inFormat, isFalse);
      },
    );

    group('Format Lifecycle', () {
      test('emits ^XA and ^CI28 for default UTF-8 encoding', () {
        final printer = ZplPrinter()
          ..startFormat()
          ..endFormat();
        expect(ascii.decode(printer.toBytes()), equals('^XA\n^CI28\n^XZ\n'));
      });

      test('emits ^XA without ^CI28 for legacy encoding', () {
        final printer = ZplPrinter(encoding: const ZplEncoding.legacy())
          ..startFormat()
          ..endFormat();
        expect(ascii.decode(printer.toBytes()), equals('^XA\n^XZ\n'));
      });

      test(
        'throws InvalidConfigError on nested startFormat or premature endFormat',
        () {
          final printer1 = ZplPrinter()..startFormat();
          expect(
            () => printer1.startFormat(),
            throwsA(isA<InvalidConfigError>()),
          );

          final printer2 = ZplPrinter();
          expect(
            () => printer2.endFormat(),
            throwsA(isA<InvalidConfigError>()),
          );
        },
      );
    });

    group('Encoding & CodePage', () {
      test('emits ^CI when characterInstruction is called', () {
        final printer = ZplPrinter()..characterInstruction(28);
        expect(ascii.decode(printer.toBytes()), equals('^CI28\n'));
      });

      test('encodes UTF-8 multi-byte characters accurately', () {
        final printer = ZplPrinter()
          ..startFormat()
          ..text(x: 10, y: 10, text: 'Café € Türkçe Ğş Привет')
          ..endFormat();

        final output = printer.toBytes();
        final text = utf8.decode(output);
        expect(text, contains('^FDCafé € Türkçe Ğş Привет^FS'));
      });
    });

    group('^FH Field Hex Escaping', () {
      test('escapes control chars ^ and ~ as _5E and _7E, and _ as _5F', () {
        final printer = ZplPrinter()
          ..startFormat()
          ..text(x: 10, y: 10, text: 'Item_41^~')
          ..endFormat();

        final text = utf8.decode(printer.toBytes());
        expect(text, contains('^FH^FDItem_5F41_5E_7E^FS'));
      });

      test('plain underscore without control chars does not trigger ^FH', () {
        final printer = ZplPrinter()
          ..startFormat()
          ..text(x: 10, y: 10, text: 'Item_41')
          ..endFormat();

        final text = utf8.decode(printer.toBytes());
        expect(text, contains('^FDItem_41^FS'));
        expect(text, isNot(contains('^FH')));
      });
    });

    group('Field Positioning & Granular Lifecycle', () {
      test(
        'emits granular field positioning, font, block, reverse, data, and separator',
        () {
          final printer = ZplPrinter()
            ..startFormat()
            ..fieldOrigin(50, 100)
            ..font(
              font: ZplFont.font0,
              rotation: ZplRotation.rotated90,
              height: 40,
              width: 30,
            )
            ..fieldBlock(
              width: 200,
              maxLines: 2,
              lineSpacing: 5,
              align: 'C',
              hangingIndent: 10,
            )
            ..fieldReverse()
            ..fieldData('Granular Block')
            ..fieldSeparator()
            ..endFormat();

          final text = utf8.decode(printer.toBytes());
          expect(
            text,
            contains(
              '^FO50,100^A0R,40,30^FB200,2,5,C,10^FR^FDGranular Block^FS\n',
            ),
          );
        },
      );

      test('emits fieldTypeset (^FT)', () {
        final printer = ZplPrinter()
          ..startFormat()
          ..fieldTypeset(100, 200)
          ..font(font: ZplFont.fontA, height: 20)
          ..fieldData('Baseline Text')
          ..fieldSeparator()
          ..endFormat();

        final text = utf8.decode(printer.toBytes());
        expect(text, contains('^FT100,200^AAN,20,20^FDBaseline Text^FS\n'));
      });
    });

    group('High-Level Text Helper', () {
      test('emits complete text field with origin and typeset modes', () {
        final printer = ZplPrinter()
          ..startFormat()
          ..text(
            x: 10,
            y: 20,
            text: 'Hello ZPL',
            font: ZplFont.font0,
            height: 30,
          )
          ..text(
            x: 10,
            y: 80,
            text: 'Typeset Text',
            positionMode: ZplPositionMode.typeset,
            maxWidth: 300,
            align: 'center',
            reverse: true,
          )
          ..endFormat();

        final text = utf8.decode(printer.toBytes());
        expect(text, contains('^FO10,20^A0N,30,30^FDHello ZPL^FS\n'));
        expect(
          text,
          contains('^FT10,80^A0N,30,30^FB300,1,0,C,0^FR^FDTypeset Text^FS\n'),
        );
      });
    });

    group('Barcodes & QR Codes', () {
      test('emits Code128 and Code39 barcodes', () {
        final printer = ZplPrinter()
          ..startFormat()
          ..barcode(
            x: 10,
            y: 20,
            content: '123456',
            type: ZplBarcodeType.code128,
            height: 60,
            interpretationLine: true,
          )
          ..barcode(
            x: 10,
            y: 100,
            content: 'CODE39',
            type: ZplBarcodeType.code39,
            height: 50,
            interpretationLine: false,
          )
          ..endFormat();

        final text = utf8.decode(printer.toBytes());
        expect(text, contains('^FO10,20^BCN,60,Y,N,N,N^FD123456^FS\n'));
        expect(text, contains('^FO10,100^B3N,50,N,N,N^FDCODE39^FS\n'));
      });

      test(
        'emits QR code with magnification boundaries (1 and 100) and mask (0..7)',
        () {
          final printer = ZplPrinter()
            ..startFormat()
            ..qrCode(
              x: 10,
              y: 20,
              content: 'https://example.com',
              magnification: 1,
              ecc: ZplQrEcc.h,
              model: ZplQrModel.model2,
              mask: 0,
            )
            ..qrCode(
              x: 10,
              y: 150,
              content: 'https://example.com/max',
              magnification: 100,
              ecc: ZplQrEcc.q,
              model: ZplQrModel.model2,
              mask: 7,
            )
            ..endFormat();

          final text = utf8.decode(printer.toBytes());
          expect(
            text,
            contains('^FO10,20^BQN,2,1,H,0^FDQA,https://example.com^FS\n'),
          );
          expect(
            text,
            contains(
              '^FO10,150^BQN,2,100,Q,7^FDQA,https://example.com/max^FS\n',
            ),
          );
        },
      );
    });

    group('Graphics & Drawing Primitives', () {
      test('emits ^GFA with uppercase ASCII hex representation', () {
        final rawData = Uint8List.fromList([0x00, 0x7F, 0x80, 0xFF]);
        final printer = ZplPrinter()
          ..startFormat()
          ..graphicField(x: 10, y: 10, data: rawData, bytesPerRow: 2, height: 2)
          ..endFormat();

        final text = utf8.decode(printer.toBytes());
        expect(text, contains('^FO10,10^GFA,4,4,2,007F80FF^FS\n'));
      });

      test('supports graphicFieldFromMonochrome helper', () {
        final bmp = MonochromeBitmap(
          data: Uint8List.fromList([0xAA, 0x55]),
          width: 8,
          height: 2,
          bytesPerRow: 1,
        );

        final printer = ZplPrinter()
          ..startFormat()
          ..graphicFieldFromMonochrome(bmp, x: 5, y: 5)
          ..endFormat();

        final text = utf8.decode(printer.toBytes());
        expect(text, contains('^FO5,5^GFA,2,2,1,AA55^FS\n'));
      });

      test('emits box, lines, circle, and erase', () {
        final printer = ZplPrinter()
          ..startFormat()
          ..box(x: 5, y: 5, width: 100, height: 50, thickness: 2, radius: 3)
          ..line(x1: 10, y1: 10, x2: 100, y2: 10, thickness: 2) // horizontal
          ..line(x1: 10, y1: 10, x2: 10, y2: 100, thickness: 2) // vertical
          ..line(x1: 10, y1: 10, x2: 100, y2: 100, thickness: 2) // diagonal
          ..circle(x: 50, y: 50, diameter: 40, thickness: 2)
          ..erase(x: 10, y: 10, width: 50, height: 30)
          ..endFormat();

        final text = utf8.decode(printer.toBytes());
        expect(text, contains('^FO5,5^GB100,50,2,B,3^FS\n'));
        expect(text, contains('^FO10,10^GB90,2,2,B,0^FS\n')); // horizontal
        expect(text, contains('^FO10,10^GB2,90,2,B,0^FS\n')); // vertical
        expect(text, contains('^FO10,10^GD90,90,2,B,R^FS\n')); // diagonal
        expect(text, contains('^FO50,50^GC40,2,B^FS\n'));
        expect(text, contains('^FO10,10^GB50,30,50,W,0^FS\n')); // erase
      });
    });

    group('Printer Configuration & Print Quantity', () {
      test('emits ^PW, ^LL, ^PR', () {
        final printer = ZplPrinter()
          ..startFormat()
          ..printWidth(800)
          ..labelLength(1200)
          ..speed(6)
          ..endFormat();

        final text = utf8.decode(printer.toBytes());
        expect(text, contains('^PW800\n'));
        expect(text, contains('^LL1200\n'));
        expect(text, contains('^PR6\n'));
      });

      test(
        'emits integer darkness (~SD15, ~SD00) and fractional darkness (~SD8.3)',
        () {
          final p1 = ZplPrinter()..darkness(15.0);
          expect(ascii.decode(p1.toBytes()), equals('~SD15\n'));

          final p2 = ZplPrinter()..darkness(0.0);
          expect(ascii.decode(p2.toBytes()), equals('~SD00\n'));

          final p3 = ZplPrinter()..darkness(8.3);
          expect(ascii.decode(p3.toBytes()), equals('~SD8.3\n'));
        },
      );

      test('emits named ^PQ parameters', () {
        final p1 = ZplPrinter()..printQuantity(copies: 5);
        expect(ascii.decode(p1.toBytes()), equals('^PQ5\n'));

        final p2 = ZplPrinter()
          ..printQuantity(
            copies: 5,
            pauseAndCut: 2,
            replicates: 1,
            overridePause: true,
          );
        expect(ascii.decode(p2.toBytes()), equals('^PQ5,2,1,Y\n'));
      });
    });

    group('Raw Passthrough', () {
      test('emits rawBytes and rawAscii verbatim', () {
        final raw = Uint8List.fromList([
          0x5E,
          0x4D,
          0x4D,
          0x54,
          0x0A,
        ]); // ^MMT\n
        final printer = ZplPrinter()
          ..rawBytes(raw)
          ..rawAscii('^JUS', appendNewline: true);

        expect(
          printer.toBytes(),
          equals(Uint8List.fromList([...raw, ...ascii.encode('^JUS\n')])),
        );
      });
    });

    group('Validation & Boundary Checking', () {
      test('validates QR magnification (1..100) and mask (0..7)', () {
        expect(
          () => ZplPrinter().qrCode(x: 0, y: 0, content: 'x', magnification: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () =>
              ZplPrinter().qrCode(x: 0, y: 0, content: 'x', magnification: 101),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => ZplPrinter().qrCode(x: 0, y: 0, content: 'x', mask: -1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => ZplPrinter().qrCode(x: 0, y: 0, content: 'x', mask: 8),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates darkness range (0.0..30.0)', () {
        expect(
          () => ZplPrinter().darkness(-0.1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => ZplPrinter().darkness(30.1),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates print quantity ranges', () {
        expect(
          () => ZplPrinter().printQuantity(copies: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => ZplPrinter().printQuantity(copies: 100000000),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => ZplPrinter().printQuantity(pauseAndCut: -1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => ZplPrinter().printQuantity(replicates: -1),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates coordinates and dimensions', () {
        expect(
          () => ZplPrinter().fieldOrigin(-1, 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => ZplPrinter().fieldTypeset(0, -1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => ZplPrinter().box(x: 0, y: 0, width: 0, height: 10),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => ZplPrinter().circle(x: 0, y: 0, diameter: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => ZplPrinter().font(height: 0),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates graphic data length', () {
        expect(
          () => ZplPrinter().graphicField(
            x: 0,
            y: 0,
            data: Uint8List.fromList([0xFF]),
            bytesPerRow: 2,
            height: 2, // expects 4 bytes
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });
    });

    group('Universal AST vs Native Equivalence', () {
      test('produces identical output for standard label block', () {
        final labelBuilder =
            label(
                  const LabelConfig(
                    width: 40,
                    height: 30,
                    speed: 4,
                    density: 15,
                  ),
                )
                .text(
                  'SHIPPING LABEL',
                  const TextOptions(x: 10, y: 10, size: 2),
                )
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
                )
                .qrcode(
                  'https://example.com',
                  const QRCodeOptions(x: 10, y: 100, cellWidth: 4),
                );

        final universalBytes = zpl.compileBytes(
          labelBuilder,
          encoding: const ZplEncoding.utf8(),
        );

        // Native equivalent:
        final nativePrinter = ZplPrinter(encoding: const ZplEncoding.utf8())
          ..startFormat()
          ..printWidth(320)
          ..labelLength(240)
          ..speed(4)
          ..darkness(15.0)
          ..text(
            x: 10,
            y: 10,
            text: 'SHIPPING LABEL',
            font: ZplFont.font0,
            height: 60, // size 2 * 30 = 60
          )
          ..box(x: 5, y: 5, width: 200, height: 100, thickness: 2)
          ..barcode(
            x: 10,
            y: 50,
            type: ZplBarcodeType.code128,
            height: 40,
            content: '123456',
          )
          ..qrCode(
            x: 10,
            y: 100,
            magnification: 4,
            ecc: ZplQrEcc.q,
            content: 'https://example.com',
          )
          ..printQuantity(copies: 1)
          ..endFormat();

        expect(nativePrinter.toBytes(), equals(universalBytes));
      });
    });
  });
}
