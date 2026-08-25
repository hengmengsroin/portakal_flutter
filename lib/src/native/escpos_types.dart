/// Strongly typed representations of ESC/POS command parameters.
library;

/// Character alignment on thermal paper roll (ESC a).
enum EscPosAlignment {
  /// Left-aligned (0).
  left(0),

  /// Centered (1).
  center(1),

  /// Right-aligned (2).
  right(2);

  final int value;

  const EscPosAlignment(this.value);
}

/// Resident font selection (ESC M).
enum EscPosFont {
  /// Font A: 12x24 dot standard font (0).
  fontA(0),

  /// Font B: 9x17 dot compressed font (1).
  fontB(1),

  /// Font C: 9x24 dot special font (2).
  ///
  /// Note: Font C availability is printer-model dependent.
  fontC(2);

  final int value;

  const EscPosFont(this.value);
}

/// Text underline mode (ESC -).
enum EscPosUnderline {
  /// Underline disabled (0).
  none(0),

  /// 1-dot thick underline (1).
  single(1),

  /// 2-dot thick underline (2).
  doubleThickness(2);

  final int value;

  const EscPosUnderline(this.value);
}

/// Supported 1D barcode symbologies in ESC/POS (Function B table / GS k).
enum EscPosBarcodeType {
  /// UPC-A (65 / 0x41).
  upca(65),

  /// UPC-E (66 / 0x42).
  upce(66),

  /// EAN-13 / JAN-13 (67 / 0x43).
  ean13(67),

  /// EAN-8 / JAN-8 (68 / 0x44).
  ean8(68),

  /// Code 39 (69 / 0x45).
  code39(69),

  /// Interleaved 2 of 5 (ITF) (70 / 0x46).
  itf(70),

  /// Codabar (NW-7) (71 / 0x47).
  codabar(71),

  /// Code 93 (72 / 0x48).
  code93(72),

  /// Code 128 (73 / 0x49).
  code128(73);

  final int value;

  const EscPosBarcodeType(this.value);
}

/// Human Readable Interpretation (HRI) character position for barcodes (GS H).
enum EscPosBarcodeHri {
  /// No HRI text printed (0).
  none(0),

  /// HRI printed above barcode (1).
  above(1),

  /// HRI printed below barcode (2).
  below(2),

  /// HRI printed both above and below barcode (3).
  both(3);

  final int value;

  const EscPosBarcodeHri(this.value);
}

/// Font selection for HRI barcode characters (GS f).
enum EscPosBarcodeFont {
  /// Standard Font A (0).
  fontA(0),

  /// Compressed Font B (1).
  fontB(1);

  final int value;

  const EscPosBarcodeFont(this.value);
}

/// QR Code model specification for GS ( k.
enum EscPosQrModel {
  /// Model 1: Original QR code specification (0x31).
  model1(0x31),

  /// Model 2: Enhanced QR code specification (0x32 - standard on modern printers).
  model2(0x32);

  final int value;

  const EscPosQrModel(this.value);
}

/// QR Code error correction level for GS ( k.
enum EscPosQrEcc {
  /// Level L: ~7% recovery (0x30).
  l(0x30),

  /// Level M: ~15% recovery (0x31).
  m(0x31),

  /// Level Q: ~25% recovery (0x32).
  q(0x32),

  /// Level H: ~30% recovery (0x33).
  h(0x33);

  final int value;

  const EscPosQrEcc(this.value);
}

/// Raster bit image scaling mode (GS v 0).
enum EscPosImageMode {
  /// Normal 1x1 scaling (0).
  normal(0),

  /// Double width scaling (1).
  doubleWidth(1),

  /// Double height scaling (2).
  doubleHeight(2),

  /// Quadruple (2x2) scaling (3).
  quadruple(3);

  final int value;

  const EscPosImageMode(this.value);
}

/// Auto-cutter cutting mode (GS V).
enum EscPosCutMode {
  /// Full cut (0x41 / 65).
  full(0x41),

  /// Partial cut (0x42 / 66).
  partial(0x42);

  final int value;

  const EscPosCutMode(this.value);
}

/// Cash drawer kick-out pin connector (ESC p).
enum EscPosDrawerPin {
  /// Pin 2 / Drawer 1 (0).
  pin2(0),

  /// Pin 5 / Drawer 2 (1).
  pin5(1);

  final int value;

  const EscPosDrawerPin(this.value);
}

/// Real-time status query request category (DLE EOT).
enum EscPosStatusType {
  /// Printer status (online/offline, cover open, feed button pressed) (1).
  printer(1),

  /// Offline status cause (cover open, feed button, paper end, error) (2).
  offline(2),

  /// Error status (auto-cutter error, unrecoverable error, auto-recoverable error) (3).
  error(3),

  /// Paper roll sensor status (paper near-end sensor, roll end sensor) (4).
  paper(4);

  final int value;

  const EscPosStatusType(this.value);
}
