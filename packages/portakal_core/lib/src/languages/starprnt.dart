import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';
import 'starprnt_writer.dart';

/// Compile a resolved label to Star PRNT binary commands as a [Uint8List].
///
/// Uses authentic Star Line Mode commands.
/// If [encoding] is supplied, text is encoded using the configured [CodePageEncoder]
/// and code page table selection (`ESC GS t <characterTable>`) is emitted if requested.
/// If omitted, defaults to [StarPrntEncoding.defaultEncoding] ([StarPrntEncoding.legacy]).
Uint8List compileToStarPRNT(ResolvedLabel label, {StarPrntEncoding? encoding}) {
  final enc = encoding ?? StarPrntEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  // ESC @ — Initialize
  StarPrntCommandWriter.writeInitialize(writer);

  // If code page selection is requested: ESC GS t <characterTable>
  if (enc.sendCodePageCommand && enc.characterTable != null) {
    StarPrntCommandWriter.writeCodePage(writer, enc.characterTable!);
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
          StarPrntCommandWriter.writeAlignment(writer, n);
        }

        // Bold: ESC E
        if (o.bold == true) {
          StarPrntCommandWriter.writeBold(writer, true);
        }

        // Size: ESC i h w
        if (o.size != null && o.size! > 1) {
          StarPrntCommandWriter.writeCharacterSize(
            writer,
            widthMultiplier: o.size!,
            heightMultiplier: o.size!,
          );
        }

        // Text content
        StarPrntCommandWriter.writeText(
          writer,
          el.content,
          encoder,
          replaceUnsupported: enc.replaceUnsupported,
        );
        StarPrntCommandWriter.writeLineFeed(writer);

        // Reset size
        if (o.size != null && o.size! > 1) {
          StarPrntCommandWriter.writeCharacterSize(
            writer,
            widthMultiplier: 1,
            heightMultiplier: 1,
          );
        }

        // Bold off: ESC F
        if (o.bold == true) {
          StarPrntCommandWriter.writeBold(writer, false);
        }

        // Reset alignment
        if (o.align != null) {
          StarPrntCommandWriter.writeAlignment(writer, 0);
        }

      case ImageElement():
        final bmp = el.bitmap;
        StarPrntCommandWriter.writeRaster(
          writer,
          data: bmp.data,
          bytesPerRow: bmp.bytesPerRow,
          height: bmp.height,
        );

      case RawElement():
        if (el.content is Uint8List) {
          StarPrntCommandWriter.writeRawBytes(writer, el.content as Uint8List);
        } else if (el.content is List<int>) {
          StarPrntCommandWriter.writeRawBytes(writer, el.content as List<int>);
        } else if (el.content is String) {
          StarPrntCommandWriter.writeRawAscii(writer, el.content as String);
        }

      case BarcodeElement():
        final o = el.options;
        final typeByte = o.type == '39' ? 1 : 5; // 1=Code39, 5=Code128
        StarPrntCommandWriter.writeBarcode(
          writer,
          typeCode: typeByte,
          readable: o.readable == 1 ? 2 : 1,
          wide: o.wide ?? 2,
          height: o.height > 255 ? 255 : o.height,
          content: el.content,
        );

      case QRCodeElement():
        final o = el.options;
        final ecc = o.eccLevel == 'L'
            ? 0
            : o.eccLevel == 'Q'
            ? 2
            : o.eccLevel == 'H'
            ? 3
            : 1;
        StarPrntCommandWriter.writeQrCode(
          writer,
          content: el.content,
          cellWidth: o.cellWidth ?? 4,
          ecc: ecc,
          model: 2,
        );

      default:
        break;
    }
  }

  // ESC d 1 — Partial cut
  StarPrntCommandWriter.writeCut(writer, 1);

  return writer.toBytes();
}

/// Convenience alias for [compileToStarPRNT] providing naming consistency across protocols.
Uint8List compileToStarPRNTBytes(
  ResolvedLabel label, {
  StarPrntEncoding? encoding,
}) => compileToStarPRNT(label, encoding: encoding);
