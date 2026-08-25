import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/lang/escpos.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('ESC/POS compiler', () {
    test('starts with ESC @ (initialize)', () {
      final output = escpos.compile(label(LabelConfig(width: 80)));
      expect(output[0], equals(0x1B));
      expect(output[1], equals(0x40));
    });

    test('returns Uint8List', () {
      final output = escpos.compile(label(LabelConfig(width: 80)));
      expect(output, isA<Uint8List>());
    });

    test('generates text with line feed', () {
      final output = escpos.compile(
        label(LabelConfig(width: 80)).text('Hello ESC/POS'),
      );
      final text = utf8.decode(output, allowMalformed: true);
      expect(text, contains('Hello ESC/POS'));
    });

    test('generates bold on/off', () {
      final output = escpos.compile(
        label(LabelConfig(width: 80)).text('Bold', TextOptions(bold: true)),
      );
      final bytes = output.toList();
      // ESC E 1 (bold on)
      final onIdx = _findSequence(bytes, [0x1B, 0x45, 1]);
      expect(onIdx, greaterThan(-1));
      // ESC E 0 (bold off)
      final offIdx = _findSequence(bytes, [0x1B, 0x45, 0]);
      expect(offIdx, greaterThan(onIdx));
    });

    test('generates alignment (ESC a n)', () {
      final output = escpos.compile(
        label(
          LabelConfig(width: 80),
        ).text('Center', TextOptions(align: 'center')),
      );
      final bytes = output.toList();
      final idx = _findSequence(bytes, [0x1B, 0x61, 1]);
      expect(idx, greaterThan(-1));
    });

    test('generates GS ! for size magnification', () {
      final output = escpos.compile(
        label(LabelConfig(width: 80)).text('Big', TextOptions(size: 3)),
      );
      final bytes = output.toList();
      final idx = _findSequence(bytes, [0x1D, 0x21]);
      expect(idx, greaterThan(-1));
      expect(bytes[idx + 2], equals(0x22)); // (3-1)<<4 | (3-1) = 0x22
    });

    test('generates GS v 0 for raster image', () {
      final bitmap = MonochromeBitmap(
        data: Uint8List.fromList([0xFF, 0x00, 0xAA, 0x55]),
        width: 8,
        height: 4,
        bytesPerRow: 1,
      );
      final output = escpos.compile(
        label(LabelConfig(width: 80)).image(bitmap),
      );
      final bytes = output.toList();
      final idx = _findSequence(bytes, [0x1D, 0x76, 0x30, 0x00]);
      expect(idx, greaterThan(-1));
    });
  });
}

/// Find the index of a byte sequence in a list.
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
