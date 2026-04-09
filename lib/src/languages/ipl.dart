import '../types.dart';

/// Compile a resolved label to IPL commands.
String compileToIPL(ResolvedLabel label) {
  final buf = StringBuffer();

  // STX ESC C1 ETX — Create format
  buf.write('\x02\x1bC1\x03');
  // STX ESC P ETX — Program mode
  buf.write('\x02\x1bP\x03');

  // Label size config
  buf.write('\x02<SI>L${label.heightDots}\x03');
  buf.write('\x02<SI>W${label.widthDots}\x03');

  if (label.speed > 0) {
    buf.write('\x02<SI>S${label.speed}0\x03');
  }
  if (label.density > 0) {
    buf.write('\x02<SI>d${label.density}\x03');
  }

  int fieldNum = 0;

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        fieldNum++;
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final rotation = _iplRotation(o.rotation ?? 0);
        buf.write('\x02H$fieldNum;o$x,$y;f$rotation;');
        // Font and size
        final size = o.size ?? 1;
        buf.write('h${size * 12};w${size * 12};c26;');
        buf.write('d3,${el.content}\x03');

      case BoxElement():
        fieldNum++;
        final o = el.options;
        buf.write('\x02W$fieldNum;o${o.x},${o.y};f0;');
        buf.write('l${o.width};h${o.height};w${o.thickness ?? 1}\x03');

      case LineElement():
        fieldNum++;
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal
          final len = (o.x2 - o.x1).abs();
          buf.write('\x02L$fieldNum;o${o.x1},${o.y1};f0;l$len;w$t\x03');
        } else if (o.x1 == o.x2) {
          // Vertical
          final len = (o.y2 - o.y1).abs();
          buf.write('\x02L$fieldNum;o${o.x1},${o.y1};f1;l$len;w$t\x03');
        }

      case CircleElement():
      case EllipseElement():
      case ImageElement():
      case ReverseElement():
      case EraseElement():
        break;

      case RawElement():
        if (el.content is String) {
          buf.write(el.content as String);
        }
    }
  }

  if (label.copies > 1) {
    buf.write('\x02\x1bM${label.copies}\x03');
  }

  // STX ESC E1 ETX — End format
  buf.write('\x02\x1bE1\x03');
  // STX R ETX — Print
  buf.write('\x02R\x03');

  return buf.toString();
}

int _iplRotation(int degrees) {
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
