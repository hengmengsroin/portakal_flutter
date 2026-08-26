import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../errors.dart';
import '../types.dart';
import 'sbpl_writer.dart';

/// Compile a resolved label to SBPL commands as a byte sequence ([Uint8List]).
///
/// Uses actual control byte `ESC` = 0x1B.
/// If [encoding] is supplied, text fields are encoded using the configured [CodePageEncoder].
/// Control character `ESC` (0x1B) inside text fields is rejected with [UnsupportedCharacterException]
/// (or replaced with `?` if `replaceUnsupported: true`) to prevent command injection / framing breaks.
/// If omitted, defaults to [SbplEncoding.defaultEncoding] ([SbplEncoding.legacy]).
Uint8List compileToSBPLBytes(
  ResolvedLabel label, {
  SbplEncoding? encoding,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final enc = encoding ?? SbplEncoding.defaultEncoding;
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  // ESC A — Start Job
  SbplCommandWriter.writeStartJob(writer);

  // ESC CS<speed> — Print Speed (if specified)
  if (label.speed > 0) {
    SbplCommandWriter.writePrintSpeed(writer, label.speed);
  }

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final size = o.size ?? 1;

        SbplCommandWriter.writeText(
          writer,
          x: x,
          y: y,
          text: el.content,
          encoder: encoder,
          replaceUnsupported: enc.replaceUnsupported,
          widthMag: size,
          heightMag: size,
          fontCode: 'K9B',
          rotation: _sbplRotation(o.rotation ?? 0),
        );

      case BoxElement():
        final o = el.options;
        SbplCommandWriter.writeBox(
          writer,
          x: o.x,
          y: o.y,
          width: o.width,
          height: o.height,
          thickness: o.thickness ?? 1,
        );

      case LineElement():
        final o = el.options;
        SbplCommandWriter.writeLine(
          writer,
          x1: o.x1,
          y1: o.y1,
          x2: o.x2,
          y2: o.y2,
          thickness: o.thickness ?? 1,
        );

      case ImageElement():
      case CircleElement():
      case EllipseElement():
      case ReverseElement():
      case EraseElement():
        if (policy == UnsupportedFeaturePolicy.throwError) {
          throw UnsupportedFeatureError(
            'SBPL compiler does not support ${el.runtimeType}',
          );
        }
        break;

      case BarcodeElement():
        final o = el.options;
        final type = o.type == '39' ? 'B1' : 'BG'; // BG is Code128
        final n = o.narrow ?? 2;
        SbplCommandWriter.writeBarcode(
          writer,
          x: o.x,
          y: o.y,
          content: el.content,
          typeCode: type,
          narrow: n,
          height: o.height,
        );

      case QRCodeElement():
        final o = el.options;
        final cw = o.cellWidth ?? 4;
        SbplCommandWriter.writeQrCode(
          writer,
          x: o.x,
          y: o.y,
          content: el.content,
          cellWidth: cw,
        );

      case RawElement():
        SbplCommandWriter.writeRawBytes(writer, el.bytes);

      case RowElement():
      case DividerElement():
        if (policy == UnsupportedFeaturePolicy.throwError) {
          throw UnsupportedFeatureError(
            'SBPL compiler does not support ${el.runtimeType} in Slice 1',
          );
        }
        break;
    }
  }

  // Copies
  if (label.copies > 1) {
    SbplCommandWriter.writeCopies(writer, label.copies);
  }

  // ESC Z — End
  SbplCommandWriter.writeEndJob(writer);
  return writer.toBytes();
}

/// Compile a resolved label to SBPL commands as a [String] compatibility view.
///
/// Decodes the underlying byte stream via `latin1.decode`, providing a 1:1 lossless
/// mapping of 8-bit byte values.
@Deprecated(
  'Use compileToSBPLBytes instead. compileToSBPL is a Latin-1 compatibility view and will be removed in 2.0.',
)
String compileToSBPL(
  ResolvedLabel label, {
  SbplEncoding? encoding,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final bytes = compileToSBPLBytes(label, encoding: encoding, policy: policy);
  return latin1.decode(bytes);
}

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
