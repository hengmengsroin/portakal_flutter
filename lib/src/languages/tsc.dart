import '../types.dart';

/// Compile a resolved label to TSC/TSPL2 commands.
String compileToTSC(ResolvedLabel label) {
  final buf = StringBuffer();

  // Label setup
  if (label.unit == Unit.dot) {
    buf.write('SIZE ${label.widthDots} dot,${label.heightDots} dot\r\n');
  } else if (label.unit == Unit.inch) {
    // Convert back from dots to inches for the command
    final wInch = label.widthDots / label.dpi;
    final hInch = label.heightDots / label.dpi;
    buf.write('SIZE $wInch,$hInch\r\n');
  } else {
    // mm: convert dots back to mm
    final wMM = (label.widthDots / label.dpi * 25.4).round();
    final hMM = (label.heightDots / label.dpi * 25.4).round();
    buf.write('SIZE $wMM mm,$hMM mm\r\n');
  }

  buf.write('GAP 3 mm,0 mm\r\n');
  buf.write('SPEED ${label.speed}\r\n');
  buf.write('DENSITY ${label.density}\r\n');
  buf.write('DIRECTION ${label.direction}\r\n');
  buf.write('CLS\r\n');

  // Elements
  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final font = o.font ?? '2';
        final rotation = o.rotation ?? 0;
        final xMul = o.xScale ?? o.size ?? 1;
        final yMul = o.yScale ?? o.size ?? 1;
        buf.write(
          'TEXT $x,$y,"$font",$rotation,$xMul,$yMul,"${el.content}"\r\n',
        );

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        buf.write('BITMAP $x,$y,${bmp.bytesPerRow},${bmp.height},0,');
        // Append raw bitmap data
        for (int i = 0; i < bmp.data.length; i++) {
          buf.write(String.fromCharCode(bmp.data[i]));
        }
        buf.write('\r\n');

      case BoxElement():
        final o = el.options;
        final x2 = o.x + o.width;
        final y2 = o.y + o.height;
        final t = o.thickness ?? 1;
        if (o.radius != null && o.radius! > 0) {
          buf.write('BOX ${o.x},${o.y},$x2,$y2,$t,${o.radius}\r\n');
        } else {
          buf.write('BOX ${o.x},${o.y},$x2,$y2,$t\r\n');
        }

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal line → BAR
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          buf.write('BAR $x,${o.y1},$w,$t\r\n');
        } else if (o.x1 == o.x2) {
          // Vertical line → BAR
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          buf.write('BAR ${o.x1},$y,$t,$h\r\n');
        } else {
          // Diagonal
          buf.write('DIAGONAL ${o.x1},${o.y1},${o.x2},${o.y2},$t\r\n');
        }

      case CircleElement():
        final o = el.options;
        buf.write('CIRCLE ${o.x},${o.y},${o.diameter},${o.thickness ?? 1}\r\n');

      case EllipseElement():
        final o = el.options;
        buf.write(
          'ELLIPSE ${o.x},${o.y},${o.width},${o.height},${o.thickness ?? 1}\r\n',
        );

      case BarcodeElement():
        final o = el.options;
        buf.write(
          'BARCODE ${o.x},${o.y},"${o.type}",${o.height},${o.readable ?? 0},${o.rotation ?? 0},${o.narrow ?? 2},${o.wide ?? 4}',
        );
        if (o.alignment != null) buf.write(',${o.alignment}');
        buf.write(',"${el.content}"\r\n');

      case QRCodeElement():
        final o = el.options;
        final ecc = o.eccLevel ?? 'H';
        final cw = o.cellWidth ?? 4;
        final mode = o.mode ?? 'A';
        final rot = o.rotation ?? 0;
        buf.write('QRCODE ${o.x},${o.y},"$ecc",$cw,"$mode",$rot,');
        if (o.model != null) buf.write('"${o.model}",');
        if (o.mask != null) buf.write('"${o.mask}",');
        buf.write('"${el.content}"\r\n');

      case ReverseElement():
        final o = el.options;
        buf.write('REVERSE ${o.x},${o.y},${o.width},${o.height}\r\n');

      case EraseElement():
        final o = el.options;
        buf.write('ERASE ${o.x},${o.y},${o.width},${o.height}\r\n');

      case RawElement():
        if (el.content is String) {
          buf.write('${el.content}\r\n');
        }
    }
  }

  buf.write('PRINT ${label.copies}\r\n');
  return buf.toString();
}
