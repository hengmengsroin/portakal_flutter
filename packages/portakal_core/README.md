# Portakal Core

Universal thermal printer SDK — Pure-Dart protocol engine.

Supports **TSC, ZPL, EPL, ESC/POS, CPCL, DPL, IPL, SBPL, and Star PRNT**.

- **Zero Flutter / UI dependencies** — runs seamlessly in Dart CLI, backend servers, microservices, Flutter, and web workers.
- **9 Protocol-Native Builders** with exact command life-cycles, bit-packed graphics, control characters, and boundary validation.
- **Universal AST & Fluent Builder** for cross-compiling markup and layouts across printer languages.
- **Full Character Encoding Engine** supporting CP437, CP850, CP858 (Euro sign), CP1252, CP866 (Cyrillic), CP857 (Turkish), and UTF-8.
- **1-Bit Bitmap & Dithering Pipeline** (Floyd-Steinberg, Atkinson, Ordered Bayer, Threshold).
- **Printer Profiles & Capabilities Database**.
- **Transport Contracts & Resilient Retry Helpers**.
- **Pure-Dart SVG Preview Generator**.

## Installation

```yaml
dependencies:
  portakal_core: ^0.3.0
```

## Quick Start

### Protocol-Native Command Generation

```dart
import 'package:portakal_core/portakal_core.dart';

void main() {
  final bytes = TscPrinter()
    ..sizeDots(width: 800, height: 1200)
    ..cls()
    ..text(x: 50, y: 50, content: 'Order #1042', size: 2, bold: true)
    ..barcode(x: 50, y: 150, type: TscBarCode.code128, height: 80, content: 'ORD-1042')
    ..print()
    ..toBytes();

  // Send bytes to network socket, serial port, or transport
}
```

### Universal AST Label Builder

```dart
import 'package:portakal_core/portakal_core.dart';

void main() {
  final myLabel = label(const LabelConfig(width: 80, height: 50))
    .text('Invoice Item', const TextOptions(x: 10, y: 10))
    .box(const BoxOptions(x: 5, y: 5, width: 620, height: 380, thickness: 2))
    .resolve();

  final zplBytes = compileToZPL(myLabel);
  final escPosBytes = compileToESCPOS(myLabel);
}
```
