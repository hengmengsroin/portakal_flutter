# 🍊 Portakal

Universal thermal and label printer SDK for Dart & Flutter.

Generate exact, byte-native command streams for 9 printer languages: **ESC/POS, TSC (TSPL2), ZPL II, EPL2, CPCL, DPL, IPL, SBPL, and Star PRNT**.

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
- 🔒 **Authoritative Byte-Native Output** — Compilers and builders output immutable `Uint8List` byte streams.
- 👁️ **Preview-Before-Print Workflow** — Single-resolve pattern (`LabelPreview.resolved` in Flutter, `renderPreview` in pure Dart SVG).
- 🌐 **Full Character Encoding Engine** — CP437, CP850, CP858 (Euro €), CP1252, CP866 (Cyrillic), CP857 (Turkish), UTF-8.
- 🖼️ **Image Processing & Dithering** — 1-bit monochrome conversion with 4 dithering modes (Floyd-Steinberg, Atkinson, Ordered, Threshold).
- 🔍 **9 Diagnostic Parsers** — Parse and inspect command streams for preview reconstruction and syntax validation.
- 🔌 **Decoupled Transport Boundary** — Pure Dart `PrinterTransport` contract, chunked writes, and exponential backoff retry.
- 🎨 **19 Practical Real-World Examples** — Complete runnable templates across Retail, Pharmacy, Restaurant, Warehouse, Logistics, Tickets, Asset Management, and Advanced.

---

## Installation

### For Flutter Applications

```bash
flutter pub add portakal_flutter
```

`portakal_flutter` automatically re-exports `portakal_core` with `ReceiptColumn` collision shielding, so you only need one dependency in your Flutter project.

### For Pure Dart Projects (CLI / Backend / Cloud Workers)

```bash
dart pub add portakal_core
```

---

## 30-Second Quick Start

Portakal's primary purpose is to **generate exact printer command bytes (`Uint8List`)**.

```dart
import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  // 1. Build a label layout
  final builder = label(const LabelConfig(width: 40, height: 30))
    ..text('Product A1', const TextOptions(x: 20, y: 20, size: 2, bold: true))
    ..qrcode('https://example.com/a1', const QRCodeOptions(x: 20, y: 70, cellWidth: 3));

  // 2. Resolve into an immutable print job
  final ResolvedLabel job = builder.resolve();

  // 3. Compile the exact same job to authoritative printer bytes
  final Uint8List bytes = tsc.compileResolved(job);

  // 4. Transmit bytes to your hardware transport (Bluetooth, USB, Network)
}
```

---

## Workflows: Simple vs Preview-Before-Print

Portakal supports two distinct compilation workflows:

### 1. Simple Workflow (`compile`)
*Best for: Automated background batch printing, headless servers, microservices, and non-interactive print queues.*

```dart
final builder = label(const LabelConfig(width: 80, height: 50))
  ..text('BATCH ITEM #1042', const TextOptions(x: 20, y: 20));

// Compiles directly to Uint8List
final Uint8List bytes = tsc.compile(builder);
```

### 2. Preview-Before-Print Workflow (`resolve` + `compileResolved`) — *Recommended for Flutter*
*Best for: Interactive applications where the user inspects a visual preview before confirming physical printing.*

This workflow guarantees that the exact `ResolvedLabel` viewed on screen is the identical object compiled for the printer head, preventing mutation race conditions:

```dart
import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

class LabelPreviewScreen extends StatelessWidget {
  final LabelBuilder builder;
  const LabelPreviewScreen({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    // 1. Resolve once into an immutable job
    final ResolvedLabel job = builder.resolve();

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Label')),
      body: Center(
        // 2. Render visual preview in Flutter
        child: LabelPreview.resolved(job: job, showMeta: true),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.print),
        onPressed: () {
          // 3. Compile that SAME resolved job to printer bytes
          final Uint8List bytes = tsc.compileResolved(job);
          // Pass bytes to your Bluetooth, USB, or TCP socket transport
        },
      ),
    );
  }
}
```

---

## Architecture & Decoupling

```
LabelBuilder (Universal AST)
     ↓
ResolvedLabel (Immutable Logical Job)
    ├── PreviewScene (Geometry & Visual Elements)
    │      ├── LabelPreview (Flutter Widget)
    │      └── renderPreview (Pure Dart SVG String)
    │
    └── Protocol Compiler (TSC / ZPL / ESC/POS / ...)
            ↓
         Uint8List (Authoritative Binary Command Bytes)
            ↓
      Your Transport (Application-Owned: Bluetooth / USB / TCP Socket)
```

> [!IMPORTANT]
> **Transport is application-owned.** Portakal handles layout composition, protocol encoding, and byte stream generation. Transmitting those bytes over Bluetooth, USB, or Network TCP sockets is handled by your application or custom transport.

---

## The Byte-Safe Contract & Transport Boundary

All Portakal compilers (`facade.compile()`, `facade.compileResolved()`) and protocol-native builders (`printer.toBytes()`) return **`Uint8List`**.

- **DO**: Pass the raw `Uint8List` bytes directly to your communication transport:
  ```dart
  transport.write(bytes);
  ```
- **DO NOT**: Convert printer byte streams to or from strings:
  ```dart
  // ❌ DANGEROUS: Corrupts binary bitmap matrices, code page bytes, and ESC controls
  final string = utf8.decode(bytes);
  socket.write(string);
  ```

### Conceptual Transport Examples

Portakal is transport-neutral. Connect `Uint8List` output to any hardware channel:

#### TCP / Network Socket (Port 9100 Raw JetDirect)
```dart
import 'dart:io';
import 'dart:typed_data';

Future<void> sendToNetworkPrinter(String ip, Uint8List bytes) async {
  final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 5));
  socket.add(bytes);
  await socket.flush();
  await socket.close();
}
```

#### Bluetooth Low Energy (Conceptual)
```dart
Future<void> sendToBlePrinter(dynamic writeCharacteristic, Uint8List bytes) async {
  // Transmit raw bytes to the printer's write characteristic
  await writeCharacteristic.write(bytes, withoutResponse: false);
}
```

#### USB / Serial (Conceptual)
```dart
Future<void> sendToUsbPrinter(dynamic usbEndpoint, Uint8List bytes) async {
  await usbEndpoint.write(bytes);
}
```

---

## 🎨 Practical Real-World Example Gallery

The [`example/`](example/) application features **19 production-style, copyable printing templates** across real-world domains with live visual preview, 9-protocol compilation, and raw byte inspection:

> *Note: These are practical, real-world examples. Businesses should adapt fields, layout geometry, barcode symbologies, and regulatory disclosures to their specific domain and jurisdiction.*

| Category | Example | Recommended Media | Demonstrates | Tested Protocols | Source |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Getting Started** | **Simple Text & Frame** | 60×40mm | Text positioning, bounding frame, divider line, QR code | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`simple_text_example.dart`](example/lib/src/examples/general/simple_text_example.dart) |
| **Retail** | 🌟 **Retail Product Price Label** | 40×30mm | Store branding, bold price emphasis, SKU, EAN-13 barcode | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`retail_price_label.dart`](example/lib/src/examples/retail/retail_price_label.dart) |
| **Retail** | **Promotion & Discount Tag** | 50×40mm | Reverse header, strike-through line composition, discount badge, Code128 | TSC, ZPL, EPL, CPCL | [`retail_promotion_label.dart`](example/lib/src/examples/retail/retail_promotion_label.dart) |
| **Pharmacy** | 🌟 **Medicine Price & Batch Label** | 50×30mm | Amoxicillin dosage, batch ID, expiry date, price, Code128 | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`medicine_price_label.dart`](example/lib/src/examples/pharmacy/medicine_price_label.dart) |
| **Pharmacy** | **Prescription Dosage & Usage Label** | 70×50mm | Patient name, dosage frequency, treatment duration, Rx QR code | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`medicine_usage_label.dart`](example/lib/src/examples/pharmacy/medicine_usage_label.dart) |
| **Pharmacy** | **Warehouse Expiry Alert Label** | 60×40mm | Reverse alert banner, large expiration date, stock quantity, Code128 | TSC, ZPL, EPL, CPCL | [`expiry_stock_label.dart`](example/lib/src/examples/pharmacy/expiry_stock_label.dart) |
| **Restaurant** | 🌟 **Kitchen Order Ticket (KOT)** | 80mm Cont. | Large table ID, order timestamp, item modifiers, allergy alert box | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`kitchen_ticket.dart`](example/lib/src/examples/restaurant/kitchen_ticket.dart) |
| **Restaurant** | **Customer Dining Receipt** | 80mm Cont. | Column alignment, itemized totals, tax calculation, e-invoice QR | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`customer_receipt.dart`](example/lib/src/examples/restaurant/customer_receipt.dart) |
| **Warehouse** | 🌟 **Warehouse Location Bin Label** | 100×50mm | Large bin ID (B12), aisle/rack hierarchy, Code128 rack barcode | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`location_bin_label.dart`](example/lib/src/examples/warehouse/location_bin_label.dart) |
| **Warehouse** | **Inventory Item & Lot Tag** | 80×50mm | SKU, lot identifier, package quantity, Code128, WMS asset QR | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`inventory_item_label.dart`](example/lib/src/examples/warehouse/inventory_item_label.dart) |
| **Logistics** | 🌟 **Cross-Border Shipping Label** | 100×150mm | Sender/consignee boxes, hub routing block, Code128, tracking QR | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`shipping_label.dart`](example/lib/src/examples/logistics/shipping_label.dart) |
| **Logistics** | **Compact Parcel Routing Tag** | 60×40mm | Large destination hub code (DEST: KPC), route ID, parcel weight | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`small_parcel_label.dart`](example/lib/src/examples/logistics/small_parcel_label.dart) |
| **Tickets & Badges** | **Conference Admission Ticket** | 80×50mm | Event branding, date/time, hall/seat, ticket number, gate QR | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`event_ticket.dart`](example/lib/src/examples/tickets/event_ticket.dart) |
| **Tickets & Badges** | **Service Queue Number Ticket** | 60mm Cont. | Oversized queue number (A-042), wait time, position, timestamp | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`queue_ticket.dart`](example/lib/src/examples/tickets/queue_ticket.dart) |
| **Tickets & Badges** | **Visitor Attendance Badge** | 80×50mm | High-contrast reverse header, visitor/host details, validity date, QR | TSC, ZPL, EPL, CPCL | [`visitor_badge.dart`](example/lib/src/examples/tickets/visitor_badge.dart) |
| **Asset Management** | **IT Hardware Asset Tag** | 50×25mm | Reverse property banner, asset serial ID, department, asset QR | TSC, ZPL, EPL, CPCL | [`asset_tag.dart`](example/lib/src/examples/asset/asset_tag.dart) |
| **General / Advanced** | 🌟 **Commercial Invoice** | 80×100mm | Corporate header, multi-row line items, calculation totals, barcode, QR | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL | [`invoice_example.dart`](example/lib/src/examples/general/invoice_example.dart) |
| **General / Advanced** | **Monochrome Logo & Branding** | 60×40mm | Embedded 64×64 1-bit monochrome raster bitmap, barcode, QR | TSC, ZPL, EPL, CPCL, ESC/POS, Star PRNT | [`bitmap_logo_example.dart`](example/lib/src/examples/general/bitmap_logo_example.dart) |
| **General / Advanced** | **Multilingual & International Text** | 70×50mm | English, French accents, Khmer, Japanese scripts with encoding guidance | ZPL (UTF-8) | [`unicode_text_example.dart`](example/lib/src/examples/general/unicode_text_example.dart) |

*(🌟 denotes Flagship Examples with deep structural verification).*

---

## Continuous Receipt Feeds vs Label Media

- **Fixed Label Media** (e.g. 40×30mm, 100×150mm): Defined with explicit width and height boundaries. The printer uses gap or black-mark sensors to index each label.
- **Continuous Receipt Feeds** (e.g. 80mm thermal receipt rolls): Have fixed roll width (e.g. 58mm or 80mm) and dynamic feed length determined by content, followed by a cut or tear command.
- In the example gallery, continuous templates (`kitchen_ticket.dart`, `customer_receipt.dart`, `queue_ticket.dart`) specify a representative preview height (e.g. 75mm–80mm / 600–640 dots) to provide deterministic bounds in visual previews.

> [!NOTE]
> Physical receipt length is normally determined by content and paper feed behavior; example preview heights are illustrative.

---

## Preview Unicode Support vs Printer Hardware Encoding

- **Flutter Visual Preview**: Renders any Unicode script (including Khmer, Thai, Japanese, Arabic, and European accents) using the device operating system's typography engine.
- **Physical Thermal Printers**: Process text according to their firmware capabilities:
  - Standard label/receipt printers use 8-bit code pages (CP437, CP850, CP1252) and only support Latin-1 or specific regional subsets.
  - ZPL printers in UTF-8 mode (`^CI28`) can process Unicode text if appropriate font ROM cards (e.g. Swiss 721 / Andale) are installed.
  - For complex Asian scripts on legacy printers, convert text into a 1-bit monochrome raster bitmap via `imageToMonochrome()` before transmission.
- If a compiler cannot encode a character in the active code page, Portakal throws an **`EncodingError`** (or `UnsupportedCharacterException`).

---

## Protocol Choice Guide

| Protocol | Typical Target Hardware | Primary Use Case |
| :--- | :--- | :--- |
| **TSC (TSPL2)** | Desktop / Industrial label printers (TSC, Xprinter, Gprinter, Godex) | Product labels, barcode stickers, shipping tags |
| **ZPL II** | Industrial label printers (Zebra, Honeywell, Printronix, SATO emulation) | Enterprise logistics, warehouse bin tags, cross-border shipping |
| **ESC/POS** | Point-of-sale receipt printers (Epson, Bixolon, Star, generic 58/80mm POS) | Restaurant dining receipts, retail POS slips, kitchen tickets |
| **EPL2** | Desktop label printers (Legacy Eltron, Zebra 2844 / GK420d) | Small courier parcels, retail shelf price tags |
| **CPCL** | Mobile portable printers (Zebra QLn/ZQ series, Bixolon mobile) | Mobile ticketing, meter reading, delivery route receipts |
| **DPL** | Datamax / O'Neil thermal printers | Industrial asset tracking, compliance labeling |
| **IPL** | Intermec / Honeywell industrial printers | High-throughput manufacturing and warehouse workflows |
| **SBPL** | SATO industrial barcode printers | High-resolution medical, electronics, and parcel labels |
| **Star PRNT**| Star Micronics line thermal printers (TSP100/650/700 series) | Hospitality POS receipts, cloud kitchen order tickets |

> [!TIP]
> **Tested Protocols vs Device Compatibility**: In the example gallery, `testedProtocols` indicates the protocols against which that specific example's compilation pipeline has been tested without error under `UnsupportedFeaturePolicy.throwError`. Always check your physical printer's programming manual for supported command emulations.

---

## Common Error Handling Guide

```dart
try {
  final bytes = tsc.compileResolved(job);
  // Send bytes to transport
} on UnsupportedFeatureError catch (e) {
  // Occurs when the selected printer language does not support the requested primitive
  // (e.g., geometric boxes or lines on receipt-stream ESC/POS printers).
  print('Unsupported primitive: ${e.message}');
} on EncodingError catch (e) {
  // Occurs when text contains characters that cannot be represented in the active code page.
  print('Character encoding error: ${e.message}');
} on InvalidConfigError catch (e) {
  // Occurs when label dimensions or parameters are invalid (e.g., width <= 0).
  print('Invalid configuration: ${e.message}');
}
```

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
