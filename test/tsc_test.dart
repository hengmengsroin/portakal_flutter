import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/lang/tsc.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('TSC compiler', () {
    test('generates SIZE with mm', () {
      final output = tsc.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('SIZE 40 mm,30 mm'));
    });

    test('generates GAP', () {
      final output = tsc.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('GAP 3 mm,0 mm'));
    });

    test('generates SPEED and DENSITY', () {
      final output = tsc.compile(label(LabelConfig(width: 40, height: 30, speed: 6, density: 10)));
      expect(output, contains('SPEED 6'));
      expect(output, contains('DENSITY 10'));
    });

    test('generates DIRECTION', () {
      final output = tsc.compile(label(LabelConfig(width: 40, height: 30, direction: 1)));
      expect(output, contains('DIRECTION 1'));
    });

    test('generates CLS', () {
      final output = tsc.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('CLS'));
    });

    test('generates TEXT with position and font', () {
      final output = tsc.compile(
        label(LabelConfig(width: 40, height: 30))
            .text('Hello TSC', TextOptions(x: 10, y: 20, font: '3', size: 2)),
      );
      expect(output, contains('TEXT 10,20,"3",0,2,2,"Hello TSC"'));
    });

    test('generates BOX', () {
      final output = tsc.compile(
        label(LabelConfig(width: 40, height: 30))
            .box(BoxOptions(x: 5, y: 5, width: 310, height: 230, thickness: 2)),
      );
      expect(output, contains('BOX 5,5,315,235,2'));
    });

    test('generates BAR (horizontal line)', () {
      final output = tsc.compile(
        label(LabelConfig(width: 40, height: 30))
            .line(LineOptions(x1: 5, y1: 55, x2: 315, y2: 55, thickness: 1)),
      );
      expect(output, contains('BAR 5,55,310,1'));
    });

    test('generates CIRCLE', () {
      final output = tsc.compile(
        label(LabelConfig(width: 40, height: 30))
            .circle(CircleOptions(x: 250, y: 180, diameter: 40, thickness: 1)),
      );
      expect(output, contains('CIRCLE 250,180,40,1'));
    });

    test('generates BITMAP header', () {
      final bitmap = MonochromeBitmap(
        data: Uint8List.fromList([0xFF, 0x00]),
        width: 8,
        height: 2,
        bytesPerRow: 1,
      );
      final output = tsc.compile(
        label(LabelConfig(width: 40, height: 30))
            .image(bitmap, ImageOptions(x: 10, y: 10)),
      );
      expect(output, contains('BITMAP 10,10,1,2,0,'));
    });

    test('generates raw passthrough', () {
      final output = tsc.compile(
        label(LabelConfig(width: 40, height: 30)).raw('SET CUTTER BATCH'),
      );
      expect(output, contains('SET CUTTER BATCH'));
    });

    test('generates PRINT with copies', () {
      final output = tsc.compile(label(LabelConfig(width: 40, height: 30, copies: 5)));
      expect(output, contains('PRINT 5'));
    });

    test('generates PRINT 1 by default', () {
      final output = tsc.compile(label(LabelConfig(width: 40, height: 30)));
      expect(output, contains('PRINT 1'));
    });
  });
}
