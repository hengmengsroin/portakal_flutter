import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../errors.dart';

/// Internal low-level command serializer for Eltron EPL2 printer commands.
///
/// Shared between the universal AST serializer (`compileToEPLBytes`) and the protocol-native
/// builder (`EplPrinter`). Emits byte-exact EPL2 syntax directly to [PrinterByteWriter].
class EplCommandWriter {
  const EplCommandWriter._();

  /// Escapes double quotes and backslashes in EPL2 quoted string parameters.
  ///
  /// Throws [InvalidConfigError] if text contains literal newlines (`\r` or `\n`),
  /// which would corrupt line-oriented EPL command stream framing.
  static String escapeEplText(String text) {
    if (text.contains('\n') || text.contains('\r')) {
      throw InvalidConfigError(
        'EPL text cannot contain literal newline characters (CR/LF).',
      );
    }
    final buf = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '"') {
        buf.write(r'\"');
      } else if (char == r'\') {
        buf.write(r'\\');
      } else {
        buf.write(char);
      }
    }
    return buf.toString();
  }

  /// Emits `N\n` — Clear Image Buffer / New Label.
  static void writeClear(PrinterByteWriter writer) {
    writer.writeAscii('N\n');
  }

  /// Emits `I8,<countryCode>,001\n` — Character Set Selection.
  static void writeCharSet(PrinterByteWriter writer, int countryCode) {
    if (countryCode < 0 || countryCode > 999) {
      throw InvalidConfigError(
        'EPL country code must be between 0 and 999, got: $countryCode',
      );
    }
    writer.writeAscii('I8,$countryCode,001\n');
  }

  /// Emits `q<widthDots>\n` — Set Label Width in dots.
  static void writeLabelWidth(PrinterByteWriter writer, int widthDots) {
    if (widthDots <= 0) {
      throw InvalidConfigError(
        'EPL label width must be positive, got: $widthDots',
      );
    }
    writer.writeAscii('q$widthDots\n');
  }

  /// Emits `Q<heightDots>,<gapDots>\n` — Set Label Form Length and Gap in dots.
  static void writeLabelLength(
    PrinterByteWriter writer,
    int heightDots, {
    int gapDots = 24,
  }) {
    if (heightDots <= 0) {
      throw InvalidConfigError(
        'EPL label length must be positive, got: $heightDots',
      );
    }
    if (gapDots < 0) {
      throw InvalidConfigError(
        'EPL gap offset must be non-negative, got: $gapDots',
      );
    }
    writer.writeAscii('Q$heightDots,$gapDots\n');
  }

  /// Emits `S<speed>\n` — Set Print Speed (1..6).
  static void writeSpeed(PrinterByteWriter writer, int speed) {
    if (speed < 1 || speed > 6) {
      throw InvalidConfigError(
        'EPL print speed must be between 1 and 6, got: $speed',
      );
    }
    writer.writeAscii('S$speed\n');
  }

  /// Emits `D<density>\n` — Set Print Density / Darkness (0..15).
  static void writeDensity(PrinterByteWriter writer, int density) {
    if (density < 0 || density > 15) {
      throw InvalidConfigError(
        'EPL print density must be between 0 and 15, got: $density',
      );
    }
    writer.writeAscii('D$density\n');
  }

  /// Emits `R<x>,<y>\n` — Set Reference Point (Offset).
  static void writeReferencePoint(PrinterByteWriter writer, int x, int y) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'EPL reference point coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    writer.writeAscii('R$x,$y\n');
  }

  /// Emits `A<x>,<y>,<rot>,<font>,<xMul>,<yMul>,<reverse>,"<content>"\n` — Text.
  static void writeText(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int rotation,
    required String font,
    required int xMultiplier,
    required int yMultiplier,
    required bool reverse,
    required String text,
    required CodePageEncoder encoder,
    bool replaceUnsupported = false,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'EPL text coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (rotation < 0 || rotation > 3) {
      throw InvalidConfigError(
        'EPL text rotation must be between 0 and 3, got: $rotation',
      );
    }
    if (xMultiplier < 1 || xMultiplier > 8) {
      throw InvalidConfigError(
        'EPL text horizontal multiplier must be between 1 and 8, got: $xMultiplier',
      );
    }
    if (yMultiplier < 1 || yMultiplier > 9) {
      throw InvalidConfigError(
        'EPL text vertical multiplier must be between 1 and 9, got: $yMultiplier',
      );
    }

    final revChar = reverse ? 'R' : 'N';
    writer.writeAscii(
      'A$x,$y,$rotation,$font,$xMultiplier,$yMultiplier,$revChar,"',
    );
    final escaped = escapeEplText(text);
    final textBytes = encoder.encode(
      escaped,
      replaceUnsupported: replaceUnsupported,
    );
    writer.writeBytes(textBytes);
    writer.writeAscii('"\n');
  }

  /// Emits `B<x>,<y>,<rot>,<type>,<narrow>,<wide>,<height>,<hr>,"<content>"\n` — 1D Barcode.
  static void writeBarcode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int rotation,
    required String typeCode,
    required int narrowBarWidth,
    required int wideBarWidth,
    required int height,
    required bool humanReadable,
    required String content,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'EPL barcode coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (rotation < 0 || rotation > 3) {
      throw InvalidConfigError(
        'EPL barcode rotation must be between 0 and 3, got: $rotation',
      );
    }
    if (narrowBarWidth <= 0 || wideBarWidth <= 0 || height <= 0) {
      throw InvalidConfigError(
        'EPL barcode dimensions must be positive, got narrow: $narrowBarWidth, wide: $wideBarWidth, height: $height',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('EPL barcode content cannot be empty.');
    }

    final hrChar = humanReadable ? 'B' : 'N';
    final escaped = escapeEplText(content);
    writer.writeAscii(
      'B$x,$y,$rotation,$typeCode,$narrowBarWidth,$wideBarWidth,$height,$hrChar,"$escaped"\n',
    );
  }

  /// Emits `b<x>,<y>,"Q",m2,s<cellWidth>,e<ecc>,"<content>"\n` — 2D QR Code.
  static void writeQrCode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int cellWidth,
    required String eccCode,
    required String content,
    required CodePageEncoder encoder,
    bool replaceUnsupported = false,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'EPL QR coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (cellWidth < 1 || cellWidth > 9) {
      throw InvalidConfigError(
        'EPL QR cell width must be between 1 and 9, got: $cellWidth',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('EPL QR content cannot be empty.');
    }

    final escaped = escapeEplText(content);
    writer.writeAscii('b$x,$y,"Q",m2,s$cellWidth,e$eccCode,"');
    final textBytes = encoder.encode(
      escaped,
      replaceUnsupported: replaceUnsupported,
    );
    writer.writeBytes(textBytes);
    writer.writeAscii('"\n');
  }

  /// Emits `X<x1>,<y1>,<x2>,<y2>,<thickness>\n` — Box.
  static void writeBox(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
    required int thickness,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'EPL box coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (width <= 0 || height <= 0 || thickness <= 0) {
      throw InvalidConfigError(
        'EPL box dimensions and thickness must be positive, got width: $width, height: $height, thickness: $thickness',
      );
    }
    final x2 = x + width;
    final y2 = y + height;
    writer.writeAscii('X$x,$y,$x2,$y2,$thickness\n');
  }

  /// Emits `LO<x>,<y>,<width>,<height>\n` — Black Line / Line Draw.
  static void writeLine(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'EPL line coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (width <= 0 || height <= 0) {
      throw InvalidConfigError(
        'EPL line dimensions must be positive, got width: $width, height: $height',
      );
    }
    writer.writeAscii('LO$x,$y,$width,$height\n');
  }

  /// Emits `LW<x>,<y>,<width>,<height>\n` — White Line / Erase.
  static void writeWhiteLine(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'EPL white line coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (width <= 0 || height <= 0) {
      throw InvalidConfigError(
        'EPL white line dimensions must be positive, got width: $width, height: $height',
      );
    }
    writer.writeAscii('LW$x,$y,$width,$height\n');
  }

  /// Emits `GW<x>,<y>,<bytesPerRow>,<height>\n<binary data>\n` — Graphics Write.
  ///
  /// In EPL2 `GW`, bit polarity is 0=black, 1=white. When [invert] is `true` (standard for
  /// 1-bit monochrome raster data where 1=black), bits are bitwise inverted before transmission.
  static void writeGraphic(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int bytesPerRow,
    required int height,
    required Uint8List data,
    bool invert = true,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'EPL graphic coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (bytesPerRow <= 0 || height <= 0) {
      throw InvalidConfigError(
        'EPL graphic dimensions must be positive, got bytesPerRow: $bytesPerRow, height: $height',
      );
    }
    final expected = bytesPerRow * height;
    if (data.length != expected) {
      throw InvalidConfigError(
        'EPL graphic data length (${data.length}) does not match bytesPerRow ($bytesPerRow) * height ($height) = $expected',
      );
    }

    writer.writeAscii('GW$x,$y,$bytesPerRow,$height\n');
    if (invert) {
      final inverted = Uint8List(data.length);
      for (int i = 0; i < data.length; i++) {
        inverted[i] = ~data[i] & 0xFF;
      }
      writer.writeBytes(inverted);
    } else {
      writer.writeBytes(data);
    }
    writer.writeAscii('\n');
  }

  /// Emits `P<sets>[,<copies>]\n` — Print.
  static void writePrint(
    PrinterByteWriter writer, {
    int sets = 1,
    int copies = 1,
  }) {
    if (sets < 1 || sets > 99999999) {
      throw InvalidConfigError(
        'EPL print sets must be between 1 and 99999999, got: $sets',
      );
    }
    if (copies < 1 || copies > 99999999) {
      throw InvalidConfigError(
        'EPL print copies must be between 1 and 99999999, got: $copies',
      );
    }

    if (copies > 1) {
      writer.writeAscii('P$sets,$copies\n');
    } else {
      writer.writeAscii('P$sets\n');
    }
  }

  /// Emits `C\n` — Cut.
  static void writeCut(PrinterByteWriter writer) {
    writer.writeAscii('C\n');
  }

  /// Emits raw binary bytes directly.
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
