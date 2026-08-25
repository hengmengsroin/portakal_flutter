import 'dart:convert';
import 'dart:typed_data';

import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/encoding.dart';
import 'package:portakal_flutter/src/errors.dart';
import 'package:portakal_flutter/src/lang/sbpl.dart';
import 'package:portakal_flutter/src/native/sbpl.dart';
import 'package:portakal_flutter/src/parsers/sbpl.dart';
import 'package:portakal_flutter/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('SbplPrinter Native Builder', () {
    test('empty builder returns empty snapshot without mutating', () {
      final printer = SbplPrinter();
      final bytes1 = printer.toBytes();
      final bytes2 = printer.toBytes();

      expect(bytes1, isEmpty);
      expect(bytes2, isEmpty);
    });

    test('reset clears accumulated buffer and restores encoding', () {
      final printer = SbplPrinter()
        ..startJob()
        ..text(x: 10, y: 10, text: 'Label')
        ..endJob();

      expect(printer.toBytes(), isNotEmpty);

      printer.reset();
      expect(printer.toBytes(), isEmpty);
    });

    group('Job Framing & Control Sequences', () {
      test('startJob() emits exact ESC A only (not ESC CS)', () {
        final printer = SbplPrinter()..startJob();
        final output = printer.toBytes().toList();

        // Exact ESC A [0x1B, 0x41]
        expect(output, equals([0x1B, 0x41]));

        // Regression: startJob must NOT emit ESC CS
        expect(_findSequence(output, [0x1B, 0x43, 0x53]), equals(-1));
      });

      test('speed() emits exact ESC CS<speed> sequence', () {
        final printer = SbplPrinter()..speed(4);
        final output = printer.toBytes().toList();

        // Exact ESC CS4 [0x1B, 0x43, 0x53, 0x34]
        expect(output, equals([0x1B, 0x43, 0x53, 0x34]));
      });

      test(
        'emits exact ESC A, ESC CS<speed>, ESC Q, ESC Z control sequences in job',
        () {
          final printer = SbplPrinter()
            ..startJob()
            ..speed(5)
            ..copies(3)
            ..endJob();

          final output = printer.toBytes().toList();

          // Starts with ESC A [0x1B, 0x41]
          expect(output.sublist(0, 2), equals([0x1B, 0x41]));

          // Speed ESC CS5 -> [0x1B, 0x43, 0x53, 0x35]
          expect(
            _findSequence(output, [0x1B, 0x43, 0x53, 0x35]),
            greaterThan(-1),
          );

          // ESC Q3 -> [0x1B, 0x51, 0x33]
          expect(_findSequence(output, [0x1B, 0x51, 0x33]), greaterThan(-1));

          // Ends with ESC Z -> [0x1B, 0x5A]
          expect(output.sublist(output.length - 2), equals([0x1B, 0x5A]));
        },
      );

      test(
        'regression: never emits literal printable placeholder text for ESC/A/Z/Q',
        () {
          final printer = SbplPrinter()
            ..startJob()
            ..speed(4)
            ..copies(2)
            ..endJob();

          final output = printer.toBytes().toList();
          expect(_findSequence(output, ascii.encode('<ESC>')), equals(-1));
          expect(_findSequence(output, ascii.encode('<A>')), equals(-1));
          expect(_findSequence(output, ascii.encode('<Z>')), equals(-1));
          expect(_findSequence(output, ascii.encode('<Q>')), equals(-1));
        },
      );
    });

    group('Positioning & Geometry', () {
      test(
        'emits exact 4-digit zero-padded H, V coordinates and FW primitives',
        () {
          final printer = SbplPrinter()
            ..box(x: 10, y: 20, width: 200, height: 100, thickness: 2)
            ..line(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2)
            ..line(x1: 50, y1: 10, x2: 50, y2: 200, thickness: 1);

          final text = latin1.decode(printer.toBytes());

          // Box: ESC H0010 ESC V0020 ESC FW02V0100H0200
          expect(text, contains('\x1bH0010\x1bV0020\x1bFW02V0100H0200'));

          // Horizontal line: ESC H0010 ESC V0050 ESC FW02H0290
          expect(text, contains('\x1bH0010\x1bV0050\x1bFW02H0290'));

          // Vertical line: ESC H0050 ESC V0010 ESC FW01V0190
          expect(text, contains('\x1bH0050\x1bV0010\x1bFW01V0190'));
        },
      );
    });

    group('Text & Font & Magnification & Rotation', () {
      test('emits text with positioning, magnification, and font code', () {
        final printer = SbplPrinter()
          ..text(
            x: 100,
            y: 50,
            text: 'Hello SATO',
            widthMag: 2,
            heightMag: 2,
            font: SbplFont.k9b,
          );

        final text = latin1.decode(printer.toBytes());
        expect(text, equals('\x1bH0100\x1bV0050\x1bL0202\x1bK9BHello SATO'));
      });

      test('wraps rotated text in ESC % and resets with ESC %0', () {
        final printer = SbplPrinter()
          ..text(
            x: 10,
            y: 20,
            text: 'Rotated',
            rotation: SbplRotation.rotated90,
          );

        final text = latin1.decode(printer.toBytes());
        expect(text, contains('\x1b%1\x1bL0101\x1bK9BRotated\x1b%0'));
      });

      test('encodes extended characters in CP437 (Café)', () {
        final printer = SbplPrinter()..text(x: 10, y: 20, text: 'Café');

        final expectedSequence = <int>[
          ...ascii.encode('\x1bK9BCaf'),
          0x82, // 'é' in CP437
        ];

        expect(
          _findSequence(printer.toBytes().toList(), expectedSequence),
          greaterThan(-1),
        );
      });

      test('rejects dangerous ESC (0x1B) character inside text', () {
        expect(
          () => SbplPrinter().text(x: 0, y: 0, text: 'Inject\x1bZ'),
          throwsA(isA<UnsupportedCharacterException>()),
        );
      });

      test(
        'replaces unsupported characters when replaceUnsupported is enabled',
        () {
          final printer = SbplPrinter(
            encoding: const SbplEncoding.legacy(replaceUnsupported: true),
          )..text(x: 0, y: 0, text: 'Inject\x1bZ');

          final text = latin1.decode(printer.toBytes());
          expect(text, contains('\x1bK9BInject?Z'));
        },
      );

      test('switches encoding mid-stream with encoding()', () {
        final printer = SbplPrinter()
          ..text(x: 10, y: 10, text: 'First')
          ..encoding(const SbplEncoding.cp1252())
          ..text(x: 10, y: 50, text: 'Second');

        expect(printer.toBytes(), isNotEmpty);
      });
    });

    group('Barcodes & QR Codes', () {
      test('emits 1D barcode for Code 39 and Code 128', () {
        final printer = SbplPrinter()
          ..barcode(
            x: 10,
            y: 20,
            content: '123456',
            height: 40,
            narrow: 2,
            type: SbplBarcodeType.code128,
          )
          ..barcode(
            x: 10,
            y: 70,
            content: 'CODE39',
            height: 40,
            narrow: 2,
            type: SbplBarcodeType.code39,
          );

        final text = latin1.decode(printer.toBytes());
        expect(text, contains('\x1bV20\x1bH10\x1bBG20040123456'));
        expect(text, contains('\x1bV70\x1bH10\x1bB120040CODE39'));
      });

      test('emits 2D QR Code with BQ command and model 2 framing', () {
        final printer = SbplPrinter()
          ..qrCode(x: 10, y: 80, content: 'https://example.com', cellWidth: 4);

        final text = latin1.decode(printer.toBytes());
        expect(text, equals('\x1bV80\x1bH10\x1bBQ04200https://example.com'));
      });
    });

    group('Raw Passthrough & Parser Compatibility', () {
      test('emits rawBytes and rawAscii verbatim', () {
        final raw = Uint8List.fromList([0x1B, 0x4B, 0x43, 0x32]);
        final printer = SbplPrinter()
          ..rawBytes(raw)
          ..rawAscii('\x1bKC1');

        final text = latin1.decode(printer.toBytes());
        expect(text, contains('\x1bKC2'));
        expect(text, contains('\x1bKC1'));
      });

      test('native output is parsed cleanly by parseSBPL', () {
        final printer = SbplPrinter()
          ..startJob()
          ..text(x: 100, y: 50, text: 'Parsed Text')
          ..endJob();

        final parsed = parseSBPL(latin1.decode(printer.toBytes()));

        expect(parsed.commands.length, greaterThanOrEqualTo(3));
        expect(parsed.elements.length, equals(1));
        expect(parsed.elements[0], isA<TextElement>());
        expect(
          (parsed.elements[0] as TextElement).content,
          equals('Parsed Text'),
        );
        expect((parsed.elements[0] as TextElement).options.x, equals(100));
        expect((parsed.elements[0] as TextElement).options.y, equals(50));
      });
    });

    group('Validation & Boundary Rejection', () {
      test('validates negative coordinates and non-positive dimensions', () {
        expect(
          () => SbplPrinter().text(x: -1, y: 0, text: 'a'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => SbplPrinter().text(x: 0, y: -1, text: 'a'),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => SbplPrinter().box(x: 0, y: 0, width: 0, height: 10),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => SbplPrinter().box(x: 0, y: 0, width: 10, height: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => SbplPrinter().box(
            x: 0,
            y: 0,
            width: 10,
            height: 10,
            thickness: 0,
          ),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates magnification bounds (1..99)', () {
        expect(
          () => SbplPrinter().text(x: 0, y: 0, text: 'a', widthMag: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => SbplPrinter().text(x: 0, y: 0, text: 'a', widthMag: 100),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => SbplPrinter().text(x: 0, y: 0, text: 'a', heightMag: 0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => SbplPrinter().text(x: 0, y: 0, text: 'a', heightMag: 100),
          throwsA(isA<InvalidConfigError>()),
        );
      });

      test('validates speed bounds and copy count', () {
        expect(
          () => SbplPrinter().speed(0),
          throwsA(isA<InvalidConfigError>()),
        );
        expect(
          () => SbplPrinter().copies(0),
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
                .text('SATO LABEL', const TextOptions(x: 100, y: 50, size: 2))
                .box(
                  const BoxOptions(
                    x: 10,
                    y: 20,
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
                  const BarcodeOptions(x: 10, y: 20, type: '128', height: 40),
                )
                .qrcode(
                  'https://example.com',
                  const QRCodeOptions(x: 10, y: 80, cellWidth: 4),
                );

        final universalBytes = sbpl.compileBytes(labelBuilder);

        // Native equivalent:
        final nativePrinter = SbplPrinter()
          ..startJob()
          ..speed(4)
          ..text(
            x: 100,
            y: 50,
            text: 'SATO LABEL',
            widthMag: 2,
            heightMag: 2,
            font: SbplFont.k9b,
          )
          ..box(x: 10, y: 20, width: 200, height: 100, thickness: 2)
          ..line(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2)
          ..barcode(
            x: 10,
            y: 20,
            content: '123456',
            height: 40,
            narrow: 2,
            type: SbplBarcodeType.code128,
          )
          ..qrCode(x: 10, y: 80, content: 'https://example.com', cellWidth: 4)
          ..copies(2)
          ..endJob();

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
