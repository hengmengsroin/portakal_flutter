import 'dart:typed_data';

import 'types.dart';

/// Convert RGBA pixel data to grayscale using BT.601 luminance.
/// Transparent pixels are composited on white background.
Uint8List rgbaToGrayscale(Uint8List rgba, int width, int height) {
  final gray = Uint8List(width * height);
  for (int i = 0; i < width * height; i++) {
    final r = rgba[i * 4];
    final g = rgba[i * 4 + 1];
    final b = rgba[i * 4 + 2];
    final a = rgba[i * 4 + 3];

    // Alpha compositing on white background
    final alpha = a / 255.0;
    final cr = (r * alpha + 255 * (1 - alpha)).round();
    final cg = (g * alpha + 255 * (1 - alpha)).round();
    final cb = (b * alpha + 255 * (1 - alpha)).round();

    // BT.601 luminance
    gray[i] = (0.299 * cr + 0.587 * cg + 0.114 * cb).round();
  }
  return gray;
}

/// Simple threshold dithering.
Uint8List ditherThreshold(Uint8List gray, int width, int height, [int threshold = 128]) {
  final result = Uint8List(gray.length);
  for (int i = 0; i < gray.length; i++) {
    result[i] = gray[i] >= threshold ? 255 : 0;
  }
  return result;
}

/// Floyd-Steinberg error diffusion dithering (serpentine).
Uint8List ditherFloydSteinberg(Uint8List gray, int width, int height) {
  final buf = Float32List(gray.length);
  for (int i = 0; i < gray.length; i++) {
    buf[i] = gray[i].toDouble();
  }

  final result = Uint8List(gray.length);

  for (int y = 0; y < height; y++) {
    final leftToRight = y % 2 == 0;
    final xStart = leftToRight ? 0 : width - 1;
    final xEnd = leftToRight ? width : -1;
    final xStep = leftToRight ? 1 : -1;

    for (int x = xStart; x != xEnd; x += xStep) {
      final idx = y * width + x;
      final old = buf[idx];
      final val = old >= 128 ? 255.0 : 0.0;
      result[idx] = val.toInt();
      final err = old - val;

      // Distribute error to neighbors
      if (leftToRight) {
        if (x + 1 < width) buf[idx + 1] += err * 7 / 16;
        if (y + 1 < height) {
          if (x - 1 >= 0) buf[idx + width - 1] += err * 3 / 16;
          buf[idx + width] += err * 5 / 16;
          if (x + 1 < width) buf[idx + width + 1] += err * 1 / 16;
        }
      } else {
        if (x - 1 >= 0) buf[idx - 1] += err * 7 / 16;
        if (y + 1 < height) {
          if (x + 1 < width) buf[idx + width + 1] += err * 3 / 16;
          buf[idx + width] += err * 5 / 16;
          if (x - 1 >= 0) buf[idx + width - 1] += err * 1 / 16;
        }
      }
    }
  }

  return result;
}

/// Atkinson dithering (75% error propagation — preserves contrast).
Uint8List ditherAtkinson(Uint8List gray, int width, int height) {
  final buf = Float32List(gray.length);
  for (int i = 0; i < gray.length; i++) {
    buf[i] = gray[i].toDouble();
  }

  final result = Uint8List(gray.length);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final idx = y * width + x;
      final old = buf[idx];
      final val = old >= 128 ? 255.0 : 0.0;
      result[idx] = val.toInt();
      final err = (old - val) / 8; // 6/8 = 75% error

      // Distribute to 6 neighbors (each gets 1/8)
      if (x + 1 < width) buf[idx + 1] += err;
      if (x + 2 < width) buf[idx + 2] += err;
      if (y + 1 < height) {
        if (x - 1 >= 0) buf[idx + width - 1] += err;
        buf[idx + width] += err;
        if (x + 1 < width) buf[idx + width + 1] += err;
      }
      if (y + 2 < height) {
        buf[idx + width * 2] += err;
      }
    }
  }

  return result;
}

/// Ordered dithering using 4×4 Bayer matrix.
Uint8List ditherOrdered(Uint8List gray, int width, int height) {
  const bayer = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
  ];

  final result = Uint8List(gray.length);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final idx = y * width + x;
      final threshold = ((bayer[y % 4][x % 4] + 0.5) / 16.0 * 255).round();
      result[idx] = gray[idx] > threshold ? 255 : 0;
    }
  }

  return result;
}

/// Pack dithered grayscale (0/255) into 1-bit-per-pixel bitmap (MSB first).
/// 0 = black → bit 1, 255 = white → bit 0.
MonochromeBitmap packBitmap(Uint8List dithered, int width, int height) {
  final bytesPerRow = (width + 7) ~/ 8;
  final data = Uint8List(bytesPerRow * height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      if (dithered[y * width + x] == 0) {
        // Black pixel — set bit (MSB first)
        final byteIdx = y * bytesPerRow + (x ~/ 8);
        final bitIdx = 7 - (x % 8);
        data[byteIdx] |= (1 << bitIdx);
      }
    }
  }

  return MonochromeBitmap(
    data: data,
    width: width,
    height: height,
    bytesPerRow: bytesPerRow,
  );
}

/// Convert RGBA image data to a monochrome bitmap.
MonochromeBitmap imageToMonochrome(
  Uint8List rgba,
  int width,
  int height, [
  MonochromeOptions? options,
]) {
  final gray = rgbaToGrayscale(rgba, width, height);

  Uint8List dithered;
  final ditherName = options?.dither ?? 'threshold';
  final threshold = options?.threshold ?? 128;

  switch (ditherName) {
    case 'floyd-steinberg':
      dithered = ditherFloydSteinberg(gray, width, height);
    case 'atkinson':
      dithered = ditherAtkinson(gray, width, height);
    case 'ordered':
      dithered = ditherOrdered(gray, width, height);
    default:
      dithered = ditherThreshold(gray, width, height, threshold);
  }

  return packBitmap(dithered, width, height);
}
