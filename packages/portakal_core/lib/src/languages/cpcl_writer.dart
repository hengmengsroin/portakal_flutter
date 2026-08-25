import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../errors.dart';

/// Internal low-level command serializer for Comtec / Zebra CPCL printer commands.
///
/// Shared between the universal AST serializer (`compileToCPCLBytes`) and the protocol-native
/// builder (`CpclPrinter`). Emits byte-exact CPCL syntax directly to [PrinterByteWriter].
class CpclCommandWriter {
  const CpclCommandWriter._();

  /// Converts a byte (0..255) to a 2-character uppercase hexadecimal string.
  static String hex(int byte) =>
      byte.toRadixString(16).toUpperCase().padLeft(2, '0');

  /// Emits CPCL session header: `! <offset> <hRes> <vRes> <height> <qty>\r\n`.
  static void writeHeader(
    PrinterByteWriter writer, {
    int offset = 0,
    int hDpi = 203,
    int vDpi = 203,
    required int heightDots,
    int copies = 1,
  }) {
    if (offset < 0) {
      throw InvalidConfigError(
        'CPCL header offset must be non-negative, got: $offset',
      );
    }
    if (hDpi <= 0 || vDpi <= 0) {
      throw InvalidConfigError(
        'CPCL DPI resolutions must be positive, got hDpi: $hDpi, vDpi: $vDpi',
      );
    }
    if (heightDots < 0) {
      throw InvalidConfigError(
        'CPCL page height must be non-negative, got: $heightDots',
      );
    }
    if (copies < 1 || copies > 99999999) {
      throw InvalidConfigError(
        'CPCL print copies must be between 1 and 99999999, got: $copies',
      );
    }

    writer.writeAscii('! $offset $hDpi $vDpi $heightDots $copies\r\n');
  }

  /// Emits `COUNTRY <country>\r\n` — Character Set Selection.
  static void writeCountry(PrinterByteWriter writer, String country) {
    if (country.isEmpty) {
      throw InvalidConfigError('CPCL country name cannot be empty.');
    }
    writer.writeAscii('COUNTRY $country\r\n');
  }

  /// Emits `PAGE-WIDTH <widthDots>\r\n` — Page Width Setup.
  static void writePageWidth(PrinterByteWriter writer, int widthDots) {
    if (widthDots <= 0) {
      throw InvalidConfigError(
        'CPCL page width must be positive, got: $widthDots',
      );
    }
    writer.writeAscii('PAGE-WIDTH $widthDots\r\n');
  }

  /// Emits `SPEED <level>\r\n` — Print Speed (0..5).
  static void writeSpeed(PrinterByteWriter writer, int speed) {
    if (speed < 0 || speed > 5) {
      throw InvalidConfigError(
        'CPCL print speed must be between 0 and 5, got: $speed',
      );
    }
    writer.writeAscii('SPEED $speed\r\n');
  }

  /// Emits `TONE <level>\r\n` — Print Density / Tone.
  static void writeTone(PrinterByteWriter writer, int tone) {
    writer.writeAscii('TONE $tone\r\n');
  }

  /// Emits `SETMAG <w> <h>\r\n` — Text Magnification (1..16).
  static void writeSetMag(PrinterByteWriter writer, int w, int h) {
    if (w < 1 || w > 16 || h < 1 || h > 16) {
      throw InvalidConfigError(
        'CPCL SETMAG scale factors must be between 1 and 16, got w: $w, h: $h',
      );
    }
    writer.writeAscii('SETMAG $w $h\r\n');
  }

  /// Emits a text field: `<TEXT[rot]> <font> <size> <x> <y>\r\n<content>\r\n`.
  static void writeText(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String font,
    required int size,
    required int rotation,
    required String text,
    required CodePageEncoder encoder,
    bool replaceUnsupported = false,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'CPCL text coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (text.contains('\n') || text.contains('\r')) {
      throw InvalidConfigError(
        'CPCL text cannot contain literal newline characters (CR/LF).',
      );
    }

    final cmd = rotation == 90
        ? 'TEXT90'
        : rotation == 180
        ? 'TEXT180'
        : rotation == 270
        ? 'TEXT270'
        : 'TEXT';

    writer.writeAscii('$cmd $font $size $x $y\r\n');
    final textBytes = encoder.encode(
      text,
      replaceUnsupported: replaceUnsupported,
    );
    writer.writeBytes(textBytes);
    writer.writeAscii('\r\n');
  }

  /// Emits a 1D barcode: `BARCODE <type> <width> <ratio> <height> <x> <y> <content>\r\n`.
  static void writeBarcode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String typeCode,
    required int narrowBarWidth,
    required int wideRatio,
    required int height,
    required bool humanReadable,
    required String content,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'CPCL barcode coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (narrowBarWidth <= 0 || wideRatio <= 0 || height <= 0) {
      throw InvalidConfigError(
        'CPCL barcode dimensions must be positive, got narrow: $narrowBarWidth, ratio: $wideRatio, height: $height',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('CPCL barcode content cannot be empty.');
    }
    if (content.contains('\n') || content.contains('\r')) {
      throw InvalidConfigError(
        'CPCL barcode content cannot contain literal newline characters.',
      );
    }

    if (humanReadable) {
      writer.writeAscii('BARCODE-TEXT 7 0 5\r\n');
    }
    writer.writeAscii(
      'BARCODE $typeCode $narrowBarWidth $wideRatio $height $x $y $content\r\n',
    );
    if (humanReadable) {
      writer.writeAscii('BARCODE-TEXT OFF\r\n');
    }
  }

  /// Emits a 2D QR Code: `BARCODE QR <x> <y> M 2 U <cellWidth>\r\nMA,<content>\r\nENDQR\r\n`.
  static void writeQrCode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int cellWidth,
    required String content,
    required CodePageEncoder encoder,
    bool replaceUnsupported = false,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'CPCL QR coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (cellWidth < 1 || cellWidth > 32) {
      throw InvalidConfigError(
        'CPCL QR cell width must be between 1 and 32, got: $cellWidth',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('CPCL QR content cannot be empty.');
    }
    if (content.contains('\n') || content.contains('\r')) {
      throw InvalidConfigError(
        'CPCL QR content cannot contain literal newline characters.',
      );
    }

    writer.writeAscii('BARCODE QR $x $y M 2 U $cellWidth\r\nMA,');
    final textBytes = encoder.encode(
      content,
      replaceUnsupported: replaceUnsupported,
    );
    writer.writeBytes(textBytes);
    writer.writeAscii('\r\nENDQR\r\n');
  }

  /// Emits `BOX <x1> <y1> <x2> <y2> <thickness>\r\n` — Box Rectangle.
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
        'CPCL box coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (width <= 0 || height <= 0 || thickness <= 0) {
      throw InvalidConfigError(
        'CPCL box dimensions and thickness must be positive, got width: $width, height: $height, thickness: $thickness',
      );
    }
    final x2 = x + width;
    final y2 = y + height;
    writer.writeAscii('BOX $x $y $x2 $y2 $thickness\r\n');
  }

  /// Emits `LINE <x1> <y1> <x2> <y2> <thickness>\r\n` — Line Segment.
  static void writeLine(
    PrinterByteWriter writer, {
    required int x1,
    required int y1,
    required int x2,
    required int y2,
    required int thickness,
  }) {
    if (x1 < 0 || y1 < 0 || x2 < 0 || y2 < 0) {
      throw InvalidConfigError(
        'CPCL line coordinates must be non-negative, got x1: $x1, y1: $y1, x2: $x2, y2: $y2',
      );
    }
    if (thickness <= 0) {
      throw InvalidConfigError(
        'CPCL line thickness must be positive, got: $thickness',
      );
    }
    writer.writeAscii('LINE $x1 $y1 $x2 $y2 $thickness\r\n');
  }

  /// Emits `EG <bytesPerRow> <height> <x> <y> <hexData>\r\n` — Expanded Graphics.
  ///
  /// Converts the binary data into an uppercase 2-character ASCII hexadecimal string.
  static void writeExpandedGraphic(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int bytesPerRow,
    required int height,
    required Uint8List data,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'CPCL graphic coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (bytesPerRow <= 0 || height <= 0) {
      throw InvalidConfigError(
        'CPCL graphic dimensions must be positive, got bytesPerRow: $bytesPerRow, height: $height',
      );
    }
    final expected = bytesPerRow * height;
    if (data.length != expected) {
      throw InvalidConfigError(
        'CPCL graphic data length (${data.length}) does not match bytesPerRow ($bytesPerRow) * height ($height) = $expected',
      );
    }

    final hexData = data.map(hex).join();
    writer.writeAscii('EG $bytesPerRow $height $x $y $hexData\r\n');
  }

  /// Emits `FORM\r\n` — Advance to next form.
  static void writeForm(PrinterByteWriter writer) {
    writer.writeAscii('FORM\r\n');
  }

  /// Emits `PRINT\r\n` — Print Page.
  static void writePrint(PrinterByteWriter writer) {
    writer.writeAscii('PRINT\r\n');
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
      writer.writeAscii('\r\n');
    }
  }
}
