import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';

/// Convert a byte to 2-char uppercase hex.
String _hex(int byte) => byte.toRadixString(16).toUpperCase().padLeft(2, '0');

/// Compile a resolved label to CPCL commands as a byte sequence ([Uint8List]).
///
/// If [encoding] is supplied, text fields are encoded using the configured [CodePageEncoder]
/// and `COUNTRY <name>\r\n` is emitted if requested.
/// If omitted, defaults to [CpclEncoding.defaultEncoding] ([CpclEncoding.legacy]), preserving
/// exact historical CPCL baseline output.
Uint8List compileToCPCLBytes(ResolvedLabel label, {CpclEncoding? encoding}) {
  final enc = encoding ?? CpclEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  // Session header: ! offset hDPI vDPI height qty
  writer.writeAscii(
    '! 0 ${label.dpi} ${label.dpi} ${label.heightDots} ${label.copies}\r\n',
  );

  // If COUNTRY command is configured, emit COUNTRY <country>\r\n
  if (enc.sendCountryCommand && enc.country != null) {
    writer.writeAscii('COUNTRY ${enc.country}\r\n');
  }

  if (label.density > 0) {
    writer.writeAscii(
      'TONE ${label.density > 8
          ? 2
          : label.density > 4
          ? 1
          : 0}\r\n',
    );
  }
  if (label.speed > 0) {
    writer.writeAscii('SPEED ${label.speed}\r\n');
  }
  writer.writeAscii('PAGE-WIDTH ${label.widthDots}\r\n');

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
        writer.writeAscii('$cmd $font $size $x $y\r\n');
        final textBytes = encoder.encode(
          el.content,
          replaceUnsupported: enc.replaceUnsupported,
        );
        writer.writeBytes(textBytes);
        writer.writeAscii('\r\n');
        if (o.size != null && o.size! > 1) {
          writer.writeAscii('SETMAG ${o.size} ${o.size}\r\n');
        }

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        final hexData = bmp.data.map(_hex).join();
        writer.writeAscii(
          'EG ${bmp.bytesPerRow} ${bmp.height} $x $y $hexData\r\n',
        );

      case BoxElement():
        final o = el.options;
        final x2 = o.x + o.width;
        final y2 = o.y + o.height;
        final t = o.thickness ?? 1;
        writer.writeAscii('BOX ${o.x} ${o.y} $x2 $y2 $t\r\n');

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        writer.writeAscii('LINE ${o.x1} ${o.y1} ${o.x2} ${o.y2} $t\r\n');

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
          writer.writeAscii('BARCODE-TEXT 7 0 5\r\n');
        }
        writer.writeAscii('BARCODE $type $n $ratio ${o.height} ${o.x} ${o.y} ');
        writer.writeAscii(el.content);
        writer.writeAscii('\r\n');
        if (o.readable == 1) {
          writer.writeAscii('BARCODE-TEXT OFF\r\n');
        }

      case QRCodeElement():
        final o = el.options;
        final cw = o.cellWidth ?? 4;
        writer.writeAscii('BARCODE QR ${o.x} ${o.y} M 2 U $cw\r\n');
        writer.writeAscii('MA,');
        writer.writeAscii(el.content);
        writer.writeAscii('\r\nENDQR\r\n');

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

  writer.writeAscii('PRINT\r\n');
  return writer.toBytes();
}

/// Compile a resolved label to CPCL commands as a [String].
///
/// Decodes the underlying byte stream via [latin1.decode], providing a 1:1 lossless
/// mapping of 8-bit byte values.
String compileToCPCL(ResolvedLabel label, {CpclEncoding? encoding}) {
  final bytes = compileToCPCLBytes(label, encoding: encoding);
  return latin1.decode(bytes);
}
