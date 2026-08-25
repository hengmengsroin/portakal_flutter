/// Strongly typed representations of TSC / TSPL2 command parameters.
library;

/// Base class for TSPL font definitions.
sealed class TscFont {
  /// The TSPL identifier string (e.g. "1", "2", "ROMAN.TTF").
  String get name;

  const TscFont();
}

/// Standard TSPL resident bitmap and scalable fonts.
enum TscResidentFont implements TscFont {
  /// Font 1: 8x12 dot resident bitmap font.
  font1('1'),

  /// Font 2: 12x20 dot resident bitmap font.
  font2('2'),

  /// Font 3: 16x24 dot resident bitmap font.
  font3('3'),

  /// Font 4: 24x32 dot resident bitmap font.
  font4('4'),

  /// Font 5: 32x48 dot resident bitmap font.
  font5('5'),

  /// Font 6: 14x19 dot resident bitmap font (OCR-B).
  font6('6'),

  /// Font 7: 21x27 dot resident bitmap font (OCR-B).
  font7('7'),

  /// Font 8: 14x25 dot resident bitmap font (OCR-A).
  font8('8'),

  /// Font 0: Monotype Scalable TrueType font (smooth scalable rendering).
  scalable('0');

  @override
  final String name;

  const TscResidentFont(this.name);
}

/// Downloaded TrueType or bitmap font stored on the printer.
class TscCustomFont extends TscFont {
  @override
  final String name;

  const TscCustomFont(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TscCustomFont &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'TscCustomFont("$name")';
}

/// Rotation angle for TSPL text, barcodes, and 2D codes.
enum TscRotation {
  /// 0 degrees (normal orientation).
  deg0(0),

  /// 90 degrees clockwise.
  deg90(90),

  /// 180 degrees (upside down).
  deg180(180),

  /// 270 degrees clockwise.
  deg270(270);

  final int degrees;

  const TscRotation(this.degrees);
}

/// Text alignment within bounding boxes or relative to coordinates.
enum TscAlignment {
  /// Default alignment (0).
  defaultAlign(0),

  /// Left alignment (1).
  left(1),

  /// Center alignment (2).
  center(2),

  /// Right alignment (3).
  right(3);

  final int value;

  const TscAlignment(this.value);
}

/// Print direction / orientation on label media.
enum TscDirection {
  /// Standard feed direction (0).
  normal(0),

  /// Inverted 180-degree feed direction (1).
  reversed(1);

  final int value;

  const TscDirection(this.value);
}

/// Supported 1D barcode symbologies in TSPL2.
enum TscBarcodeType {
  /// Code 128 auto switching (subsets A, B, C).
  code128('128'),

  /// Code 128 manual subset switching.
  code128m('128M'),

  /// EAN-128 / GS1-128.
  ean128('EAN128'),

  /// Code 39 standard.
  code39('39'),

  /// Code 39 with check digit.
  code39c('39C'),

  /// Code 93.
  code93('93'),

  /// Codabar (NW-7).
  codebar('CODA'),

  /// EAN-13.
  ean13('EAN13'),

  /// EAN-13 with 2-digit add-on.
  ean13Plus2('EAN13+2'),

  /// EAN-13 with 5-digit add-on.
  ean13Plus5('EAN13+5'),

  /// EAN-8.
  ean8('EAN8'),

  /// EAN-8 with 2-digit add-on.
  ean8Plus2('EAN8+2'),

  /// EAN-8 with 5-digit add-on.
  ean8Plus5('EAN8+5'),

  /// Interleaved 2 of 5 with 14 digits (ITF-14).
  itf('ITF14'),

  /// Interleaved 2 of 5 standard.
  itf25('ITF25'),

  /// UPC-A.
  upca('UPCA'),

  /// UPC-A with 2-digit add-on.
  upcaPlus2('UPCA+2'),

  /// UPC-A with 5-digit add-on.
  upcaPlus5('UPCA+5'),

  /// UPC-E.
  upce('UPCE'),

  /// UPC-E with 2-digit add-on.
  upcePlus2('UPCE+2'),

  /// UPC-E with 5-digit add-on.
  upcePlus5('UPCE+5'),

  /// PostNet postal barcode.
  postnet('POST');

  final String value;

  const TscBarcodeType(this.value);
}

/// Human-readable text placement for 1D barcodes.
enum TscBarcodeReadable {
  /// No human-readable text (0).
  none(0),

  /// Left-aligned human-readable text (1).
  left(1),

  /// Center-aligned human-readable text (2).
  center(2),

  /// Right-aligned human-readable text (3).
  right(3);

  final int value;

  const TscBarcodeReadable(this.value);
}

/// Error correction level for TSPL QR codes.
enum TscQrEcc {
  /// Level L: ~7% error correction.
  l('L'),

  /// Level M: ~15% error correction.
  m('M'),

  /// Level Q: ~25% error correction.
  q('Q'),

  /// Level H: ~30% error correction.
  h('H');

  final String value;

  const TscQrEcc(this.value);
}

/// Encoding mode for TSPL QR codes.
enum TscQrMode {
  /// Auto mode (A) — automatic selection of numerical/alphanumeric/byte encoding.
  auto('A'),

  /// Manual mode (M).
  manual('M');

  final String value;

  const TscQrMode(this.value);
}

/// Model version for TSPL QR codes.
enum TscQrModel {
  /// Model 1: Original QR code specification (M1).
  m1('M1'),

  /// Model 2: Enhanced QR code specification (M2 - standard on modern printers).
  m2('M2');

  final String value;

  const TscQrModel(this.value);
}

/// TSPL BITMAP graphics drawing mode.
enum TscBitmapMode {
  /// Mode 0: Overwrite existing graphics in image buffer.
  overwrite(0),

  /// Mode 1: Bitwise OR with existing graphics.
  or(1),

  /// Mode 2: Bitwise XOR with existing graphics.
  xor(2);

  final int value;

  const TscBitmapMode(this.value);
}
