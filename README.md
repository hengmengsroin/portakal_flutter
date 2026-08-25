# 🍊 Portakal

Universal thermal and label printer SDK for Dart & Flutter.

Generates exact command bytes for 9 printer languages: **ESC/POS, TSC (TSPL2), ZPL II, EPL2, CPCL, DPL, IPL, SBPL, and Star PRNT**.

---

## Packages

| Package | Role | Dependencies | Description |
| :--- | :--- | :--- | :--- |
| [`portakal_core`](packages/portakal_core/) | **Pure Dart Engine** | Zero runtime dependencies | Universal AST builder, 9 protocol compilers, 9 native builders, 9 parsers, character encodings, dithering, SVG preview, and transport contracts. Runs on Dart CLI, backend servers, microservices, Flutter, and web. |
| [`portakal_flutter`](packages/portakal_flutter/) | **Flutter Integration** | Flutter SDK, `portakal_core` | Flutter `LabelPreview` widget and re-export of `portakal_core` (with `ReceiptColumn` collision shielding). |

---

## Features

- 🖨️ **9 Printer Protocols** — ESC/POS, TSC (TSPL2), ZPL II, EPL2, CPCL, DPL, IPL, SBPL, and Star PRNT.
- ⚡ **9 Protocol-Native Builders** — 1:1 hardware control with exact command lifecycles, memory slots, and cutter triggers.
- 🏷️ **Universal Label Builder** — Design cross-protocol labels once; compile to any supported language.
- 🔒 **Byte-Native by Default** — Compilers and builders output authoritative `Uint8List` byte streams.
- 🌐 **Character Encodings** — CP437, CP850, CP858 (Euro €), CP1252, CP866 (Cyrillic), CP857 (Turkish), UTF-8.
- 🖼️ **Image Processing & Dithering** — 1-bit monochrome conversion with 4 dithering modes (Floyd-Steinberg, Atkinson, Ordered, Threshold).
- 🔍 **9 Diagnostic Parsers** — Parse and inspect command streams for preview reconstruction and syntax validation.
- 📱 **Flutter & SVG Previews** — Visual preview before printing via pure Dart SVG (`renderPreview`) and Flutter widget (`LabelPreview`).
- 🔌 **Transport Decoupling** — Pure Dart `PrinterTransport` interface, chunked writes, and exponential backoff retry.
- 🔬 **Deterministic Hardware Bench** — 3-level validation framework with automated golden SHA-256 test harness.

---

## 30-Second Quick Start

### 1. Protocol-Native Builder (ESC/POS Receipt)

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = EscPosPrinter()
    ..initialize()
    ..text('Coffee Shop', align: 'center', bold: true, size: 2)
    ..feedLines(1)
    ..text('1x Espresso         \$3.50')
    ..text('1x Croissant        \$4.00')
    ..feedLines(1)
    ..text('Total:              \$7.50', bold: true)
    ..feedLines(3)
    ..cut();

  final Uint8List bytes = printer.toBytes();
  // Pass bytes to your Bluetooth, USB, or Network socket
}
```

### 2. Universal Label Builder (Cross-Protocol)

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final myLabel = label(const LabelConfig(width: 80, height: 50))
    .text('SHIPPING LABEL', const TextOptions(x: 20, y: 20, size: 2, bold: true))
    .barcode('TRACK-123456', const BarcodeOptions(x: 20, y: 70, type: '128', height: 60))
    .qrcode('https://example.com', const QRCodeOptions(x: 20, y: 150, cellWidth: 4))
    .box(const BoxOptions(x: 10, y: 10, width: 620, height: 380, thickness: 2));

  // Compile directly to canonical Uint8List byte streams
  final Uint8List tscBytes = tsc.compile(myLabel);
  final Uint8List zplBytes = zpl.compile(myLabel);
  final Uint8List eplBytes = epl.compile(myLabel);
}
```

### 3. Flutter Preview-Before-Print (`portakal_flutter`)

```dart
import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

class PreviewScreen extends StatelessWidget {
  final LabelBuilder builder;
  const PreviewScreen({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    // 1. Resolve once
    final ResolvedLabel job = builder.resolve();

    return Scaffold(
      appBar: AppBar(title: const Text('Label Preview')),
      body: Center(
        // 2. Preview the resolved job
        child: LabelPreview.resolved(job: job),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.print),
        onPressed: () {
          // 3. Compile the exact same job for printing
          final tscBytes = tsc.compileResolved(job);
        },
      ),
    );
  }
}
```

---

## The Byte-Native Contract & Transport Boundary

> [!IMPORTANT]
> **Portakal generates command bytes — physical I/O is decoupled.**
>
> All compilers (`facade.compile()`) and native builders (`printer.toBytes()`) produce `Uint8List` byte streams. Transmitting those bytes over Bluetooth Low Energy, USB, Serial, or TCP Network Sockets (Port 9100) is managed by your application or transport layer.
>
> **Never decode printer byte streams as UTF-8 Strings.** Printer streams contain binary bitmap matrices, non-ASCII code page bytes, and hardware control characters.

---

## Physical Hardware Validation Status

Portakal uses a 3-level hardware verification framework (Level 1: Byte Verified, Level 2: Device Command Acceptance, Level 3: Physical Output / Optical Scan Verified).

| Printer Model | Connection | Protocol | Verified Scope | Status |
| :--- | :--- | :--- | :--- | :---: |
| **`Printer001-328F`** | BLE | **ESC/POS** | Text, CP437, Scaling, Code128, QR, 64×64 Raster, Partial Cut, Reset | **PASS** |
| **`Printer001-328F`** | BLE | **TSC (TSPL2)** | Text, CP437/850/1252, Scaling, Code128, QR, Primitives, BITMAP, Copies | **PASS** |
| **`Printer001-328F`** | BLE | **ZPL II** | D00 Capability Probe (Device firmware lacks ZPL emulation) | **N/S-DEVICE** |

*See full details in the [Compatibility Matrix](docs/compatibility.md).*

---

## Documentation

- [Getting Started](docs/getting-started.md) — Installation, package choice, and 60-second quick start.
- [Architecture & Concepts](docs/concepts.md) — Dual builder layers, byte-native contract, and error hierarchy.
- [Universal LabelBuilder](docs/universal-builder.md) — Cross-compilation, visual elements, and copies precedence.
- [Native Protocol Builders](docs/native-builders.md) — Direct 1:1 hardware control for all 9 languages.
- [Character Encodings](docs/encoding.md) — Code pages, Euro symbol (€), Cyrillic, Turkish, and UTF-8.
- [Raw Bytes Passthrough](docs/raw-bytes.md) — Safe binary and ASCII escape sequence injection.
- [Images & Raster](docs/images-raster.md) — 1-bit monochrome bitmaps, dithering algorithms, and protocol framing.
- [Transport & Retries](docs/transport.md) — `PrinterTransport` interface, chunked writes, and retry backoff.
- [Hardware Validation](docs/validation.md) — 3-level verification methodology and offline CLI harness.
- [Compatibility Matrix](docs/compatibility.md) — Tested physical devices, capability records, and evidence.
- [Protocol Guides](docs/protocols/):
  - [ESC/POS](docs/protocols/escpos.md)
  - [TSC (TSPL2)](docs/protocols/tsc.md)
  - [ZPL II](docs/protocols/zpl.md)
  - [EPL2](docs/protocols/epl.md)
  - [CPCL](docs/protocols/cpcl.md)
  - [DPL](docs/protocols/dpl.md)
  - [IPL](docs/protocols/ipl.md)
  - [SBPL](docs/protocols/sbpl.md)
  - [Star PRNT](docs/protocols/star.md)
- [Migration Guide](docs/migration/pre-1.0-to-1.0.md) — Upgrading from pre-1.0 to Portakal 1.0.

---

## License

MIT License - see [LICENSE](LICENSE).
