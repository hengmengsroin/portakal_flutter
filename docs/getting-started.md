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

Add `portakal_core` to your `pubspec.yaml`:

```yaml
dependencies:
  portakal_core: ^1.0.0
```

Or via terminal:

```bash
dart pub add portakal_core
```

### Flutter Applications

Add `portakal_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  portakal_flutter: ^1.0.0
```

Or via terminal:

```bash
flutter pub add portakal_flutter
```

---

## 3. Your First Print Job in 60 Seconds

### A. Receipt Printing (ESC/POS)

Generate receipt command bytes using the native `EscPosPrinter`:

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
  print('Generated ${bytes.length} ESC/POS bytes ready for transport.');
}
```

### B. Shipping Label (TSC / TSPL2)

Generate label command bytes using the native `TscPrinter`:

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
      text: 'EXPRESS SHIPPING',
      xMultiplication: 2,
      yMultiplication: 2,
    )
    ..barcode(
      x: 50,
      y: 120,
      type: TscBarcodeType.code128,
      height: 80,
      content: 'TRACK-998877',
    )
    ..qrCode(x: 50, y: 240, content: 'https://track.example.com/998877')
    ..print()
    ..toBytes();

  final Uint8List bytes = printer.toBytes();
  print('Generated ${bytes.length} TSC label bytes ready for transport.');
}
```

---

## 4. The Byte-Native Contract & Transport Boundary

> [!IMPORTANT]
> **Portakal generates command bytes — it does not manage printer network connections, Bluetooth pairings, or USB endpoints directly.**
>
> All compiler and native builder methods output `Uint8List`. Sending those bytes to physical hardware is handled by your application's transport layer (TCP Sockets, Bluetooth Low Energy, USB, or Serial ports).

### Sending Bytes over TCP / Raw Port 9100 (Pure Dart)

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

Future<void> sendToNetworkPrinter(String ipAddress, Uint8List commandBytes) async {
  final socket = await Socket.connect(ipAddress, 9100, timeout: const Duration(seconds: 5));
  socket.add(commandBytes);
  await socket.flush();
  await socket.close();
}
```

---

## 5. Next Steps

- [Core Concepts](concepts.md) — Understand the architecture, byte-native rule, and error handling.
- [Universal LabelBuilder](universal-builder.md) — Design cross-protocol layouts with the fluent AST builder.
- [Native Protocol Builders](native-builders.md) — Direct 1:1 hardware control for all 9 supported protocols.
- [Character Encodings](encoding.md) — Code pages, Euro sign (€), Cyrillic, Turkish, and UTF-8.
- [Transport & Resilient Retries](transport.md) — Transport interface, chunked writes, and exponential backoff.
