import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';

const int _stx = 0x02;
const int _etx = 0x03;
const int _esc = 0x1B;
const int _si = 0x0F;

/// Compile a resolved label to IPL commands as a byte sequence ([Uint8List]).
///
/// Uses actual control bytes (`STX` = 0x02, `ETX` = 0x03, `ESC` = 0x1B, `SI` = 0x0F).
/// If [encoding] is supplied, text fields are encoded using the configured [CodePageEncoder].
/// Control characters (`STX`, `ETX`, `ESC`) inside text fields are explicitly rejected with
/// [UnsupportedCharacterException] (or replaced with `?` if `replaceUnsupported: true`) to prevent
/// framing corruption.
/// If omitted, defaults to [IplEncoding.defaultEncoding] ([IplEncoding.legacy]).
Uint8List compileToIPLBytes(ResolvedLabel label, {IplEncoding? encoding}) {
  final enc = encoding ?? IplEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  // STX ESC C1 ETX — Create format 1 / Advanced mode
  writer.writeByte(_stx);
  writer.writeByte(_esc);
  writer.writeAscii('C1');
  writer.writeByte(_etx);

  // STX ESC P ETX — Enter Program mode
  writer.writeByte(_stx);
  writer.writeByte(_esc);
  writer.writeAscii('P');
  writer.writeByte(_etx);

  // Label size and printer configuration: <STX><SI>L<height><ETX>, <STX><SI>W<width><ETX>
  writer.writeByte(_stx);
  writer.writeByte(_si);
  writer.writeAscii('L${label.heightDots}');
  writer.writeByte(_etx);

  writer.writeByte(_stx);
  writer.writeByte(_si);
  writer.writeAscii('W${label.widthDots}');
  writer.writeByte(_etx);

  if (label.speed > 0) {
    writer.writeByte(_stx);
    writer.writeByte(_si);
    writer.writeAscii('S${label.speed}0');
    writer.writeByte(_etx);
  }
  if (label.density > 0) {
    writer.writeByte(_stx);
    writer.writeByte(_si);
    writer.writeAscii('d${label.density}');
    writer.writeByte(_etx);
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
        final size = o.size ?? 1;

        writer.writeByte(_stx);
        writer.writeAscii('H$fieldNum;o$x,$y;f$rotation;');
        writer.writeAscii('h${size * 12};w${size * 12};c26;');
        writer.writeAscii('d3,');

        final textBytes = _encodeIplText(
          el.content,
          encoder,
          replaceUnsupported: enc.replaceUnsupported,
        );
        writer.writeBytes(textBytes);
        writer.writeByte(_etx);

      case BoxElement():
        fieldNum++;
        final o = el.options;
        writer.writeByte(_stx);
        writer.writeAscii('W$fieldNum;o${o.x},${o.y};f0;');
        writer.writeAscii('l${o.width};h${o.height};w${o.thickness ?? 1}');
        writer.writeByte(_etx);

      case LineElement():
        fieldNum++;
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal line
          final len = (o.x2 - o.x1).abs();
          writer.writeByte(_stx);
          writer.writeAscii('L$fieldNum;o${o.x1},${o.y1};f0;l$len;w$t');
          writer.writeByte(_etx);
        } else if (o.x1 == o.x2) {
          // Vertical line
          final len = (o.y2 - o.y1).abs();
          writer.writeByte(_stx);
          writer.writeAscii('L$fieldNum;o${o.x1},${o.y1};f1;l$len;w$t');
          writer.writeByte(_etx);
        }

      case CircleElement():
      case EllipseElement():
      case ImageElement():
      case ReverseElement():
      case EraseElement():
        // Universal AST does not implement graphic download commands for IPL currently
        break;

      case BarcodeElement():
        final o = el.options;
        writer.writeByte(_stx);
        writer.writeAscii(
          'B1;o0;f0;c0;h${o.height};w${o.wide ?? 2};d0,${o.y};',
        );
        writer.writeByte(_etx);
        writer.writeAscii('\n');
        writer.writeByte(_stx);
        writer.writeAscii(el.content);
        writer.writeByte(_etx);
        writer.writeAscii('\n');

      case QRCodeElement():
        final o = el.options;
        writer.writeByte(_stx);
        writer.writeAscii(
          'B2;o0;f0;c21;w${o.cellWidth ?? 4};h${o.cellWidth ?? 4};d0,${o.y};',
        );
        writer.writeByte(_etx);
        writer.writeAscii('\n');
        writer.writeByte(_stx);
        writer.writeAscii(el.content);
        writer.writeByte(_etx);
        writer.writeAscii('\n');

      case RawElement():
        if (el.content is Uint8List) {
          writer.writeBytes(el.content as Uint8List);
        } else if (el.content is List<int>) {
          writer.writeBytes(el.content as List<int>);
        } else if (el.content is String) {
          writer.writeString(el.content as String, encoding: latin1);
        }
    }
  }

  if (label.copies > 1) {
    writer.writeByte(_stx);
    writer.writeByte(_esc);
    writer.writeAscii('M${label.copies}');
    writer.writeByte(_etx);
  }

  // STX ESC E1 ETX — End format
  writer.writeByte(_stx);
  writer.writeByte(_esc);
  writer.writeAscii('E1');
  writer.writeByte(_etx);

  // STX R ETX — Print / Execute
  writer.writeByte(_stx);
  writer.writeAscii('R');
  writer.writeByte(_etx);

  return writer.toBytes();
}

/// Helper to encode text and guard against dangerous control bytes that break IPL framing.
Uint8List _encodeIplText(
  String text,
  CodePageEncoder encoder, {
  bool replaceUnsupported = false,
}) {
  final bytes = encoder.encode(text, replaceUnsupported: replaceUnsupported);
  final result = Uint8List(bytes.length);
  for (int i = 0; i < bytes.length; i++) {
    final b = bytes[i];
    if (b == _stx || b == _etx || b == _esc) {
      if (replaceUnsupported) {
        result[i] = 0x3F; // '?'
      } else {
        throw UnsupportedCharacterException(
          character: String.fromCharCode(b),
          codePoint: b,
          codePage: encoder.codePage,
          message:
              'Control character (0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}) '
              'is not supported inside unescaped IPL text records.',
        );
      }
    } else {
      result[i] = b;
    }
  }
  return result;
}

/// Compile a resolved label to IPL commands as a [String].
///
/// Decodes the underlying byte stream via [latin1.decode], providing a 1:1 lossless
/// mapping of 8-bit byte values.
String compileToIPL(ResolvedLabel label, {IplEncoding? encoding}) {
  final bytes = compileToIPLBytes(label, encoding: encoding);
  return latin1.decode(bytes);
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
