import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/src/image.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('rgbaToGrayscale', () {
    test('converts white pixel to 255', () {
      final rgba = Uint8List.fromList([255, 255, 255, 255]);
      final gray = rgbaToGrayscale(rgba, 1, 1);
      expect(gray[0], equals(255));
    });

    test('converts black pixel to 0', () {
      final rgba = Uint8List.fromList([0, 0, 0, 255]);
      final gray = rgbaToGrayscale(rgba, 1, 1);
      expect(gray[0], equals(0));
    });

    test('converts red pixel using BT.601', () {
      final rgba = Uint8List.fromList([255, 0, 0, 255]);
      final gray = rgbaToGrayscale(rgba, 1, 1);
      expect(gray[0], equals(76)); // 0.299 * 255 ≈ 76
    });

    test('composites transparent pixel on white background', () {
      final rgba = Uint8List.fromList([0, 0, 0, 0]); // fully transparent
      final gray = rgbaToGrayscale(rgba, 1, 1);
      expect(gray[0], equals(255)); // white background
    });

    test('composites semi-transparent black on white', () {
      final rgba = Uint8List.fromList([0, 0, 0, 128]); // 50% transparent black
      final gray = rgbaToGrayscale(rgba, 1, 1);
      expect(gray[0], greaterThan(120));
      expect(gray[0], lessThan(135));
    });

    test('handles multiple pixels', () {
      final rgba = Uint8List.fromList([
        0, 0, 0, 255, // black
        255, 255, 255, 255, // white
        128, 128, 128, 255, // gray
      ]);
      final gray = rgbaToGrayscale(rgba, 3, 1);
      expect(gray[0], equals(0));
      expect(gray[1], equals(255));
      expect(gray[2], equals(128));
    });
  });

  group('ditherThreshold', () {
    test('converts values below threshold to 0', () {
      final gray = Uint8List.fromList([0, 50, 127]);
      final result = ditherThreshold(gray, 3, 1, 128);
      expect(result[0], equals(0));
      expect(result[1], equals(0));
      expect(result[2], equals(0));
    });

    test('converts values at/above threshold to 255', () {
      final gray = Uint8List.fromList([128, 200, 255]);
      final result = ditherThreshold(gray, 3, 1, 128);
      expect(result[0], equals(255));
      expect(result[1], equals(255));
      expect(result[2], equals(255));
    });

    test('uses custom threshold', () {
      final gray = Uint8List.fromList([100]);
      expect(ditherThreshold(gray, 1, 1, 50)[0], equals(255));
      expect(ditherThreshold(gray, 1, 1, 150)[0], equals(0));
    });
  });

  group('ditherFloydSteinberg', () {
    test('returns only 0 and 255 values', () {
      final gray = Uint8List.fromList([
        100,
        150,
        200,
        50,
        180,
        30,
        220,
        90,
        160,
      ]);
      final result = ditherFloydSteinberg(gray, 3, 3);
      for (int i = 0; i < result.length; i++) {
        expect(result[i] == 0 || result[i] == 255, isTrue);
      }
    });

    test('all-black input stays black', () {
      final gray = Uint8List.fromList([0, 0, 0, 0]);
      final result = ditherFloydSteinberg(gray, 2, 2);
      for (int i = 0; i < result.length; i++) {
        expect(result[i], equals(0));
      }
    });

    test('all-white input stays white', () {
      final gray = Uint8List.fromList([255, 255, 255, 255]);
      final result = ditherFloydSteinberg(gray, 2, 2);
      for (int i = 0; i < result.length; i++) {
        expect(result[i], equals(255));
      }
    });

    test('50% gray produces roughly equal black and white', () {
      final size = 100;
      final gray = Uint8List(size * size);
      gray.fillRange(0, gray.length, 128);
      final result = ditherFloydSteinberg(gray, size, size);
      int blackCount = 0;
      for (int i = 0; i < result.length; i++) {
        if (result[i] == 0) blackCount++;
      }
      final ratio = blackCount / result.length;
      expect(ratio, greaterThan(0.35));
      expect(ratio, lessThan(0.65));
    });
  });

  group('ditherAtkinson', () {
    test('returns only 0 and 255 values', () {
      final gray = Uint8List.fromList([100, 150, 200, 50]);
      final result = ditherAtkinson(gray, 2, 2);
      for (int i = 0; i < result.length; i++) {
        expect(result[i] == 0 || result[i] == 255, isTrue);
      }
    });

    test('preserves contrast better — dark values stay dark', () {
      final gray = Uint8List(16);
      gray.fillRange(0, 16, 30); // very dark
      final result = ditherAtkinson(gray, 4, 4);
      int blackCount = 0;
      for (int i = 0; i < result.length; i++) {
        if (result[i] == 0) blackCount++;
      }
      expect(blackCount, greaterThan(12)); // mostly black
    });
  });

  group('ditherOrdered', () {
    test('returns only 0 and 255 values', () {
      final gray = Uint8List.fromList([100, 150, 200, 50]);
      final result = ditherOrdered(gray, 2, 2);
      for (int i = 0; i < result.length; i++) {
        expect(result[i] == 0 || result[i] == 255, isTrue);
      }
    });

    test('produces deterministic output (no randomness)', () {
      final gray = Uint8List.fromList([
        100,
        150,
        200,
        50,
        180,
        30,
        220,
        90,
        160,
      ]);
      final r1 = ditherOrdered(gray, 3, 3);
      final r2 = ditherOrdered(gray, 3, 3);
      expect(r1, equals(r2));
    });
  });

  group('packBitmap', () {
    test('packs 8 pixels into 1 byte', () {
      // 0=black, 255=white → bit 1=black, 0=white
      final dithered = Uint8List.fromList([0, 255, 0, 255, 0, 255, 0, 255]);
      final bmp = packBitmap(dithered, 8, 1);
      expect(bmp.bytesPerRow, equals(1));
      expect(bmp.data[0], equals(0xAA)); // 10101010 MSB first
    });

    test('pads incomplete byte', () {
      final dithered = Uint8List.fromList([0, 0, 0]); // 3 pixels
      final bmp = packBitmap(dithered, 3, 1);
      expect(bmp.bytesPerRow, equals(1));
      expect(bmp.data[0], equals(0xE0)); // 11100000 — 3 black + 5 padding
    });

    test('handles multi-row bitmap', () {
      final dithered = Uint8List.fromList([
        0, 0, 0, 0, 0, 0, 0, 0, // row 0: all black
        255, 255, 255, 255, 255, 255, 255, 255, // row 1: all white
      ]);
      final bmp = packBitmap(dithered, 8, 2);
      expect(bmp.data[0], equals(0xFF)); // all black
      expect(bmp.data[1], equals(0x00)); // all white
    });

    test('sets correct MonochromeBitmap fields', () {
      final dithered = Uint8List(16 * 10); // 16x10
      final bmp = packBitmap(dithered, 16, 10);
      expect(bmp.width, equals(16));
      expect(bmp.height, equals(10));
      expect(bmp.bytesPerRow, equals(2));
      expect(bmp.data.length, equals(20));
    });
  });

  group('imageToMonochrome', () {
    test('converts RGBA to MonochromeBitmap with default threshold', () {
      final rgba = Uint8List.fromList([
        0, 0, 0, 255, // black pixel
        255, 255, 255, 255, // white pixel
      ]);
      final bmp = imageToMonochrome(rgba, 2, 1);
      expect(bmp.width, equals(2));
      expect(bmp.height, equals(1));
      expect(bmp.bytesPerRow, equals(1));
      expect(bmp.data[0], equals(0x80)); // first pixel black (10000000)
    });

    test('supports floyd-steinberg dithering', () {
      final rgba = Uint8List(8 * 8 * 4);
      rgba.fillRange(0, rgba.length, 128); // gray image
      // Set alpha to 255
      for (int i = 0; i < 8 * 8; i++) {
        rgba[i * 4 + 3] = 255;
      }
      final bmp = imageToMonochrome(
        rgba,
        8,
        8,
        MonochromeOptions(dither: 'floyd-steinberg'),
      );
      expect(bmp.width, equals(8));
      expect(bmp.height, equals(8));
    });

    test('supports atkinson dithering', () {
      final rgba = Uint8List(4 * 4 * 4);
      for (int i = 0; i < 16; i++) {
        rgba[i * 4] = 100;
        rgba[i * 4 + 1] = 100;
        rgba[i * 4 + 2] = 100;
        rgba[i * 4 + 3] = 255;
      }
      final bmp = imageToMonochrome(
        rgba,
        4,
        4,
        MonochromeOptions(dither: 'atkinson'),
      );
      expect(bmp.data.length, equals(4)); // 1 byte per row * 4 rows
    });

    test('supports ordered dithering', () {
      final rgba = Uint8List(4 * 4 * 4);
      for (int i = 0; i < 16; i++) {
        rgba[i * 4] = 150;
        rgba[i * 4 + 1] = 150;
        rgba[i * 4 + 2] = 150;
        rgba[i * 4 + 3] = 255;
      }
      final bmp = imageToMonochrome(
        rgba,
        4,
        4,
        MonochromeOptions(dither: 'ordered'),
      );
      expect(bmp.data.length, equals(4));
    });

    test('handles transparent image (composites on white)', () {
      final rgba = Uint8List.fromList([0, 0, 0, 0]); // fully transparent
      final bmp = imageToMonochrome(rgba, 1, 1);
      expect(bmp.data[0], equals(0)); // white (transparent = white bg)
    });
  });
}
