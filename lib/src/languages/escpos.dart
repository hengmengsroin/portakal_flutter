import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';

/// Compile a resolved label to ESC/POS binary commands as [Uint8List].
///
/// If [encoding] is provided, text is encoded using the configured [CodePageEncoder]
/// and table selection commands (`ESC t <tableId>`) are emitted accordingly.
/// If omitted, defaults to standard CP437 without emitting redundant table switches.
Uint8List compileToESCPOS(ResolvedLabel label, {EscPosEncoding? encoding}) {
  final enc = encoding ?? const EscPosEncoding.cp437(sendTableSelect: false);
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  // ESC @ — Initialize printer
  writer.writeBytes([0x1B, 0x40]);

  // If table selection is configured, emit ESC t <tableId>
  if (enc.sendTableSelect && enc.tableId != null) {
    writer.writeBytes([0x1B, 0x74, enc.tableId!]);
  }

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;

        // Alignment: ESC a n
        if (o.align != null) {
          int n = 0;
          if (o.align == 'center') n = 1;
          if (o.align == 'right') n = 2;
          writer.writeBytes([0x1B, 0x61, n]);
        }

        // Bold: ESC E n
        if (o.bold == true) {
          writer.writeBytes([0x1B, 0x45, 1]);
        }

        // Size: GS ! n — width and height magnification
        if (o.size != null && o.size! > 1) {
          final s = o.size! - 1;
          final n = (s << 4) | s;
          writer.writeBytes([0x1D, 0x21, n]);
        }

        // Text content encoded via explicit code page encoder
        final textBytes = encoder.encode(
          el.content,
          replaceUnsupported: enc.replaceUnsupported,
        );
        writer.writeBytes(textBytes);
        writer.writeByte(0x0A); // LF

        // Reset size
        if (o.size != null && o.size! > 1) {
          writer.writeBytes([0x1D, 0x21, 0x00]);
        }

        // Reset bold
        if (o.bold == true) {
          writer.writeBytes([0x1B, 0x45, 0]);
        }

        // Reset alignment
        if (o.align != null) {
          writer.writeBytes([0x1B, 0x61, 0]);
        }

      case ImageElement():
        final bmp = el.bitmap;
        // GS v 0 — raster bit image
        writer.writeBytes([0x1D, 0x76, 0x30, 0x00]);
        // xL, xH — bytes per row (little-endian)
        writer.writeBytes([
          bmp.bytesPerRow & 0xFF,
          (bmp.bytesPerRow >> 8) & 0xFF,
        ]);
        // yL, yH — number of rows (little-endian)
        writer.writeBytes([bmp.height & 0xFF, (bmp.height >> 8) & 0xFF]);
        writer.writeBytes(bmp.data);

      case RawElement():
        if (el.content is Uint8List) {
          writer.writeBytes(el.content as Uint8List);
        } else if (el.content is List<int>) {
          writer.writeBytes(el.content as List<int>);
        } else if (el.content is String) {
          writer.writeBytes(
            encoder.encode(
              el.content as String,
              replaceUnsupported: enc.replaceUnsupported,
            ),
          );
        }

      case BarcodeElement():
        final o = el.options;
        writer.writeBytes([0x1D, 0x68, (o.height > 255 ? 255 : o.height)]);
        writer.writeBytes([0x1D, 0x48, o.readable == 1 ? 2 : 0]);
        final typeByte = o.type == '39' ? 69 : 73;
        final barcodeBytes = ascii.encode(el.content);
        writer.writeBytes([0x1D, 0x6B, typeByte, barcodeBytes.length]);
        writer.writeBytes(barcodeBytes);

      case QRCodeElement():
        final o = el.options;
        final contentBytes = utf8.encode(el.content);
        final len = contentBytes.length + 3;
        final pL = len & 0xFF;
        final pH = (len >> 8) & 0xFF;

        writer.writeBytes([
          0x1D,
          0x28,
          0x6B,
          0x04,
          0x00,
          0x31,
          0x41,
          0x32,
          0x00,
        ]);
        final cw = o.cellWidth ?? 4;
        writer.writeBytes([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, cw]);
        final ecc = o.eccLevel == 'L'
            ? 0x30
            : o.eccLevel == 'Q'
            ? 0x32
            : o.eccLevel == 'H'
            ? 0x33
            : 0x31;
        writer.writeBytes([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, ecc]);
        writer.writeBytes([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
        writer.writeBytes(contentBytes);
        writer.writeBytes([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);

      default:
        // ESC/POS doesn't support box, line, circle natively in text mode
        break;
    }
  }

  // GS V B 3 — Partial cut with 3 lines feed
  writer.writeBytes([0x1D, 0x56, 0x42, 0x03]);

  return writer.toBytes();
}
