import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';
import 'ipl_writer.dart';

/// Compile a resolved label to IPL commands as a byte sequence ([Uint8List]).
///
/// Uses actual control bytes (`STX` = 0x02, `ETX` = 0x03, `ESC` = 0x1B, `SI` = 0x0F).
/// If [encoding] is supplied, text fields are encoded using the configured [CodePageEncoder].
/// Control characters (`STX`, `ETX`, `ESC`, `SI`) inside text fields are explicitly rejected with
/// [UnsupportedCharacterException] (or replaced with `?` if `replaceUnsupported: true`) to prevent
/// framing corruption.
/// If omitted, defaults to [IplEncoding.defaultEncoding] ([IplEncoding.legacy]).
Uint8List compileToIPLBytes(ResolvedLabel label, {IplEncoding? encoding}) {
  final enc = encoding ?? IplEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  // STX ESC C1 ETX — Create format 1 / Advanced mode
  IplCommandWriter.writeCreateFormat(writer, 1);

  // STX ESC P ETX — Enter Program mode
  IplCommandWriter.writeProgramMode(writer);

  // Label size and printer configuration: <STX><SI>L<height><ETX>, <STX><SI>W<width><ETX>
  IplCommandWriter.writeLabelLength(writer, label.heightDots);
  IplCommandWriter.writeLabelWidth(writer, label.widthDots);

  if (label.speed > 0) {
    IplCommandWriter.writeSpeed(writer, label.speed);
  }
  if (label.density > 0) {
    IplCommandWriter.writeDensity(writer, label.density);
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

        IplCommandWriter.writeTextField(
          writer,
          fieldNumber: fieldNum,
          x: x,
          y: y,
          rotation: rotation,
          fontHeight: size * 12,
          fontWidth: size * 12,
          fontCode: 26,
          text: el.content,
          encoder: encoder,
          replaceUnsupported: enc.replaceUnsupported,
        );

      case BoxElement():
        fieldNum++;
        final o = el.options;
        IplCommandWriter.writeBoxField(
          writer,
          fieldNumber: fieldNum,
          x: o.x,
          y: o.y,
          width: o.width,
          height: o.height,
          thickness: o.thickness ?? 1,
        );

      case LineElement():
        fieldNum++;
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal line
          final len = (o.x2 - o.x1).abs();
          IplCommandWriter.writeLineField(
            writer,
            fieldNumber: fieldNum,
            x: o.x1,
            y: o.y1,
            length: len,
            thickness: t,
            isVertical: false,
          );
        } else if (o.x1 == o.x2) {
          // Vertical line
          final len = (o.y2 - o.y1).abs();
          IplCommandWriter.writeLineField(
            writer,
            fieldNumber: fieldNum,
            x: o.x1,
            y: o.y1,
            length: len,
            thickness: t,
            isVertical: true,
          );
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
        IplCommandWriter.writeBarcodeField(
          writer,
          fieldNumber: 1,
          y: o.y,
          height: o.height,
          wideMultiplier: o.wide ?? 2,
          content: el.content,
          symbologyCode: 0,
        );

      case QRCodeElement():
        final o = el.options;
        IplCommandWriter.writeQrCodeField(
          writer,
          fieldNumber: 2,
          y: o.y,
          cellWidth: o.cellWidth ?? 4,
          content: el.content,
        );

      case RawElement():
        if (el.content is Uint8List) {
          IplCommandWriter.writeRawBytes(writer, el.content as Uint8List);
        } else if (el.content is List<int>) {
          IplCommandWriter.writeRawBytes(writer, el.content as List<int>);
        } else if (el.content is String) {
          IplCommandWriter.writeRawAscii(writer, el.content as String);
        }
    }
  }

  if (label.copies > 1) {
    IplCommandWriter.writeCopies(writer, label.copies);
  }

  // STX ESC E1 ETX — End format
  IplCommandWriter.writeEndFormat(writer, 1);

  // STX R ETX — Print / Execute
  IplCommandWriter.writePrint(writer);

  return writer.toBytes();
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
