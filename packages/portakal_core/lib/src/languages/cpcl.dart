import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';
import 'cpcl_writer.dart';

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
  CpclCommandWriter.writeHeader(
    writer,
    offset: 0,
    hDpi: label.dpi,
    vDpi: label.dpi,
    heightDots: label.heightDots,
    copies: label.copies,
  );

  // If COUNTRY command is configured, emit COUNTRY <country>\r\n
  if (enc.sendCountryCommand && enc.country != null) {
    CpclCommandWriter.writeCountry(writer, enc.country!);
  }

  if (label.density > 0) {
    final tone = label.density > 8
        ? 2
        : label.density > 4
        ? 1
        : 0;
    CpclCommandWriter.writeTone(writer, tone);
  }
  if (label.speed > 0) {
    CpclCommandWriter.writeSpeed(writer, label.speed);
  }
  CpclCommandWriter.writePageWidth(writer, label.widthDots);

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final font = o.font ?? '2';
        final size = o.size ?? 0;
        final r = o.rotation ?? 0;

        CpclCommandWriter.writeText(
          writer,
          x: x,
          y: y,
          font: font,
          size: size,
          rotation: r,
          text: el.content,
          encoder: encoder,
          replaceUnsupported: enc.replaceUnsupported,
        );
        if (o.size != null && o.size! > 1) {
          CpclCommandWriter.writeSetMag(writer, o.size!, o.size!);
        }

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        CpclCommandWriter.writeExpandedGraphic(
          writer,
          x: x,
          y: y,
          bytesPerRow: bmp.bytesPerRow,
          height: bmp.height,
          data: bmp.data,
        );

      case BoxElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        CpclCommandWriter.writeBox(
          writer,
          x: o.x,
          y: o.y,
          width: o.width,
          height: o.height,
          thickness: t,
        );

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        CpclCommandWriter.writeLine(
          writer,
          x1: o.x1,
          y1: o.y1,
          x2: o.x2,
          y2: o.y2,
          thickness: t,
        );

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
        CpclCommandWriter.writeBarcode(
          writer,
          x: o.x,
          y: o.y,
          typeCode: type,
          narrowBarWidth: n,
          wideRatio: ratio == 0 ? 1 : ratio,
          height: o.height,
          humanReadable: o.readable == 1,
          content: el.content,
        );

      case QRCodeElement():
        final o = el.options;
        final cw = o.cellWidth ?? 4;
        CpclCommandWriter.writeQrCode(
          writer,
          x: o.x,
          y: o.y,
          cellWidth: cw,
          content: el.content,
          encoder: encoder,
          replaceUnsupported: enc.replaceUnsupported,
        );

      case RawElement():
        if (el.content is Uint8List) {
          CpclCommandWriter.writeRawBytes(writer, el.content as Uint8List);
        } else if (el.content is List<int>) {
          CpclCommandWriter.writeRawBytes(writer, el.content as List<int>);
        } else if (el.content is String) {
          CpclCommandWriter.writeRawAscii(
            writer,
            el.content as String,
            appendNewline: true,
          );
        }
    }
  }

  CpclCommandWriter.writePrint(writer);
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
