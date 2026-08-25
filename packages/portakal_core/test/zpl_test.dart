import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/lang/zpl.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  group('ZPL compiler', () {
    test('generates ^XA and ^XZ', () {
      final output = zpl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('^XA'));
      expect(output, contains('^XZ'));
    });

    test('generates ^PW and ^LL', () {
      final output = zpl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('^PW320'));
      expect(output, contains('^LL240'));
    });

    test('generates ^FO position', () {
      final output = zpl.compile(
        label(
          LabelConfig(width: 40, height: 30),
        ).text('Hello', TextOptions(x: 50, y: 100)),
      );
      expect(output, contains('^FO50,100'));
    });

    test('generates ^FD...^FS text', () {
      final output = zpl.compile(
        label(
          LabelConfig(width: 40, height: 30),
        ).text('Hello ZPL', TextOptions(x: 10, y: 10)),
      );
      expect(output, contains('^FDHello ZPL^FS'));
    });

    test('generates ^GB for box', () {
      final output = zpl.compile(
        label(
          LabelConfig(width: 40, height: 30),
        ).box(BoxOptions(x: 10, y: 10, width: 300, height: 220, thickness: 3)),
      );
      expect(output, contains('^GB'));
    });

    test('generates ^GC for circle', () {
      final output = zpl.compile(
        label(
          LabelConfig(width: 40, height: 30),
        ).circle(CircleOptions(x: 100, y: 100, diameter: 60, thickness: 2)),
      );
      expect(output, contains('^GC60,2'));
    });

    test('generates ^GFA for image', () {
      final bitmap = MonochromeBitmap(
        data: Uint8List.fromList([0xFF, 0x00]),
        width: 8,
        height: 2,
        bytesPerRow: 1,
      );
      final output = zpl.compile(
        label(
          LabelConfig(width: 40, height: 30),
        ).image(bitmap, ImageOptions(x: 10, y: 10)),
      );
      expect(output, contains('^GFA,2,2,1,FF00'));
    });

    test('handles raw passthrough', () {
      final output = zpl.compile(
        label(LabelConfig(width: 40, height: 30)).raw('^MMT'),
      );
      expect(output, contains('^MMT'));
    });

    test('omits ^LL for receipt mode (height 0)', () {
      final output = zpl.compile(label(LabelConfig(width: 80)));
      expect(output, contains('^XA'));
      expect(output, isNot(contains('^LL0')));
    });
  });
}
