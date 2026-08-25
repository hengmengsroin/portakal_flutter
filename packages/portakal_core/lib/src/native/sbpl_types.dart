/// Strongly typed representations of SBPL rotations, fonts, and symbologies.
library;

/// Text and field rotation orientations in SATO SBPL.
enum SbplRotation {
  /// 0 degrees (normal horizontal, code 0).
  unrotated(0),

  /// 90 degrees clockwise (code 1).
  rotated90(1),

  /// 180 degrees inverted (code 2).
  inverted180(2),

  /// 270 degrees clockwise (bottom-up, code 3).
  bottomUp270(3);

  final int code;

  const SbplRotation(this.code);
}

/// SATO standard font codes.
enum SbplFont {
  /// Standard vector / proportional font (K9B).
  k9b('K9B'),

  /// Small bitmap font (XS).
  xs('XS'),

  /// Ultra-small bitmap font (XU).
  xu('XU'),

  /// Medium bitmap font (XM).
  xm('XM'),

  /// Bold bitmap font (XB).
  xb('XB'),

  /// Large bitmap font (XL).
  xl('XL');

  final String code;

  const SbplFont(this.code);
}

/// Supported 1D barcode symbologies in SATO SBPL.
enum SbplBarcodeType {
  /// Code 39 (command B1).
  code39('B1'),

  /// Code 128 (command BG).
  code128('BG');

  final String code;

  const SbplBarcodeType(this.code);
}
