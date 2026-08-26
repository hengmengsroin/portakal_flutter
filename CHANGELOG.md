# Portakal Changelog

## 1.2.0

Portakal 1.2 introduces **Hybrid Layout DX**: sequential document-style authoring, semantic horizontal rows, tables, dividers, stream receipt formatting, and type-safe barcode configuration while preserving full backward compatibility with exact-canvas coordinate layout.

### Added
- **Sequential Document Authoring**: Added top-level `sequentialLabel(config, {margin, lineAdvance})` entry point for document-style vertical layout with automatic vertical progression.
- **Semantic Rows**: Added `row(left, right)` for familiar 3:1 left/right pairs and `rowCells([LabelCell, ...])` for custom fixed and flex horizontal composition.
- **Structured Tables**: Added `builder.table(columns: [...])` returning `LabelTable` for repeated row generation sharing the parent builder's sequential document state.
- **Semantic Dividers & Spacing**: Added `divider({thickness, advance, margin})` emitting `DividerElement` and `space(amount)` advancing vertical state without emitting an AST node.
- **Universal AST Elements**: Added `RowElement`, `RowCellElement`, `DividerElement`, `LabelCell`, `LabelColumn`, `LabelTextAlign`, and `LabelTextStyle`.
- **Stream Row Formatter**: Added `StreamRowFormatter` lowering `RowElement` and `DividerElement` into formatted monospaced character lines for ESC/POS and Star PRNT with unstyled padding separation.
- **Stream Compiler Override**: Added optional `charsPerLine` parameter to `compileToESCPOS`, `compileToESCPOSBytes`, `compileToStarPRNT`, and `compileToStarPRNTBytes`.
- **Type-Safe Barcodes**: Added `enum BarcodeSymbology { code128, code39 }` and `BarcodeOptions.typed(...)` factory constructor lowering directly into canonical string identifiers.
- **PreviewScene Lowering**: Added full visual SVG layout for `RowElement` and vector lines for `DividerElement`.
- **AST-Based API Snapshot Tool**: Upgraded `tool/generate_api_snapshot.dart` to a structural Dart AST analyzer capturing complete signatures, parameter types, default values, and export filters.

### Improved
- **Developer Experience**: Drastically reduced manual Y coordinate bookkeeping in receipt, ticket, and invoice layouts.
- **Example Gallery**: Migrated restaurant receipts, kitchen tickets, queue slips, and commercial invoices to sequential document authoring and type-safe barcodes.

### Fixed
- **IPL Code 128 Lowering**: Corrected Intermec IPL barcode lowering where Code 128 previously emitted format selector `c0` (Code 39). Now emits authentic `c6` for Code 128 and `c0` for Code 39. Updated `IplBarcodeType.code128` from `0` to `6`.

### Compatibility
- **100% Source-Compatible**: `label(config)` remains available for exact coordinate canvas authoring.
- **Non-Breaking Barcode API**: `const BarcodeOptions(type: String, ...)` remains non-deprecated and fully functional as an escape hatch for custom or printer-specific symbologies (e.g. `type: 'EAN13'`).
- **Exact Coordinate Escape Hatch**: Inside a `sequentialLabel`, providing `x` or `y` on an element places it at exact coordinates without advancing sequential document state.
- **Intentional IPL Byte Change**: IPL Code 128 output changes from `c0` to `c6` to fix symbology encoding on Intermec hardware.

### Known Limitations
- **Visual Alignment Across Hardware**: Alignment fidelity varies across target printer firmware. PreviewScene and ZPL support native bounded alignment; ESC/POS and Star PRNT use space-padded character grids; other label protocols anchor at cell start coordinates.
- **Stream Unicode Glyphs**: Monospaced stream character-grid allocation does not guarantee visual glyph width for complex scripts (Khmer, CJK, emoji) where printer firmware font shaping governs physical output.
- **Typed Barcode Scope**: `BarcodeSymbology` is intentionally constrained to `code128` and `code39` where authentic semantic identity is guaranteed across all 9 supported compilers.

---

## 1.0.0

Stable production release of the Portakal Universal Thermal & Label Printer SDK.

### Added
- Standardized canonical byte-native `.compile()` API returning `Uint8List` across all 9 protocol facades (`tsc`, `zpl`, `epl`, `escpos`, `cpcl`, `dpl`, `ipl`, `sbpl`, `star`).
- Added `LabelBuilder.print([int copies = 1])` with eager positive integer validation.
- Added typed `LabelBuilder.rawBytes(Uint8List)` and `LabelBuilder.rawAscii(String)` with ASCII validation and defensive copying.
- Added `UnsupportedFeaturePolicy` (`throwError`, `ignore`).
- Added structured error hierarchy rooted at `PortakalError`.
- Added canonical `ReceiptColumn` table column definition.
- Added `LabelPreview` Flutter widget in `portakal_flutter` with zero symbol collision against Flutter `Column`.
- Added 9 protocol-native fluent builders with non-destructive `.toBytes()` snapshots and `.reset()`.
- Added pure Dart SVG preview engine (`renderPreview`).

### Changed
- Decoupled `portakal_core` into an independent pure-Dart package with zero Flutter/UI dependencies.
- Standardized all protocol serializers on direct byte stream generation.
- Updated Dart SDK minimum environment constraint to `^3.6.0` and Flutter to `>=3.27.0`.

### Deprecated
- Deprecated `typedef Column = ReceiptColumn` in favor of `ReceiptColumn` (removal in 2.0).
- Deprecated `compileBytes` method on language facades in favor of canonical `.compile()` (removal in 2.0).
- Deprecated legacy String serializers `compileToTSC`, `compileToZPL`, `compileToEPL`, `compileToCPCL`, `compileToDPL`, `compileToIPL`, and `compileToSBPL` (removal in 2.0).
- Deprecated untyped `RawElement({required Object content})` and `label.raw(Object)` in favor of `rawBytes` / `rawAscii` (removal in 2.0).
- Deprecated legacy `encodeTextForPrinter` helper in favor of `getEncoder(PrinterCodePage)` (removal in 2.0).

### Hardware Validation
- Physical hardware validation on `Printer001-328F`: ESC/POS verified subset (PASS), TSC/TSPL2 verified subset (PASS), ZPL II emulation (N/S-DEVICE).
- Byte-level golden SHA-256 validation suite for all 9 protocol compilers.

## 1.0.0-rc.1

- Release candidate for 1.0.0 contract freeze and external pub.dev validation.

## 0.3.0

- Split repository into `portakal_core` (pure Dart protocol engine) and `portakal_flutter` (Flutter widgets and integration).
- Zero Flutter/UI dependencies in `portakal_core`.
- 9 protocol-native builders (TSC, ESC/POS, ZPL, EPL, CPCL, DPL, IPL, SBPL, Star PRNT).
- Universal AST builder, 9 protocol compilers, 9 parsers.
- Character encoding subsystem for CP437, CP858, CP850, CP1252, CP866, CP857.
- Bitmap and dithering engine.
- Printer profiles database and query functions.
- Pure Dart SVG preview generator (`renderPreview`).
