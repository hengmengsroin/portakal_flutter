import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/lang/cpcl.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('CPCL compiler', () {
    test('generates session header', () {
      final output = cpcl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('! 0 203 203 240 1'));
    });

    test('generates TONE', () {
      final output = cpcl.compile(label(LabelConfig(width: 40, height: 30, density: 10)));
      expect(output, contains('TONE'));
    });

    test('generates SPEED', () {
      final output = cpcl.compile(label(LabelConfig(width: 40, height: 30, speed: 4)));
      expect(output, contains('SPEED 4'));
    });

    test('generates PAGE-WIDTH', () {
      final output = cpcl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('PAGE-WIDTH 320'));
    });

    test('generates TEXT with position', () {
      final output = cpcl.compile(
        label(LabelConfig(width: 40, height: 30))
            .text('Hello CPCL', TextOptions(x: 10, y: 20)),
      );
      expect(output, contains('TEXT'));
      expect(output, contains('10 20'));
      expect(output, contains('Hello CPCL'));
    });

    test('generates TEXT90 for rotated text', () {
      final output = cpcl.compile(
        label(LabelConfig(width: 40, height: 30))
            .text('Rotated', TextOptions(x: 10, y: 20, rotation: 90)),
      );
      expect(output, contains('TEXT90'));
    });

    test('generates BOX', () {
      final output = cpcl.compile(
        label(LabelConfig(width: 40, height: 30))
            .box(BoxOptions(x: 5, y: 5, width: 310, height: 230, thickness: 2)),
      );
      expect(output, contains('BOX 5 5 315 235 2'));
    });

    test('generates LINE', () {
      final output = cpcl.compile(
        label(LabelConfig(width: 40, height: 30))
            .line(LineOptions(x1: 10, y1: 50, x2: 300, y2: 50, thickness: 2)),
      );
      expect(output, contains('LINE 10 50 300 50 2'));
    });

    test('generates EG for image', () {
      final bitmap = MonochromeBitmap(
        data: Uint8List.fromList([0xFF, 0x00]),
        width: 8,
        height: 2,
        bytesPerRow: 1,
      );
      final output = cpcl.compile(
        label(LabelConfig(width: 40, height: 30))
            .image(bitmap, ImageOptions(x: 10, y: 10)),
      );
      expect(output, contains('EG 1 2 10 10'));
    });

    test('generates raw passthrough', () {
      final output = cpcl.compile(
        label(LabelConfig(width: 40, height: 30)).raw('COUNTRY USA'),
      );
      expect(output, contains('COUNTRY USA'));
    });

    test('generates PRINT', () {
      final output = cpcl.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('PRINT'));
    });

    test('generates copies in session header', () {
      final output = cpcl.compile(label(LabelConfig(width: 40, height: 30, copies: 3)));
      expect(output, contains('! 0 203 203 240 3'));
    });
  });
}
