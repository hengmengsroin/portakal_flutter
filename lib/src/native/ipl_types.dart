/// Strongly typed representations of IPL command parameters, rotations, and symbologies.
library;

/// Text and field rotation orientations in IPL.
enum IplRotation {
  /// 0 degrees (normal horizontal text, code 0).
  unrotated(0),

  /// 90 degrees clockwise (code 1).
  rotated90(1),

  /// 180 degrees inverted (code 2).
  inverted180(2),

  /// 270 degrees clockwise (bottom-up, code 3).
  bottomUp270(3);

  final int code;

  const IplRotation(this.code);
}

/// Supported 1D and 2D barcode symbologies in IPL.
enum IplBarcodeType {
  /// Code 128 (symbology code 0).
  code128(0),

  /// Code 39 (symbology code 0).
  code39(0),

  /// 2D QR Code (symbology code 21).
  qrCode(21);

  final int code;

  const IplBarcodeType(this.code);
}
