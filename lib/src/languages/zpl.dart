import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';

/// Convert a byte to 2-char uppercase hex.
String _hex(int byte) => byte.toRadixString(16).toUpperCase().padLeft(2, '0');

/// Escapes ZPL command control delimiters (^ and ~) using ZPL ^FH hex escape format.
///
/// When ^FH is enabled on a field, literal underscores must also be escaped as
/// `_5F` to prevent the printer from misinterpreting following hexadecimal characters
/// (e.g. `_41` becoming `A`).
String _escapeZplHex(String text) {
  final buf = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == '^') {
      buf.write('_5E');
    } else if (char == '~') {
      buf.write('_7E');
    } else if (char == '_') {
      buf.write('_5F');
    } else {
      buf.write(char);
    }
  }
  return buf.toString();
}

/// Compile a resolved label to ZPL II commands as a byte sequence ([Uint8List]).
///
/// By default, uses [ZplEncoding.defaultEncoding] ([ZplEncoding.utf8]), which emits
/// `^CI28` and serializes text as UTF-8 (matching historical Portakal behavior).
/// For legacy environments without `^CI28`, pass [ZplEncoding.legacy].
Uint8List compileToZPLBytes(ResolvedLabel label, {ZplEncoding? encoding}) {
  final enc = encoding ?? ZplEncoding.defaultEncoding;
  final isUtf8 = enc.type == ZplTextEncoding.utf8;
  final writer = PrinterByteWriter();

  writer.writeAscii('^XA\n');

  // Emit ^CI28 for UTF-8 mode
  if (isUtf8 && enc.emitCiCommand) {
    writer.writeAscii('^CI28\n');
  }

  writer.writeAscii('^PW${label.widthDots}\n');
  if (label.heightDots > 0) {
    writer.writeAscii('^LL${label.heightDots}\n');
  }
  if (label.speed > 0) {
    writer.writeAscii('^PR${label.speed}\n');
  }
  if (label.density > 0) {
    writer.writeAscii('~SD${label.density.toString().padLeft(2, '0')}\n');
  }

  // Elements
  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final size = o.size ?? 1;
        final h = size * 30;
        final w = h;
        final r = _zplRotation(o.rotation ?? 0);
        writer.writeAscii('^FO$x,$y');
        writer.writeAscii('^A0$r,$h,$w');
        if (o.maxWidth != null) {
          final align = o.align == 'center'
              ? 'C'
              : o.align == 'right'
              ? 'R'
              : 'L';
          writer.writeAscii('^FB${o.maxWidth},1,0,$align');
        }
        if (o.reverse == true) {
          writer.writeAscii('^FR');
        }

        // Text field escaping and encoding
        final content = el.content;
        if (content.contains('^') || content.contains('~')) {
          // Contains ZPL control characters — activate ^FH (Field Hex) escaping
          final escaped = _escapeZplHex(content);
          writer.writeAscii('^FH^FD');
          if (isUtf8) {
            writer.writeString(escaped, encoding: utf8);
          } else {
            writer.writeString(escaped, encoding: latin1);
          }
          writer.writeAscii('^FS\n');
        } else {
          writer.writeAscii('^FD');
          if (isUtf8) {
            writer.writeString(content, encoding: utf8);
          } else {
            writer.writeString(content, encoding: latin1);
          }
          writer.writeAscii('^FS\n');
        }

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        final totalBytes = bmp.data.length;
        final hexData = bmp.data.map(_hex).join();
        writer.writeAscii(
          '^FO$x,$y^GFA,$totalBytes,$totalBytes,${bmp.bytesPerRow},$hexData^FS\n',
        );

      case BoxElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        final r = o.radius ?? 0;
        writer.writeAscii(
          '^FO${o.x},${o.y}^GB${o.width},${o.height},$t,B,$r^FS\n',
        );

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal line
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          writer.writeAscii('^FO$x,${o.y1}^GB$w,$t,$t^FS\n');
        } else if (o.x1 == o.x2) {
          // Vertical line
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          writer.writeAscii('^FO${o.x1},$y^GB$t,$h,$t^FS\n');
        } else {
          // Diagonal — use GD
          final w = (o.x2 - o.x1).abs();
          final h = (o.y2 - o.y1).abs();
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final dir = ((o.x2 > o.x1) == (o.y2 > o.y1)) ? 'R' : 'L';
          writer.writeAscii('^FO$x,$y^GD$w,$h,$t,B,$dir^FS\n');
        }

      case CircleElement():
        final o = el.options;
        writer.writeAscii(
          '^FO${o.x},${o.y}^GC${o.diameter},${o.thickness ?? 1},B^FS\n',
        );

      case EllipseElement():
        // ZPL has no native ellipse — skip
        break;

      case ReverseElement():
        // ZPL uses ^FR on text — region reverse not directly supported
        break;

      case EraseElement():
        final o = el.options;
        writer.writeAscii(
          '^FO${o.x},${o.y}^GB${o.width},${o.height},${o.width},W^FS\n',
        );

      case BarcodeElement():
        final o = el.options;
        final type = o.type == '39' ? '3' : 'C'; // 3=Code39, C=Code128
        final hr = o.readable == 1 ? 'Y' : 'N';
        final rot = o.rotation == 90
            ? 'R'
            : o.rotation == 180
            ? 'I'
            : o.rotation == 270
            ? 'B'
            : 'N';
        writer.writeAscii('^FO${o.x},${o.y}^B$type$rot,${o.height},$hr,N,N^FD');
        writer.writeAscii(el.content);
        writer.writeAscii('^FS\n');

      case QRCodeElement():
        final o = el.options;
        final cw = o.cellWidth ?? 4;
        final ecc = o.eccLevel ?? 'Q';
        final rot = o.rotation == 90
            ? 'R'
            : o.rotation == 180
            ? 'I'
            : o.rotation == 270
            ? 'B'
            : 'N';
        writer.writeAscii('^FO${o.x},${o.y}^BQ$rot,2,$cw,$ecc,7^FDQA,');
        if (isUtf8) {
          writer.writeString(el.content, encoding: utf8);
        } else {
          writer.writeString(el.content, encoding: latin1);
        }
        writer.writeAscii('^FS\n');

      case RawElement():
        if (el.content is Uint8List) {
          writer.writeBytes(el.content as Uint8List);
        } else if (el.content is List<int>) {
          writer.writeBytes(el.content as List<int>);
        } else if (el.content is String) {
          writer.writeString(el.content as String, encoding: utf8);
          writer.writeAscii('\n');
        }
    }
  }

  writer.writeAscii('^PQ${label.copies}\n');
  writer.writeAscii('^XZ\n');
  return writer.toBytes();
}

/// Compile a resolved label to ZPL II commands as a [String].
///
/// Decodes the underlying byte stream strictly: via [utf8.decode] in UTF-8 mode,
/// and via [latin1.decode] in legacy 8-bit mode.
String compileToZPL(ResolvedLabel label, {ZplEncoding? encoding}) {
  final enc = encoding ?? ZplEncoding.defaultEncoding;
  final bytes = compileToZPLBytes(label, encoding: enc);
  if (enc.type == ZplTextEncoding.utf8) {
    return utf8.decode(bytes);
  } else {
    return latin1.decode(bytes);
  }
}

String _zplRotation(int degrees) {
  switch (degrees) {
    case 90:
      return 'R';
    case 180:
      return 'I';
    case 270:
      return 'B';
    default:
      return 'N';
  }
}
