/// Strongly typed representations of ZPL II command parameters and fonts.
library;

/// Standard resident and scalable fonts in ZPL II (^A).
enum ZplFont {
  /// Scalable outline font (0). Smooth font scalable to any dot dimensions.
  font0('0'),

  /// Resident bitmap font A (5x7 matrix).
  fontA('A'),

  /// Resident bitmap font B (7x11 matrix).
  fontB('B'),

  /// Resident bitmap font C (10x18 matrix).
  fontC('C'),

  /// Resident bitmap font D (10x18 matrix).
  fontD('D'),

  /// Resident bitmap font E (15x28 matrix - OCR-B).
  fontE('E'),

  /// Resident bitmap font F (13x26 matrix).
  fontF('F'),

  /// Resident bitmap font G (40x60 matrix).
  fontG('G'),

  /// Resident bitmap font H (13x21 matrix - OCR-A).
  fontH('H'),

  /// Resident symbol font (GS).
  fontGS('GS');

  final String code;

  const ZplFont(this.code);
}

/// Text and field rotation angles in ZPL II.
enum ZplRotation {
  /// Normal unrotated orientation (N).
  unrotated('N'),

  /// Rotated 90 degrees clockwise (R).
  rotated90('R'),

  /// Inverted 180 degrees (I).
  inverted180('I'),

  /// Bottom-up 270 degrees clockwise (B).
  bottomUp270('B');

  final String code;

  const ZplRotation(this.code);
}

/// Field positioning coordinate reference mode in ZPL II.
enum ZplPositionMode {
  /// Field Origin (^FO) — coordinates referenced from top-left.
  origin,

  /// Field Typeset (^FT) — coordinates referenced from text baseline.
  typeset,
}

/// Supported 1D barcode symbologies in ZPL II.
enum ZplBarcodeType {
  /// Code 128 (^BC).
  code128('C'),

  /// Code 39 (^B3).
  code39('3'),

  /// EAN-13 (^BE).
  ean13('E'),

  /// EAN-8 (^B8).
  ean8('8'),

  /// UPC-A (^BU).
  upca('U'),

  /// UPC-E (^B9).
  upce('9'),

  /// Interleaved 2 of 5 (^BI).
  itf('I'),

  /// Codabar (^BK).
  codabar('K');

  final String code;

  const ZplBarcodeType(this.code);
}

/// QR Code model specification for ^BQ.
enum ZplQrModel {
  /// Model 1 (1).
  model1(1),

  /// Model 2 (2 - standard).
  model2(2);

  final int value;

  const ZplQrModel(this.value);
}

/// QR Code error correction level for ^BQ.
enum ZplQrEcc {
  /// Level L: ~7% recovery.
  l('L'),

  /// Level M: ~15% recovery.
  m('M'),

  /// Level Q: ~25% recovery.
  q('Q'),

  /// Level H: ~30% recovery.
  h('H');

  final String code;

  const ZplQrEcc(this.code);
}
