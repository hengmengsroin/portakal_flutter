import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../errors.dart';
import '../types.dart';
import 'tsc_writer.dart';

/// Compile a resolved label to TSC/TSPL2 binary commands as [Uint8List].
///
/// This is the canonical, byte-safe serializer that preserves raw binary payloads
/// (e.g. [MonochromeBitmap] data in BITMAP commands) without intermediate String
/// transformations.
Uint8List compileToTSCBytes(
  ResolvedLabel label, {
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final writer = PrinterByteWriter();

  // Label setup
  if (label.unit == Unit.dot) {
    TscCommandWriter.writeSizeDots(writer, label.widthDots, label.heightDots);
  } else if (label.unit == Unit.inch) {
    // Convert back from dots to inches for the command
    final wInch = label.widthDots / label.dpi;
    final hInch = label.heightDots / label.dpi;
    TscCommandWriter.writeSizeInches(writer, wInch, hInch);
  } else {
    // mm: convert dots back to mm
    final wMM = (label.widthDots / label.dpi * 25.4).roundToDouble();
    final hMM = (label.heightDots / label.dpi * 25.4).roundToDouble();
    TscCommandWriter.writeSizeMm(writer, wMM, hMM);
  }

  TscCommandWriter.writeGapMm(writer, 3, 0);
  TscCommandWriter.writeSpeed(writer, label.speed.toDouble());
  TscCommandWriter.writeDensity(writer, label.density);
  TscCommandWriter.writeDirection(writer, label.direction);
  TscCommandWriter.writeCls(writer);

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
        final encoded = Uint8List.fromList(latin1.encode(el.content));
        TscCommandWriter.writeText(
          writer,
          x: x,
          y: y,
          font: font,
          rotation: rotation,
          xMul: xMul,
          yMul: yMul,
          encodedContent: encoded,
        );

      case ImageElement():
        final o = el.options;
        final x = o.x ?? 0;
        final y = o.y ?? 0;
        final bmp = el.bitmap;
        TscCommandWriter.writeBitmap(
          writer,
          x: x,
          y: y,
          bytesPerRow: bmp.bytesPerRow,
          height: bmp.height,
          mode: 0,
          data: bmp.data,
        );

      case BoxElement():
        final o = el.options;
        final x2 = o.x + o.width;
        final y2 = o.y + o.height;
        final t = o.thickness ?? 1;
        TscCommandWriter.writeBox(
          writer,
          x: o.x,
          y: o.y,
          xEnd: x2,
          yEnd: y2,
          thickness: t,
          radius: o.radius,
        );

      case LineElement():
        final o = el.options;
        final t = o.thickness ?? 1;
        if (o.y1 == o.y2) {
          // Horizontal line → BAR
          final x = o.x1 < o.x2 ? o.x1 : o.x2;
          final w = (o.x2 - o.x1).abs();
          TscCommandWriter.writeBar(writer, x: x, y: o.y1, width: w, height: t);
        } else if (o.x1 == o.x2) {
          // Vertical line → BAR
          final y = o.y1 < o.y2 ? o.y1 : o.y2;
          final h = (o.y2 - o.y1).abs();
          TscCommandWriter.writeBar(writer, x: o.x1, y: y, width: t, height: h);
        } else {
          // Diagonal
          TscCommandWriter.writeDiagonal(
            writer,
            x1: o.x1,
            y1: o.y1,
            x2: o.x2,
            y2: o.y2,
            thickness: t,
          );
        }

      case CircleElement():
        final o = el.options;
        TscCommandWriter.writeCircle(
          writer,
          x: o.x,
          y: o.y,
          diameter: o.diameter,
          thickness: o.thickness ?? 1,
        );

      case EllipseElement():
        final o = el.options;
        TscCommandWriter.writeEllipse(
          writer,
          x: o.x,
          y: o.y,
          width: o.width,
          height: o.height,
          thickness: o.thickness ?? 1,
        );

      case BarcodeElement():
        final o = el.options;
        TscCommandWriter.writeBarcode(
          writer,
          x: o.x,
          y: o.y,
          type: o.type,
          height: o.height,
          readable: o.readable ?? 0,
          rotation: o.rotation ?? 0,
          narrow: o.narrow ?? 2,
          wide: o.wide ?? 4,
          alignment: o.alignment,
          content: el.content,
        );

      case QRCodeElement():
        final o = el.options;
        TscCommandWriter.writeQrCode(
          writer,
          x: o.x,
          y: o.y,
          ecc: o.eccLevel ?? 'H',
          cellWidth: o.cellWidth ?? 4,
          mode: o.mode ?? 'A',
          rotation: o.rotation ?? 0,
          model: o.model,
          mask: o.mask,
          content: el.content,
        );

      case ReverseElement():
        final o = el.options;
        TscCommandWriter.writeReverse(
          writer,
          x: o.x,
          y: o.y,
          width: o.width,
          height: o.height,
        );

      case EraseElement():
        final o = el.options;
        TscCommandWriter.writeErase(
          writer,
          x: o.x,
          y: o.y,
          width: o.width,
          height: o.height,
        );

      case RawElement():
        TscCommandWriter.writeRawBytes(writer, el.bytes);

      case RowElement():
      case DividerElement():
        if (policy == UnsupportedFeaturePolicy.throwError) {
          throw UnsupportedFeatureError(
            'TSC compiler does not support ${el.runtimeType} in Slice 1',
          );
        }
        break;
    }
  }

  TscCommandWriter.writePrint(writer, sets: label.copies);
  return writer.toBytes();
}

/// Compile a resolved label to TSC/TSPL2 commands as a Latin-1 [String] compatibility view.
///
/// Note: For binary content (e.g. BITMAP commands), prefer [compileToTSCBytes]
/// to avoid string character encoding ambiguities during transmission.
@Deprecated(
  'Use compileToTSCBytes instead. compileToTSC is a Latin-1 compatibility view and will be removed in 2.0.',
)
String compileToTSC(
  ResolvedLabel label, {
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final bytes = compileToTSCBytes(label, policy: policy);
  return latin1.decode(bytes);
}
