import '../types.dart';

/// Convert a byte to 2-char uppercase hex.
String _hex(int byte) => byte.toRadixString(16).toUpperCase().padLeft(2, '0');

/// Compile a resolved label to ZPL II commands.
String compileToZPL(ResolvedLabel label) {
  final buf = StringBuffer();

  buf.write('^XA\n');
  buf.write('^CI28\n');
  buf.write('^PW${label.widthDots}\n');
  if (label.heightDots > 0) {
    buf.write('^LL${label.heightDots}\n');
  }
  if (label.speed > 0) {
    buf.write('^PR${label.speed}\n');
  }
  if (label.density > 0) {
    buf.write('~SD${label.density.toString().padLeft(2, '0')}\n');
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
        buf.write('^FO$x,$y');
        buf.write('^A0$r,$h,$w');
        if (o.maxWidth != null) {
          final align = o.align == 'center' ? 'C' : o.align == 'right' ? 'R' : 'L';
          buf.write('^FB${o.maxWidth},1,0,$align');
        }
        if (o.reverse == true) {
          buf.write('^FR');
        }
        buf.write('^FD${el.content}^FS\n');

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        final totalBytes = bmp.data.length;
        final hexData = bmp.data.map(_hex).join();
        buf.write('^FO$x,$y^GFA,$totalBytes,$totalBytes,${bmp.bytesPerRow},$hexData^FS\n');

      case BoxElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        final r = o.radius ?? 0;
        buf.write('^FO${o.x},${o.y}^GB${o.width},${o.height},$t,B,$r^FS\n');

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal line
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          buf.write('^FO$x,${o.y1}^GB$w,$t,$t^FS\n');
        } else if (o.x1 == o.x2) {
          // Vertical line
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          buf.write('^FO${o.x1},$y^GB$t,$h,$t^FS\n');
        } else {
          // Diagonal — use GD
          final w = (o.x2 - o.x1).abs();
          final h = (o.y2 - o.y1).abs();
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final dir = ((o.x2 > o.x1) == (o.y2 > o.y1)) ? 'R' : 'L';
          buf.write('^FO$x,$y^GD$w,$h,$t,B,$dir^FS\n');
        }

      case CircleElement():
        final o = el.options;
        buf.write('^FO${o.x},${o.y}^GC${o.diameter},${o.thickness ?? 1},B^FS\n');

      case EllipseElement():
        // ZPL has no native ellipse — skip
        break;

      case ReverseElement():
        // ZPL uses ^FR on text — region reverse not directly supported
        break;

      case EraseElement():
        final o = el.options;
        buf.write('^FO${o.x},${o.y}^GB${o.width},${o.height},${o.width},W^FS\n');

      case RawElement():
        if (el.content is String) {
          buf.write('${el.content}\n');
        }
    }
  }

  buf.write('^PQ${label.copies}\n');
  buf.write('^XZ\n');
  return buf.toString();
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
