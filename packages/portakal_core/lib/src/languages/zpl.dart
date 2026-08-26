import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../errors.dart';
import '../types.dart';
import 'zpl_writer.dart';

/// Compile a resolved label to ZPL II commands as a byte sequence ([Uint8List]).
///
/// By default, uses [ZplEncoding.defaultEncoding] ([ZplEncoding.utf8]), which emits
/// `^CI28` and serializes text as UTF-8 (matching historical Portakal behavior).
/// For legacy environments without `^CI28`, pass [ZplEncoding.legacy].
Uint8List compileToZPLBytes(
  ResolvedLabel label, {
  ZplEncoding? encoding,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final enc = encoding ?? ZplEncoding.defaultEncoding;
  final isUtf8 = enc.type == ZplTextEncoding.utf8;
  final writer = PrinterByteWriter();

  ZplCommandWriter.writeStartFormat(writer);

  // Emit ^CI28 for UTF-8 mode
  if (isUtf8 && enc.emitCiCommand) {
    ZplCommandWriter.writeCodePage(writer, 28);
  }

  ZplCommandWriter.writePrintWidth(writer, label.widthDots);
  if (label.heightDots > 0) {
    ZplCommandWriter.writeLabelLength(writer, label.heightDots);
  }
  if (label.speed > 0) {
    ZplCommandWriter.writeSpeed(writer, label.speed);
  }
  if (label.density > 0) {
    ZplCommandWriter.writeDarkness(writer, label.density.toDouble());
  }

  // Elements
  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final size = o.size ?? 1;
        final h = size * 30;
        final w = h;
        final r = _zplRotation(o.rotation ?? 0);
        ZplCommandWriter.writeFieldOrigin(writer, x, y);
        ZplCommandWriter.writeFont(
          writer,
          fontCode: '0',
          rotationCode: r,
          height: h,
          width: w,
        );
        if (o.maxWidth != null) {
          final align = o.align == 'center'
              ? 'C'
              : o.align == 'right'
                  ? 'R'
                  : 'L';
          ZplCommandWriter.writeFieldBlock(
            writer,
            width: o.maxWidth!,
            maxLines: 1,
            lineSpacing: 0,
            align: align,
            hangingIndent: 0,
          );
        }
        if (o.reverse == true) {
          ZplCommandWriter.writeFieldReverse(writer);
        }

        ZplCommandWriter.writeFieldData(
          writer,
          text: el.content,
          isUtf8: isUtf8,
        );
        ZplCommandWriter.writeFieldSeparator(writer);

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        ZplCommandWriter.writeGraphicField(
          writer,
          x: x,
          y: y,
          bytesPerRow: bmp.bytesPerRow,
          height: bmp.height,
          data: bmp.data,
          useTypeset: false,
        );

      case BoxElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        final r = o.radius ?? 0;
        ZplCommandWriter.writeBox(
          writer,
          x: o.x,
          y: o.y,
          width: o.width,
          height: o.height,
          thickness: t,
          radius: r,
          white: false,
        );

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal line
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          final width = w == 0 ? 1 : w;
          ZplCommandWriter.writeBox(
            writer,
            x: x,
            y: o.y1,
            width: width,
            height: t,
            thickness: t,
            radius: 0,
            white: false,
          );
        } else if (o.x1 == o.x2) {
          // Vertical line
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          final height = h == 0 ? 1 : h;
          ZplCommandWriter.writeBox(
            writer,
            x: o.x1,
            y: y,
            width: t,
            height: height,
            thickness: t,
            radius: 0,
            white: false,
          );
        } else {
          // Diagonal — use GD
          final w = (o.x2 - o.x1).abs();
          final h = (o.y2 - o.y1).abs();
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final dir = ((o.x2 > o.x1) == (o.y2 > o.y1)) ? 'R' : 'L';
          ZplCommandWriter.writeDiagonal(
            writer,
            x: x,
            y: y,
            width: w == 0 ? 1 : w,
            height: h == 0 ? 1 : h,
            thickness: t,
            direction: dir,
          );
        }

      case CircleElement():
        final o = el.options;
        ZplCommandWriter.writeCircle(
          writer,
          x: o.x,
          y: o.y,
          diameter: o.diameter,
          thickness: o.thickness ?? 1,
        );

      case EllipseElement():
        // ZPL has no native ellipse — skip
        break;

      case ReverseElement():
        // ZPL uses ^FR on text — region reverse not directly supported
        break;

      case EraseElement():
        final o = el.options;
        final w = o.width;
        final h = o.height;
        ZplCommandWriter.writeBox(
          writer,
          x: o.x,
          y: o.y,
          width: w,
          height: h,
          thickness: w,
          radius: 0,
          white: true,
        );

      case BarcodeElement():
        final o = el.options;
        final type = o.type == '39' ? '3' : 'C'; // 3=Code39, C=Code128
        final rot = _zplRotation(o.rotation ?? 0);
        ZplCommandWriter.writeBarcode(
          writer,
          x: o.x,
          y: o.y,
          typeCode: type,
          rotCode: rot,
          height: o.height,
          interpretationLine: o.readable == 1,
          interpretationAbove: false,
          content: el.content,
          useTypeset: false,
        );

      case QRCodeElement():
        final o = el.options;
        final cw = o.cellWidth ?? 4;
        final ecc = o.eccLevel ?? 'Q';
        ZplCommandWriter.writeQrCode(
          writer,
          x: o.x,
          y: o.y,
          model: 2,
          magnification: cw,
          eccCode: ecc,
          mask: 7,
          content: el.content,
          isUtf8: isUtf8,
          useTypeset: false,
        );

      case RawElement():
        ZplCommandWriter.writeRawBytes(writer, el.bytes);

      case RowElement():
      case DividerElement():
        if (policy == UnsupportedFeaturePolicy.throwError) {
          throw UnsupportedFeatureError(
            'ZPL compiler does not support ${el.runtimeType} in Slice 1',
          );
        }
        break;
    }
  }

  ZplCommandWriter.writePrintQuantity(
    writer,
    copies: label.copies,
    pauseAndCut: 0,
    replicates: 0,
    overridePause: false,
  );
  ZplCommandWriter.writeEndFormat(writer);
  return writer.toBytes();
}

/// Compile a resolved label to ZPL II commands as a [String] compatibility view.
///
/// Decodes the underlying byte stream strictly: via `utf8.decode` in UTF-8 mode,
/// and via `latin1.decode` in legacy 8-bit mode.
@Deprecated(
  'Use compileToZPLBytes instead. compileToZPL is a string compatibility view and will be removed in 2.0.',
)
String compileToZPL(
  ResolvedLabel label, {
  ZplEncoding? encoding,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final enc = encoding ?? ZplEncoding.defaultEncoding;
  final bytes = compileToZPLBytes(label, encoding: enc, policy: policy);
  if (enc.type == ZplTextEncoding.utf8) {
    return utf8.decode(bytes);
  } else {
    return latin1.decode(bytes);
  }
}

String _zplRotation(int degrees) {
  switch (degrees) {
    case 90:
      return 'R';
    case 180:
      return 'I';
    case 270:
      return 'B';
    default:
      return 'N';
  }
}
