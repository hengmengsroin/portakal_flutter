import '../types.dart';

/// Convert a byte to 2-char uppercase hex.
String _hex(int byte) => byte.toRadixString(16).toUpperCase().padLeft(2, '0');

/// Pad an integer to 4-char zero-filled string.
String _pad4(int n) => n.toString().padLeft(4, '0');

/// Compile a resolved label to SBPL commands.
String compileToSBPL(ResolvedLabel label) {
  final buf = StringBuffer();

  // ESC A — Start
  buf.write('\x1bA');
  // ESC CS — Clear buffer
  buf.write('\x1bCS');

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final size = o.size ?? 1;

        // Position
        buf.write('\x1bH${_pad4(x)}');
        buf.write('\x1bV${_pad4(y)}');

        // Rotation
        if (o.rotation != null && o.rotation! > 0) {
          buf.write('\x1b%${_sbplRotation(o.rotation!)}');
        }

        // Magnification
        buf.write('\x1bL${_pad2(size)}${_pad2(size)}');

        // Text output: ESC K9B
        buf.write('\x1bK9B${el.content}');

        // Reset rotation
        if (o.rotation != null && o.rotation! > 0) {
          buf.write('\x1b%0');
        }

      case BoxElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        buf.write('\x1bH${_pad4(o.x)}');
        buf.write('\x1bV${_pad4(o.y)}');
        buf.write('\x1bFW${_pad2(t)}V${_pad4(o.height)}H${_pad4(o.width)}');

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          buf.write('\x1bH${_pad4(x)}');
          buf.write('\x1bV${_pad4(o.y1)}');
          buf.write('\x1bFW${_pad2(t)}H${_pad4(w)}');
        } else if (o.x1 == o.x2) {
          // Vertical
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          buf.write('\x1bH${_pad4(o.x1)}');
          buf.write('\x1bV${_pad4(y)}');
          buf.write('\x1bFW${_pad2(t)}V${_pad4(h)}');
        }

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        buf.write('\x1bH${_pad4(x)}');
        buf.write('\x1bV${_pad4(y)}');
        final hexData = bmp.data.map(_hex).join();
        buf.write('\x1bGM${_pad5(bmp.data.length)},$hexData');

      case CircleElement():
      case EllipseElement():
      case ReverseElement():
      case EraseElement():
        break;

      case RawElement():
        if (el.content is String) {
          buf.write(el.content as String);
        }
    }
  }

  // Copies
  if (label.copies > 1) {
    buf.write('\x1bQ${label.copies}');
  }

  // ESC Z — End
  buf.write('\x1bZ');
  return buf.toString();
}

String _pad2(int n) => n.toString().padLeft(2, '0');
String _pad5(int n) => n.toString().padLeft(5, '0');

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
