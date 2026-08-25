import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';

const int _esc = 0x1B;
const int _gs = 0x1D;

/// Compile a resolved label to Star PRNT binary commands as a [Uint8List].
///
/// If [encoding] is supplied, text is encoded using the configured [CodePageEncoder]
/// and code page table selection (`ESC GS t <characterTable>`) is emitted if requested.
/// If omitted, defaults to [StarPrntEncoding.defaultEncoding] ([StarPrntEncoding.legacy]).
Uint8List compileToStarPRNT(ResolvedLabel label, {StarPrntEncoding? encoding}) {
  final enc = encoding ?? StarPrntEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  // ESC @ — Initialize
  writer.writeByte(_esc);
  writer.writeAscii('@');

  // If code page selection is requested: ESC GS t <characterTable>
  if (enc.sendCodePageCommand && enc.characterTable != null) {
    writer.writeByte(_esc);
    writer.writeByte(_gs);
    writer.writeAscii('t');
    writer.writeByte(enc.characterTable!);
  }

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;

        // Alignment: ESC GS a n
        if (o.align != null) {
          int n = 0;
          if (o.align == 'center') n = 1;
          if (o.align == 'right') n = 2;
          writer.writeByte(_esc);
          writer.writeByte(_gs);
          writer.writeAscii('a');
          writer.writeByte(n);
        }

        // Bold: ESC E
        if (o.bold == true) {
          writer.writeByte(_esc);
          writer.writeAscii('E');
        }

        // Size: ESC i h w
        if (o.size != null && o.size! > 1) {
          writer.writeByte(_esc);
          writer.writeAscii('i');
          writer.writeByte(o.size!);
          writer.writeByte(o.size!);
        }

        // Text content
        final textBytes = encoder.encode(
          el.content,
          replaceUnsupported: enc.replaceUnsupported,
        );
        writer.writeBytes(textBytes);
        writer.writeByte(0x0A); // LF

        // Reset size
        if (o.size != null && o.size! > 1) {
          writer.writeByte(_esc);
          writer.writeAscii('i');
          writer.writeByte(1);
          writer.writeByte(1);
        }

        // Bold off: ESC F
        if (o.bold == true) {
          writer.writeByte(_esc);
          writer.writeAscii('F');
        }

        // Reset alignment
        if (o.align != null) {
          writer.writeByte(_esc);
          writer.writeByte(_gs);
          writer.writeAscii('a');
          writer.writeByte(0);
        }

      case ImageElement():
        final bmp = el.bitmap;
        // Enter raster mode: ESC * r A
        writer.writeByte(_esc);
        writer.writeBytes(const [0x2A, 0x72, 0x41]); // * r A

        // Send each row: 'b' nL nH data...
        for (int y = 0; y < bmp.height; y++) {
          final rowStart = y * bmp.bytesPerRow;
          writer.writeByte(0x62); // 'b'
          writer.writeByte(bmp.bytesPerRow & 0xFF);
          writer.writeByte((bmp.bytesPerRow >> 8) & 0xFF);
          for (int i = 0; i < bmp.bytesPerRow; i++) {
            writer.writeByte(bmp.data[rowStart + i]);
          }
        }
        // Exit raster mode: ESC * r B
        writer.writeByte(_esc);
        writer.writeBytes(const [0x2A, 0x72, 0x42]); // * r B

      case RawElement():
        if (el.content is Uint8List) {
          writer.writeBytes(el.content as Uint8List);
        } else if (el.content is List<int>) {
          writer.writeBytes(el.content as List<int>);
        } else if (el.content is String) {
          writer.writeString(el.content as String, encoding: latin1);
        }

      case BarcodeElement():
        final o = el.options;
        final typeByte = o.type == '39' ? 1 : 5; // 1=Code39, 5=Code128
        writer.writeByte(_esc);
        writer.writeByte(0x62); // 'b'
        writer.writeByte(typeByte);
        writer.writeByte(o.readable == 1 ? 2 : 1);
        writer.writeByte(o.wide ?? 2);
        writer.writeByte(o.height > 255 ? 255 : o.height);
        writer.writeAscii(el.content);
        writer.writeByte(0x1E); // RS terminator

      case QRCodeElement():
        final o = el.options;
        // ESC GS y S 0 <cellWidth>
        writer.writeByte(_esc);
        writer.writeByte(_gs);
        writer.writeBytes([0x79, 0x53, 0x30, o.cellWidth ?? 4]);

        final ecc = o.eccLevel == 'L'
            ? 0
            : o.eccLevel == 'M'
            ? 1
            : o.eccLevel == 'Q'
            ? 2
            : 3;
        // ESC GS y S 1 <ecc>
        writer.writeByte(_esc);
        writer.writeByte(_gs);
        writer.writeBytes([0x79, 0x53, 0x31, ecc]);

        // ESC GS y S 2 2 (model 2)
        writer.writeByte(_esc);
        writer.writeByte(_gs);
        writer.writeBytes(const [0x79, 0x53, 0x32, 2]);

        final len = el.content.length;
        // ESC GS y D 1 0 <nL> <nH> <data>
        writer.writeByte(_esc);
        writer.writeByte(_gs);
        writer.writeBytes([
          0x79,
          0x44,
          0x31,
          0x30,
          len & 0xFF,
          (len >> 8) & 0xFF,
        ]);
        writer.writeAscii(el.content);

        // ESC GS y P (print)
        writer.writeByte(_esc);
        writer.writeByte(_gs);
        writer.writeBytes(const [0x79, 0x50]);

      default:
        break;
    }
  }

  // ESC d 1 — Partial cut
  writer.writeByte(_esc);
  writer.writeAscii('d');
  writer.writeByte(1);

  return writer.toBytes();
}

/// Convenience alias for [compileToStarPRNT] providing naming consistency across protocols.
Uint8List compileToStarPRNTBytes(
  ResolvedLabel label, {
  StarPrntEncoding? encoding,
}) => compileToStarPRNT(label, encoding: encoding);
