import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/lang/starprnt.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('Star PRNT compiler', () {
    test('starts with ESC @ (initialize)', () {
      final output = starprnt.compile(label(LabelConfig(width: 80)));
      expect(output[0], equals(0x1B));
      expect(output[1], equals(0x40));
    });

    test('returns Uint8List', () {
      final output = starprnt.compile(label(LabelConfig(width: 80)));
      expect(output, isA<Uint8List>());
    });

    test('ends with partial cut (ESC d 1)', () {
      final output = starprnt.compile(label(LabelConfig(width: 80)));
      final bytes = output.toList();
      final len = bytes.length;
      expect(bytes[len - 3], equals(0x1B));
      expect(bytes[len - 2], equals(0x64));
      expect(bytes[len - 1], equals(1));
    });

    test('generates text with line feed', () {
      final output = starprnt.compile(
        label(LabelConfig(width: 80)).text('Hello Star'),
      );
      final text = utf8.decode(output, allowMalformed: true);
      expect(text, contains('Hello Star'));
    });

    test('generates Star alignment: ESC GS a n', () {
      final output = starprnt.compile(
        label(
          LabelConfig(width: 80),
        ).text('Center', TextOptions(align: 'center')),
      );
      final bytes = output.toList();
      // ESC GS a 1 (center)
      final idx = _findSequence(bytes, [0x1B, 0x1D, 0x61]);
      expect(idx, greaterThan(-1));
      expect(bytes[idx + 3], equals(1));
    });

    test('generates Star bold: ESC E (on) / ESC F (off)', () {
      final output = starprnt.compile(
        label(LabelConfig(width: 80)).text('Bold', TextOptions(bold: true)),
      );
      final bytes = output.toList();
      // ESC E (bold on)
      final onIdx = _findSequence(bytes, [0x1B, 0x45]);
      expect(onIdx, greaterThan(-1));
      // ESC F (bold off)
      final offIdx = _findSequence(bytes, [0x1B, 0x46]);
      expect(offIdx, greaterThan(onIdx));
    });

    test('generates Star size: ESC i h w', () {
      final output = starprnt.compile(
        label(LabelConfig(width: 80)).text('Big', TextOptions(size: 3)),
      );
      final bytes = output.toList();
      final idx = _findSequence(bytes, [0x1B, 0x69]);
      expect(idx, greaterThan(-1));
      expect(bytes[idx + 2], equals(3)); // height
      expect(bytes[idx + 3], equals(3)); // width
    });

    test('generates Star raster mode for images', () {
      final bitmap = MonochromeBitmap(
        data: Uint8List.fromList([0xFF, 0x00, 0xAA, 0x55]),
        width: 8,
        height: 4,
        bytesPerRow: 1,
      );
      final output = starprnt.compile(
        label(LabelConfig(width: 80)).image(bitmap),
      );
      final bytes = output.toList();

      // Enter raster: ESC * r A
      final enterIdx = _findSequence(bytes, [0x1B, 0x2A, 0x72, 0x41]);
      expect(enterIdx, greaterThan(-1));

      // Exit raster: ESC * r B
      final exitIdx = _findSequence(bytes, [0x1B, 0x2A, 0x72, 0x42]);
      expect(exitIdx, greaterThan(enterIdx));

      // Should have 4 'b' commands (one per row)
      int bCount = 0;
      for (int i = enterIdx + 4; i < exitIdx; i++) {
        if (bytes[i] == 0x62) bCount++;
      }
      expect(bCount, equals(4));
    });

    test('generates raw passthrough', () {
      final raw = Uint8List.fromList([0x07]); // BEL (cash drawer)
      final output = starprnt.compile(label(LabelConfig(width: 80)).raw(raw));
      expect(output.toList(), contains(0x07));
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
