import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';

const int _esc = 0x1B;

/// Convert a byte to 2-char uppercase hex.
String _hex(int byte) => byte.toRadixString(16).toUpperCase().padLeft(2, '0');

/// Pad an integer to 2-char zero-filled string.
String _pad2(int n) => n.toString().padLeft(2, '0');

/// Pad an integer to 4-char zero-filled string.
String _pad4(int n) => n.toString().padLeft(4, '0');

/// Pad an integer to 5-char zero-filled string.
String _pad5(int n) => n.toString().padLeft(5, '0');

/// Compile a resolved label to SBPL commands as a byte sequence ([Uint8List]).
///
/// Uses actual control byte `ESC` = 0x1B.
/// If [encoding] is supplied, text fields are encoded using the configured [CodePageEncoder].
/// Control character `ESC` (0x1B) inside text fields is rejected with [UnsupportedCharacterException]
/// (or replaced with `?` if `replaceUnsupported: true`) to prevent command injection / framing breaks.
/// If omitted, defaults to [SbplEncoding.defaultEncoding] ([SbplEncoding.legacy]).
Uint8List compileToSBPLBytes(ResolvedLabel label, {SbplEncoding? encoding}) {
  final enc = encoding ?? SbplEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  // ESC A — Start
  writer.writeByte(_esc);
  writer.writeAscii('A');

  // ESC CS — Clear buffer
  writer.writeByte(_esc);
  writer.writeAscii('CS');

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final size = o.size ?? 1;

        // Position
        writer.writeByte(_esc);
        writer.writeAscii('H${_pad4(x)}');
        writer.writeByte(_esc);
        writer.writeAscii('V${_pad4(y)}');

        // Rotation
        if (o.rotation != null && o.rotation! > 0) {
          writer.writeByte(_esc);
          writer.writeAscii('%${_sbplRotation(o.rotation!)}');
        }

        // Magnification
        writer.writeByte(_esc);
        writer.writeAscii('L${_pad2(size)}${_pad2(size)}');

        // Text output: ESC K9B
        writer.writeByte(_esc);
        writer.writeAscii('K9B');

        final textBytes = _encodeSbplText(
          el.content,
          encoder,
          replaceUnsupported: enc.replaceUnsupported,
        );
        writer.writeBytes(textBytes);

        // Reset rotation
        if (o.rotation != null && o.rotation! > 0) {
          writer.writeByte(_esc);
          writer.writeAscii('%0');
        }

      case BoxElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        writer.writeByte(_esc);
        writer.writeAscii('H${_pad4(o.x)}');
        writer.writeByte(_esc);
        writer.writeAscii('V${_pad4(o.y)}');
        writer.writeByte(_esc);
        writer.writeAscii('FW${_pad2(t)}V${_pad4(o.height)}H${_pad4(o.width)}');

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          writer.writeByte(_esc);
          writer.writeAscii('H${_pad4(x)}');
          writer.writeByte(_esc);
          writer.writeAscii('V${_pad4(o.y1)}');
          writer.writeByte(_esc);
          writer.writeAscii('FW${_pad2(t)}H${_pad4(w)}');
        } else if (o.x1 == o.x2) {
          // Vertical
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          writer.writeByte(_esc);
          writer.writeAscii('H${_pad4(o.x1)}');
          writer.writeByte(_esc);
          writer.writeAscii('V${_pad4(y)}');
          writer.writeByte(_esc);
          writer.writeAscii('FW${_pad2(t)}V${_pad4(h)}');
        }

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        writer.writeByte(_esc);
        writer.writeAscii('H${_pad4(x)}');
        writer.writeByte(_esc);
        writer.writeAscii('V${_pad4(y)}');
        final hexData = bmp.data.map(_hex).join();
        writer.writeByte(_esc);
        writer.writeAscii('GM${_pad5(bmp.data.length)},$hexData');

      case CircleElement():
      case EllipseElement():
      case ReverseElement():
      case EraseElement():
        break;

      case BarcodeElement():
        final o = el.options;
        final type = o.type == '39' ? 'B1' : 'BG'; // BG is Code128
        final n = o.narrow ?? 2;
        final h = o.height.toString().padLeft(3, '0');
        writer.writeByte(_esc);
        writer.writeAscii('V${o.y}');
        writer.writeByte(_esc);
        writer.writeAscii('H${o.x}');
        writer.writeByte(_esc);
        writer.writeAscii('$type${n}0$h');
        writer.writeAscii(el.content);

      case QRCodeElement():
        final o = el.options;
        final cw = (o.cellWidth ?? 4).toString().padLeft(2, '0');
        writer.writeByte(_esc);
        writer.writeAscii('V${o.y}');
        writer.writeByte(_esc);
        writer.writeAscii('H${o.x}');
        writer.writeByte(_esc);
        writer.writeAscii('BQ${cw}200');
        writer.writeAscii(el.content);

      case RawElement():
        if (el.content is Uint8List) {
          writer.writeBytes(el.content as Uint8List);
        } else if (el.content is List<int>) {
          writer.writeBytes(el.content as List<int>);
        } else if (el.content is String) {
          writer.writeString(el.content as String, encoding: latin1);
        }
    }
  }

  // Copies
  if (label.copies > 1) {
    writer.writeByte(_esc);
    writer.writeAscii('Q${label.copies}');
  }

  // ESC Z — End
  writer.writeByte(_esc);
  writer.writeAscii('Z');
  return writer.toBytes();
}

/// Helper to encode text and guard against ESC (0x1B) which breaks SBPL command stream.
Uint8List _encodeSbplText(
  String text,
  CodePageEncoder encoder, {
  bool replaceUnsupported = false,
}) {
  final bytes = encoder.encode(text, replaceUnsupported: replaceUnsupported);
  final result = Uint8List(bytes.length);
  for (int i = 0; i < bytes.length; i++) {
    final b = bytes[i];
    if (b == _esc) {
      if (replaceUnsupported) {
        result[i] = 0x3F; // '?'
      } else {
        throw UnsupportedCharacterException(
          character: String.fromCharCode(b),
          codePoint: b,
          codePage: encoder.codePage,
          message:
              'Control character ESC (0x1B) is not allowed inside SBPL text payload.',
        );
      }
    } else {
      result[i] = b;
    }
  }
  return result;
}

/// Compile a resolved label to SBPL commands as a [String].
///
/// Decodes the underlying byte stream via [latin1.decode], providing a 1:1 lossless
/// mapping of 8-bit byte values.
String compileToSBPL(ResolvedLabel label, {SbplEncoding? encoding}) {
  final bytes = compileToSBPLBytes(label, encoding: encoding);
  return latin1.decode(bytes);
}

int _sbplRotation(int degrees) {
  switch (degrees) {
    case 90:
      return 1;
    case 180:
      return 2;
    case 270:
      return 3;
    default:
      return 0;
  }
}
