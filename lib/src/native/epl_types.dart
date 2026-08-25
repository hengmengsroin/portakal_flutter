/// Strongly typed representations of EPL2 command parameters, fonts, and symbologies.
library;

/// Standard resident bitmap fonts in EPL2 (`A` command).
enum EplFont {
  /// Font 1: 6x8 dot matrix (20.3 CPI).
  font1('1'),

  /// Font 2: 8x12 dot matrix (16.9 CPI - default standard).
  font2('2'),

  /// Font 3: 10x16 dot matrix (14.5 CPI).
  font3('3'),

  /// Font 4: 12x20 dot matrix (12.7 CPI).
  font4('4'),

  /// Font 5: 32x48 dot matrix (5.6 CPI).
  font5('5');

  final String code;

  const EplFont(this.code);
}

/// Text and barcode rotation orientations in EPL2.
enum EplRotation {
  /// 0 degrees (normal unrotated orientation).
  unrotated(0),

  /// 90 degrees clockwise.
  rotated90(1),

  /// 180 degrees inverted.
  inverted180(2),

  /// 270 degrees clockwise (bottom-up).
  bottomUp270(3);

  final int value;

  const EplRotation(this.value);
}

/// Supported 1D barcode symbologies in EPL2 (`B` command).
enum EplBarcodeType {
  /// Code 128 Auto (1).
  code128('1'),

  /// Code 128 Mode A (1A).
  code128A('1A'),

  /// Code 128 Mode B (1B).
  code128B('1B'),

  /// Code 128 Mode C (1C).
  code128C('1C'),

  /// Code 39 standard (3).
  code39('3'),

  /// Code 39 with check digit (3C).
  code39WithCheck('3C'),

  /// EAN-8 (8 / E80).
  ean8('8'),

  /// EAN-13 (E / E30).
  ean13('E'),

  /// UPC-A (9).
  upcA('9'),

  /// UPC-E (E30).
  upcE('E30'),

  /// Interleaved 2 of 5 standard (2).
  itf('2'),

  /// Codabar (K).
  codabar('K');

  final String code;

  const EplBarcodeType(this.code);
}

/// QR Code error correction level in EPL2 (`b` command).
enum EplQrEcc {
  /// Level L: ~7% recovery.
  l('L'),

  /// Level M: ~15% recovery.
  m('M'),

  /// Level Q: ~25% recovery (standard default).
  q('Q'),

  /// Level H: ~30% recovery.
  h('H');

  final String code;

  const EplQrEcc(this.code);
}
