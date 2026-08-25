# Portakal Flutter

Flutter integration package for **Portakal**, the universal thermal and label printer SDK.

- Provides the `LabelPreview` widget to visually render and preview label layouts before sending command streams to hardware.
- Re-exports the complete pure-Dart `portakal_core` engine — fluent AST builder, 9 protocol compilers, 9 native protocol builders, 9 parsers, encodings, and dithering.
- Re-exports `portakal_core` with `ReceiptColumn` collision shielding (`hide Column`), ensuring zero namespace conflict with Flutter's built-in `Column` widget.

---

## Installation

```yaml
dependencies:
  portakal_flutter: ^1.0.0
```

---

## Quick Start (Label Preview Widget)

```dart
import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

class ShippingLabelScreen extends StatelessWidget {
  const ShippingLabelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define layout with fluent Universal LabelBuilder
    final shippingLabel = label(const LabelConfig(width: 80, height: 60))
      .text('EXPRESS DELIVERY', const TextOptions(x: 20, y: 20, size: 2, bold: true))
      .line(const LineOptions(x1: 20, y1: 50, x2: 600, y2: 50, thickness: 2))
      .barcode('TRACK-998877', const BarcodeOptions(x: 20, y: 70, type: '128', height: 60))
      .qrcode('https://track.example.com/998877', const QRCodeOptions(x: 20, y: 160, cellWidth: 4))
      .box(const BoxOptions(x: 10, y: 10, width: 620, height: 460, thickness: 2));

    return Scaffold(
      appBar: AppBar(title: const Text('Label Preview')),
      body: Center(
        // Interactive visual preview widget
        child: LabelPreview(
          label: shippingLabel,
          showMeta: true, // Shows width, height, and DPI bar
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Compile & Print'),
        icon: const Icon(Icons.print),
        onPressed: () {
          // Compile directly to canonical Uint8List bytes
          final tscBytes = tsc.compile(shippingLabel);
          final zplBytes = zpl.compile(shippingLabel);

          // Pass bytes to your Bluetooth, USB, or Network transport
        },
      ),
    );
  }
}
```

---

## Receipt Formatting without Widget Collisions

When formatting receipts, use `ReceiptColumn` to avoid symbol collisions with Flutter's `Column` widget:

```dart
import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

Widget buildReceiptView() {
  // Flutter Column widget:
  return Column(
    children: [
      Text('Receipt Header'),
      // Portakal ReceiptColumn:
      Builder(
        builder: (context) {
          final receiptRow = formatRow(
            [
              ReceiptColumn(width: 20, align: 'left'),
              ReceiptColumn(width: 12, align: 'right'),
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

Full documentation, architecture guides, and protocol references:
- [Getting Started Guide](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/getting-started.md)
- [Universal LabelBuilder](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/universal-builder.md)
- [Native Protocol Builders](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/native-builders.md)
- [Character Encodings](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/encoding.md)
- [Hardware Validation Matrix](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/compatibility.md)
- [Migration Guide (pre-1.0 to 1.0)](https://github.com/hengmengsroin/portakal_flutter/blob/main/docs/migration/pre-1.0-to-1.0.md)

---

## License

MIT License - see [LICENSE](LICENSE).
