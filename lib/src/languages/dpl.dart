import '../types.dart';

/// Compile a resolved label to DPL commands.
String compileToDPL(ResolvedLabel label) {
  final buf = StringBuffer();

  // STX L — Start label
  buf.write('\x02L\n');
  buf.write('D${label.density.toString().padLeft(2, '0')}\n');
  buf.write('S${label.speed.toString().padLeft(2, '0')}\n');
  buf.write('A${label.widthDots.toString().padLeft(4, '0')}\n');
  if (label.copies > 1) {
    buf.write('Q${label.copies.toString().padLeft(4, '0')}\n');
  } else {
    buf.write('Q0001\n');
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
        buf.write('$rotation');
        buf.write('${_pad4(y)}');
        buf.write('${_pad4(x)}');
        buf.write('$font');
        buf.write('${xMul.toString().padLeft(2, '0')}');
        buf.write('${yMul.toString().padLeft(2, '0')}');
        buf.write('${el.content}\n');

      case BoxElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        buf.write('1e${_pad4(o.y)}${_pad4(o.x)}${_pad4(o.width)}${_pad4(o.height)}${_pad4(t)}\n');

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          buf.write('1X${_pad4(o.y1)}${_pad4(x)}L${_pad4(w)}$t\n');
        } else {
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          buf.write('1X${_pad4(y)}${_pad4(o.x1)}L${_pad4(h)}$t\n');
        }

      case ImageElement():
      case CircleElement():
      case EllipseElement():
      case ReverseElement():
      case EraseElement():
        break;

      case RawElement():
        if (el.content is String) {
          buf.write('${el.content}\n');
        }
    }
  }

  buf.write('E\n');
  return buf.toString();
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
