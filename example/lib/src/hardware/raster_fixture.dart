import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';

/// Generates the canonical 64x64 deterministic 1-bit raster test matrix.
///
/// Matrix structure (64x64 dots, 8 bytes/row, 512 bytes total, MSB-first):
/// - 1-px solid outer border
/// - 16x16 checkerboard area (x: 4..19, y: 4..19)
/// - Horizontal stripe area (x: 36..59, y: 4..19)
/// - 1-px diagonal line (from (4, 24) to (40, 60))
/// - Solid black rectangle (x: 22..30, y: 24..32)
/// - Vertical stripe area (x: 44..59, y: 24..59)
Uint8List generateCanonicalRaster64x64Bytes() {
  const int width = 64;
  const int height = 64;
  const int bytesPerRow = 8;
  final data = Uint8List(width * height ~/ 8);

  void setPixel(int x, int y, bool isBlack) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    if (isBlack) {
      final byteIdx = y * bytesPerRow + (x ~/ 8);
      final bitIdx = 7 - (x % 8);
      data[byteIdx] |= (1 << bitIdx);
    }
  }

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      // 1-px outer border
      if (y == 0 || y == height - 1 || x == 0 || x == width - 1) {
        setPixel(x, y, true);
        continue;
      }

      // Checkerboard area (x: 4..19, y: 4..19)
      if (x >= 4 && x <= 19 && y >= 4 && y <= 19) {
        if ((x + y) % 2 == 0) {
          setPixel(x, y, true);
        }
        continue;
      }

      // Horizontal stripes (x: 36..59, y: 4..19)
      if (x >= 36 && x <= 59 && y >= 4 && y <= 19) {
        if (y % 2 == 0) {
          setPixel(x, y, true);
        }
        continue;
      }

      // Solid black box (x: 22..30, y: 24..32)
      if (x >= 22 && x <= 30 && y >= 24 && y <= 32) {
        setPixel(x, y, true);
        continue;
      }

      // 1-px diagonal line (from (4, 24) to (40, 60))
      if (x >= 4 && x <= 40 && y >= 24 && y <= 60 && (x - 4) == (y - 24)) {
        setPixel(x, y, true);
        continue;
      }

      // Vertical stripes (x: 44..59, y: 24..59)
      if (x >= 44 && x <= 59 && y >= 24 && y <= 59) {
        if (x % 2 == 0) {
          setPixel(x, y, true);
        }
        continue;
      }
    }
  }

  return data;
}

/// Creates a [MonochromeBitmap] instance with the canonical 64x64 raster fixture.
MonochromeBitmap createCanonicalRaster64x64Bitmap() {
  final bytes = generateCanonicalRaster64x64Bytes();
  return MonochromeBitmap(data: bytes, width: 64, height: 64, bytesPerRow: 8);
}
