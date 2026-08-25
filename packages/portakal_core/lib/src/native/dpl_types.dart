/// Strongly typed representations of DPL command parameters, rotations, and symbologies.
library;

/// Text and field rotation orientations in DPL.
enum DplRotation {
  /// 0 degrees (normal unrotated orientation, code '1').
  unrotated('1'),

  /// 90 degrees clockwise (code '2').
  rotated90('2'),

  /// 180 degrees inverted (code '3').
  inverted180('3'),

  /// 270 degrees clockwise (bottom-up, code '4').
  bottomUp270('4');

  final String code;

  const DplRotation(this.code);
}

/// Supported 1D barcode symbologies in DPL.
enum DplBarcodeType {
  /// Code 128 (E).
  code128('E'),

  /// Code 39 (A).
  code39('A'),

  /// UPC-A (B).
  upcA('B'),

  /// UPC-E (C).
  upcE('C'),

  /// EAN-13 (F).
  ean13('F'),

  /// EAN-8 (G).
  ean8('G'),

  /// Interleaved 2 of 5 (D).
  itf('D'),

  /// Codabar (K).
  codabar('K');

  final String code;

  const DplBarcodeType(this.code);
}
