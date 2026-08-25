/// Strongly typed representations of CPCL command parameters, rotations, and symbologies.
library;

/// Text and field rotation orientations in CPCL.
enum CpclRotation {
  /// 0 degrees (normal horizontal text).
  unrotated(0),

  /// 90 degrees clockwise (vertical text).
  rotated90(90),

  /// 180 degrees inverted.
  inverted180(180),

  /// 270 degrees clockwise (bottom-up).
  bottomUp270(270);

  final int degrees;

  const CpclRotation(this.degrees);
}

/// Supported 1D barcode symbologies in CPCL (`BARCODE` command).
enum CpclBarcodeType {
  /// Code 128 (128).
  code128('128'),

  /// Code 39 (39).
  code39('39'),

  /// EAN-13 (E30 / EAN13).
  ean13('E30'),

  /// EAN-8 (E80 / EAN8).
  ean8('E80'),

  /// UPC-A (UPCA / 9).
  upcA('UPCA'),

  /// UPC-E (UPCE).
  upcE('UPCE'),

  /// Interleaved 2 of 5 (I2OF5 / 2).
  itf('I2OF5'),

  /// Codabar (CODABAR).
  codabar('CODABAR');

  final String code;

  const CpclBarcodeType(this.code);
}
