import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';

/// Compile a resolved label to DPL commands as a byte sequence ([Uint8List]).
///
/// Uses actual control bytes (`STX` = 0x02, etc.).
/// If [encoding] is supplied, text fields are encoded using the configured [CodePageEncoder].
/// If omitted, defaults to [DplEncoding.defaultEncoding] ([DplEncoding.legacy]), preserving
/// exact historical DPL baseline output.
Uint8List compileToDPLBytes(ResolvedLabel label, {DplEncoding? encoding}) {
  final enc = encoding ?? DplEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  // STX L — Start label formatting mode (0x02, 'L', '\n')
  writer.writeByte(0x02);
  writer.writeAscii('L\n');

  writer.writeAscii('D${label.density.toString().padLeft(2, '0')}\n');
  writer.writeAscii('S${label.speed.toString().padLeft(2, '0')}\n');
  writer.writeAscii('A${label.widthDots.toString().padLeft(4, '0')}\n');
  if (label.copies > 1) {
    writer.writeAscii('Q${label.copies.toString().padLeft(4, '0')}\n');
  } else {
    writer.writeAscii('Q0001\n');
  }

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final rotation = _dplRotation(o.rotation ?? 0);
        final font = o.font ?? '0';
        final xMul = o.xScale ?? o.size ?? 1;
        final yMul = o.yScale ?? o.size ?? 1;

        // DPL text record: rotation y x font xmul ymul
        writer.writeAscii(rotation);
        writer.writeAscii(_pad4(y));
        writer.writeAscii(_pad4(x));
        writer.writeAscii(font);
        writer.writeAscii(xMul.toString().padLeft(2, '0'));
        writer.writeAscii(yMul.toString().padLeft(2, '0'));

        final textBytes = encoder.encode(
          el.content,
          replaceUnsupported: enc.replaceUnsupported,
        );
        writer.writeBytes(textBytes);
        writer.writeAscii('\n');

      case BoxElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        writer.writeAscii(
          '1e${_pad4(o.y)}${_pad4(o.x)}${_pad4(o.width)}${_pad4(o.height)}${_pad4(t)}\n',
        );

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          writer.writeAscii('1X${_pad4(o.y1)}${_pad4(x)}L${_pad4(w)}$t\n');
        } else {
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          writer.writeAscii('1X${_pad4(y)}${_pad4(o.x1)}L${_pad4(h)}$t\n');
        }

      case ImageElement():
      case CircleElement():
      case EllipseElement():
      case ReverseElement():
      case EraseElement():
        // DPL universal AST does not implement graphic download commands currently
        break;

      case BarcodeElement():
        final o = el.options;
        final rot = o.rotation == 90
            ? '1'
            : o.rotation == 180
            ? '2'
            : o.rotation == 270
            ? '3'
            : '1';
        final type = o.type == '39' ? 'A' : 'E'; // E=Code128
        final w = o.wide ?? 2;
        final h = o.height.toString().padLeft(3, '0');
        final x = o.x.toString().padLeft(4, '0');
        final y = o.y.toString().padLeft(4, '0');
        writer.writeAscii('$rot$type${w}0${h}0000$x$y');
        writer.writeAscii(el.content);
        writer.writeAscii('\n');

      case QRCodeElement():
        final o = el.options;
        final x = o.x.toString().padLeft(4, '0');
        final y = o.y.toString().padLeft(4, '0');
        final cw = (o.cellWidth ?? 4).toString().padLeft(3, '0');
        writer.writeAscii('1W1c${cw}0000$x$y');
        writer.writeAscii(el.content);
        writer.writeAscii('\n');

      case RawElement():
        if (el.content is Uint8List) {
          writer.writeBytes(el.content as Uint8List);
        } else if (el.content is List<int>) {
          writer.writeBytes(el.content as List<int>);
        } else if (el.content is String) {
          writer.writeString(el.content as String, encoding: latin1);
          writer.writeAscii('\n');
        }
    }
  }

  // E — End label format & print
  writer.writeAscii('E\n');
  return writer.toBytes();
}

/// Compile a resolved label to DPL commands as a [String].
///
/// Decodes the underlying byte stream via [latin1.decode], providing a 1:1 lossless
/// mapping of 8-bit byte values.
String compileToDPL(ResolvedLabel label, {DplEncoding? encoding}) {
  final bytes = compileToDPLBytes(label, encoding: encoding);
  return latin1.decode(bytes);
}

String _pad4(int n) => n.toString().padLeft(4, '0');

String _dplRotation(int degrees) {
  switch (degrees) {
    case 90:
      return '2';
    case 180:
      return '3';
    case 270:
      return '4';
    default:
      return '1';
  }
}
