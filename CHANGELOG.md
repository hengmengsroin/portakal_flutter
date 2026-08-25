## 1.0.0

### Added
- Standardized canonical byte-native `.compile()` API returning `Uint8List` across all 9 language facades (`tsc`, `zpl`, `epl`, `cpcl`, `dpl`, `ipl`, `sbpl`, `escpos`, `starprnt`).
- Added `LabelBuilder.print([int copies = 1])` with eager positive-integer validation and authoritative resolution precedence.
- Added `LabelBuilder.rawBytes(Uint8List)` and `LabelBuilder.rawAscii(String)` with full binary gamut safety and ASCII validation.
- Added `UnsupportedFeaturePolicy` (`throwError`, `ignore`) defaulting to safe error throwing.
- Added `EncodingError` base class with clean inheritance (`UnsupportedCharacterException` extends `EncodingError` extends `PortakalError`).
- Added canonical `ReceiptColumn` in `portakal_core` and configured `portakal_flutter` export with `hide Column` to eliminate Flutter widget collisions.
- Added universal hardware validation bench in `example/` with deterministic test harness and automated golden SHA-256 assertions.
- Added comprehensive documentation hierarchy under `docs/` covering all 9 protocols, concepts, encodings, and migration.

### Changed
- Replaced `Column` with `ReceiptColumn` in receipt layout functions (`formatRow`, `formatTable`).
- Standardized all native protocol builders (`TscPrinter`, `EscPosPrinter`, `ZplPrinter`, etc.) on `.toBytes() -> Uint8List`.
- Decoupled `portakal_core` (pure Dart, zero UI dependencies) from `portakal_flutter` (Flutter integration).

### Deprecated
- Deprecated legacy `typedef Column = ReceiptColumn;` (removal in 2.0).
- Deprecated `.compileBytes()` aliases in favor of `.compile()` (removal in 2.0).
- Deprecated String serializers (`compileToTSC`, `compileToZPL`, etc.) in favor of byte-native APIs (removal in 2.0).
- Deprecated untyped `LabelBuilder.raw(Object)` and `RawElement({required Object content})` in favor of `rawBytes` and `rawAscii` (removal in 2.0).
- Deprecated legacy encoding helpers (`EncodedSegment`, `CodePage`, `isASCII`, `encodeText`, `encodeTextForPrinter`) in favor of `PrinterCodePage` and `CodePageEncoder` (removal in 2.0).

### Physical Hardware Validation
- Physically validated ESC/POS verified subset on `Printer001-328F` (PASS).
- Physically validated TSC/TSPL2 verified subset on `Printer001-328F` (PASS).
- Cataloged ZPL II emulation absence on `Printer001-328F` as `N/S-DEVICE`.

## 0.1.7

- Added `BarcodeElement` and `QRCodeElement` to the `LabelBuilder` API (`.barcode()` and `.qrcode()`).
- Implemented Barcode and QRCode native compilation support across all 9 printer languages.
- Added visual placeholder rendering for Barcodes and QRCodes in Flutter `LabelPreview`.

## 0.1.6

- Fixed analyzer warnings and minor formatting across packages.

## 0.1.5

- Package version bump and preparation for release.

## 0.1.0

- Initial public release of Portakal SDK.
