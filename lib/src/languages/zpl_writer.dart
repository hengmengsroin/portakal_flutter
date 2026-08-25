import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../errors.dart';

/// Internal low-level command serializer for Zebra ZPL II commands.
///
/// Shared between the universal AST serializer (`compileToZPLBytes`) and the protocol-native
/// builder (`ZplPrinter`). Emits byte-exact ZPL II syntax directly to [PrinterByteWriter].
class ZplCommandWriter {
  const ZplCommandWriter._();

  /// Converts a byte (0..255) to a 2-character uppercase hexadecimal string.
  static String hex(int byte) =>
      byte.toRadixString(16).toUpperCase().padLeft(2, '0');

  /// Escapes ZPL command control delimiters (^ and ~) using ZPL ^FH hex escape format.
  ///
  /// When ^FH is enabled on a field, literal underscores must also be escaped as
  /// `_5F` to prevent the printer from misinterpreting following hexadecimal characters
  /// (e.g. `_41` becoming `A`).
  static String escapeZplHex(String text) {
    final buf = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '^') {
        buf.write('_5E');
      } else if (char == '~') {
        buf.write('_7E');
      } else if (char == '_') {
        buf.write('_5F');
      } else {
        buf.write(char);
      }
    }
    return buf.toString();
  }

  /// Emits `^XA\n` — Start Format.
  static void writeStartFormat(PrinterByteWriter writer) {
    writer.writeAscii('^XA\n');
  }

  /// Emits `^XZ\n` — End Format.
  static void writeEndFormat(PrinterByteWriter writer) {
    writer.writeAscii('^XZ\n');
  }

  /// Emits `^CI<ciCode>\n` — Change International Font / Encoding.
  static void writeCodePage(PrinterByteWriter writer, int ciCode) {
    if (ciCode < 0 || ciCode > 36) {
      throw InvalidConfigError(
        'ZPL international font code (^CI) must be between 0 and 36, got: $ciCode',
      );
    }
    writer.writeAscii('^CI$ciCode\n');
  }

  /// Emits `^PW<dots>\n` — Print Width.
  static void writePrintWidth(PrinterByteWriter writer, int dots) {
    if (dots <= 0) {
      throw InvalidConfigError('ZPL print width must be positive, got: $dots');
    }
    writer.writeAscii('^PW$dots\n');
  }

  /// Emits `^LL<dots>\n` — Label Length.
  static void writeLabelLength(PrinterByteWriter writer, int dots) {
    if (dots <= 0) {
      throw InvalidConfigError('ZPL label length must be positive, got: $dots');
    }
    writer.writeAscii('^LL$dots\n');
  }

  /// Emits `^PR<ips>\n` — Print Rate / Slew Speed.
  static void writeSpeed(PrinterByteWriter writer, int ips) {
    if (ips <= 0) {
      throw InvalidConfigError('ZPL print speed must be positive, got: $ips');
    }
    writer.writeAscii('^PR$ips\n');
  }

  /// Emits `~SD<value>\n` — Set Darkness.
  static void writeDarkness(PrinterByteWriter writer, double value) {
    if (value < 0.0 || value > 30.0) {
      throw InvalidConfigError(
        'ZPL darkness value must be between 0.0 and 30.0, got: $value',
      );
    }
    final formatted = (value == value.truncateToDouble())
        ? value.toInt().toString().padLeft(2, '0')
        : value.toString();
    writer.writeAscii('~SD$formatted\n');
  }

  /// Emits `^PQ<copies>,<pauseAndCut>,<replicates>,<overridePause>\n` — Print Quantity.
  static void writePrintQuantity(
    PrinterByteWriter writer, {
    required int copies,
    required int pauseAndCut,
    required int replicates,
    required bool overridePause,
  }) {
    if (copies < 1 || copies > 99999999) {
      throw InvalidConfigError(
        'Print quantity copies must be between 1 and 99999999, got: $copies',
      );
    }
    if (pauseAndCut < 0 || pauseAndCut > 99999999) {
      throw InvalidConfigError(
        'Print quantity pauseAndCut count must be between 0 and 99999999, got: $pauseAndCut',
      );
    }
    if (replicates < 0 || replicates > 99999999) {
      throw InvalidConfigError(
        'Print quantity replicates must be between 0 and 99999999, got: $replicates',
      );
    }

    if (pauseAndCut == 0 && replicates == 0 && !overridePause) {
      writer.writeAscii('^PQ$copies\n');
    } else {
      final overrideChar = overridePause ? 'Y' : 'N';
      writer.writeAscii('^PQ$copies,$pauseAndCut,$replicates,$overrideChar\n');
    }
  }

  /// Emits `^FO<x>,<y>` — Field Origin.
  static void writeFieldOrigin(PrinterByteWriter writer, int x, int y) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'Field origin coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    writer.writeAscii('^FO$x,$y');
  }

  /// Emits `^FT<x>,<y>` — Field Typeset.
  static void writeFieldTypeset(PrinterByteWriter writer, int x, int y) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'Field typeset coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    writer.writeAscii('^FT$x,$y');
  }

  /// Emits `^A<fontCode><rotCode>,<height>,<width>` — Scalable / Bitmap Font.
  static void writeFont(
    PrinterByteWriter writer, {
    required String fontCode,
    required String rotationCode,
    required int height,
    int? width,
  }) {
    if (height <= 0) {
      throw InvalidConfigError('Font height must be positive, got: $height');
    }
    final w = width ?? height;
    if (w <= 0) {
      throw InvalidConfigError('Font width must be positive, got: $w');
    }
    writer.writeAscii('^A$fontCode$rotationCode,$height,$w');
  }

  /// Emits `^FB<width>,<maxLines>,<lineSpacing>,<align>,<hangingIndent>` — Field Block.
  static void writeFieldBlock(
    PrinterByteWriter writer, {
    required int width,
    required int maxLines,
    required int lineSpacing,
    required String align,
    required int hangingIndent,
  }) {
    if (width <= 0) {
      throw InvalidConfigError(
        'Field block width must be positive, got: $width',
      );
    }
    writer.writeAscii('^FB$width,$maxLines,$lineSpacing,$align,$hangingIndent');
  }

  /// Emits `^FR` — Field Reverse Print.
  static void writeFieldReverse(PrinterByteWriter writer) {
    writer.writeAscii('^FR');
  }

  /// Emits `^FD<text>` (or `^FH^FD<escaped>`) — Field Data.
  static void writeFieldData(
    PrinterByteWriter writer, {
    required String text,
    required bool isUtf8,
    bool useHexEscape = false,
  }) {
    if (useHexEscape || text.contains('^') || text.contains('~')) {
      final escaped = escapeZplHex(text);
      writer.writeAscii('^FH^FD');
      writer.writeString(escaped, encoding: isUtf8 ? utf8 : latin1);
    } else {
      writer.writeAscii('^FD');
      writer.writeString(text, encoding: isUtf8 ? utf8 : latin1);
    }
  }

  /// Emits `^FS\n` — Field Separator.
  static void writeFieldSeparator(PrinterByteWriter writer) {
    writer.writeAscii('^FS\n');
  }

  /// Emits complete 1D barcode sequence.
  static void writeBarcode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String typeCode,
    required String rotCode,
    required int height,
    required bool interpretationLine,
    required bool interpretationAbove,
    required String content,
    required bool useTypeset,
  }) {
    if (content.isEmpty) {
      throw InvalidConfigError('Barcode content cannot be empty');
    }
    if (height <= 0) {
      throw InvalidConfigError('Barcode height must be positive, got: $height');
    }

    if (useTypeset) {
      writeFieldTypeset(writer, x, y);
    } else {
      writeFieldOrigin(writer, x, y);
    }

    final hr = interpretationLine ? 'Y' : 'N';
    final above = interpretationAbove ? 'Y' : 'N';

    if (typeCode == '3') {
      // Code 39 (^B3)
      writer.writeAscii('^B3$rotCode,$height,$hr,$above,N');
    } else {
      // Code 128 (^BC) / general
      writer.writeAscii('^B$typeCode$rotCode,$height,$hr,$above,N,N');
    }

    writer.writeAscii('^FD');
    writer.writeAscii(content);
    writeFieldSeparator(writer);
  }

  /// Emits complete QR code sequence (^BQ).
  static void writeQrCode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int model,
    required int magnification,
    required String eccCode,
    required int mask,
    required String content,
    required bool isUtf8,
    required bool useTypeset,
  }) {
    if (content.isEmpty) {
      throw InvalidConfigError('QR code content cannot be empty');
    }
    if (magnification < 1 || magnification > 100) {
      throw InvalidConfigError(
        'QR code magnification must be between 1 and 100 dots, got: $magnification',
      );
    }
    if (mask < 0 || mask > 7) {
      throw InvalidConfigError(
        'QR code mask must be between 0 and 7, got: $mask',
      );
    }

    if (useTypeset) {
      writeFieldTypeset(writer, x, y);
    } else {
      writeFieldOrigin(writer, x, y);
    }

    // Standard ZPL QR syntax: ^BQa,b,c,d,e where a=orientation ('N'), b=model, c=magnification, d=ecc, e=mask
    writer.writeAscii('^BQN,$model,$magnification,$eccCode,$mask^FDQA,');
    writer.writeString(content, encoding: isUtf8 ? utf8 : latin1);
    writeFieldSeparator(writer);
  }

  /// Emits `^GFA` (Graphic Field ASCII hex) sequence.
  static void writeGraphicField(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int bytesPerRow,
    required int height,
    required Uint8List data,
    required bool useTypeset,
  }) {
    if (bytesPerRow <= 0 || height <= 0) {
      throw InvalidConfigError(
        'Graphics dimensions must be positive, got bytesPerRow: $bytesPerRow, height: $height',
      );
    }
    final expectedLength = bytesPerRow * height;
    if (data.length != expectedLength) {
      throw InvalidConfigError(
        'Graphic data length (${data.length}) does not match expected bytesPerRow ($bytesPerRow) * height ($height) = $expectedLength',
      );
    }

    if (useTypeset) {
      writeFieldTypeset(writer, x, y);
    } else {
      writeFieldOrigin(writer, x, y);
    }

    final totalBytes = data.length;
    final hexData = data.map(hex).join();
    writer.writeAscii('^GFA,$totalBytes,$totalBytes,$bytesPerRow,$hexData');
    writeFieldSeparator(writer);
  }

  /// Emits `^GB` Graphic Box sequence.
  static void writeBox(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
    required int thickness,
    required int radius,
    required bool white,
  }) {
    if (width <= 0 || height <= 0 || thickness <= 0) {
      throw InvalidConfigError(
        'Box dimensions and thickness must be positive, got width: $width, height: $height, thickness: $thickness',
      );
    }
    if (radius < 0 || radius > 8) {
      throw InvalidConfigError(
        'Box corner radius index must be between 0 and 8, got: $radius',
      );
    }
    writeFieldOrigin(writer, x, y);
    final color = white ? 'W' : 'B';
    writer.writeAscii('^GB$width,$height,$thickness,$color,$radius');
    writeFieldSeparator(writer);
  }

  /// Emits `^GC` Graphic Circle sequence.
  static void writeCircle(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int diameter,
    required int thickness,
  }) {
    if (diameter <= 0 || thickness <= 0) {
      throw InvalidConfigError(
        'Circle diameter and thickness must be positive, got diameter: $diameter, thickness: $thickness',
      );
    }
    writeFieldOrigin(writer, x, y);
    writer.writeAscii('^GC$diameter,$thickness,B');
    writeFieldSeparator(writer);
  }

  /// Emits `^GD` Graphic Diagonal Line sequence.
  static void writeDiagonal(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
    required int thickness,
    required String direction,
  }) {
    if (width <= 0 || height <= 0 || thickness <= 0) {
      throw InvalidConfigError(
        'Diagonal dimensions must be positive, got width: $width, height: $height, thickness: $thickness',
      );
    }
    writeFieldOrigin(writer, x, y);
    writer.writeAscii('^GD$width,$height,$thickness,B,$direction');
    writeFieldSeparator(writer);
  }

  /// Emits raw bytes directly.
  static void writeRawBytes(PrinterByteWriter writer, List<int> bytes) {
    writer.writeBytes(bytes);
  }

  /// Emits raw ASCII command string.
  static void writeRawAscii(
    PrinterByteWriter writer,
    String text, {
    bool appendNewline = false,
  }) {
    writer.writeAscii(text);
    if (appendNewline) {
      writer.writeAscii('\n');
    }
  }
}
