/// Strongly typed representations of Star Line Mode / StarPRNT alignment, cut modes, symbologies, and QR settings.
library;

/// Text alignment modes in Star Line Mode.
enum StarAlignment {
  /// Left-aligned (code 0).
  left(0),

  /// Centered (code 1).
  center(1),

  /// Right-aligned (code 2).
  right(2);

  final int code;

  const StarAlignment(this.code);
}

/// Auto-cutter modes in Star Line Mode (`ESC d <n>`).
enum StarCutMode {
  /// Full cut (code 0).
  full(0),

  /// Partial cut (code 1).
  partial(1),

  /// Feed to cutting position and full cut (code 2).
  feedThenFull(2),

  /// Feed to cutting position and partial cut (code 3).
  feedThenPartial(3);

  final int code;

  const StarCutMode(this.code);
}

/// Supported 1D barcode symbologies in Star Line Mode (`ESC b <n1> ...`).
enum StarBarcodeType {
  /// Code 39 (code 1).
  code39(1),

  /// Interleaved 2 of 5 / ITF (code 2).
  itf(2),

  /// NW-7 / Codabar (code 3).
  nw7(3),

  /// UPC-A (code 4).
  upcA(4),

  /// Code 128 (code 5).
  code128(5),

  /// Code 93 (code 6).
  code93(6),

  /// EAN-13 / JAN-13 (code 7).
  ean13(7),

  /// EAN-8 / JAN-8 (code 8).
  ean8(8);

  final int code;

  const StarBarcodeType(this.code);
}

/// Error correction levels for Star QR Code (`ESC GS y S 1 <n>`).
enum StarQrEcc {
  /// Level L: ~7% recovery (code 0).
  l(0),

  /// Level M: ~15% recovery (code 1).
  m(1),

  /// Level Q: ~25% recovery (code 2).
  q(2),

  /// Level H: ~30% recovery (code 3).
  h(3);

  final int code;

  const StarQrEcc(this.code);
}

/// Star QR Code generation model (`ESC GS y S 2 <n>`).
enum StarQrModel {
  /// QR Code Model 1 (code 1).
  model1(1),

  /// QR Code Model 2 (code 2).
  model2(2);

  final int code;

  const StarQrModel(this.code);
}
