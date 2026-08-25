# Portakal Flutter

Flutter integration package for **Portakal**, the universal thermal and label printer SDK.

- Provides the `LabelPreview` widget to visually render and preview label layouts before sending command streams to hardware.
- Supports the **Preview-Before-Print** workflow: resolve a label once, review the preview widget, and compile that exact same resolved job for printing.
- Re-exports the complete pure-Dart `portakal_core` engine — fluent AST builder, 9 protocol compilers, 9 native protocol builders, 9 parsers, encodings, and dithering.
- Re-exports `portakal_core` with `ReceiptColumn` collision shielding (`hide Column`), ensuring zero namespace conflict with Flutter's built-in `Column` widget.

---

## Installation

```yaml
dependencies:
  portakal_flutter: ^1.1.0
```

---

## Headline Workflow: Preview-Before-Print

The canonical 1.1 workflow guarantees that the exact logical job reviewed in the preview is the job compiled for printing:

```dart
import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

class ShippingLabelScreen extends StatelessWidget {
  const ShippingLabelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Define layout with fluent Universal LabelBuilder
    final builder = label(const LabelConfig(width: 80, height: 60))
      .text('EXPRESS DELIVERY', const TextOptions(x: 20, y: 20, size: 2, bold: true))
      .line(const LineOptions(x1: 20, y1: 50, x2: 600, y2: 50, thickness: 2))
      .barcode('TRACK-998877', const BarcodeOptions(x: 20, y: 70, type: '128', height: 60))
      .qrcode('https://track.example.com/998877', const QRCodeOptions(x: 20, y: 160, cellWidth: 4))
      .box(const BoxOptions(x: 10, y: 10, width: 620, height: 460, thickness: 2));

    // 2. Resolve once into canonical logical print job
    final ResolvedLabel job = builder.resolve();

    return Scaffold(
      appBar: AppBar(title: const Text('Label Preview')),
      body: Center(
        // 3. Render preview from the resolved job
        child: LabelPreview.resolved(
          job: job,
          showMeta: true, // Shows width, height, and DPI bar
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Confirm & Print'),
        icon: const Icon(Icons.print),
        onPressed: () {
          // 4. Compile that SAME resolved job directly to Uint8List bytes
          final tscBytes = tsc.compileResolved(job);
          final zplBytes = zpl.compileResolved(job);

          // Pass bytes to your Bluetooth, USB, or Network transport
        },
      ),
    );
  }
}
```

### Simple Mode

For quick demonstrations or dynamic builders where separate resolution is not required, `LabelPreview(label: builder)` and `tsc.compile(builder)` remain fully supported.

---

## Preview Fidelity & Standards Conformance

| Feature Area | Fidelity Level | Description |
| :--- | :--- | :--- |
| **Geometry & Layout** | **Exact Logical** | Dimensions, coordinates, lines, boxes, clipping, multiline layout, and reverse regions are deterministically mapped to canonical dots. |
| **1D Barcodes** | **Standards-Based Preview** | Real visual patterns for **Code 128 (Set B)**, **Code 39**, **EAN-13**, **EAN-8**, and **UPC-A** with standard quiet zones. Independently validated against decoder reference implementations. |
| **2D QR Codes** | **Standards-Based Preview** | Real visual matrices for **Versions 1–10** in Byte (UTF-8) mode with **ECC L/M/Q/H** and ISO/IEC 18004 4-module quiet zones. |
| **Unsupported Symbologies** | **Honest Placeholders** | `UPCE`, `ITF`, `Codabar`, `PDF417`, and `DataMatrix` render high-contrast diagnostic bounding placeholders rather than unvalidated bar patterns. |
| **Fonts & Text** | **Approximate Visual** | Screen renderers utilize platform fonts matching the target dot height and aspect ratio; physical printer firmware internal bitmap ROM fonts are not emulated pixel-for-pixel. |
| **Hardware Emulation** | **Not Simulated** | Physical thermal print head darkness burn times, mechanical paper feeding tolerances, and cutter hardware state are not simulated. |

---

## Receipt Formatting without Widget Collisions

When formatting receipts, use `ReceiptColumn` to avoid symbol collisions with Flutter's `Column` widget:

```dart
import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

Widget buildReceiptView() {
  return Column(
    children: [
      const Text('Receipt Header'),
      Builder(
        builder: (context) {
          final receiptRow = formatRow(
            [
              const ReceiptColumn(width: 20, align: 'left'),
              const ReceiptColumn(width: 12, align: 'right'),
            ],
            ['Espresso', '\$3.50'],
            32,
          );
          return Text(receiptRow, style: const TextStyle(fontFamily: 'monospace'));
        },
      ),
    ],
  );
}
```

---

## Documentation

- [Core Engine & Compiler Documentation](https://pub.dev/packages/portakal_core)
- [Issue Tracker](https://github.com/hengmengsroin/portakal_flutter/issues)
- [Repository](https://github.com/hengmengsroin/portakal_flutter)
