import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/encoding.dart';
import 'package:portakal_core/src/errors.dart';
import 'package:portakal_core/src/lang/tsc.dart';
import 'package:portakal_core/src/native/tsc.dart';
import 'package:portakal_core/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('TscPrinter Native Builder', () {
    test('empty builder returns empty Uint8List snapshot without mutating', () {
      final tsc = TscPrinter();
      final bytes1 = tsc.toBytes();
      final bytes2 = tsc.toBytes();

      expect(bytes1, isEmpty);
      expect(bytes2, isEmpty);
    });

    test('reset clears accumulated buffer', () {
      final tsc = TscPrinter()
        ..sizeMm(widthMm: 40, heightMm: 30)
        ..clear();

      expect(tsc.toBytes(), isNotEmpty);
      tsc.reset();
      expect(tsc.toBytes(), isEmpty);
    });

    group('Page Setup Commands', () {
      test('emits exact SIZE in dots, mm, and inches', () {
        final tscDots = TscPrinter()..sizeDots(400, 300);
        expect(
          ascii.decode(tscDots.toBytes()),
          equals('SIZE 400 dot,300 dot\r\n'),
        );

        final tscMm = TscPrinter()..sizeMm(widthMm: 40, heightMm: 30);
        expect(ascii.decode(tscMm.toBytes()), equals('SIZE 40 mm,30 mm\r\n'));

        final tscInches = TscPrinter()
          ..sizeInches(widthInches: 4, heightInches: 3);
        expect(ascii.decode(tscInches.toBytes()), equals('SIZE 4,3\r\n'));
      });

      test('emits exact GAP in dots, mm, and continuous mode', () {
        final tscDots = TscPrinter()..gapDots(distanceDots: 24, offsetDots: 8);
        expect(ascii.decode(tscDots.toBytes()), equals('GAP 24 dot,8 dot\r\n'));

        final tscMm = TscPrinter()..gapMm(distanceMm: 3, offsetMm: 0);
        expect(ascii.decode(tscMm.toBytes()), equals('GAP 3 mm,0 mm\r\n'));

        final tscCont = TscPrinter()..gapContinuous();
        expect(ascii.decode(tscCont.toBytes()), equals('GAP 0 mm,0 mm\r\n'));
      });

      test('emits exact SPEED and DENSITY', () {
        final tsc = TscPrinter()
          ..speed(4)
          ..density(8);
        expect(ascii.decode(tsc.toBytes()), equals('SPEED 4\r\nDENSITY 8\r\n'));
      });

      test('emits exact DIRECTION with and without mirror', () {
        final tscNormal = TscPrinter()..direction(TscDirection.normal);
        expect(ascii.decode(tscNormal.toBytes()), equals('DIRECTION 0\r\n'));

        final tscReversed = TscPrinter()
          ..direction(TscDirection.reversed, mirror: true);
        expect(
          ascii.decode(tscReversed.toBytes()),
          equals('DIRECTION 1,1\r\n'),
        );
      });

      test('emits exact REFERENCE and SHIFT', () {
        final tsc = TscPrinter()
          ..reference(10, 20)
          ..shift(y: 15)
          ..shift(x: 5, y: 25);
        expect(
          ascii.decode(tsc.toBytes()),
          equals('REFERENCE 10,20\r\nSHIFT 15\r\nSHIFT 5,25\r\n'),
        );
      });

      test('emits exact CLS / clear', () {
        final tsc1 = TscPrinter()..clear();
        expect(ascii.decode(tsc1.toBytes()), equals('CLS\r\n'));

        final tsc2 = TscPrinter()..cls();
        expect(ascii.decode(tsc2.toBytes()), equals('CLS\r\n'));
      });

      test('emits BLINE and OFFSET', () {
        final tsc = TscPrinter()
          ..blineMm(heightMm: 2, offsetMm: 0)
          ..offsetMm(3);
        expect(
          ascii.decode(tsc.toBytes()),
          equals('BLINE 2 mm,0 mm\r\nOFFSET 3 mm\r\n'),
        );
      });
    });

    group('TscEncoding & Text Commands', () {
      test('emits basic ASCII text with resident font', () {
        final tsc = TscPrinter()
          ..text(
            x: 10,
            y: 20,
            font: TscResidentFont.font3,
            text: 'Hello TSC',
            xMultiplication: 2,
            yMultiplication: 2,
          );

        expect(
          ascii.decode(tsc.toBytes()),
          equals('TEXT 10,20,"3",0,2,2,"Hello TSC"\r\n'),
        );
      });

      test('emits text with alignment parameter when specified', () {
        final tsc = TscPrinter()
          ..text(
            x: 100,
            y: 50,
            font: TscResidentFont.font2,
            text: 'Centered',
            alignment: TscAlignment.center,
          );

        expect(
          ascii.decode(tsc.toBytes()),
          equals('TEXT 100,50,"2",0,1,1,2,"Centered"\r\n'),
        );
      });

      test('emits custom downloaded font name', () {
        final tsc = TscPrinter()
          ..text(
            x: 10,
            y: 20,
            font: const TscCustomFont('ROMAN.TTF'),
            text: 'Scalable TrueType',
          );

        expect(
          ascii.decode(tsc.toBytes()),
          equals('TEXT 10,20,"ROMAN.TTF",0,1,1,"Scalable TrueType"\r\n'),
        );
      });

      test('encodes extended characters with CP1252 and emits CODEPAGE 1252', () {
        final tsc = TscPrinter(encoding: const TscEncoding.cp1252())
          ..text(x: 0, y: 0, text: 'Café €50');

        final bytes = tsc.toBytes();
        final textPrefix = ascii.encode(
          'CODEPAGE 1252\r\nTEXT 0,0,"2",0,1,1,"',
        );
        final textSuffix = ascii.encode('"\r\n');

        expect(bytes.sublist(0, textPrefix.length), equals(textPrefix));
        expect(
          bytes.sublist(bytes.length - textSuffix.length),
          equals(textSuffix),
        );

        // Verify exact CP1252 byte representation:
        // 'C' (0x43), 'a' (0x61), 'f' (0x66), 'é' (0xE9), ' ' (0x20), '€' (0x80), '5' (0x35), '0' (0x30)
        final payload = bytes.sublist(
          textPrefix.length,
          bytes.length - textSuffix.length,
        );
        expect(
          payload,
          equals([0x43, 0x61, 0x66, 0xE9, 0x20, 0x80, 0x35, 0x30]),
        );
      });

      test('encodes extended characters with CP437', () {
        final tsc = TscPrinter(
          encoding: const TscEncoding.cp437(sendCodePageCommand: true),
        )..text(x: 0, y: 0, text: 'Café');

        final bytes = tsc.toBytes();
        final prefix = ascii.encode('CODEPAGE 437\r\nTEXT 0,0,"2",0,1,1,"');
        final suffix = ascii.encode('"\r\n');
        final payload = bytes.sublist(
          prefix.length,
          bytes.length - suffix.length,
        );

        // CP437: 'é' is 0x82
        expect(payload, equals([0x43, 0x61, 0x66, 0x82]));
      });

      test('encodes UTF-8 and emits CODEPAGE UTF-8', () {
        final tsc = TscPrinter(encoding: const TscEncoding.utf8())
          ..text(x: 0, y: 0, text: 'Café');

        final bytes = tsc.toBytes();
        final prefix = ascii.encode('CODEPAGE UTF-8\r\nTEXT 0,0,"2",0,1,1,"');
        final suffix = ascii.encode('"\r\n');
        final payload = bytes.sublist(
          prefix.length,
          bytes.length - suffix.length,
        );

        // UTF-8: 'é' is 0xC3, 0xA9
        expect(payload, equals([0x43, 0x61, 0x66, 0xC3, 0xA9]));
      });

      test('throws UnsupportedCharacterException on unencodable character', () {
        final tsc = TscPrinter(encoding: const TscEncoding.cp437());

        expect(
          () => tsc.text(x: 0, y: 0, text: 'Russian text: Привет'),
          throwsA(isA<UnsupportedCharacterException>()),
        );
      });

      test(
        'replaces unsupported character with ? when replaceUnsupported is true',
        () {
          final tsc = TscPrinter(
            encoding: const TscEncoding.cp437(replaceUnsupported: true),
          )..text(x: 0, y: 0, text: 'Ш');

          final bytes = tsc.toBytes();
          final prefix = ascii.encode('TEXT 0,0,"2",0,1,1,"');
          final suffix = ascii.encode('"\r\n');
          final payload = bytes.sublist(
            prefix.length,
            bytes.length - suffix.length,
          );

          expect(payload, equals([0x3F])); // '?'
        },
      );

      test(r'escapes double quotes as \["] per TSPL specification', () {
        final tsc = TscPrinter()..text(x: 10, y: 10, text: 'Item "Super" Box');

        expect(
          ascii.decode(tsc.toBytes()),
          equals(
            r'TEXT 10,10,"2",0,1,1,"Item \["]Super\["] Box"'
            '\r\n',
          ),
        );
      });

      test('rejects literal newline characters in single-line text', () {
        final tsc = TscPrinter();

        expect(
          () => tsc.text(x: 0, y: 0, text: 'Line 1\nLine 2'),
          throwsA(isA<InvalidConfigError>()),
        );

        expect(
          () => tsc.text(x: 0, y: 0, text: 'Line 1\rLine 2'),
          throwsA(isA<InvalidConfigError>()),
        );
      });
    });

    group('Barcodes & QR Codes', () {
      test('emits Code128 barcode with full parameters', () {
        final tsc = TscPrinter()
          ..barcode(
            x: 10,
            y: 50,
            type: TscBarcodeType.code128,
            height: 60,
            readable: TscBarcodeReadable.center,
            rotation: TscRotation.deg0,
            narrow: 2,
            wide: 4,
            alignment: TscAlignment.center,
            content: '12345678',
          );

        expect(
          ascii.decode(tsc.toBytes()),
          equals('BARCODE 10,50,"128",60,2,0,2,4,2,"12345678"\r\n'),
        );
      });

      test('escapes quotes in barcode content and rejects newlines', () {
        final tsc = TscPrinter()
          ..barcode(
            x: 0,
            y: 0,
            type: TscBarcodeType.code39,
            height: 40,
            content: 'CODE"39"',
          );

        expect(
          ascii.decode(tsc.toBytes()),
          equals(
            r'BARCODE 0,0,"39",40,0,0,2,4,"CODE\["]39\["]"'
            '\r\n',
          ),
        );

        expect(
          () => tsc.barcode(
            x: 0,
            y: 0,
            type: TscBarcodeType.code39,
            height: 40,
            content: 'ABC\n123',
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('emits QR code with ECC, cellWidth, model, and mask', () {
        final tsc = TscPrinter()
          ..qrCode(
            x: 10,
            y: 10,
            ecc: TscQrEcc.q,
            cellWidth: 5,
            mode: TscQrMode.auto,
            rotation: TscRotation.deg90,
            model: TscQrModel.m2,
            mask: 'S1',
            content: 'https://example.com',
          );

        expect(
          ascii.decode(tsc.toBytes()),
          equals(
            'QRCODE 10,10,"Q",5,"A",90,"M2","S1","https://example.com"\r\n',
          ),
        );
      });
    });

    group('Drawing Primitives', () {
      test('emits BOX with and without radius', () {
        final tsc1 = TscPrinter()
          ..box(x: 5, y: 5, xEnd: 300, yEnd: 200, thickness: 2);
        expect(ascii.decode(tsc1.toBytes()), equals('BOX 5,5,300,200,2\r\n'));

        final tsc2 = TscPrinter()
          ..box(x: 5, y: 5, xEnd: 300, yEnd: 200, thickness: 2, radius: 8);
        expect(ascii.decode(tsc2.toBytes()), equals('BOX 5,5,300,200,2,8\r\n'));
      });

      test('emits BAR', () {
        final tsc = TscPrinter()..bar(x: 10, y: 20, width: 100, height: 4);
        expect(ascii.decode(tsc.toBytes()), equals('BAR 10,20,100,4\r\n'));
      });

      test('emits CIRCLE, ELLIPSE, DIAGONAL, REVERSE, ERASE', () {
        final tsc = TscPrinter()
          ..circle(x: 100, y: 100, diameter: 50, thickness: 2)
          ..ellipse(x: 100, y: 100, width: 60, height: 40, thickness: 2)
          ..diagonal(x1: 10, y1: 20, x2: 100, y2: 200, thickness: 2)
          ..reverse(x: 10, y: 10, width: 200, height: 50)
          ..erase(x: 10, y: 10, width: 100, height: 30);

        expect(
          ascii.decode(tsc.toBytes()),
          equals(
            'CIRCLE 100,100,50,2\r\n'
            'ELLIPSE 100,100,60,40,2\r\n'
            'DIAGONAL 10,20,100,200,2\r\n'
            'REVERSE 10,10,200,50\r\n'
            'ERASE 10,10,100,30\r\n',
          ),
        );
      });
    });

    group('Bitmap Graphics', () {
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

        final tsc = TscPrinter()
          ..bitmap(
            x: 10,
            y: 20,
            data: rawData,
            bytesPerRow: 7,
            height: 1,
            mode: TscBitmapMode.overwrite,
          );

        final bytes = tsc.toBytes();
        final prefix = ascii.encode('BITMAP 10,20,7,1,0,');
        final suffix = ascii.encode('\r\n');

        final expectedFull = <int>[...prefix, ...rawData, ...suffix];
        expect(bytes, equals(Uint8List.fromList(expectedFull)));
      });

      test('validates bitmap length against bytesPerRow * height', () {
        final invalidData = Uint8List.fromList([
          0xFF,
          0x00,
        ]); // 2 bytes instead of 3

        final tsc = TscPrinter();
        expect(
          () => tsc.bitmap(
            x: 0,
            y: 0,
            data: invalidData,
            bytesPerRow: 1,
            height: 3, // expects 3 bytes
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('supports bitmapFromMonochrome helper', () {
        final bmp = MonochromeBitmap(
          data: Uint8List.fromList([0xAA, 0x55]),
          width: 8,
          height: 2,
          bytesPerRow: 1,
        );

        final tsc = TscPrinter()..bitmapFromMonochrome(bmp, x: 0, y: 0);
        final bytes = tsc.toBytes();
        final prefix = ascii.encode('BITMAP 0,0,1,2,0,');
        final suffix = ascii.encode('\r\n');

        expect(
          bytes,
          equals(Uint8List.fromList([...prefix, 0xAA, 0x55, ...suffix])),
        );
      });
    });

    group('Execution & Hardware Commands', () {
      test('emits PRINT with single and multiple copies', () {
        final tsc1 = TscPrinter()..print(sets: 1);
        expect(ascii.decode(tsc1.toBytes()), equals('PRINT 1\r\n'));

        final tsc2 = TscPrinter()..print(sets: 5, copies: 2);
        expect(ascii.decode(tsc2.toBytes()), equals('PRINT 5,2\r\n'));
      });

      test('emits FORMFEED, HOME, FEED, BACKFEED, CUT', () {
        final tsc = TscPrinter()
          ..formFeed()
          ..home()
          ..feed(50)
          ..backFeed(20)
          ..cut();

        expect(
          ascii.decode(tsc.toBytes()),
          equals(
            'FORMFEED\r\n'
            'HOME\r\n'
            'FEED 50\r\n'
            'BACKFEED 20\r\n'
            'CUT\r\n',
          ),
        );
      });

      test('emits SOUND with level and interval validation', () {
        final tsc = TscPrinter()..sound(level: 5, interval: 200);
        expect(ascii.decode(tsc.toBytes()), equals('SOUND 5,200\r\n'));

        expect(
          () => TscPrinter().sound(level: 10, interval: 100),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().sound(level: -1, interval: 100),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().sound(level: 5, interval: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().sound(level: 5, interval: 5000),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test(
        'emits immediate status request <ESC>!? (exact bytes 0x1B, 0x21, 0x3F without CRLF)',
        () {
          final tsc = TscPrinter()..requestStatus();
          final bytes = tsc.toBytes();

          expect(bytes, equals(Uint8List.fromList([0x1B, 0x21, 0x3F])));
          expect(bytes.length, equals(3));
        },
      );
    });

    group('Raw Commands & Escape Hatches', () {
      test('emits rawBytes verbatim', () {
        final rawHardwareBytes = Uint8List.fromList([0x1B, 0x21, 0x00, 0xFF]);
        final tsc = TscPrinter()..rawBytes(rawHardwareBytes);

        expect(tsc.toBytes(), equals(rawHardwareBytes));
      });

      test('emits rawAscii with and without newline', () {
        final tsc1 = TscPrinter()..rawAscii('AUTODETECT');
        expect(ascii.decode(tsc1.toBytes()), equals('AUTODETECT\r\n'));

        final tsc2 = TscPrinter()
          ..rawAscii('LIMITFEED 100', appendNewline: false);
        expect(ascii.decode(tsc2.toBytes()), equals('LIMITFEED 100'));
      });
    });

    group('Command Ordering & Sequential Determinism', () {
      test('preserves exact method call sequence in output byte stream', () {
        final tsc = TscPrinter()
          ..sizeMm(widthMm: 40, heightMm: 30)
          ..gapMm(distanceMm: 3)
          ..speed(4)
          ..density(8)
          ..direction(TscDirection.normal)
          ..clear()
          ..text(x: 10, y: 20, text: 'Hello')
          ..barcode(
            x: 10,
            y: 60,
            type: TscBarcodeType.code128,
            height: 40,
            content: '1234',
          )
          ..print();

        final expected =
            'SIZE 40 mm,30 mm\r\n'
            'GAP 3 mm,0 mm\r\n'
            'SPEED 4\r\n'
            'DENSITY 8\r\n'
            'DIRECTION 0\r\n'
            'CLS\r\n'
            'TEXT 10,20,"2",0,1,1,"Hello"\r\n'
            'BARCODE 10,60,"128",40,0,0,2,4,"1234"\r\n'
            'PRINT 1\r\n';

        expect(ascii.decode(tsc.toBytes()), equals(expected));
      });
    });

    group('Universal AST vs Native Builder Equivalence', () {
      test('produces identical byte stream for standard label layout', () {
        // Universal AST compilation
        final universalBytes = tsc.compileBytes(
          label(
                const LabelConfig(
                  width: 40,
                  height: 30,
                  speed: 4,
                  density: 8,
                  direction: 0,
                ),
              )
              .text(
                'TEST LABEL',
                const TextOptions(x: 10, y: 10, font: '2', size: 1),
              )
              .box(
                const BoxOptions(
                  x: 5,
                  y: 5,
                  width: 100,
                  height: 50,
                  thickness: 1,
                ),
              )
              .barcode(
                '12345678',
                const BarcodeOptions(x: 10, y: 70, type: '128', height: 30),
              )
              .qrcode(
                'https://example.com',
                const QRCodeOptions(x: 10, y: 120, cellWidth: 4),
              ),
        );

        // Native Builder compilation
        final nativeBytes =
            (TscPrinter()
                  ..sizeMm(widthMm: 40, heightMm: 30)
                  ..gapMm(distanceMm: 3, offsetMm: 0)
                  ..speed(4)
                  ..density(8)
                  ..direction(TscDirection.normal)
                  ..clear()
                  ..text(
                    x: 10,
                    y: 10,
                    font: TscResidentFont.font2,
                    text: 'TEST LABEL',
                  )
                  ..box(x: 5, y: 5, xEnd: 105, yEnd: 55, thickness: 1)
                  ..barcode(
                    x: 10,
                    y: 70,
                    type: TscBarcodeType.code128,
                    height: 30,
                    content: '12345678',
                  )
                  ..qrCode(
                    x: 10,
                    y: 120,
                    cellWidth: 4,
                    content: 'https://example.com',
                  )
                  ..print())
                .toBytes();

        expect(nativeBytes, equals(universalBytes));
      });
    });

    group('Validation & Boundary Rejection', () {
      test('rejects negative coordinates and invalid parameters', () {
        expect(
          () => TscPrinter().reference(-1, 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().reference(0, -1),
          throwsA(isA<InvalidConfigError>()),
        );

        expect(
          () => TscPrinter().sizeDots(0, 100),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().sizeMm(widthMm: -10, heightMm: 20),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().sizeInches(widthInches: 0, heightInches: 3),
          throwsA(isA<InvalidConfigError>()),
        );

        expect(() => TscPrinter().speed(0), throwsA(isA<InvalidConfigError>()));
        expect(
          () => TscPrinter().speed(-2),
          throwsA(isA<InvalidConfigError>()),
        );

        expect(
          () => TscPrinter().density(-1),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().density(16),
          throwsA(isA<InvalidConfigError>()),
        );

        expect(
          () => TscPrinter().text(x: -1, y: 0, text: 'Hi'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().text(x: 0, y: 0, text: 'Hi', xMultiplication: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().text(x: 0, y: 0, text: 'Hi', yMultiplication: 11),
          throwsA(isA<InvalidConfigError>()),
        );

        expect(
          () => TscPrinter().barcode(
            x: 0,
            y: 0,
            content: '123',
            type: TscBarcodeType.code128,
            height: 0,
          ),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().barcode(
            x: 0,
            y: 0,
            content: '123',
            type: TscBarcodeType.code128,
            height: 40,
            narrow: 0,
          ),
          throwsA(isA<InvalidConfigError>()),
        );

        expect(
          () => TscPrinter().qrCode(x: 0, y: 0, content: '123', cellWidth: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().qrCode(x: 0, y: 0, content: '123', cellWidth: 11),
          throwsA(isA<InvalidConfigError>()),
        );

        expect(
          () => TscPrinter().box(x: 0, y: 0, xEnd: 10, yEnd: 10, thickness: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().bar(x: 0, y: 0, width: 0, height: 10),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().circle(x: 0, y: 0, diameter: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().ellipse(x: 0, y: 0, width: 0, height: 10),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().reverse(x: 0, y: 0, width: 0, height: 10),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => TscPrinter().erase(x: 0, y: 0, width: 0, height: 10),
          throwsA(isA<InvalidConfigError>()),
        );

        expect(
          () => TscPrinter().print(sets: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(() => TscPrinter().feed(0), throwsA(isA<InvalidConfigError>()));
        expect(
          () => TscPrinter().backFeed(0),
          throwsA(isA<InvalidConfigError>()),
        );
      });
    });
  });
}
