import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../types.dart';
import 'epl_writer.dart';

/// Compile a resolved label to EPL2 commands as a byte sequence ([Uint8List]).
///
/// If [encoding] is supplied, text fields are encoded using the configured [CodePageEncoder]
/// and character set selection commands (`I8,<countryCode>,001`) are emitted if requested.
/// If omitted, defaults to [EplEncoding.defaultEncoding] ([EplEncoding.legacy]), preserving
/// exact historical EPL baseline behavior.
Uint8List compileToEPLBytes(
  ResolvedLabel label, {
  EplEncoding? encoding,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final enc = encoding ?? EplEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  EplCommandWriter.writeClear(writer);

  // If character set command is configured, emit I8,<countryCode>,001\n
  if (enc.sendSetCharSetCommand && enc.countryCode != null) {
    EplCommandWriter.writeCharSet(writer, enc.countryCode!);
  }

  EplCommandWriter.writeLabelWidth(writer, label.widthDots);
  if (label.heightDots > 0) {
    EplCommandWriter.writeLabelLength(writer, label.heightDots, gapDots: 24);
  }
  if (label.speed > 0) {
    EplCommandWriter.writeSpeed(writer, label.speed);
  }
  if (label.density > 0) {
    EplCommandWriter.writeDensity(writer, label.density);
  }

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final font = o.font ?? '2';
        final rotation = _eplRotation(o.rotation ?? 0);
        final xMul = o.xScale ?? o.size ?? 1;
        final yMul = o.yScale ?? o.size ?? 1;
        final reverse = o.reverse == true;

        EplCommandWriter.writeText(
          writer,
          x: x,
          y: y,
          rotation: rotation,
          font: font,
          xMultiplier: xMul,
          yMultiplier: yMul,
          reverse: reverse,
          text: el.content,
          encoder: encoder,
          replaceUnsupported: enc.replaceUnsupported,
        );

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        // EPL GW: polarity INVERTED (0=black in data)
        EplCommandWriter.writeGraphic(
          writer,
          x: x,
          y: y,
          bytesPerRow: bmp.bytesPerRow,
          height: bmp.height,
          data: bmp.data,
          invert: true,
        );

      case BoxElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        EplCommandWriter.writeBox(
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
        if (o.y1 == o.y2) {
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          final width = w == 0 ? 1 : w;
          EplCommandWriter.writeLine(
            writer,
            x: x,
            y: o.y1,
            width: width,
            height: t,
          );
        } else if (o.x1 == o.x2) {
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          final height = h == 0 ? 1 : h;
          EplCommandWriter.writeLine(
            writer,
            x: o.x1,
            y: y,
            width: t,
            height: height,
          );
        } else {
          // EPL doesn't support diagonal — approximate with LO
          final w = (o.x2 - o.x1).abs();
          final h = (o.y2 - o.y1).abs();
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          EplCommandWriter.writeLine(
            writer,
            x: x,
            y: y,
            width: w == 0 ? 1 : w,
            height: h == 0 ? 1 : h,
          );
        }

      case CircleElement():
      case EllipseElement():
      case ReverseElement():
      case EraseElement():
        // EPL doesn't support these natively
        break;

      case BarcodeElement():
        final o = el.options;
        final type = o.type == '39' ? '3' : '1'; // 3=Code39, 1=Code128
        final rot = _eplRotation(o.rotation ?? 0);
        final hr = o.readable == 1;
        final n = o.narrow ?? 2;
        final w = o.wide ?? 4;
        EplCommandWriter.writeBarcode(
          writer,
          x: o.x,
          y: o.y,
          rotation: rot,
          typeCode: type,
          narrowBarWidth: n,
          wideBarWidth: w,
          height: o.height,
          humanReadable: hr,
          content: el.content,
        );

      case QRCodeElement():
        final o = el.options;
        final cw = o.cellWidth ?? 4;
        final ecc = o.eccLevel ?? 'Q';
        EplCommandWriter.writeQrCode(
          writer,
          x: o.x,
          y: o.y,
          cellWidth: cw,
          eccCode: ecc,
          content: el.content,
          encoder: encoder,
          replaceUnsupported: enc.replaceUnsupported,
        );

      case RawElement():
        EplCommandWriter.writeRawBytes(writer, el.bytes);
    }
  }

  EplCommandWriter.writePrint(writer, sets: label.copies, copies: 1);
  return writer.toBytes();
}

/// Compile a resolved label to EPL2 commands as a [String] compatibility view.
///
/// Decodes the underlying byte stream via [latin1.decode], providing a 1:1 lossless
/// mapping of 8-bit byte values.
@Deprecated(
  'Use compileToEPLBytes instead. compileToEPL is a Latin-1 compatibility view and will be removed in 2.0.',
)
String compileToEPL(
  ResolvedLabel label, {
  EplEncoding? encoding,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final bytes = compileToEPLBytes(label, encoding: encoding, policy: policy);
  return latin1.decode(bytes);
}

int _eplRotation(int degrees) {
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
