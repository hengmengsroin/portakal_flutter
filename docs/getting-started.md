# Getting Started with Portakal

Portakal is a universal thermal and label printer SDK for Dart and Flutter. It generates exact command bytes for 9 printer languages: **ESC/POS, TSC (TSPL2), ZPL II, EPL2, CPCL, DPL, IPL, SBPL, and Star PRNT**.

---

## 1. Choosing Your Package

| Package | Environment | Primary Role |
| :--- | :--- | :--- |
| **`portakal_core`** | Dart CLI, Server, Backend, Cloud Functions, Edge Workers | Pure Dart command generation, 9 native builders, 9 compilers, 9 parsers, character encodings, dithering, and transport contracts. **Zero Flutter dependencies.** |
| **`portakal_flutter`** | Flutter Mobile, Desktop, Web | Flutter integration package. Provides the `LabelPreview` widget to visually preview labels before printing. Re-exports `portakal_core` with Flutter `Column` namespace protection. |

---

## 2. Installation

### Pure Dart Projects (CLI / Backend / Microservices)
```bash
dart pub add portakal_core
```

### Flutter Applications
```bash
flutter pub add portakal_flutter
```

---

## 3. Your First Print Job in ~15 Lines (Universal Hybrid Layout)

With Portakal 1.2 `sequentialLabel`, you author a document-style receipt once, preview it in Flutter, and compile it to any printer protocol without manually computing Y coordinates:

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  // 1. Build document sequentially
  final receipt = sequentialLabel(const LabelConfig(width: 80, height: 80, unit: Unit.mm))
    ..text('PORTAKAL CAFE', const TextOptions(size: 2, bold: true))
    ..divider()
    ..row('Latte', r'$2.50')
    ..row('Cake', r'$3.00')
    ..divider()
    ..row('TOTAL', r'$5.50', bold: true);

  // 2. Resolve once
  final job = receipt.resolve();

  // 3. Compile to any target protocol
  final Uint8List escposBytes = escpos.compileResolved(job);
  final Uint8List tscBytes = tsc.compileResolved(job);
  final Uint8List zplBytes = zpl.compileResolved(job);

  print('Generated ${escposBytes.length} ESC/POS bytes & ${tscBytes.length} TSC bytes.');
}
```

---

## 4. Exact-Canvas Positioning (Labels, Badges, Assets)

When designing complex asset tags or multi-column barcodes where exact coordinates are desired, use `label(config)`:

```dart
final badge = label(const LabelConfig(width: 60, height: 40, unit: Unit.mm))
  ..box(const BoxOptions(x: 10, y: 10, width: 460, height: 300, thickness: 2))
  ..text('VISITOR PASS', const TextOptions(x: 30, y: 30, size: 2, bold: true))
  ..barcode(
    'VIS-001',
    BarcodeOptions.typed(
      x: 30,
      y: 100,
      symbology: BarcodeSymbology.code128,
      height: 60,
      readable: 1,
    ),
  );

final job = badge.resolve();
final Uint8List zplBytes = zpl.compileResolved(job);
```

---

## 5. The Byte-Native Contract & Transport Boundary

> [!IMPORTANT]
> **Portakal generates command bytes — it does not manage printer network connections, Bluetooth pairings, or USB endpoints directly.**
>
> All compiler and native builder methods output `Uint8List`. Sending those bytes to physical hardware is handled by your application's transport layer (TCP Sockets, Bluetooth Low Energy, USB, or Serial ports).

### Sending Bytes over TCP / Raw Port 9100 (Pure Dart)

```dart
import 'dart:io';
import 'dart:typed_data';

Future<void> sendToNetworkPrinter(String ipAddress, Uint8List commandBytes) async {
  final socket = await Socket.connect(ipAddress, 9100, timeout: const Duration(seconds: 5));
  socket.add(commandBytes);
  await socket.flush();
  await socket.close();
}
```

---

## 6. Next Steps

- [Universal LabelBuilder & Layout Guide](universal-builder.md) — Document flow, tables, rows, dividers, and exact coordinate escape hatches.
- [Hybrid Layout Architecture](hybrid-layout-architecture.md) — Technical design, AST lowering, and stream grid allocation.
- [Native Protocol Builders](native-builders.md) — Direct 1:1 hardware control for all 9 supported protocols.
- [Character Encodings](encoding.md) — Code pages, Euro sign (€), Cyrillic, Turkish, and UTF-8.
- [Transport & Resilient Retries](transport.md) — Transport interface, chunked writes, and exponential backoff.
