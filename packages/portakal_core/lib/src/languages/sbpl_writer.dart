import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../errors.dart';

/// Internal low-level command serializer for SATO SBPL printer commands.
///
/// Shared between the universal AST serializer (`compileToSBPLBytes`) and the protocol-native
/// builder (`SbplPrinter`). Emits byte-exact SBPL syntax using real binary ESC (0x1B) control bytes.
class SbplCommandWriter {
  const SbplCommandWriter._();

  static const int esc = 0x1B;

  static String _pad2(int n) => n.toString().padLeft(2, '0');
  static String _pad4(int n) => n.toString().padLeft(4, '0');

  /// Emits `ESC A` — Start Job.
  static void writeStartJob(PrinterByteWriter writer) {
    writer.writeByte(esc);
    writer.writeAscii('A');
  }

  /// Emits `ESC CS<speed>` — Set Print Speed.
  static void writePrintSpeed(PrinterByteWriter writer, int speed) {
    if (speed <= 0) {
      throw InvalidConfigError(
        'SBPL print speed must be positive, got: $speed',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('CS$speed');
  }

  /// Emits `ESC H<xxxx>` — Set Horizontal Position.
  static void writeHorizontalPosition(PrinterByteWriter writer, int x) {
    if (x < 0) {
      throw InvalidConfigError(
        'SBPL horizontal coordinate must be non-negative, got: $x',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('H${_pad4(x)}');
  }

  /// Emits `ESC V<yyyy>` — Set Vertical Position.
  static void writeVerticalPosition(PrinterByteWriter writer, int y) {
    if (y < 0) {
      throw InvalidConfigError(
        'SBPL vertical coordinate must be non-negative, got: $y',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('V${_pad4(y)}');
  }

  /// Emits `ESC %<rot>` — Set Rotation.
  static void writeRotation(PrinterByteWriter writer, int rotation) {
    if (rotation < 0 || rotation > 3) {
      throw InvalidConfigError(
        'SBPL rotation code must be in range 0..3, got: $rotation',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('%$rotation');
  }

  /// Emits `ESC %0` — Reset Rotation.
  static void writeResetRotation(PrinterByteWriter writer) {
    writer.writeByte(esc);
    writer.writeAscii('%0');
  }

  /// Emits `ESC L<hh><ww>` — Set Text Magnification (1..99).
  static void writeMagnification(
    PrinterByteWriter writer, {
    int width = 1,
    int height = 1,
  }) {
    if (width < 1 || width > 99 || height < 1 || height > 99) {
      throw InvalidConfigError(
        'SBPL magnification must be between 1 and 99, got width: $width, height: $height',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('L${_pad2(height)}${_pad2(width)}');
  }

  /// Emits `ESC <fontCode>` — Font Selection.
  static void writeFont(PrinterByteWriter writer, String fontCode) {
    if (fontCode.isEmpty) {
      throw InvalidConfigError('SBPL font code cannot be empty.');
    }
    writer.writeByte(esc);
    writer.writeAscii(fontCode);
  }

  /// Encodes text content guarding against dangerous ESC (0x1B) control bytes.
  static Uint8List encodeSbplText(
    String text,
    CodePageEncoder encoder, {
    bool replaceUnsupported = false,
  }) {
    final bytes = encoder.encode(text, replaceUnsupported: replaceUnsupported);
    final result = Uint8List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      if (b == esc) {
        if (replaceUnsupported) {
          result[i] = 0x3F; // '?'
        } else {
          throw UnsupportedCharacterException(
            character: String.fromCharCode(b),
            codePoint: b,
            codePage: encoder.codePage,
            message:
                'Control character ESC (0x1B) is not allowed inside SBPL text payload.',
          );
        }
      } else {
        result[i] = b;
      }
    }
    return result;
  }

  /// Emits text field with positioning, rotation, magnification, font, and encoded payload.
  static void writeText(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String text,
    required CodePageEncoder encoder,
    bool replaceUnsupported = false,
    int widthMag = 1,
    int heightMag = 1,
    String fontCode = 'K9B',
    int rotation = 0,
  }) {
    writeHorizontalPosition(writer, x);
    writeVerticalPosition(writer, y);

    if (rotation > 0) {
      writeRotation(writer, rotation);
    }

    writeMagnification(writer, width: widthMag, height: heightMag);
    writeFont(writer, fontCode);

    final textBytes = encodeSbplText(
      text,
      encoder,
      replaceUnsupported: replaceUnsupported,
    );
    writer.writeBytes(textBytes);

    if (rotation > 0) {
      writeResetRotation(writer);
    }
  }

  /// Emits a box rectangle: `ESC H<x> ESC V<y> ESC FW<t>V<h>H<w>`.
  static void writeBox(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
    int thickness = 1,
  }) {
    if (width <= 0 || height <= 0 || thickness <= 0) {
      throw InvalidConfigError(
        'SBPL box dimensions must be positive, got width: $width, height: $height, thickness: $thickness',
      );
    }
    writeHorizontalPosition(writer, x);
    writeVerticalPosition(writer, y);
    writer.writeByte(esc);
    writer.writeAscii('FW${_pad2(thickness)}V${_pad4(height)}H${_pad4(width)}');
  }

  /// Emits a line segment: `ESC H<x> ESC V<y> ESC FW<t>H<w>` or `FW<t>V<h>`.
  static void writeLine(
    PrinterByteWriter writer, {
    required int x1,
    required int y1,
    required int x2,
    required int y2,
    int thickness = 1,
  }) {
    if (x1 < 0 || y1 < 0 || x2 < 0 || y2 < 0 || thickness <= 0) {
      throw InvalidConfigError(
        'SBPL line coordinates must be non-negative and thickness positive, got ($x1,$y1) to ($x2,$y2), thickness: $thickness',
      );
    }

    if (y1 == y2) {
      // Horizontal line
      final x = x1 < x2 ? x1 : x2;
      final w = (x2 - x1).abs();
      writeHorizontalPosition(writer, x);
      writeVerticalPosition(writer, y1);
      writer.writeByte(esc);
      writer.writeAscii('FW${_pad2(thickness)}H${_pad4(w == 0 ? 1 : w)}');
    } else {
      // Vertical line
      final y = y1 < y2 ? y1 : y2;
      final h = (y2 - y1).abs();
      writeHorizontalPosition(writer, x1);
      writeVerticalPosition(writer, y);
      writer.writeByte(esc);
      writer.writeAscii('FW${_pad2(thickness)}V${_pad4(h == 0 ? 1 : h)}');
    }
  }

  /// Emits a 1D barcode: `ESC V<y> ESC H<x> ESC <type><narrow>0<height><content>`.
  static void writeBarcode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String content,
    String typeCode = 'BG',
    int narrow = 2,
    required int height,
  }) {
    if (x < 0 || y < 0 || height <= 0 || narrow <= 0) {
      throw InvalidConfigError(
        'SBPL barcode parameters must be positive, got x: $x, y: $y, height: $height, narrow: $narrow',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('SBPL barcode content cannot be empty.');
    }

    writer.writeByte(esc);
    writer.writeAscii('V$y');
    writer.writeByte(esc);
    writer.writeAscii('H$x');
    writer.writeByte(esc);
    writer.writeAscii(
      '$typeCode${narrow}0${height.toString().padLeft(3, '0')}',
    );
    writer.writeAscii(content);
  }

  /// Emits a 2D QR Code: `ESC V<y> ESC H<x> ESC BQ<cellWidth>200<content>`.
  static void writeQrCode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String content,
    int cellWidth = 4,
  }) {
    if (x < 0 || y < 0 || cellWidth <= 0) {
      throw InvalidConfigError(
        'SBPL QR parameters must be positive, got x: $x, y: $y, cellWidth: $cellWidth',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('SBPL QR content cannot be empty.');
    }

    writer.writeByte(esc);
    writer.writeAscii('V$y');
    writer.writeByte(esc);
    writer.writeAscii('H$x');
    writer.writeByte(esc);
    writer.writeAscii('BQ${_pad2(cellWidth)}200');
    writer.writeAscii(content);
  }

  /// Emits `ESC Q<copies>` — Print Copies.
  static void writeCopies(PrinterByteWriter writer, int copies) {
    if (copies <= 0) {
      throw InvalidConfigError(
        'SBPL copy count must be positive, got: $copies',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('Q$copies');
  }

  /// Emits `ESC Z` — End Job.
  static void writeEndJob(PrinterByteWriter writer) {
    writer.writeByte(esc);
    writer.writeAscii('Z');
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
