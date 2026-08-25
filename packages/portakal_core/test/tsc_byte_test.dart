import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/lang/tsc.dart';
import 'package:portakal_core/src/languages/tsc.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('TSC Byte-Native Compiler', () {
    test('generates exact ASCII bytes for basic label structure', () {
      final resolved = label(
        const LabelConfig(width: 40, height: 30, speed: 4, density: 8),
      ).resolve();

      final bytes = compileToTSCBytes(resolved);

      final expectedString = 'SIZE 40 mm,30 mm\r\n'
          'GAP 3 mm,0 mm\r\n'
          'SPEED 4\r\n'
          'DENSITY 8\r\n'
          'DIRECTION 0\r\n'
          'CLS\r\n'
          'PRINT 1\r\n';

      expect(bytes, equals(Uint8List.fromList(ascii.encode(expectedString))));
    });

    test('preserves exact BITMAP binary bytes across full 0x00..0xFF range',
        () {
      // 7-byte raw payload including 0x00, 0x7F, 0x80, 0xFF
      final rawBitmapData = Uint8List.fromList([
        0x00,
        0x01,
        0x7F,
        0x80,
        0x81,
        0xFE,
        0xFF,
      ]);

      final bitmap = MonochromeBitmap(
        data: rawBitmapData,
        width: 56, // 7 bytes * 8 bits
        height: 1,
        bytesPerRow: 7,
      );

      final resolved = label(
        const LabelConfig(width: 40, height: 30),
      ).image(bitmap, const ImageOptions(x: 10, y: 20)).resolve();

      final bytes = compileToTSCBytes(resolved);

      // Verify the output has the exact sequence:
      // ASCII header -> rawBitmapData -> \r\n
      final expectedPrefix = ascii.encode('BITMAP 10,20,7,1,0,');
      final expectedSuffix = ascii.encode('\r\n');

      final expectedFullBitmapCommand = <int>[
        ...expectedPrefix,
        ...rawBitmapData,
        ...expectedSuffix,
      ];

      expect(
        _containsSubsequence(bytes, expectedFullBitmapCommand),
        isTrue,
        reason:
            'Raw binary bitmap bytes must appear verbatim in the output stream',
      );

      // Also verify via tsc.compileBytes facade
      final facadeBytes = tsc.compileBytes(
        label(
          const LabelConfig(width: 40, height: 30),
        ).image(bitmap, const ImageOptions(x: 10, y: 20)),
      );
      expect(facadeBytes, equals(bytes));
    });

    test(
      'preserves byte-for-byte equivalence with legacy compileToTSC for text commands',
      () {
        final myLabel = label(const LabelConfig(width: 50, height: 40))
            .text(
              'Hello TSC',
              const TextOptions(x: 10, y: 10, font: '3', size: 2),
            )
            .box(
              const BoxOptions(
                x: 5,
                y: 5,
                width: 300,
                height: 200,
                thickness: 2,
              ),
            )
            .line(
              const LineOptions(x1: 5, y1: 50, x2: 305, y2: 50, thickness: 1),
            )
            .circle(
              const CircleOptions(x: 200, y: 100, diameter: 30, thickness: 1),
            )
            .barcode(
              '12345678',
              const BarcodeOptions(x: 10, y: 60, type: '128', height: 40),
            )
            .qrcode('https://example.com', const QRCodeOptions(x: 10, y: 120))
            .reverse(const ReverseOptions(x: 0, y: 0, width: 100, height: 20))
            .erase(const EraseOptions(x: 0, y: 0, width: 50, height: 10));

        final stringOutput = compileToTSC(myLabel.resolve());
        final byteOutput = compileToTSCBytes(myLabel.resolve());

        // For non-binary commands, latin1/ascii encoding of stringOutput equals byteOutput
        expect(
          byteOutput,
          equals(Uint8List.fromList(latin1.encode(stringOutput))),
        );
      },
    );

    test('supports raw binary passthrough in RawElement', () {
      final rawHardwareBytes = Uint8List.fromList([0x1B, 0x21, 0x00, 0xFF]);

      final resolved = label(
        const LabelConfig(width: 40, height: 30),
      ).raw(rawHardwareBytes).resolve();

      final bytes = compileToTSCBytes(resolved);
      expect(_containsSubsequence(bytes, rawHardwareBytes), isTrue);
    });
  });
}

bool _containsSubsequence(List<int> source, List<int> target) {
  if (target.isEmpty) return true;
  if (source.length < target.length) return false;
  for (int i = 0; i <= source.length - target.length; i++) {
    bool match = true;
    for (int j = 0; j < target.length; j++) {
      if (source[i + j] != target[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}
