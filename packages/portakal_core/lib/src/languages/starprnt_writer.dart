import 'dart:convert';
import 'dart:typed_data';

import '../byte_writer.dart';
import '../encoding.dart';
import '../errors.dart';

/// Internal low-level command serializer for Star Line Mode / StarPRNT commands.
///
/// Shared between the universal AST serializer (`compileToStarPRNT`) and the protocol-native
/// builder (`StarPrntPrinter`). Emits byte-exact Star Line Mode binary commands.
class StarPrntCommandWriter {
  const StarPrntCommandWriter._();

  static const int esc = 0x1B;
  static const int gs = 0x1D;
  static const int rs = 0x1E;
  static const int bel = 0x07;

  /// Emits `ESC @` — Initialize Printer.
  static void writeInitialize(PrinterByteWriter writer) {
    writer.writeByte(esc);
    writer.writeAscii('@');
  }

  /// Emits `ESC GS t <characterTable>` — Select Character Code Page.
  static void writeCodePage(PrinterByteWriter writer, int characterTable) {
    if (characterTable < 0 || characterTable > 255) {
      throw InvalidConfigError(
        'Star PRNT character table must be in range 0..255, got: $characterTable',
      );
    }
    writer.writeByte(esc);
    writer.writeByte(gs);
    writer.writeAscii('t');
    writer.writeByte(characterTable);
  }

  /// Emits `ESC GS a <alignCode>` — Select Alignment (0=Left, 1=Center, 2=Right).
  static void writeAlignment(PrinterByteWriter writer, int alignCode) {
    if (alignCode < 0 || alignCode > 2) {
      throw InvalidConfigError(
        'Star PRNT alignment code must be in range 0..2, got: $alignCode',
      );
    }
    writer.writeByte(esc);
    writer.writeByte(gs);
    writer.writeAscii('a');
    writer.writeByte(alignCode);
  }

  /// Emits `ESC E` (Bold ON) or `ESC F` (Bold OFF).
  static void writeBold(PrinterByteWriter writer, bool enable) {
    writer.writeByte(esc);
    writer.writeAscii(enable ? 'E' : 'F');
  }

  /// Emits `ESC - <mode>` — Underline Mode (0=OFF, 1=1-dot, 2=2-dot).
  static void writeUnderline(PrinterByteWriter writer, int mode) {
    if (mode < 0 || mode > 2) {
      throw InvalidConfigError(
        'Star PRNT underline mode must be in range 0..2, got: $mode',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('-');
    writer.writeByte(mode);
  }

  /// Emits `ESC 4` (Invert ON) or `ESC 5` (Invert OFF).
  static void writeInvert(PrinterByteWriter writer, bool enable) {
    writer.writeByte(esc);
    writer.writeAscii(enable ? '4' : '5');
  }

  /// Emits `ESC i <heightMultiplier> <widthMultiplier>` — Character Expansion.
  static void writeCharacterSize(
    PrinterByteWriter writer, {
    int widthMultiplier = 1,
    int heightMultiplier = 1,
  }) {
    if (widthMultiplier < 1 ||
        widthMultiplier > 6 ||
        heightMultiplier < 1 ||
        heightMultiplier > 6) {
      throw InvalidConfigError(
        'Star PRNT character size multipliers must be between 1 and 6, got width: $widthMultiplier, height: $heightMultiplier',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('i');
    writer.writeByte(heightMultiplier);
    writer.writeByte(widthMultiplier);
  }

  /// Encodes and writes text content.
  static void writeText(
    PrinterByteWriter writer,
    String text,
    CodePageEncoder encoder, {
    bool replaceUnsupported = false,
  }) {
    final textBytes = encoder.encode(
      text,
      replaceUnsupported: replaceUnsupported,
    );
    writer.writeBytes(textBytes);
  }

  /// Emits a line feed byte (0x0A).
  static void writeLineFeed(PrinterByteWriter writer) {
    writer.writeByte(0x0A);
  }

  /// Emits `ESC a <lines>` — Feed Paper by Lines.
  static void writeFeedLines(PrinterByteWriter writer, int lines) {
    if (lines <= 0 || lines > 255) {
      throw InvalidConfigError(
        'Star PRNT feed lines must be between 1 and 255, got: $lines',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('a');
    writer.writeByte(lines);
  }

  /// Emits `ESC J <dots>` — Feed Paper by Dots.
  static void writeFeedDots(PrinterByteWriter writer, int dots) {
    if (dots <= 0 || dots > 255) {
      throw InvalidConfigError(
        'Star PRNT feed dots must be between 1 and 255, got: $dots',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('J');
    writer.writeByte(dots);
  }

  /// Emits `ESC d <mode>` — Auto-Cutter (0=Full, 1=Partial, 2=Feed+Full, 3=Feed+Partial).
  static void writeCut(PrinterByteWriter writer, [int mode = 1]) {
    if (mode < 0 || mode > 3) {
      throw InvalidConfigError(
        'Star PRNT cutter mode must be in range 0..3, got: $mode',
      );
    }
    writer.writeByte(esc);
    writer.writeAscii('d');
    writer.writeByte(mode);
  }

  /// Emits `BEL` (0x07) — Kick Cash Drawer Channel 1.
  static void writePulseDrawer(PrinterByteWriter writer, [int channel = 1]) {
    writer.writeByte(bel);
  }

  /// Emits `ESC b <type> <readable> <wide> <height> <content> RS` — 1D Barcode.
  static void writeBarcode(
    PrinterByteWriter writer, {
    required int typeCode,
    required String content,
    int readable = 1,
    int wide = 2,
    int height = 40,
  }) {
    if (typeCode < 1 || typeCode > 8) {
      throw InvalidConfigError(
        'Star PRNT barcode type code must be between 1 and 8, got: $typeCode',
      );
    }
    if (height < 1 || height > 255) {
      throw InvalidConfigError(
        'Star PRNT barcode height must be between 1 and 255, got: $height',
      );
    }
    if (wide < 1 || wide > 3) {
      throw InvalidConfigError(
        'Star PRNT barcode wide ratio must be between 1 and 3, got: $wide',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('Star PRNT barcode content cannot be empty.');
    }

    writer.writeByte(esc);
    writer.writeByte(0x62); // 'b'
    writer.writeByte(typeCode);
    writer.writeByte(readable);
    writer.writeByte(wide);
    writer.writeByte(height);
    writer.writeAscii(content);
    writer.writeByte(rs);
  }

  /// Emits the Star Line Mode QR code command family:
  /// `ESC GS y S 0 <cw>`, `ESC GS y S 1 <ecc>`, `ESC GS y S 2 <model>`, `ESC GS y D 1 0 <nL> <nH> <content>`, `ESC GS y P`.
  static void writeQrCode(
    PrinterByteWriter writer, {
    required String content,
    int cellWidth = 4,
    int ecc = 1,
    int model = 2,
  }) {
    if (cellWidth < 1 || cellWidth > 16) {
      throw InvalidConfigError(
        'Star PRNT QR cell width must be between 1 and 16, got: $cellWidth',
      );
    }
    if (ecc < 0 || ecc > 3) {
      throw InvalidConfigError(
        'Star PRNT QR ECC level must be in range 0..3, got: $ecc',
      );
    }
    if (model < 1 || model > 2) {
      throw InvalidConfigError(
        'Star PRNT QR model must be 1 or 2, got: $model',
      );
    }
    if (content.isEmpty) {
      throw InvalidConfigError('Star PRNT QR content cannot be empty.');
    }

    // ESC GS y S 0 <cellWidth>
    writer.writeByte(esc);
    writer.writeByte(gs);
    writer.writeBytes([0x79, 0x53, 0x30, cellWidth]);

    // ESC GS y S 1 <ecc>
    writer.writeByte(esc);
    writer.writeByte(gs);
    writer.writeBytes([0x79, 0x53, 0x31, ecc]);

    // ESC GS y S 2 <model>
    writer.writeByte(esc);
    writer.writeByte(gs);
    writer.writeBytes([0x79, 0x53, 0x32, model]);

    // ESC GS y D 1 0 <nL> <nH> <content>
    final len = content.length;
    writer.writeByte(esc);
    writer.writeByte(gs);
    writer.writeBytes([0x79, 0x44, 0x31, 0x30, len & 0xFF, (len >> 8) & 0xFF]);
    writer.writeAscii(content);

    // ESC GS y P (print)
    writer.writeByte(esc);
    writer.writeByte(gs);
    writer.writeBytes(const [0x79, 0x50]);
  }

  /// Emits `ESC * r A` — Enter Raster Mode.
  static void writeEnterRaster(PrinterByteWriter writer) {
    writer.writeByte(esc);
    writer.writeBytes(const [0x2A, 0x72, 0x41]); // * r A
  }

  /// Emits `b <nL> <nH> <rowData>` — Raster Row Command.
  static void writeRasterRow(PrinterByteWriter writer, Uint8List rowData) {
    writer.writeByte(0x62); // 'b'
    writer.writeByte(rowData.length & 0xFF);
    writer.writeByte((rowData.length >> 8) & 0xFF);
    writer.writeBytes(rowData);
  }

  /// Emits `ESC * r B` — Exit Raster Mode.
  static void writeExitRaster(PrinterByteWriter writer) {
    writer.writeByte(esc);
    writer.writeBytes(const [0x2A, 0x72, 0x42]); // * r B
  }

  /// Emits a complete raster image bounded by enter/exit raster mode frames.
  static void writeRaster(
    PrinterByteWriter writer, {
    required Uint8List data,
    required int bytesPerRow,
    required int height,
  }) {
    if (bytesPerRow <= 0 || height <= 0) {
      throw InvalidConfigError(
        'Star PRNT raster dimensions must be positive, got bytesPerRow: $bytesPerRow, height: $height',
      );
    }
    final expectedLength = bytesPerRow * height;
    if (data.length != expectedLength) {
      throw InvalidConfigError(
        'Star PRNT raster data length (${data.length}) does not match bytesPerRow ($bytesPerRow) * height ($height) = $expectedLength',
      );
    }

    writeEnterRaster(writer);
    for (int y = 0; y < height; y++) {
      final start = y * bytesPerRow;
      writeRasterRow(
        writer,
        Uint8List.sublistView(data, start, start + bytesPerRow),
      );
    }
    writeExitRaster(writer);
  }

  /// Emits raw binary bytes directly.
  static void writeRawBytes(PrinterByteWriter writer, List<int> bytes) {
    writer.writeBytes(bytes);
  }

  /// Emits raw command string (losslessly encoded as 8-bit bytes via latin1).
  static void writeRawAscii(
    PrinterByteWriter writer,
    String text, {
    bool appendNewline = false,
  }) {
    writer.writeString(text, encoding: latin1);
    if (appendNewline) {
      writer.writeString('\n', encoding: latin1);
    }
  }
}
