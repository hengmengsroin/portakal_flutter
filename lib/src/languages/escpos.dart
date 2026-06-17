import 'dart:typed_data';
import '../types.dart';

/// Compile a resolved label to ESC/POS binary commands.
Uint8List compileToESCPOS(ResolvedLabel label) {
  final bytes = <int>[];

  // ESC @ — Initialize printer
  bytes.addAll([0x1B, 0x40]);

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;

        // Alignment: ESC a n
        if (o.align != null) {
          int n = 0;
          if (o.align == 'center') n = 1;
          if (o.align == 'right') n = 2;
          bytes.addAll([0x1B, 0x61, n]);
        }

        // Bold: ESC E n
        if (o.bold == true) {
          bytes.addAll([0x1B, 0x45, 1]);
        }

        // Size: GS ! n — width and height magnification
        if (o.size != null && o.size! > 1) {
          final s = o.size! - 1;
          final n = (s << 4) | s;
          bytes.addAll([0x1D, 0x21, n]);
        }

        // Text content
        bytes.addAll(el.content.codeUnits);
        bytes.add(0x0A); // LF

        // Reset size
        if (o.size != null && o.size! > 1) {
          bytes.addAll([0x1D, 0x21, 0x00]);
        }

        // Reset bold
        if (o.bold == true) {
          bytes.addAll([0x1B, 0x45, 0]);
        }

        // Reset alignment
        if (o.align != null) {
          bytes.addAll([0x1B, 0x61, 0]);
        }

      case ImageElement():
        final bmp = el.bitmap;
        // GS v 0 — raster bit image
        bytes.addAll([0x1D, 0x76, 0x30, 0x00]);
        // xL, xH — bytes per row (little-endian)
        bytes.addAll([bmp.bytesPerRow & 0xFF, (bmp.bytesPerRow >> 8) & 0xFF]);
        // yL, yH — number of rows (little-endian)
        bytes.addAll([bmp.height & 0xFF, (bmp.height >> 8) & 0xFF]);
        bytes.addAll(bmp.data);

      case RawElement():
        if (el.content is String) {
          bytes.addAll((el.content as String).codeUnits);
        } else if (el.content is Uint8List) {
          bytes.addAll(el.content as Uint8List);
        }

      case BarcodeElement():
        final o = el.options;
        bytes.addAll([0x1D, 0x68, (o.height > 255 ? 255 : o.height)]);
        bytes.addAll([0x1D, 0x48, o.readable == 1 ? 2 : 0]);
        final typeByte = o.type == '39' ? 69 : 73;
        bytes.addAll([0x1D, 0x6B, typeByte, el.content.length]);
        bytes.addAll(el.content.codeUnits);

      case QRCodeElement():
        final o = el.options;
        final contentBytes = el.content.codeUnits;
        final len = contentBytes.length + 3;
        final pL = len & 0xFF;
        final pH = (len >> 8) & 0xFF;

        bytes.addAll([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
        final cw = o.cellWidth ?? 4;
        bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, cw]);
        final ecc = o.eccLevel == 'L'
            ? 0x30
            : o.eccLevel == 'Q'
            ? 0x32
            : o.eccLevel == 'H'
            ? 0x33
            : 0x31;
        bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, ecc]);
        bytes.addAll([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
        bytes.addAll(contentBytes);
        bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);

      default:
        // ESC/POS doesn't support box, line, circle natively in text mode
        break;
    }
  }

  // GS V B 3 — Partial cut with 3 lines feed
  bytes.addAll([0x1D, 0x56, 0x42, 0x03]);

  return Uint8List.fromList(bytes);
}
