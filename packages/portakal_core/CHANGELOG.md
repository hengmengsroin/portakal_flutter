## 1.0.0

- Frozen Portakal 1.0 pure-Dart API.
- Standardized canonical byte-native `.compile()` API returning `Uint8List` across all 9 language facades.
- Added `LabelBuilder.print([int copies = 1])` with eager positive-integer validation.
- Added `LabelBuilder.rawBytes(Uint8List)` and `LabelBuilder.rawAscii(String)`.
- Added `UnsupportedFeaturePolicy` (`throwError`, `ignore`).
- Added `EncodingError` base class (`UnsupportedCharacterException` extends `EncodingError` extends `PortakalError`).
- Added canonical `ReceiptColumn` and deprecated `typedef Column = ReceiptColumn`.
- Deprecated legacy String serializers, `compileBytes`, and legacy encoding helpers.

## 0.3.0

- Initial standalone release of `portakal_core` as a pure Dart package extracted from `portakal_flutter`.
- Zero Flutter/UI dependencies.
- 9 protocol-native builders (TSC, ESC/POS, ZPL, EPL, CPCL, DPL, IPL, SBPL, Star PRNT).
- Universal AST builder, 9 protocol compilers, 9 parsers.
- Character encoding subsystem for CP437, CP858, CP850, CP1252, CP866, CP857.
- Bitmap and dithering engine.
- Printer profiles database and query functions.
- Pure Dart SVG preview generator (`renderPreview`).
