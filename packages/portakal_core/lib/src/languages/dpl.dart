import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../errors.dart';
import '../types.dart';
import 'dpl_writer.dart';

/// Compile a resolved label to DPL commands as a byte sequence ([Uint8List]).
///
/// Uses actual control bytes (`STX` = 0x02, etc.).
///
/// NOTE: The legacy universal DPL serializer preserves historical Portakal / upstream
/// LF (`0x0A`, `\n`) record termination for backward compatibility, whereas the
/// protocol-native builder [DplPrinter] emits standard DPL CR (`0x0D`, `\r`) record termination.
///
/// If [encoding] is supplied, text fields are encoded using the configured [CodePageEncoder].
/// If omitted, defaults to [DplEncoding.defaultEncoding] ([DplEncoding.legacy]), preserving
/// exact historical DPL baseline output.
Uint8List compileToDPLBytes(
  ResolvedLabel label, {
  DplEncoding? encoding,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final enc = encoding ?? DplEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();
  const term = DplCommandWriter.legacyUniversalTerminator;

  // STX L — Start label formatting mode (0x02, 'L', '\n')
  DplCommandWriter.writeStartLabel(writer, terminator: term);

  DplCommandWriter.writeHeat(writer, label.density, terminator: term);
  DplCommandWriter.writeSpeed(
    writer,
    label.speed > 0 ? label.speed : 4,
    terminator: term,
  );
  DplCommandWriter.writeWidth(
    writer,
    label.widthDots > 0 ? label.widthDots : 320,
    terminator: term,
  );
  DplCommandWriter.writeCopies(
    writer,
    label.copies > 0 ? label.copies : 1,
    terminator: term,
  );

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final rotation = _dplRotation(o.rotation ?? 0);
        final font = o.font ?? '0';
        final xMul = o.xScale ?? o.size ?? 1;
        final yMul = o.yScale ?? o.size ?? 1;

        DplCommandWriter.writeText(
          writer,
          x: x,
          y: y,
          font: font,
          xMultiplier: xMul,
          yMultiplier: yMul,
          rotationCode: rotation,
          text: el.content,
          encoder: encoder,
          replaceUnsupported: enc.replaceUnsupported,
          terminator: term,
        );

      case BoxElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        DplCommandWriter.writeBox(
          writer,
          x: o.x,
          y: o.y,
          width: o.width,
          height: o.height,
          thickness: t,
          terminator: term,
        );

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        DplCommandWriter.writeLine(
          writer,
          x1: o.x1,
          y1: o.y1,
          x2: o.x2,
          y2: o.y2,
          thickness: t,
          terminator: term,
        );

      case ImageElement():
      case CircleElement():
      case EllipseElement():
      case ReverseElement():
      case EraseElement():
        if (policy == UnsupportedFeaturePolicy.throwError) {
          throw UnsupportedFeatureError(
            'DPL compiler does not support ${el.runtimeType}',
          );
        }
        break;

      case BarcodeElement():
        final o = el.options;
        final rot = o.rotation == 90
            ? '2'
            : o.rotation == 180
                ? '3'
                : o.rotation == 270
                    ? '4'
                    : '1';
        final type = o.type == '39' ? 'A' : 'E'; // E=Code128
        final w = o.wide ?? 2;
        DplCommandWriter.writeBarcode(
          writer,
          x: o.x,
          y: o.y,
          typeCode: type,
          wideMultiplier: w,
          height: o.height,
          rotationCode: rot,
          content: el.content,
          terminator: term,
        );

      case QRCodeElement():
        final o = el.options;
        final cw = o.cellWidth ?? 4;
        DplCommandWriter.writeQrCode(
          writer,
          x: o.x,
          y: o.y,
          cellWidth: cw,
          content: el.content,
          terminator: term,
        );

      case RawElement():
        DplCommandWriter.writeRawBytes(writer, el.bytes);

      case RowElement():
      case DividerElement():
        if (policy == UnsupportedFeaturePolicy.throwError) {
          throw UnsupportedFeatureError(
            'DPL compiler does not support ${el.runtimeType} in Slice 1',
          );
        }
        break;
    }
  }

  // E — End label format & print
  DplCommandWriter.writeEndLabel(writer, terminator: term);
  return writer.toBytes();
}

/// Compile a resolved label to DPL commands as a [String] compatibility view.
///
/// Decodes the underlying byte stream via `latin1.decode`, providing a 1:1 lossless
/// mapping of 8-bit byte values.
@Deprecated(
  'Use compileToDPLBytes instead. compileToDPL is a Latin-1 compatibility view and will be removed in 2.0.',
)
String compileToDPL(
  ResolvedLabel label, {
  DplEncoding? encoding,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final bytes = compileToDPLBytes(label, encoding: encoding, policy: policy);
  return latin1.decode(bytes);
}

String _dplRotation(int degrees) {
  switch (degrees) {
    case 90:
      return '2';
    case 180:
      return '3';
    case 270:
      return '4';
    default:
      return '1';
  }
}
