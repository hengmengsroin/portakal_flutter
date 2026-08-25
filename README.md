# 🍊 Portakal

Universal thermal printer language SDK for Dart & Flutter — **TSC, ZPL, EPL, ESC/POS, CPCL, DPL, IPL, SBPL, Star PRNT**.

Text, images, printer-native commands, bit-packed graphics, encodings, and Flutter preview widgets.

---

## Packages in this Repository

| Package | Role | Dependencies | Description |
| :--- | :--- | :--- | :--- |
| [`portakal_core`](packages/portakal_core/) | **Pure Dart** | Zero runtime dependencies | AST builder, 9 protocol compilers, 9 byte-native builders, 9 parsers, encodings, dithering, SVG preview, transport contracts. Runs on Dart CLI, backend servers, microservices, Flutter, and web. |
| [`portakal_flutter`](packages/portakal_flutter/) | **Flutter Integration** | Flutter SDK, `portakal_core` | Flutter widgets (`LabelPreview`), CustomPainter rendering, and re-exports of `portakal_core`. |

---

## Features

- 🖨️ **9 Printer Languages** — TSC (TSPL2), ZPL (ZPL II), EPL (EPL2), ESC/POS, CPCL, DPL, IPL, SBPL, Star PRNT.
- ⚡ **9 Protocol-Native Builders** with exact command life-cycles, bit-packed graphics, control characters, and boundary validation.
- 🔄 **Cross-compilation** — convert between supported printer languages via universal AST.
- 🏷️ **Fluent Label Builder** — design labels with a clean, chainable API.
- 📝 **HTML-like Markup** — `<label><text>Hello</text></label>` DSL.
- 🔍 **Parsers** — parse raw printer commands back into structured AST data.
- 👁️ **SVG Preview** — render labels as SVG strings for visual inspection (Pure Dart).
- 📱 **Flutter Preview Widget** — preview labels in Flutter apps with `LabelPreview`.
- 🌐 **Encoding & Code Pages** — CP437, CP850, CP858 (Euro €), CP1252, CP866 (Cyrillic), CP857 (Turkish), UTF-8.
- 🖼️ **Image Processing** — RGBA to monochrome with 4 dithering algorithms (Floyd-Steinberg, Atkinson, Ordered, Threshold).
- 📇 **Printer Profiles Database** — Epson, Zebra, TSC, Star, Bixolon, Citizen, SATO, Honeywell.
- 🔌 **Transport Contracts & Retries** — `PrinterTransport`, chunked writes, and exponential backoff retry.

---

## Usage

### Pure Dart (CLI / Server / Backend)

```yaml
dependencies:
  portakal_core: ^0.3.0
```

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
}
```

### Flutter Applications

```yaml
dependencies:
  portakal_flutter: ^0.3.0
```

```dart
import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

class MyPreviewScreen extends StatelessWidget {
  const MyPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myLabel = label(const LabelConfig(width: 80, height: 60))
      .text('Shipping Label', const TextOptions(x: 20, y: 20, size: 2, bold: true))
      .box(const BoxOptions(x: 10, y: 10, width: 620, height: 460, thickness: 2));

    return Scaffold(
      appBar: AppBar(title: const Text('Label Preview')),
      body: Center(child: LabelPreview(label: myLabel)),
    );
  }
}
```

---

## License

MIT License - see [LICENSE](LICENSE).
