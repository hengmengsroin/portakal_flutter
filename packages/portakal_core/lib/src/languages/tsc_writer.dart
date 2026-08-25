import 'dart:typed_data';

import '../byte_writer.dart';
import '../errors.dart';

/// Internal low-level command serializer for TSC / TSPL2 commands.
///
/// Shared between the universal AST serializer (`compileToTSCBytes`) and the protocol-native
/// builder (`TscPrinter`). Emits byte-exact TSPL2 syntax directly to [PrinterByteWriter].
class TscCommandWriter {
  const TscCommandWriter._();

  /// Escapes double quotes per TSPL specification (`"` -> `\["]`) and rejects
  /// embedded literal CR/LF characters with [InvalidConfigError].
  static String escapeTscString(String input) {
    if (input.contains('\r') || input.contains('\n')) {
      throw InvalidConfigError(
        'TSPL text and barcode content cannot contain literal newline characters (CR/LF): "$input"',
      );
    }
    return input.replaceAll('"', r'\["]');
  }

  /// Emit `SIZE <width> dot,<height> dot\r\n`.
  static void writeSizeDots(
    PrinterByteWriter writer,
    int widthDots,
    int heightDots,
  ) {
    if (widthDots <= 0 || heightDots <= 0) {
      throw InvalidConfigError(
        'Label dimensions in dots must be positive, got width: $widthDots, height: $heightDots',
      );
    }
    writer.writeAscii('SIZE $widthDots dot,$heightDots dot\r\n');
  }

  /// Emit `SIZE <width> mm,<height> mm\r\n`.
  static void writeSizeMm(
    PrinterByteWriter writer,
    double widthMm,
    double heightMm,
  ) {
    if (widthMm <= 0 || heightMm <= 0) {
      throw InvalidConfigError(
        'Label dimensions in mm must be positive, got width: $widthMm, height: $heightMm',
      );
    }
    final wStr = widthMm == widthMm.roundToDouble()
        ? widthMm.round().toString()
        : widthMm.toString();
    final hStr = heightMm == heightMm.roundToDouble()
        ? heightMm.round().toString()
        : heightMm.toString();
    writer.writeAscii('SIZE $wStr mm,$hStr mm\r\n');
  }

  /// Emit `SIZE <width>,<height>\r\n` (inches).
  static void writeSizeInches(
    PrinterByteWriter writer,
    double widthInches,
    double heightInches,
  ) {
    if (widthInches <= 0 || heightInches <= 0) {
      throw InvalidConfigError(
        'Label dimensions in inches must be positive, got width: $widthInches, height: $heightInches',
      );
    }
    final wStr = widthInches == widthInches.roundToDouble()
        ? widthInches.round().toString()
        : widthInches.toString();
    final hStr = heightInches == heightInches.roundToDouble()
        ? heightInches.round().toString()
        : heightInches.toString();
    writer.writeAscii('SIZE $wStr,$hStr\r\n');
  }

  /// Emit `GAP <distance> dot,<offset> dot\r\n`.
  static void writeGapDots(
    PrinterByteWriter writer,
    int distanceDots,
    int offsetDots,
  ) {
    if (distanceDots < 0 || offsetDots < 0) {
      throw InvalidConfigError(
        'Gap dimensions cannot be negative, got distance: $distanceDots, offset: $offsetDots',
      );
    }
    writer.writeAscii('GAP $distanceDots dot,$offsetDots dot\r\n');
  }

  /// Emit `GAP <distance> mm,<offset> mm\r\n`.
  static void writeGapMm(
    PrinterByteWriter writer,
    double distanceMm,
    double offsetMm,
  ) {
    if (distanceMm < 0 || offsetMm < 0) {
      throw InvalidConfigError(
        'Gap dimensions cannot be negative, got distance: $distanceMm, offset: $offsetMm',
      );
    }
    final dStr = distanceMm == distanceMm.roundToDouble()
        ? distanceMm.round().toString()
        : distanceMm.toString();
    final oStr = offsetMm == offsetMm.roundToDouble()
        ? offsetMm.round().toString()
        : offsetMm.toString();
    writer.writeAscii('GAP $dStr mm,$oStr mm\r\n');
  }

  /// Emit `GAP 0 mm,0 mm\r\n` (continuous media).
  static void writeGapContinuous(PrinterByteWriter writer) {
    writer.writeAscii('GAP 0 mm,0 mm\r\n');
  }

  /// Emit `BLINE <height> dot,<offset> dot\r\n`.
  static void writeBlineDots(
    PrinterByteWriter writer,
    int heightDots,
    int offsetDots,
  ) {
    writer.writeAscii('BLINE $heightDots dot,$offsetDots dot\r\n');
  }

  /// Emit `BLINE <height> mm,<offset> mm\r\n`.
  static void writeBlineMm(
    PrinterByteWriter writer,
    double heightMm,
    double offsetMm,
  ) {
    final hStr = heightMm == heightMm.roundToDouble()
        ? heightMm.round().toString()
        : heightMm.toString();
    final oStr = offsetMm == offsetMm.roundToDouble()
        ? offsetMm.round().toString()
        : offsetMm.toString();
    writer.writeAscii('BLINE $hStr mm,$oStr mm\r\n');
  }

  /// Emit `OFFSET <distance> dot\r\n`.
  static void writeOffsetDots(PrinterByteWriter writer, int distanceDots) {
    writer.writeAscii('OFFSET $distanceDots dot\r\n');
  }

  /// Emit `OFFSET <distance> mm\r\n`.
  static void writeOffsetMm(PrinterByteWriter writer, double distanceMm) {
    final dStr = distanceMm == distanceMm.roundToDouble()
        ? distanceMm.round().toString()
        : distanceMm.toString();
    writer.writeAscii('OFFSET $dStr mm\r\n');
  }

  /// Emit `SPEED <ips>\r\n`.
  static void writeSpeed(PrinterByteWriter writer, double ips) {
    if (ips <= 0) {
      throw InvalidConfigError('Speed must be positive, got: $ips');
    }
    final sStr =
        ips == ips.roundToDouble() ? ips.round().toString() : ips.toString();
    writer.writeAscii('SPEED $sStr\r\n');
  }

  /// Emit `DENSITY <darkness>\r\n` (0..15).
  static void writeDensity(PrinterByteWriter writer, int darkness) {
    if (darkness < 0 || darkness > 15) {
      throw InvalidConfigError(
        'Density must be between 0 and 15, got: $darkness',
      );
    }
    writer.writeAscii('DENSITY $darkness\r\n');
  }

  /// Emit `DIRECTION <direction>[,<mirror>]\r\n`.
  static void writeDirection(
    PrinterByteWriter writer,
    int direction, [
    int? mirror,
  ]) {
    if (mirror != null) {
      writer.writeAscii('DIRECTION $direction,$mirror\r\n');
    } else {
      writer.writeAscii('DIRECTION $direction\r\n');
    }
  }

  /// Emit `REFERENCE <x>,<y>\r\n`.
  static void writeReference(PrinterByteWriter writer, int x, int y) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'Reference coordinates cannot be negative, got x: $x, y: $y',
      );
    }
    writer.writeAscii('REFERENCE $x,$y\r\n');
  }

  /// Emit `SHIFT [<x>,]<y>\r\n`.
  static void writeShift(PrinterByteWriter writer, int y, [int? x]) {
    if (x != null && x != 0) {
      writer.writeAscii('SHIFT $x,$y\r\n');
    } else {
      writer.writeAscii('SHIFT $y\r\n');
    }
  }

  /// Emit `CLS\r\n`.
  static void writeCls(PrinterByteWriter writer) {
    writer.writeAscii('CLS\r\n');
  }

  /// Emit `CODEPAGE <code>\r\n`.
  static void writeCodePage(PrinterByteWriter writer, String codepage) {
    writer.writeAscii('CODEPAGE $codepage\r\n');
  }

  /// Emit `TEXT <x>,<y>,"<font>",<rotation>,<xMul>,<yMul>[,<alignment>],"<encodedContent>"\r\n`.
  static void writeText(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String font,
    required int rotation,
    required int xMul,
    required int yMul,
    int? alignment,
    required Uint8List encodedContent,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'Text position cannot be negative, got x: $x, y: $y',
      );
    }
    if (xMul < 1 || xMul > 10 || yMul < 1 || yMul > 10) {
      throw InvalidConfigError(
        'Text scale multiplication must be between 1 and 10, got xMul: $xMul, yMul: $yMul',
      );
    }

    writer.writeAscii('TEXT $x,$y,"$font",$rotation,$xMul,$yMul');
    if (alignment != null && alignment > 0) {
      writer.writeAscii(',$alignment');
    }
    writer.writeAscii(',"');
    writer.writeBytes(encodedContent);
    writer.writeAscii('"\r\n');
  }

  /// Emit `BARCODE <x>,<y>,"<type>",<height>,<readable>,<rotation>,<narrow>,<wide>[,<alignment>],"<escapedContent>"\r\n`.
  static void writeBarcode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String type,
    required int height,
    required int readable,
    required int rotation,
    required int narrow,
    required int wide,
    int? alignment,
    required String content,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'Barcode position cannot be negative, got x: $x, y: $y',
      );
    }
    if (height <= 0) {
      throw InvalidConfigError('Barcode height must be positive, got: $height');
    }
    if (narrow <= 0 || wide <= 0) {
      throw InvalidConfigError(
        'Barcode narrow and wide bar widths must be positive, got narrow: $narrow, wide: $wide',
      );
    }
    final escaped = escapeTscString(content);
    writer.writeAscii(
      'BARCODE $x,$y,"$type",$height,$readable,$rotation,$narrow,$wide',
    );
    if (alignment != null && alignment > 0) {
      writer.writeAscii(',$alignment');
    }
    writer.writeAscii(',"$escaped"\r\n');
  }

  /// Emit `QRCODE <x>,<y>,"<ecc>",<cellWidth>,"<mode>",<rotation>[,"<model>"][,"<mask >"],"<escapedContent>"\r\n`.
  static void writeQrCode(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required String ecc,
    required int cellWidth,
    required String mode,
    required int rotation,
    String? model,
    String? mask,
    required String content,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'QR code position cannot be negative, got x: $x, y: $y',
      );
    }
    if (cellWidth < 1 || cellWidth > 10) {
      throw InvalidConfigError(
        'QR code cell width must be between 1 and 10, got: $cellWidth',
      );
    }
    final escaped = escapeTscString(content);
    writer.writeAscii('QRCODE $x,$y,"$ecc",$cellWidth,"$mode",$rotation');
    if (model != null) {
      writer.writeAscii(',"$model"');
    }
    if (mask != null) {
      writer.writeAscii(',"$mask"');
    }
    writer.writeAscii(',"$escaped"\r\n');
  }

  /// Emit `BOX <x>,<y>,<xEnd>,<yEnd>,<thickness>[,<radius>]\r\n`.
  static void writeBox(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int xEnd,
    required int yEnd,
    required int thickness,
    int? radius,
  }) {
    if (thickness <= 0) {
      throw InvalidConfigError(
        'Box thickness must be positive, got: $thickness',
      );
    }
    if (radius != null && radius > 0) {
      writer.writeAscii('BOX $x,$y,$xEnd,$yEnd,$thickness,$radius\r\n');
    } else {
      writer.writeAscii('BOX $x,$y,$xEnd,$yEnd,$thickness\r\n');
    }
  }

  /// Emit `BAR <x>,<y>,<width>,<height>\r\n`.
  static void writeBar(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0) {
      throw InvalidConfigError(
        'Bar dimensions must be positive, got width: $width, height: $height',
      );
    }
    writer.writeAscii('BAR $x,$y,$width,$height\r\n');
  }

  /// Emit `CIRCLE <x>,<y>,<diameter>,<thickness>\r\n`.
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
    writer.writeAscii('CIRCLE $x,$y,$diameter,$thickness\r\n');
  }

  /// Emit `ELLIPSE <x>,<y>,<width>,<height>,<thickness>\r\n`.
  static void writeEllipse(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
    required int thickness,
  }) {
    if (width <= 0 || height <= 0 || thickness <= 0) {
      throw InvalidConfigError(
        'Ellipse dimensions and thickness must be positive, got width: $width, height: $height, thickness: $thickness',
      );
    }
    writer.writeAscii('ELLIPSE $x,$y,$width,$height,$thickness\r\n');
  }

  /// Emit `DIAGONAL <x1>,<y1>,<x2>,<y2>,<thickness>\r\n`.
  static void writeDiagonal(
    PrinterByteWriter writer, {
    required int x1,
    required int y1,
    required int x2,
    required int y2,
    required int thickness,
  }) {
    if (thickness <= 0) {
      throw InvalidConfigError(
        'Diagonal line thickness must be positive, got: $thickness',
      );
    }
    writer.writeAscii('DIAGONAL $x1,$y1,$x2,$y2,$thickness\r\n');
  }

  /// Emit `REVERSE <x>,<y>,<width>,<height>\r\n`.
  static void writeReverse(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0) {
      throw InvalidConfigError(
        'Reverse area dimensions must be positive, got width: $width, height: $height',
      );
    }
    writer.writeAscii('REVERSE $x,$y,$width,$height\r\n');
  }

  /// Emit `ERASE <x>,<y>,<width>,<height>\r\n`.
  static void writeErase(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0) {
      throw InvalidConfigError(
        'Erase area dimensions must be positive, got width: $width, height: $height',
      );
    }
    writer.writeAscii('ERASE $x,$y,$width,$height\r\n');
  }

  /// Emit `BITMAP <x>,<y>,<bytesPerRow>,<height>,<mode>,<binary data>\r\n`.
  static void writeBitmap(
    PrinterByteWriter writer, {
    required int x,
    required int y,
    required int bytesPerRow,
    required int height,
    required int mode,
    required Uint8List data,
  }) {
    if (x < 0 || y < 0) {
      throw InvalidConfigError(
        'Bitmap position cannot be negative, got x: $x, y: $y',
      );
    }
    if (bytesPerRow <= 0 || height <= 0) {
      throw InvalidConfigError(
        'Bitmap dimensions must be positive, got bytesPerRow: $bytesPerRow, height: $height',
      );
    }
    final expectedLength = bytesPerRow * height;
    if (data.length != expectedLength) {
      throw InvalidConfigError(
        'Bitmap data length (${data.length}) does not match expected bytesPerRow ($bytesPerRow) * height ($height) = $expectedLength',
      );
    }
    writer.writeAscii('BITMAP $x,$y,$bytesPerRow,$height,$mode,');
    writer.writeBytes(data);
    writer.writeAscii('\r\n');
  }

  /// Emit `PRINT <sets>[,<copies>]\r\n`.
  static void writePrint(
    PrinterByteWriter writer, {
    required int sets,
    int? copies,
  }) {
    if (sets <= 0) {
      throw InvalidConfigError('Print sets must be positive, got: $sets');
    }
    if (copies != null && copies > 1) {
      writer.writeAscii('PRINT $sets,$copies\r\n');
    } else {
      writer.writeAscii('PRINT $sets\r\n');
    }
  }

  /// Emit `FORMFEED\r\n`.
  static void writeFormFeed(PrinterByteWriter writer) {
    writer.writeAscii('FORMFEED\r\n');
  }

  /// Emit `HOME\r\n`.
  static void writeHome(PrinterByteWriter writer) {
    writer.writeAscii('HOME\r\n');
  }

  /// Emit `FEED <dots>\r\n`.
  static void writeFeed(PrinterByteWriter writer, int dots) {
    if (dots <= 0) {
      throw InvalidConfigError('Feed dots must be positive, got: $dots');
    }
    writer.writeAscii('FEED $dots\r\n');
  }

  /// Emit `BACKFEED <dots>\r\n`.
  static void writeBackFeed(PrinterByteWriter writer, int dots) {
    if (dots <= 0) {
      throw InvalidConfigError('Backfeed dots must be positive, got: $dots');
    }
    writer.writeAscii('BACKFEED $dots\r\n');
  }

  /// Emit `CUT\r\n`.
  static void writeCut(PrinterByteWriter writer) {
    writer.writeAscii('CUT\r\n');
  }

  /// Emit `SOUND <level>,<interval>\r\n`.
  static void writeSound(
    PrinterByteWriter writer, {
    required int level,
    required int interval,
  }) {
    if (level < 0 || level > 9) {
      throw InvalidConfigError(
        'Sound level must be between 0 and 9, got: $level',
      );
    }
    if (interval < 1 || interval > 4095) {
      throw InvalidConfigError(
        'Sound interval must be between 1 and 4095 ms, got: $interval',
      );
    }
    writer.writeAscii('SOUND $level,$interval\r\n');
  }

  /// Emit immediate status request `<ESC>!?` (exact bytes: `0x1B, 0x21, 0x3F` without CRLF).
  static void writeImmediateStatus(PrinterByteWriter writer) {
    writer.writeBytes(const [0x1B, 0x21, 0x3F]);
  }

  /// Emit raw bytes directly to writer.
  static void writeRawBytes(PrinterByteWriter writer, List<int> bytes) {
    writer.writeBytes(bytes);
  }

  /// Emit raw ASCII command.
  static void writeRawAscii(
    PrinterByteWriter writer,
    String command, {
    bool appendNewline = true,
  }) {
    writer.writeAscii(command);
    if (appendNewline) {
      writer.writeAscii('\r\n');
    }
  }
}
