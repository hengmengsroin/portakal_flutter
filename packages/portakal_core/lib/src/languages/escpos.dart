import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../errors.dart';
import '../stream_row_formatter.dart';
import '../types.dart';
import 'escpos_writer.dart';

/// Compile a resolved label to ESC/POS binary commands as [Uint8List].
///
/// If [encoding] is provided, text is encoded using the configured [CodePageEncoder]
/// and table selection commands (`ESC t <tableId>`) are emitted accordingly.
/// If omitted, defaults to standard CP437 without emitting redundant table switches.
///
/// If [charsPerLine] is provided, overrides standard Font A media width capacity detection.
Uint8List compileToESCPOS(
  ResolvedLabel label, {
  EscPosEncoding? encoding,
  int? charsPerLine,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  final enc = encoding ?? const EscPosEncoding.cp437(sendTableSelect: false);
  final encoder = getEncoder(enc.codePage);
  final writer = PrinterByteWriter();

  // ESC @ — Initialize printer
  EscPosCommandWriter.writeInitialize(writer);

  // If table selection is configured, emit ESC t <tableId>
  if (enc.sendTableSelect && enc.tableId != null) {
    EscPosCommandWriter.writeCodePage(writer, enc.tableId!);
  }

  for (final el in label.elements) {
    switch (el) {
      case TextElement():
        final o = el.options;

        // Alignment: ESC a n
        if (o.align != null) {
          int n = 0;
          if (o.align == 'center') n = 1;
          if (o.align == 'right') n = 2;
          EscPosCommandWriter.writeAlign(writer, n);
        }

        // Bold: ESC E n
        if (o.bold == true) {
          EscPosCommandWriter.writeBold(writer, true);
        }

        // Size: GS ! n — width and height magnification
        if (o.size != null && o.size! > 1) {
          EscPosCommandWriter.writeTextSize(
            writer,
            width: o.size!,
            height: o.size!,
          );
        }

        // Text content encoded via explicit code page encoder
        final textBytes = encoder.encode(
          el.content,
          replaceUnsupported: enc.replaceUnsupported,
        );
        writer.writeBytes(textBytes);
        EscPosCommandWriter.writeLineFeed(writer);

        // Reset size
        if (o.size != null && o.size! > 1) {
          EscPosCommandWriter.writeTextSize(writer, width: 1, height: 1);
        }

        // Reset bold
        if (o.bold == true) {
          EscPosCommandWriter.writeBold(writer, false);
        }

        // Reset alignment
        if (o.align != null) {
          EscPosCommandWriter.writeAlign(writer, 0);
        }

      case ImageElement():
        final bmp = el.bitmap;
        EscPosCommandWriter.writeRaster(
          writer,
          mode: 0,
          bytesPerRow: bmp.bytesPerRow,
          height: bmp.height,
          data: bmp.data,
        );

      case RawElement():
        EscPosCommandWriter.writeRawBytes(writer, el.bytes);

      case BarcodeElement():
        final o = el.options;
        final typeByte = o.type == '39' ? 69 : 73;
        final barcodeBytes = ascii.encode(el.content);
        final height = o.height > 255 ? 255 : (o.height < 1 ? 1 : o.height);
        final hri = o.readable == 1 ? 2 : 0;
        final width = (o.narrow ?? 3).clamp(2, 6);
        EscPosCommandWriter.writeBarcode(
          writer,
          type: typeByte,
          height: height,
          width: width,
          hri: hri,
          hriFont: 0,
          content: barcodeBytes,
        );

      case QRCodeElement():
        final o = el.options;
        final contentBytes = utf8.encode(el.content);
        final cw = (o.cellWidth ?? 4).clamp(1, 16);
        final ecc = o.eccLevel == 'L'
            ? 0x30
            : o.eccLevel == 'Q'
                ? 0x32
                : o.eccLevel == 'H'
                    ? 0x33
                    : 0x31;
        EscPosCommandWriter.writeQrCode(
          writer,
          model: 0x32,
          size: cw,
          ecc: ecc,
          content: contentBytes,
        );

      case BoxElement():
      case LineElement():
      case CircleElement():
      case EllipseElement():
      case ReverseElement():
      case EraseElement():
        if (policy == UnsupportedFeaturePolicy.throwError) {
          throw UnsupportedFeatureError(
            'ESC/POS receipt compiler does not support geometric ${el.runtimeType}',
          );
        }
        break;

      case RowElement():
        final plan = StreamRowFormatter.formatRow(
          label,
          el,
          charsPerLine: charsPerLine,
        );
        _emitStreamRow(writer, plan, encoder, enc.replaceUnsupported);

      case DividerElement():
        final plan = StreamRowFormatter.formatDivider(
          label,
          el,
          charsPerLine: charsPerLine,
        );
        _emitStreamRow(writer, plan, encoder, enc.replaceUnsupported);
    }
  }

  // GS V B 3 — Partial cut with 3 lines feed
  EscPosCommandWriter.writeCut(writer, mode: 0x42, feedLines: 3);

  return writer.toBytes();
}

/// Convenience alias for [compileToESCPOS] providing naming consistency across protocols.
Uint8List compileToESCPOSBytes(
  ResolvedLabel label, {
  EscPosEncoding? encoding,
  int? charsPerLine,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) =>
    compileToESCPOS(
      label,
      encoding: encoding,
      charsPerLine: charsPerLine,
      policy: policy,
    );

void _emitStreamRow(
  PrinterByteWriter writer,
  StreamRowPlan plan,
  CodePageEncoder encoder,
  bool replaceUnsupported,
) {
  if (plan.size > 1) {
    EscPosCommandWriter.writeTextSize(
      writer,
      width: plan.size,
      height: plan.size,
    );
  }

  bool currentBold = false;
  bool currentUnderline = false;

  for (final seg in plan.segments) {
    if (seg.text.isEmpty) continue;

    if (seg.bold != currentBold) {
      currentBold = seg.bold;
      EscPosCommandWriter.writeBold(writer, currentBold);
    }

    if (seg.underline != currentUnderline) {
      currentUnderline = seg.underline;
      EscPosCommandWriter.writeUnderline(writer, currentUnderline ? 1 : 0);
    }

    final textBytes = encoder.encode(
      seg.text,
      replaceUnsupported: replaceUnsupported,
    );
    writer.writeBytes(textBytes);
  }

  if (currentUnderline) {
    EscPosCommandWriter.writeUnderline(writer, 0);
  }
  if (currentBold) {
    EscPosCommandWriter.writeBold(writer, false);
  }

  EscPosCommandWriter.writeLineFeed(writer);

  if (plan.size > 1) {
    EscPosCommandWriter.writeTextSize(writer, width: 1, height: 1);
  }
}
