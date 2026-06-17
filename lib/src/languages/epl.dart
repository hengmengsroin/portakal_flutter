import 'dart:typed_data';
import '../types.dart';

/// Compile a resolved label to EPL2 commands.
String compileToEPL(ResolvedLabel label) {
  final buf = StringBuffer();

  buf.write('N\n');
  buf.write('q${label.widthDots}\n');
  if (label.heightDots > 0) {
    buf.write('Q${label.heightDots},24\n');
  }
  buf.write('S${label.speed}\n');
  buf.write('D${label.density}\n');

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
        buf.write(
          'A$x,$y,$rotation,$font,$xMul,$yMul,$reverse,"${el.content}"\n',
        );

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        // EPL GW: polarity INVERTED (0=black in data)
        buf.write('GW$x,$y,${bmp.bytesPerRow},${bmp.height}\n');
        // Binary image data follows — we write inverted bytes
        final inverted = Uint8List(bmp.data.length);
        for (int i = 0; i < bmp.data.length; i++) {
          inverted[i] = ~bmp.data[i] & 0xFF;
        }
        buf.write(String.fromCharCodes(inverted));
        buf.write('\n');

      case BoxElement():
        final o = el.options;
        final x2 = o.x + o.width;
        final y2 = o.y + o.height;
        final t = o.thickness ?? 1;
        buf.write('X${o.x},${o.y},$x2,$y2,$t\n');

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          buf.write('LO$x,${o.y1},$w,$t\n');
        } else if (o.x1 == o.x2) {
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          buf.write('LO${o.x1},$y,$t,$h\n');
        } else {
          // EPL doesn't support diagonal — approximate with LO
          buf.write(
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
        buf.write(
          'B${o.x},${o.y},$rot,$type,$n,$w,${o.height},$hr,"${el.content}"\n',
        );

      case QRCodeElement():
        final o = el.options;
        final cw = o.cellWidth ?? 4;
        final ecc = o.eccLevel ?? 'Q';
        buf.write('b${o.x},${o.y},"Q",m2,s$cw,e$ecc,"${el.content}"\n');

      case RawElement():
        if (el.content is String) {
          buf.write('${el.content}\n');
        }
    }
  }

  buf.write('P${label.copies}\n');
  return buf.toString();
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
