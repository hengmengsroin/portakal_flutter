import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../errors.dart';

/// Internal low-level command serializer for Intermec IPL printer commands.
///
/// Shared between the universal AST serializer (`compileToIPLBytes`) and the protocol-native
/// builder (`IplPrinter`). Emits byte-exact IPL syntax using real binary control bytes:
/// - STX (0x02)
/// - ETX (0x03)
/// - ESC (0x1B)
/// - SI  (0x0F)
class IplCommandWriter {
  const IplCommandWriter._();

  static const int stx = 0x02;
  static const int etx = 0x03;
  static const int esc = 0x1B;
  static const int si = 0x0F;

  /// Emits `<STX><ESC>C<formatNumber><ETX>` — Create Format (Advanced Mode).
  static void writeCreateFormat(
    PrinterByteWriter writer, [
    int formatNumber = 1,
  ]) {
    if (formatNumber < 1) {
      throw InvalidConfigError(
        'IPL format number must be positive, got: $formatNumber',
      );
    }
    writer.writeByte(stx);
    writer.writeByte(esc);
    writer.writeAscii('C$formatNumber');
    writer.writeByte(etx);
  }

  /// Emits `<STX><ESC>P<ETX>` — Enter Program Mode.
  static void writeProgramMode(PrinterByteWriter writer) {
    writer.writeByte(stx);
    writer.writeByte(esc);
    writer.writeAscii('P');
    writer.writeByte(etx);
  }

  /// Emits `<STX><SI>L<heightDots><ETX>` — Set Label Length / Height.
  static void writeLabelLength(PrinterByteWriter writer, int heightDots) {
    if (heightDots <= 0) {
      throw InvalidConfigError(
        'IPL label length (height) must be positive, got: $heightDots',
      );
    }
    writer.writeByte(stx);
    writer.writeByte(si);
    writer.writeAscii('L$heightDots');
    writer.writeByte(etx);
  }

  /// Emits `<STX><SI>W<widthDots><ETX>` — Set Label Width.
  static void writeLabelWidth(PrinterByteWriter writer, int widthDots) {
    if (widthDots <= 0) {
      throw InvalidConfigError(
        'IPL label width must be positive, got: $widthDots',
      );
    }
    writer.writeByte(stx);
    writer.writeByte(si);
    writer.writeAscii('W$widthDots');
    writer.writeByte(etx);
  }

  /// Emits `<STX><SI>S<speed>0<ETX>` — Set Print Speed.
  static void writeSpeed(PrinterByteWriter writer, int speed) {
    if (speed <= 0) {
      throw InvalidConfigError('IPL print speed must be positive, got: $speed');
    }
    writer.writeByte(stx);
    writer.writeByte(si);
    writer.writeAscii('S${speed}0');
    writer.writeByte(etx);
  }

  /// Emits `<STX><SI>d<density><ETX>` — Set Print Density / Darkness.
  static void writeDensity(PrinterByteWriter writer, int density) {
    if (density < 0) {
      throw InvalidConfigError(
        'IPL print density must be non-negative, got: $density',
      );
    }
    writer.writeByte(stx);
    writer.writeByte(si);
    writer.writeAscii('d$density');
    writer.writeByte(etx);
  }

  /// Emits `<STX><ESC>M<copies><ETX>` — Set Print Quantity / Copies.
  static void writeCopies(PrinterByteWriter writer, int copies) {
    if (copies <= 0) {
      throw InvalidConfigError(
        'IPL print copies must be positive, got: $copies',
      );
    }
    writer.writeByte(stx);
    writer.writeByte(esc);
    writer.writeAscii('M$copies');
    writer.writeByte(etx);
  }

  /// Encodes text content guarding against dangerous control bytes (`STX`, `ETX`, `ESC`, `SI`).
  static Uint8List encodeIplText(
    String text,
    CodePageEncoder encoder, {
    bool replaceUnsupported = false,
  }) {
    final bytes = encoder.encode(text, replaceUnsupported: replaceUnsupported);
    final result = Uint8List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      if (b == stx || b == etx || b == esc || b == si) {
        if (replaceUnsupported) {
          result[i] = 0x3F; // '?'
        } else {
          throw UnsupportedCharacterException(
            character: String.fromCharCode(b),
            codePoint: b,
            codePage: encoder.codePage,
            message:
                'Control character (0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}) '
                'is not supported inside unescaped IPL text records.',
          );
        }
      } else {
        result[i] = b;
      }
    }
    return result;
  }

  /// Emits a text field: `<STX>H<fieldNum>;o<x>,<y>;f<rot>;h<fh>;w<fw>;c<font>;d3,<text><ETX>`.
  static void writeTextField(
    PrinterByteWriter writer, {
    required int fieldNumber,
    required int x,
    required int y,
    required int rotation,
    required int fontHeight,
    required int fontWidth,
    int fontCode = 26,
    required String text,
    required CodePageEncoder encoder,
    bool replaceUnsupported = false,
  }) {
    if (fieldNumber <= 0) {
      throw InvalidConfigError(
        'IPL field number must be positive, got: $fieldNumber',
      );
    }
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'IPL text field coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (fontHeight <= 0 || fontWidth <= 0) {
      throw InvalidConfigError(
        'IPL font dimensions must be positive, got height: $fontHeight, width: $fontWidth',
      );
    }

    writer.writeByte(stx);
    writer.writeAscii(
      'H$fieldNumber;o$x,$y;f$rotation;h$fontHeight;w$fontWidth;c$fontCode;d3,',
    );

    final textBytes = encodeIplText(
      text,
      encoder,
      replaceUnsupported: replaceUnsupported,
    );
    writer.writeBytes(textBytes);
    writer.writeByte(etx);
  }

  /// Emits a box rectangle: `<STX>W<fieldNum>;o<x>,<y>;f0;l<width>;h<height>;w<thickness><ETX>`.
  static void writeBoxField(
    PrinterByteWriter writer, {
    required int fieldNumber,
    required int x,
    required int y,
    required int width,
    required int height,
    int thickness = 1,
  }) {
    if (fieldNumber <= 0) {
      throw InvalidConfigError(
        'IPL field number must be positive, got: $fieldNumber',
      );
    }
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'IPL box coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (width <= 0 || height <= 0 || thickness <= 0) {
      throw InvalidConfigError(
        'IPL box dimensions must be positive, got width: $width, height: $height, thickness: $thickness',
      );
    }

    writer.writeByte(stx);
    writer.writeAscii('W$fieldNumber;o$x,$y;f0;l$width;h$height;w$thickness');
    writer.writeByte(etx);
  }

  /// Emits a line segment: `<STX>L<fieldNum>;o<x>,<y>;f<rot>;l<length>;w<thickness><ETX>`.
  static void writeLineField(
    PrinterByteWriter writer, {
    required int fieldNumber,
    required int x,
    required int y,
    required int length,
    required int thickness,
    bool isVertical = false,
  }) {
    if (fieldNumber <= 0) {
      throw InvalidConfigError(
        'IPL field number must be positive, got: $fieldNumber',
      );
    }
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'IPL line coordinates must be non-negative, got x: $x, y: $y',
      );
    }
    if (length <= 0 || thickness <= 0) {
      throw InvalidConfigError(
        'IPL line length and thickness must be positive, got length: $length, thickness: $thickness',
      );
    }

    final rot = isVertical ? 1 : 0;
    writer.writeByte(stx);
    writer.writeAscii('L$fieldNumber;o$x,$y;f$rot;l$length;w$thickness');
    writer.writeByte(etx);
  }

  /// Emits a 1D barcode field definition + data frame.
  static void writeBarcodeField(
    PrinterByteWriter writer, {
    required int fieldNumber,
    required int y,
    required int height,
    required int wideMultiplier,
    required String content,
    int symbologyCode = 0,
  }) {
    if (fieldNumber <= 0) {
      throw InvalidConfigError(
        'IPL barcode field number must be positive, got: $fieldNumber',
      );
    }
    if (y < 0 || height <= 0 || wideMultiplier <= 0) {
      throw InvalidConfigError(
        'IPL barcode parameters must be valid, got y: $y, height: $height, wideMultiplier: $wideMultiplier',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('IPL barcode content cannot be empty.');
    }

    writer.writeByte(stx);
    writer.writeAscii(
      'B$fieldNumber;o0;f0;c$symbologyCode;h$height;w$wideMultiplier;d0,$y;',
    );
    writer.writeByte(etx);
    writer.writeAscii('\n');
    writer.writeByte(stx);
    writer.writeAscii(content);
    writer.writeByte(etx);
    writer.writeAscii('\n');
  }

  /// Emits a 2D QR Code field definition + data frame.
  static void writeQrCodeField(
    PrinterByteWriter writer, {
    required int fieldNumber,
    required int y,
    required int cellWidth,
    required String content,
  }) {
    if (fieldNumber <= 0) {
      throw InvalidConfigError(
        'IPL QR field number must be positive, got: $fieldNumber',
      );
    }
    if (y < 0 || cellWidth <= 0) {
      throw InvalidConfigError(
        'IPL QR parameters must be valid, got y: $y, cellWidth: $cellWidth',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('IPL QR content cannot be empty.');
    }

    writer.writeByte(stx);
    writer.writeAscii('B$fieldNumber;o0;f0;c21;w$cellWidth;h$cellWidth;d0,$y;');
    writer.writeByte(etx);
    writer.writeAscii('\n');
    writer.writeByte(stx);
    writer.writeAscii(content);
    writer.writeByte(etx);
    writer.writeAscii('\n');
  }

  /// Emits `<STX><ESC>E<formatNumber><ETX>` — End Format.
  static void writeEndFormat(PrinterByteWriter writer, [int formatNumber = 1]) {
    if (formatNumber < 1) {
      throw InvalidConfigError(
        'IPL format number must be positive, got: $formatNumber',
      );
    }
    writer.writeByte(stx);
    writer.writeByte(esc);
    writer.writeAscii('E$formatNumber');
    writer.writeByte(etx);
  }

  /// Emits `<STX>R<ETX>` — Print / Execute Format.
  static void writePrint(PrinterByteWriter writer) {
    writer.writeByte(stx);
    writer.writeAscii('R');
    writer.writeByte(etx);
  }

  /// Emits raw binary bytes directly.
  static void writeRawBytes(PrinterByteWriter writer, List<int> bytes) {
    writer.writeBytes(bytes);
  }

  /// Emits raw ASCII command string.
  static void writeRawAscii(PrinterByteWriter writer, String text) {
    writer.writeAscii(text);
  }
}
