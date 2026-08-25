import '../byte_writer.dart';
import '../encoding.dart';
import '../errors.dart';

/// Internal low-level command serializer for Datamax DPL printer commands.
///
/// Shared between the universal AST serializer (`compileToDPLBytes`) and the protocol-native
/// builder (`DplPrinter`). Emits byte-exact DPL syntax directly to [PrinterByteWriter].
///
/// Standard DPL uses carriage return (`\r`, 0x0D) for record termination, while historical
/// Portakal / upstream universal serializer uses line feed (`\n`, 0x0A).
class DplCommandWriter {
  const DplCommandWriter._();

  /// Default record terminator for native DPL streams (CR, 0x0D).
  static const String defaultNativeTerminator = '\r';

  /// Legacy record terminator for historical universal DPL streams (LF, 0x0A).
  static const String legacyUniversalTerminator = '\n';

  /// Pads integer to 4-digit zero-prefixed string.
  static String pad4(int n) => n.toString().padLeft(4, '0');

  /// Pads integer to 3-digit zero-prefixed string.
  static String pad3(int n) => n.toString().padLeft(3, '0');

  /// Pads integer to 2-digit zero-prefixed string.
  static String pad2(int n) => n.toString().padLeft(2, '0');

  /// Emits `<STX>L<term>` (0x02, 'L', terminator) — Start Label Formatting Mode.
  static void writeStartLabel(
    PrinterByteWriter writer, {
    String terminator = defaultNativeTerminator,
  }) {
    writer.writeByte(0x02);
    writer.writeAscii('L$terminator');
  }

  /// Emits `E<term>` (0x45, terminator) — End Label Formatting and Print.
  static void writeEndLabel(
    PrinterByteWriter writer, {
    String terminator = defaultNativeTerminator,
  }) {
    writer.writeAscii('E$terminator');
  }

  /// Emits `D<heat:2><term>` — Set Print Heat / Darkness (00..30).
  static void writeHeat(
    PrinterByteWriter writer,
    int heat, {
    String terminator = defaultNativeTerminator,
  }) {
    if (heat < 0 || heat > 30) {
      throw InvalidConfigError(
        'DPL heat/darkness value must be between 0 and 30, got: $heat',
      );
    }
    writer.writeAscii('D${pad2(heat)}$terminator');
  }

  /// Emits `S<speed:2><term>` — Set Print Speed (01..14).
  static void writeSpeed(
    PrinterByteWriter writer,
    int speed, {
    String terminator = defaultNativeTerminator,
  }) {
    if (speed < 1 || speed > 14) {
      throw InvalidConfigError(
        'DPL print speed must be between 1 and 14, got: $speed',
      );
    }
    writer.writeAscii('S${pad2(speed)}$terminator');
  }

  /// Emits `A<widthDots:4><term>` — Set Label Width in dots (0001..9999).
  static void writeWidth(
    PrinterByteWriter writer,
    int widthDots, {
    String terminator = defaultNativeTerminator,
  }) {
    if (widthDots <= 0 || widthDots > 9999) {
      throw InvalidConfigError(
        'DPL label width must be between 1 and 9999 dots, got: $widthDots',
      );
    }
    writer.writeAscii('A${pad4(widthDots)}$terminator');
  }

  /// Emits `Q<copies:4><term>` — Set Print Quantity (0001..9999).
  static void writeCopies(
    PrinterByteWriter writer,
    int copies, {
    String terminator = defaultNativeTerminator,
  }) {
    if (copies < 1 || copies > 9999) {
      throw InvalidConfigError(
        'DPL print copies must be between 1 and 9999, got: $copies',
      );
    }
    writer.writeAscii('Q${pad4(copies)}$terminator');
  }

  /// Emits a text record: `<rot><y:4><x:4><font><xMul:2><yMul:2><content><term>`.
  static void writeText(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String font,
    required int xMultiplier,
    required int yMultiplier,
    required String rotationCode,
    required String text,
    required CodePageEncoder encoder,
    bool replaceUnsupported = false,
    String terminator = defaultNativeTerminator,
  }) {
    if (x < 0 || y < 0 || x > 9999 || y > 9999) {
      throw InvalidConfigError(
        'DPL text coordinates must be between 0 and 9999, got x: $x, y: $y',
      );
    }
    if (xMultiplier < 1 ||
        xMultiplier > 99 ||
        yMultiplier < 1 ||
        yMultiplier > 99) {
      throw InvalidConfigError(
        'DPL text scale multipliers must be between 1 and 99, got xMultiplier: $xMultiplier, yMultiplier: $yMultiplier',
      );
    }
    if (text.contains('\n') ||
        text.contains('\r') ||
        text.contains('\x02') ||
        text.contains('\x01') ||
        text.contains('\x1B')) {
      throw InvalidConfigError(
        'DPL text cannot contain structural control characters (LF, CR, STX, SOH, ESC).',
      );
    }

    writer.writeAscii(rotationCode);
    writer.writeAscii(pad4(y));
    writer.writeAscii(pad4(x));
    writer.writeAscii(font);
    writer.writeAscii(pad2(xMultiplier));
    writer.writeAscii(pad2(yMultiplier));

    final textBytes = encoder.encode(
      text,
      replaceUnsupported: replaceUnsupported,
    );
    writer.writeBytes(textBytes);
    writer.writeAscii(terminator);
  }

  /// Emits a 1D barcode: `<rot><type><wide:1>0<height:3>0000<x:4><y:4><content><term>`.
  static void writeBarcode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String typeCode,
    required int wideMultiplier,
    required int height,
    required String rotationCode,
    required String content,
    String terminator = defaultNativeTerminator,
  }) {
    if (x < 0 || y < 0 || x > 9999 || y > 9999) {
      throw InvalidConfigError(
        'DPL barcode coordinates must be between 0 and 9999, got x: $x, y: $y',
      );
    }
    if (height <= 0 || height > 999) {
      throw InvalidConfigError(
        'DPL barcode height must be between 1 and 999 dots, got: $height',
      );
    }
    if (wideMultiplier < 1 || wideMultiplier > 9) {
      throw InvalidConfigError(
        'DPL barcode wide multiplier must be between 1 and 9, got: $wideMultiplier',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('DPL barcode content cannot be empty.');
    }
    if (content.contains('\n') ||
        content.contains('\r') ||
        content.contains('\x02')) {
      throw InvalidConfigError(
        'DPL barcode content cannot contain structural control characters (LF, CR, STX).',
      );
    }

    writer.writeAscii(
      '$rotationCode$typeCode${wideMultiplier}0${pad3(height)}0000${pad4(x)}${pad4(y)}$content$terminator',
    );
  }

  /// Emits a 2D QR Code: `1W1c<cellWidth:3>0000<x:4><y:4><content><term>`.
  static void writeQrCode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int cellWidth,
    required String content,
    String terminator = defaultNativeTerminator,
  }) {
    if (x < 0 || y < 0 || x > 9999 || y > 9999) {
      throw InvalidConfigError(
        'DPL QR coordinates must be between 0 and 9999, got x: $x, y: $y',
      );
    }
    if (cellWidth < 1 || cellWidth > 999) {
      throw InvalidConfigError(
        'DPL QR cell width must be between 1 and 999, got: $cellWidth',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('DPL QR content cannot be empty.');
    }
    if (content.contains('\n') ||
        content.contains('\r') ||
        content.contains('\x02')) {
      throw InvalidConfigError(
        'DPL QR content cannot contain structural control characters (LF, CR, STX).',
      );
    }

    writer.writeAscii(
      '1W1c${pad3(cellWidth)}0000${pad4(x)}${pad4(y)}$content$terminator',
    );
  }

  /// Emits `1e<y:4><x:4><width:4><height:4><thickness:4><term>` — Box Rectangle.
  static void writeBox(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
    required int thickness,
    String terminator = defaultNativeTerminator,
  }) {
    if (x < 0 || y < 0 || x > 9999 || y > 9999) {
      throw InvalidConfigError(
        'DPL box coordinates must be between 0 and 9999, got x: $x, y: $y',
      );
    }
    if (width <= 0 ||
        height <= 0 ||
        thickness <= 0 ||
        width > 9999 ||
        height > 9999 ||
        thickness > 9999) {
      throw InvalidConfigError(
        'DPL box dimensions must be positive (<= 9999), got width: $width, height: $height, thickness: $thickness',
      );
    }

    writer.writeAscii(
      '1e${pad4(y)}${pad4(x)}${pad4(width)}${pad4(height)}${pad4(thickness)}$terminator',
    );
  }

  /// Emits `1X<y:4><x:4>L<length:4><thickness><term>` — Line Segment.
  static void writeLine(
    PrinterByteWriter writer, {
    required int x1,
    required int y1,
    required int x2,
    required int y2,
    required int thickness,
    String terminator = defaultNativeTerminator,
  }) {
    if (x1 < 0 || y1 < 0 || x2 < 0 || y2 < 0 || thickness <= 0) {
      throw InvalidConfigError(
        'DPL line coordinates and thickness must be valid, got x1: $x1, y1: $y1, x2: $x2, y2: $y2, thickness: $thickness',
      );
    }

    if (y1 == y2) {
      // Horizontal line
      final x = x1 < x2 ? x1 : x2;
      final w = (x2 - x1).abs();
      final width = w == 0 ? 1 : w;
      writer.writeAscii(
        '1X${pad4(y1)}${pad4(x)}L${pad4(width)}$thickness$terminator',
      );
    } else {
      // Vertical / fallback line
      final y = y1 < y2 ? y1 : y2;
      final h = (y2 - y1).abs();
      final height = h == 0 ? 1 : h;
      writer.writeAscii(
        '1X${pad4(y)}${pad4(x1)}L${pad4(height)}$thickness$terminator',
      );
    }
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
    String terminator = defaultNativeTerminator,
  }) {
    writer.writeAscii(text);
    if (appendNewline) {
      writer.writeAscii(terminator);
    }
  }
}
