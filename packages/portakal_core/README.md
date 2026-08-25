# Portakal Core

Universal thermal and label printer SDK — Pure-Dart protocol engine.

Supports **ESC/POS, TSC (TSPL2), ZPL II, EPL2, CPCL, DPL, IPL, SBPL, and Star PRNT**.

- **Zero Flutter / UI dependencies** — runs seamlessly in Dart CLI, backend servers, cloud microservices, Flutter apps, and web workers.
- **Preview-Before-Print Architecture** — resolve once with `builder.resolve()`, generate canonical `PreviewScene` models or SVG strings (`renderPreview`), and compile the exact same resolved job via `compileResolved(job)` across all 9 protocol facades.
- **9 Protocol-Native Builders** with exact command lifecycles, memory slots, and cutter triggers.
- **Universal AST & Fluent Builder** for cross-compiling layouts across printer languages.
- **Byte-Native by Default** — `.compile()`, `.compileResolved()`, and `.toBytes()` return authoritative `Uint8List` byte streams.
- **Full Character Encoding Engine** supporting CP437, CP850, CP858 (Euro €), CP1252, CP866 (Cyrillic), CP857 (Turkish), and UTF-8.
- **1-Bit Bitmap & Dithering Pipeline** (Floyd-Steinberg, Atkinson, Ordered Bayer, Threshold).
- **Transport Contracts & Resilient Retry Helpers** (`PrinterTransport`, `chunkedWrite`, `writeWithRetry`).
- **9 Diagnostic Parsers & Pure-Dart SVG Preview Generator** (`renderPreview`, `renderPreviewScene`).

---

## Installation

```bash
dart pub add portakal_core
```

---

## Quick Start

### 1. Universal Preview-Before-Print Workflow (Pure Dart)

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  // 1. Build universal label layout
  final builder = label(const LabelConfig(width: 80, height: 50))
    ..text('Invoice Item', const TextOptions(x: 10, y: 10, size: 2, bold: true))
    ..barcode('ITEM-9988', const BarcodeOptions(x: 10, y: 60, type: '128', height: 50))
    ..qrcode('https://example.com/invoice/9988', const QRCodeOptions(x: 10, y: 130, cellWidth: 3))
    ..box(const BoxOptions(x: 5, y: 5, width: 620, height: 380, thickness: 2));

  // 2. Resolve once into canonical logical print job
  final ResolvedLabel job = builder.resolve();

  // 3. Render pure-Dart SVG preview string for web / backend visual verification
  final String svg = renderPreview(job);

  // 4. Compile that SAME resolved job to printer bytes
  final Uint8List zplBytes = zpl.compileResolved(job);
  final Uint8List tscBytes = tsc.compileResolved(job);
}
```

### 2. Protocol-Native Command Generation (ESC/POS Receipt)

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = EscPosPrinter()
    ..initialize()
    ..align(EscPosAlignment.center)
    ..bold(true)
    ..textSize(width: 2, height: 2)
    ..textLine('Coffee Shop')
    ..bold(false)
    ..textSize(width: 1, height: 1)
    ..align(EscPosAlignment.left)
    ..feedLines(1)
    ..textLine('1x Espresso         \$3.50')
    ..textLine('1x Croissant        \$4.00')
    ..feedLines(1)
    ..bold(true)
    ..textLine('Total:              \$7.50')
    ..bold(false)
    ..feedLines(3)
    ..cut();

  final Uint8List bytes = printer.toBytes();
  // Pass bytes to TCP socket, serial port, or transport
}
```

---

## Byte-Safe Output & Transport Boundary

Portakal output is strictly binary `Uint8List`. Transmit directly to your hardware transport:

```dart
// TCP raw socket example
final socket = await Socket.connect('192.168.1.100', 9100);
socket.add(bytes);
await socket.flush();
await socket.close();
```

> [!WARNING]
> Never decode printer byte streams as UTF-8 strings. Printer streams contain binary bitmap matrices, custom code page bytes, and hardware escape sequences.

---

## Common Error Handling

- **`UnsupportedFeatureError`**: The chosen printer protocol does not support the requested primitive (e.g. geometric boxes on ESC/POS stream printers).
- **`EncodingError` / `UnsupportedCharacterException`**: Text contains characters outside the active code page.
- **`InvalidConfigError`**: Invalid job dimensions or configuration parameters.

---

## Documentation & References

- [Getting Started Guide](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/getting-started.md)
- [Architecture & Concepts](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/concepts.md)
- [Universal LabelBuilder Reference](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/universal-builder.md)
- [Native Protocol Builders](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/native-builders.md)
- [Character Encodings & Code Pages](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/encoding.md)
- [Raw Bytes Passthrough](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/raw-bytes.md)
- [Images & Raster Graphics](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/images-raster.md)
- [Transport & Retries](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/transport.md)
- [Hardware Validation Framework](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/validation.md)
- [Hardware Compatibility Matrix](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/compatibility.md)
- [Migration Guide (pre-1.0 to 1.0)](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/migration/pre-1.0-to-1.0.md)

---

## License

MIT License - see [LICENSE](LICENSE).
