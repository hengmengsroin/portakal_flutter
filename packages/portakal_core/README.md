# Portakal Core

Universal thermal and label printer SDK — Pure-Dart protocol engine.

Supports **ESC/POS, TSC (TSPL2), ZPL II, EPL2, CPCL, DPL, IPL, SBPL, and Star PRNT**.

- **Zero Flutter / UI dependencies** — runs seamlessly in Dart CLI, backend servers, microservices, Flutter apps, and web workers.
- **Preview-Before-Print Architecture** — resolve once with `builder.resolve()`, generate canonical `PreviewScene` models or SVG strings (`renderPreview`), and compile the exact same resolved job via `compileResolved(job)` across all 9 protocol facades.
- **9 Protocol-Native Builders** with exact command lifecycles, memory slots, and cutter triggers.
- **Universal AST & Fluent Builder** for cross-compiling layouts across printer languages.
- **Byte-Native by Default** — `.compile()` and `.toBytes()` return authoritative `Uint8List` byte streams.
- **Full Character Encoding Engine** supporting CP437, CP850, CP858 (Euro €), CP1252, CP866 (Cyrillic), CP857 (Turkish), and UTF-8.
- **1-Bit Bitmap & Dithering Pipeline** (Floyd-Steinberg, Atkinson, Ordered Bayer, Threshold).
- **Transport Contracts & Resilient Retry Helpers** (`PrinterTransport`, `chunkedWrite`, `writeWithRetry`).
- **9 Diagnostic Parsers & Pure-Dart SVG Preview Generator** (`renderPreview`, `renderPreviewScene`).

---

## Installation

```yaml
dependencies:
  portakal_core: ^1.1.0
```

---

## Quick Start

### 1. Preview-Before-Print Workflow

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  // 1. Build universal label
  final builder = label(const LabelConfig(width: 80, height: 50))
    .text('Invoice Item', const TextOptions(x: 10, y: 10, size: 2, bold: true))
    .barcode('ITEM-9988', const BarcodeOptions(x: 10, y: 60, type: '128', height: 50))
    .qrcode('https://example.com/invoice/9988', const QRCodeOptions(x: 10, y: 130, cellWidth: 3))
    .box(const BoxOptions(x: 5, y: 5, width: 620, height: 380, thickness: 2));

  // 2. Resolve once into canonical logical print job
  final ResolvedLabel job = builder.resolve();

  // 3. Render pure-Dart SVG preview string for web/UI review
  final String svg = renderPreview(job);

  // 4. Compile that SAME resolved job to printer bytes
  final Uint8List zplBytes = zpl.compileResolved(job);
  final Uint8List tscBytes = tsc.compileResolved(job);
}
```

### 2. Protocol-Native Command Generation (TSC Label)

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = TscPrinter()
    ..sizeDots(800, 1200)
    ..cls()
    ..text(
      x: 50,
      y: 50,
      text: 'Order #1042',
      xMultiplication: 2,
      yMultiplication: 2,
    )
    ..barcode(
      x: 50,
      y: 150,
      type: TscBarcodeType.code128,
      height: 80,
      content: 'ORD-1042',
    )
    ..qrCode(x: 50, y: 260, content: 'https://example.com/orders/1042')
    ..print();

  final Uint8List bytes = printer.toBytes();
  // Pass bytes to network socket, serial port, or transport
}
```

---

## Documentation

Comprehensive guides, architecture overviews, and protocol references:
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
