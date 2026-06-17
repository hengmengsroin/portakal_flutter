import '../types.dart';

/// Compile a resolved label to CPCL commands.
String compileToCPCL(ResolvedLabel label) {
  final buf = StringBuffer();

  // Session header: ! offset hDPI vDPI height qty
  buf.write(
    '! 0 ${label.dpi} ${label.dpi} ${label.heightDots} ${label.copies}\r\n',
  );

  if (label.density > 0) {
    buf.write(
      'TONE ${label.density > 8
          ? 2
          : label.density > 4
          ? 1
          : 0}\r\n',
    );
  }
  if (label.speed > 0) {
    buf.write('SPEED ${label.speed}\r\n');
  }
  buf.write('PAGE-WIDTH ${label.widthDots}\r\n');

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final font = o.font ?? '2';
        final size = o.size ?? 0;
        final r = o.rotation ?? 0;
        final cmd = r == 90
            ? 'TEXT90'
            : r == 180
            ? 'TEXT180'
            : r == 270
            ? 'TEXT270'
            : 'TEXT';
        buf.write('$cmd $font $size $x $y\r\n');
        buf.write('${el.content}\r\n');
        if (o.size != null && o.size! > 1) {
          buf.write('SETMAG ${o.size} ${o.size}\r\n');
        }

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        final hexData = bmp.data
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join();
        buf.write('EG ${bmp.bytesPerRow} ${bmp.height} $x $y $hexData\r\n');

      case BoxElement():
        final o = el.options;
        final x2 = o.x + o.width;
        final y2 = o.y + o.height;
        final t = o.thickness ?? 1;
        buf.write('BOX ${o.x} ${o.y} $x2 $y2 $t\r\n');

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        buf.write('LINE ${o.x1} ${o.y1} ${o.x2} ${o.y2} $t\r\n');

      case CircleElement():
      case EllipseElement():
      case ReverseElement():
      case EraseElement():
        break;

      case BarcodeElement():
        final o = el.options;
        final type = o.type == '39' ? '39' : '128';
        final n = o.narrow ?? 1;
        final ratio = (o.wide ?? 2) ~/ n;
        if (o.readable == 1) {
          buf.write('BARCODE-TEXT 7 0 5\r\n');
        }
        buf.write('BARCODE $type $n $ratio ${o.height} ${o.x} ${o.y} ${el.content}\r\n');
        if (o.readable == 1) {
          buf.write('BARCODE-TEXT OFF\r\n');
        }

      case QRCodeElement():
        final o = el.options;
        final cw = o.cellWidth ?? 4;
        buf.write('BARCODE QR ${o.x} ${o.y} M 2 U $cw\r\n');
        buf.write('MA,${el.content}\r\n');
        buf.write('ENDQR\r\n');

      case RawElement():
        if (el.content is String) {
          buf.write('${el.content}\r\n');
        }
    }
  }

  buf.write('PRINT\r\n');
  return buf.toString();
}
