import 'dart:typed_data';
import '../types.dart';

/// Compile a resolved label to Star PRNT binary commands.
Uint8List compileToStarPRNT(ResolvedLabel label) {
  final bytes = <int>[];

  // ESC @ — Initialize
  bytes.addAll([0x1B, 0x40]);

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;

        // Alignment: ESC GS a n
        if (o.align != null) {
          int n = 0;
          if (o.align == 'center') n = 1;
          if (o.align == 'right') n = 2;
          bytes.addAll([0x1B, 0x1D, 0x61, n]);
        }

        // Bold: ESC E
        if (o.bold == true) {
          bytes.addAll([0x1B, 0x45]);
        }

        // Size: ESC i h w
        if (o.size != null && o.size! > 1) {
          bytes.addAll([0x1B, 0x69, o.size!, o.size!]);
        }

        // Text content
        bytes.addAll(el.content.codeUnits);
        bytes.add(0x0A); // LF

        // Reset size
        if (o.size != null && o.size! > 1) {
          bytes.addAll([0x1B, 0x69, 1, 1]);
        }

        // Bold off: ESC F
        if (o.bold == true) {
          bytes.addAll([0x1B, 0x46]);
        }

        // Reset alignment
        if (o.align != null) {
          bytes.addAll([0x1B, 0x1D, 0x61, 0]);
        }

      case ImageElement():
        final bmp = el.bitmap;
        // Enter raster mode: ESC * r A
        bytes.addAll([0x1B, 0x2A, 0x72, 0x41]);
        // Send each row
        for (int y = 0; y < bmp.height; y++) {
          final rowStart = y * bmp.bytesPerRow;
          // b nL nH data...
          bytes.add(0x62); // b
          bytes.addAll([bmp.bytesPerRow & 0xFF, (bmp.bytesPerRow >> 8) & 0xFF]);
          for (int i = 0; i < bmp.bytesPerRow; i++) {
            bytes.add(bmp.data[rowStart + i]);
          }
        }
        // Exit raster mode: ESC * r B
        bytes.addAll([0x1B, 0x2A, 0x72, 0x42]);

      case RawElement():
        if (el.content is String) {
          bytes.addAll((el.content as String).codeUnits);
        } else if (el.content is Uint8List) {
          bytes.addAll(el.content as Uint8List);
        }

      case BarcodeElement():
        final o = el.options;
        final typeByte = o.type == '39' ? 1 : 5; // 1=Code39, 5=Code128
        bytes.addAll([0x1B, 0x62, typeByte, o.readable == 1 ? 2 : 1, o.wide ?? 2, o.height > 255 ? 255 : o.height]);
        bytes.addAll(el.content.codeUnits);
        bytes.add(0x1E);

      case QRCodeElement():
        final o = el.options;
        bytes.addAll([0x1B, 0x1D, 0x79, 0x53, 0x30, o.cellWidth ?? 4]);
        final ecc = o.eccLevel == 'L' ? 0 : o.eccLevel == 'M' ? 1 : o.eccLevel == 'Q' ? 2 : 3;
        bytes.addAll([0x1B, 0x1D, 0x79, 0x53, 0x31, ecc]);
        bytes.addAll([0x1B, 0x1D, 0x79, 0x53, 0x32, 2]); // model 2
        final len = el.content.length;
        bytes.addAll([0x1B, 0x1D, 0x79, 0x44, 0x31, 0x30, len & 0xFF, (len >> 8) & 0xFF]);
        bytes.addAll(el.content.codeUnits);
        bytes.addAll([0x1B, 0x1D, 0x79, 0x50]);

      default:
        break;
    }
  }

  // ESC d 1 — Partial cut
  bytes.addAll([0x1B, 0x64, 1]);

  return Uint8List.fromList(bytes);
}
