import 'dart:typed_data';

import '../byte_writer.dart';
import '../errors.dart';

/// Internal low-level command serializer for ESC/POS commands.
///
/// Shared between the universal AST serializer (`compileToESCPOS`) and the protocol-native
/// builder (`EscPosPrinter`). Emits byte-exact ESC/POS syntax directly to [PrinterByteWriter].
class EscPosCommandWriter {
  const EscPosCommandWriter._();

  /// Emit `ESC @` (0x1B, 0x40) — Initialize printer.
  static void writeInitialize(PrinterByteWriter writer) {
    writer.writeBytes([0x1B, 0x40]);
  }

  /// Emit `ESC t <tableId>` (0x1B, 0x74, tableId) — Select character code table.
  static void writeCodePage(PrinterByteWriter writer, int tableId) {
    if (tableId < 0 || tableId > 255) {
      throw InvalidConfigError(
        'ESC/POS character table ID must be between 0 and 255, got: $tableId',
      );
    }
    writer.writeBytes([0x1B, 0x74, tableId]);
  }

  /// Emit `ESC a <n>` (0x1B, 0x61, n) — Select justification (0: Left, 1: Center, 2: Right).
  static void writeAlign(PrinterByteWriter writer, int alignValue) {
    if (alignValue < 0 || alignValue > 2) {
      throw InvalidConfigError(
        'ESC/POS alignment value must be between 0 and 2, got: $alignValue',
      );
    }
    writer.writeBytes([0x1B, 0x61, alignValue]);
  }

  /// Emit `ESC E <n>` (0x1B, 0x45, n) — Turn emphasized (bold) mode on/off.
  static void writeBold(PrinterByteWriter writer, bool enabled) {
    writer.writeBytes([0x1B, 0x45, enabled ? 1 : 0]);
  }

  /// Emit `ESC - <n>` (0x1B, 0x2D, n) — Turn underline mode on/off (0: none, 1: 1-dot, 2: 2-dot).
  static void writeUnderline(PrinterByteWriter writer, int underlineValue) {
    if (underlineValue < 0 || underlineValue > 2) {
      throw InvalidConfigError(
        'ESC/POS underline mode must be 0, 1, or 2, got: $underlineValue',
      );
    }
    writer.writeBytes([0x1B, 0x2D, underlineValue]);
  }

  /// Emit `GS B <n>` (0x1D, 0x42, n) — Turn white/black reverse printing mode on/off.
  static void writeInvert(PrinterByteWriter writer, bool enabled) {
    writer.writeBytes([0x1D, 0x42, enabled ? 1 : 0]);
  }

  /// Emit `ESC M <n>` (0x1B, 0x4D, n) — Select font (0: Font A, 1: Font B, 2: Font C).
  static void writeFont(PrinterByteWriter writer, int fontValue) {
    if (fontValue < 0 || fontValue > 2) {
      throw InvalidConfigError(
        'ESC/POS font value must be 0, 1, or 2, got: $fontValue',
      );
    }
    writer.writeBytes([0x1B, 0x4D, fontValue]);
  }

  /// Emit `GS ! <n>` (0x1D, 0x21, n) — Select character size magnification.
  ///
  /// [width] and [height] are 1-based scaling multipliers (1..8).
  static void writeTextSize(
    PrinterByteWriter writer, {
    required int width,
    required int height,
  }) {
    if (width < 1 || width > 8 || height < 1 || height > 8) {
      throw InvalidConfigError(
        'Character size multipliers must be between 1 and 8, got width: $width, height: $height',
      );
    }
    final n = ((width - 1) << 4) | (height - 1);
    writer.writeBytes([0x1D, 0x21, n]);
  }

  /// Emit `LF` (0x0A) [lines] times.
  static void writeLineFeed(PrinterByteWriter writer, [int lines = 1]) {
    if (lines < 1) return;
    for (int i = 0; i < lines; i++) {
      writer.writeByte(0x0A);
    }
  }

  /// Emit `ESC d <lines>` (0x1B, 0x64, lines) — Print and feed paper by [lines].
  static void writeFeedLines(PrinterByteWriter writer, int lines) {
    if (lines < 0 || lines > 255) {
      throw InvalidConfigError(
        'Paper feed lines must be between 0 and 255, got: $lines',
      );
    }
    if (lines == 0) return;
    writer.writeBytes([0x1B, 0x64, lines]);
  }

  /// Emit `ESC J <dots>` (0x1B, 0x4A, dots) — Print and feed paper by [dots].
  static void writeFeedDots(PrinterByteWriter writer, int dots) {
    if (dots < 0 || dots > 255) {
      throw InvalidConfigError(
        'Paper feed dots must be between 0 and 255, got: $dots',
      );
    }
    if (dots == 0) return;
    writer.writeBytes([0x1B, 0x4A, dots]);
  }

  /// Emit 1D barcode sequence using Function B (GS k m n d1..dn).
  static void writeBarcode(
    PrinterByteWriter writer, {
    required int type,
    required int height,
    required int width,
    required int hri,
    required int hriFont,
    required List<int> content,
  }) {
    if (content.isEmpty) {
      throw InvalidConfigError('Barcode content cannot be empty');
    }
    if (height < 1 || height > 255) {
      throw InvalidConfigError(
        'Barcode height must be between 1 and 255 dots, got: $height',
      );
    }
    if (width < 2 || width > 6) {
      throw InvalidConfigError(
        'Barcode module width must be between 2 and 6, got: $width',
      );
    }

    // GS h n — Set barcode height
    writer.writeBytes([0x1D, 0x68, height]);
    // GS w n — Set barcode module width
    writer.writeBytes([0x1D, 0x77, width]);
    // GS H n — Set HRI characters printing position
    writer.writeBytes([0x1D, 0x48, hri]);
    // GS f n — Set font for HRI characters
    writer.writeBytes([0x1D, 0x66, hriFont]);
    // GS k m n d1..dn — Print barcode
    writer.writeBytes([0x1D, 0x6B, type, content.length]);
    writer.writeBytes(content);
  }

  /// Emit 2D QR code sequence using standard Epson GS ( k lifecycle.
  static void writeQrCode(
    PrinterByteWriter writer, {
    required int model,
    required int size,
    required int ecc,
    required List<int> content,
  }) {
    if (content.isEmpty) {
      throw InvalidConfigError('QR code content cannot be empty');
    }
    if (size < 1 || size > 16) {
      throw InvalidConfigError(
        'QR code module size must be between 1 and 16 dots, got: $size',
      );
    }

    // 1. Select model: GS ( k 0x04 0x00 0x31 0x41 <model> 0x00
    writer.writeBytes([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, model, 0x00]);

    // 2. Set module size: GS ( k 0x03 0x00 0x31 0x43 <size>
    writer.writeBytes([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, size]);

    // 3. Set ECC level: GS ( k 0x03 0x00 0x31 0x45 <ecc>
    writer.writeBytes([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, ecc]);

    // 4. Store symbol data: GS ( k <pL> <pH> 0x31 0x50 0x30 <data>
    final len = content.length + 3;
    final pL = len & 0xFF;
    final pH = (len >> 8) & 0xFF;
    writer.writeBytes([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
    writer.writeBytes(content);

    // 5. Print symbol: GS ( k 0x03 0x00 0x31 0x51 0x30
    writer.writeBytes([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
  }

  /// Emit `GS v 0 <mode> <xL> <xH> <yL> <yH> <data>` (0x1D, 0x76, 0x30, ...) — Print raster bit image.
  static void writeRaster(
    PrinterByteWriter writer, {
    required int mode,
    required int bytesPerRow,
    required int height,
    required Uint8List data,
  }) {
    if (bytesPerRow <= 0 || height <= 0) {
      throw InvalidConfigError(
        'Raster image dimensions must be positive, got bytesPerRow: $bytesPerRow, height: $height',
      );
    }
    final expectedLength = bytesPerRow * height;
    if (data.length != expectedLength) {
      throw InvalidConfigError(
        'Raster image data length (${data.length}) does not match expected bytesPerRow ($bytesPerRow) * height ($height) = $expectedLength',
      );
    }

    writer.writeBytes([0x1D, 0x76, 0x30, mode]);
    writer.writeBytes([bytesPerRow & 0xFF, (bytesPerRow >> 8) & 0xFF]);
    writer.writeBytes([height & 0xFF, (height >> 8) & 0xFF]);
    writer.writeBytes(data);
  }

  /// Emit `GS V` paper cut command.
  ///
  /// If [feedLines] > 0, emits Function B `GS V <mode> <feedLines>` (`0x1D, 0x56, mode, feedLines`).
  /// If [feedLines] == 0, emits direct cut `GS V <0|1>` (`0x1D, 0x56, 0` for full, `0x1D, 0x56, 1` for partial).
  static void writeCut(
    PrinterByteWriter writer, {
    required int mode,
    required int feedLines,
  }) {
    if (feedLines < 0 || feedLines > 255) {
      throw InvalidConfigError(
        'Cut feed lines must be between 0 and 255, got: $feedLines',
      );
    }
    if (feedLines > 0) {
      writer.writeBytes([0x1D, 0x56, mode, feedLines]);
    } else {
      final directMode = mode == 0x41 ? 0 : 1;
      writer.writeBytes([0x1D, 0x56, directMode]);
    }
  }

  /// Emit `ESC p <pin> <t1> <t2>` (0x1B, 0x70, pin, t1, t2) — Generate cash drawer kick pulse.
  static void writePulseDrawer(
    PrinterByteWriter writer, {
    required int pin,
    required int onTimeMs,
    required int offTimeMs,
  }) {
    if (onTimeMs < 0 || onTimeMs > 510) {
      throw InvalidConfigError(
        'Drawer pulse ON duration must be between 0 and 510 ms, got: $onTimeMs',
      );
    }
    if (offTimeMs < 0 || offTimeMs > 510) {
      throw InvalidConfigError(
        'Drawer pulse OFF duration must be between 0 and 510 ms, got: $offTimeMs',
      );
    }
    if (onTimeMs % 2 != 0) {
      throw InvalidConfigError(
        'Drawer pulse ON duration must be an even multiple of 2 ms, got: $onTimeMs',
      );
    }
    if (offTimeMs % 2 != 0) {
      throw InvalidConfigError(
        'Drawer pulse OFF duration must be an even multiple of 2 ms, got: $offTimeMs',
      );
    }
    if (offTimeMs < onTimeMs) {
      throw InvalidConfigError(
        'Drawer pulse OFF duration ($offTimeMs ms) must be greater than or equal to ON duration ($onTimeMs ms)',
      );
    }

    final t1 = onTimeMs ~/ 2;
    final t2 = offTimeMs ~/ 2;
    writer.writeBytes([0x1B, 0x70, pin, t1, t2]);
  }

  /// Emit `DLE EOT <n>` (0x10, 0x04, n) — Real-time status transmission request.
  static void writeRealTimeStatus(PrinterByteWriter writer, int statusType) {
    if (statusType < 1 || statusType > 4) {
      throw InvalidConfigError(
        'Real-time status request type must be between 1 and 4, got: $statusType',
      );
    }
    writer.writeBytes([0x10, 0x04, statusType]);
  }

  /// Emit raw bytes directly to writer.
  static void writeRawBytes(PrinterByteWriter writer, List<int> bytes) {
    writer.writeBytes(bytes);
  }

  /// Emit raw ASCII command string.
  static void writeRawAscii(
    PrinterByteWriter writer,
    String text, {
    bool appendNewline = false,
  }) {
    writer.writeAscii(text);
    if (appendNewline) {
      writer.writeByte(0x0A);
    }
  }
}
