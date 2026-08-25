# Portakal Core

Universal thermal and label printer SDK — Pure-Dart protocol engine.

Supports **ESC/POS, TSC (TSPL2), ZPL II, EPL2, CPCL, DPL, IPL, SBPL, and Star PRNT**.

- **Zero Flutter / UI dependencies** — runs seamlessly in Dart CLI, backend servers, microservices, Flutter apps, and web workers.
- **9 Protocol-Native Builders** with exact command lifecycles, memory slots, and cutter triggers.
- **Universal AST & Fluent Builder** for cross-compiling layouts across printer languages.
- **Byte-Native by Default** — `.compile()` and `.toBytes()` return authoritative `Uint8List` byte streams.
- **Full Character Encoding Engine** supporting CP437, CP850, CP858 (Euro €), CP1252, CP866 (Cyrillic), CP857 (Turkish), and UTF-8.
- **1-Bit Bitmap & Dithering Pipeline** (Floyd-Steinberg, Atkinson, Ordered Bayer, Threshold).
- **Transport Contracts & Resilient Retry Helpers** (`PrinterTransport`, `chunkedWrite`, `writeWithRetry`).
- **9 Diagnostic Parsers & Pure-Dart SVG Preview Generator** (`renderPreview`).

---

## Installation

```yaml
dependencies:
  portakal_core: ^1.0.0
```

---

## Quick Start

### 1. Protocol-Native Command Generation (TSC Label)

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = TscPrinter()
    ..sizeDots(width: 800, height: 1200)
    ..cls()
    ..text(x: 50, y: 50, content: 'Order #1042', size: 2, bold: true)
    ..barcode(x: 50, y: 150, type: TscBarCode.code128, height: 80, content: 'ORD-1042')
    ..qrcode(x: 50, y: 260, content: 'https://example.com/orders/1042')
    ..print();

  final Uint8List bytes = printer.toBytes();
  // Pass bytes to network socket, serial port, or transport
}
```

### 2. Universal AST Label Builder

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final myLabel = label(const LabelConfig(width: 80, height: 50))
    .text('Invoice Item', const TextOptions(x: 10, y: 10, size: 2, bold: true))
    .barcode('ITEM-9988', const BarcodeOptions(x: 10, y: 60, type: '128', height: 50))
    .box(const BoxOptions(x: 5, y: 5, width: 620, height: 380, thickness: 2));

  // Compile directly to canonical Uint8List byte streams
  final Uint8List zplBytes = zpl.compile(myLabel);
  final Uint8List escPosBytes = escpos.compile(myLabel);
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
