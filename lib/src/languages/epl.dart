import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';

/// Compile a resolved label to EPL2 commands as a byte sequence ([Uint8List]).
///
/// If [encoding] is supplied, text fields are encoded using the configured [CodePageEncoder]
/// and character set selection commands (`I8,<countryCode>,001`) are emitted if requested.
/// If omitted, defaults to [EplEncoding.defaultEncoding] ([EplEncoding.legacy]), preserving
/// exact historical EPL baseline behavior.
Uint8List compileToEPLBytes(ResolvedLabel label, {EplEncoding? encoding}) {
  final enc = encoding ?? EplEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  writer.writeAscii('N\n');

  // If character set command is configured, emit I8,<countryCode>,001\n
  if (enc.sendSetCharSetCommand && enc.countryCode != null) {
    writer.writeAscii('I8,${enc.countryCode},001\n');
  }

  writer.writeAscii('q${label.widthDots}\n');
  if (label.heightDots > 0) {
    writer.writeAscii('Q${label.heightDots},24\n');
  }
  writer.writeAscii('S${label.speed}\n');
  writer.writeAscii('D${label.density}\n');

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final font = o.font ?? '2';
        final rotation = _eplRotation(o.rotation ?? 0);
        final xMul = o.xScale ?? o.size ?? 1;
        final yMul = o.yScale ?? o.size ?? 1;
        final reverse = o.reverse == true ? 'R' : 'N';

        // Format: A<x>,<y>,<rot>,<font>,<xMul>,<yMul>,<reverse>,"<content>"\n
        writer.writeAscii('A$x,$y,$rotation,$font,$xMul,$yMul,$reverse,"');
        final textBytes = encoder.encode(
          el.content,
          replaceUnsupported: enc.replaceUnsupported,
        );
        writer.writeBytes(textBytes);
        writer.writeAscii('"\n');

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        // EPL GW: polarity INVERTED (0=black in data)
        writer.writeAscii('GW$x,$y,${bmp.bytesPerRow},${bmp.height}\n');
        final inverted = Uint8List(bmp.data.length);
        for (int i = 0; i < bmp.data.length; i++) {
          inverted[i] = ~bmp.data[i] & 0xFF;
        }
        writer.writeBytes(inverted);
        writer.writeAscii('\n');

      case BoxElement():
        final o = el.options;
        final x2 = o.x + o.width;
        final y2 = o.y + o.height;
        final t = o.thickness ?? 1;
        writer.writeAscii('X${o.x},${o.y},$x2,$y2,$t\n');

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          writer.writeAscii('LO$x,${o.y1},$w,$t\n');
        } else if (o.x1 == o.x2) {
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          writer.writeAscii('LO${o.x1},$y,$t,$h\n');
        } else {
          // EPL doesn't support diagonal — approximate with LO
          writer.writeAscii(
            'LO${o.x1},${o.y1},${(o.x2 - o.x1).abs()},${(o.y2 - o.y1).abs()}\n',
          );
        }

      case CircleElement():
      case EllipseElement():
      case ReverseElement():
      case EraseElement():
        // EPL doesn't support these natively
        break;

      case BarcodeElement():
        final o = el.options;
        final type = o.type == '39' ? '3' : '1'; // 3=Code39, 1=Code128
        final rot = o.rotation == 90
            ? 1
            : o.rotation == 180
            ? 2
            : o.rotation == 270
            ? 3
            : 0;
        final hr = o.readable == 1 ? 'B' : 'N';
        final n = o.narrow ?? 2;
        final w = o.wide ?? 4;
        writer.writeAscii('B${o.x},${o.y},$rot,$type,$n,$w,${o.height},$hr,"');
        writer.writeAscii(el.content);
        writer.writeAscii('"\n');

      case QRCodeElement():
        final o = el.options;
        final cw = o.cellWidth ?? 4;
        final ecc = o.eccLevel ?? 'Q';
        writer.writeAscii('b${o.x},${o.y},"Q",m2,s$cw,e$ecc,"');
        writer.writeAscii(el.content);
        writer.writeAscii('"\n');

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

  writer.writeAscii('P${label.copies}\n');
  return writer.toBytes();
}

/// Compile a resolved label to EPL2 commands as a [String].
///
/// Decodes the underlying byte stream via [latin1.decode], providing a 1:1 lossless
/// mapping of 8-bit byte values.
String compileToEPL(ResolvedLabel label, {EplEncoding? encoding}) {
  final bytes = compileToEPLBytes(label, encoding: encoding);
  return latin1.decode(bytes);
}

int _eplRotation(int degrees) {
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
