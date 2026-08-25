import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../types.dart';

/// Compile a resolved label to TSC/TSPL2 binary commands as [Uint8List].
///
/// This is the canonical, byte-safe serializer that preserves raw binary payloads
/// (e.g. [MonochromeBitmap] data in BITMAP commands) without intermediate String
/// transformations.
Uint8List compileToTSCBytes(ResolvedLabel label) {
  final writer = PrinterByteWriter();

  // Label setup
  if (label.unit == Unit.dot) {
    writer.writeAscii(
      'SIZE ${label.widthDots} dot,${label.heightDots} dot\r\n',
    );
  } else if (label.unit == Unit.inch) {
    // Convert back from dots to inches for the command
    final wInch = label.widthDots / label.dpi;
    final hInch = label.heightDots / label.dpi;
    writer.writeAscii('SIZE $wInch,$hInch\r\n');
  } else {
    // mm: convert dots back to mm
    final wMM = (label.widthDots / label.dpi * 25.4).round();
    final hMM = (label.heightDots / label.dpi * 25.4).round();
    writer.writeAscii('SIZE $wMM mm,$hMM mm\r\n');
  }

  writer.writeAscii('GAP 3 mm,0 mm\r\n');
  writer.writeAscii('SPEED ${label.speed}\r\n');
  writer.writeAscii('DENSITY ${label.density}\r\n');
  writer.writeAscii('DIRECTION ${label.direction}\r\n');
  writer.writeAscii('CLS\r\n');

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
        writer.writeAscii('TEXT $x,$y,"$font",$rotation,$xMul,$yMul,"');
        writer.writeString(el.content, encoding: latin1);
        writer.writeAscii('"\r\n');

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        writer.writeAscii('BITMAP $x,$y,${bmp.bytesPerRow},${bmp.height},0,');
        // Append raw 8-bit binary bitmap data directly
        writer.writeBytes(bmp.data);
        writer.writeAscii('\r\n');

      case BoxElement():
        final o = el.options;
        final x2 = o.x + o.width;
        final y2 = o.y + o.height;
        final t = o.thickness ?? 1;
        if (o.radius != null && o.radius! > 0) {
          writer.writeAscii('BOX ${o.x},${o.y},$x2,$y2,$t,${o.radius}\r\n');
        } else {
          writer.writeAscii('BOX ${o.x},${o.y},$x2,$y2,$t\r\n');
        }

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal line → BAR
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          writer.writeAscii('BAR $x,${o.y1},$w,$t\r\n');
        } else if (o.x1 == o.x2) {
          // Vertical line → BAR
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          writer.writeAscii('BAR ${o.x1},$y,$t,$h\r\n');
        } else {
          // Diagonal
          writer.writeAscii('DIAGONAL ${o.x1},${o.y1},${o.x2},${o.y2},$t\r\n');
        }

      case CircleElement():
        final o = el.options;
        writer.writeAscii(
          'CIRCLE ${o.x},${o.y},${o.diameter},${o.thickness ?? 1}\r\n',
        );

      case EllipseElement():
        final o = el.options;
        writer.writeAscii(
          'ELLIPSE ${o.x},${o.y},${o.width},${o.height},${o.thickness ?? 1}\r\n',
        );

      case BarcodeElement():
        final o = el.options;
        writer.writeAscii(
          'BARCODE ${o.x},${o.y},"${o.type}",${o.height},${o.readable ?? 0},${o.rotation ?? 0},${o.narrow ?? 2},${o.wide ?? 4}',
        );
        if (o.alignment != null) writer.writeAscii(',${o.alignment}');
        writer.writeAscii(',"${el.content}"\r\n');

      case QRCodeElement():
        final o = el.options;
        final ecc = o.eccLevel ?? 'H';
        final cw = o.cellWidth ?? 4;
        final mode = o.mode ?? 'A';
        final rot = o.rotation ?? 0;
        writer.writeAscii('QRCODE ${o.x},${o.y},"$ecc",$cw,"$mode",$rot,');
        if (o.model != null) writer.writeAscii('"${o.model}",');
        if (o.mask != null) writer.writeAscii('"${o.mask}",');
        writer.writeAscii('"${el.content}"\r\n');

      case ReverseElement():
        final o = el.options;
        writer.writeAscii('REVERSE ${o.x},${o.y},${o.width},${o.height}\r\n');

      case EraseElement():
        final o = el.options;
        writer.writeAscii('ERASE ${o.x},${o.y},${o.width},${o.height}\r\n');

      case RawElement():
        if (el.content is Uint8List) {
          writer.writeBytes(el.content as Uint8List);
        } else if (el.content is List<int>) {
          writer.writeBytes(el.content as List<int>);
        } else if (el.content is String) {
          writer.writeString(el.content as String, encoding: latin1);
          writer.writeAscii('\r\n');
        }
    }
  }

  writer.writeAscii('PRINT ${label.copies}\r\n');
  return writer.toBytes();
}

/// Compile a resolved label to TSC/TSPL2 commands as a [String].
///
/// Note: For binary content (e.g. BITMAP commands), prefer [compileToTSCBytes]
/// to avoid string character encoding ambiguities during transmission.
String compileToTSC(ResolvedLabel label) {
  final bytes = compileToTSCBytes(label);
  return latin1.decode(bytes);
}
