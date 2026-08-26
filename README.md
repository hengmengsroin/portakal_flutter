# 🍊 Portakal

Universal thermal and label printer SDK for Dart & Flutter.

Generate exact, byte-native command streams for 9 printer languages: **ESC/POS, TSC (TSPL2), ZPL II, EPL2, CPCL, DPL, IPL, SBPL, and Star PRNT**.

---

## Choosing Your Package

| If you are building... | Install | Dependencies | What it provides |
| :--- | :--- | :--- | :--- |
| **Flutter Application** (Mobile, Desktop, Web) | [`portakal_flutter`](packages/portakal_flutter/) | Flutter SDK, `portakal_core` | Live `LabelPreview` widget, visual DPI scaling, and re-export of `portakal_core` with `ReceiptColumn` collision shielding. |
| **Pure Dart / Backend / CLI / Microservice** | [`portakal_core`](packages/portakal_core/) | **Zero dependencies** | Universal AST builder, 9 protocol compilers, 9 native builders, 9 parsers, encodings, dithering, SVG preview (`renderPreview`), and transport contracts. |

### Installation Commands

```bash
# For Flutter applications
flutter pub add portakal_flutter

# For Pure Dart projects (CLI, backend, cloud workers)
dart pub add portakal_core
```

---

## 30-Second Quick Starts

### 1. Flutter Interactive Quick Start (`portakal_flutter`)

In interactive Flutter applications, use the **Preview-Before-Print** workflow. The exact same `ResolvedLabel` reviewed by the user in `LabelPreview.resolved` is compiled for printing:

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

class LabelConfirmationScreen extends StatelessWidget {
  final LabelBuilder builder;
  const LabelConfirmationScreen({super.key, required this.builder});

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
          // 3. Compile that SAME resolved job to authoritative printer bytes
          final Uint8List bytes = tsc.compileResolved(job);
          // 4. Pass bytes to your transport (Bluetooth, USB, Network Socket)
        },
      ),
    );
  }
}
```

### 2. Pure Dart Quick Start (`portakal_core`)

`portakal_core` has zero Flutter dependencies and runs seamlessly on backend servers, cloud functions, and Dart CLI tools:

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  // 1. Build document layout sequentially (no manual Y calculation required)
  final receipt = sequentialLabel(const LabelConfig(width: 80, height: 80, unit: Unit.mm))
    ..text('PORTAKAL CAFE', const TextOptions(size: 2, bold: true))
    ..divider()
    ..row('Iced Latte', r'$2.50')
    ..row('Butter Croissant', r'$2.00')
    ..divider()
    ..row('TOTAL', r'$4.50', bold: true)
    ..barcode(
      'ORD-8821',
      BarcodeOptions.typed(
        x: 20,
        y: 450,
        symbology: BarcodeSymbology.code128,
        height: 50,
      ),
    );

  // 2. Resolve once into an immutable job
  final ResolvedLabel job = receipt.resolve();

  // 3. Generate pure Dart SVG preview string for web / server-side verification
  final String svg = renderPreview(job);

  // 4. Compile the exact same job to printer command bytes
  final Uint8List escposBytes = escpos.compileResolved(job);
  final Uint8List tscBytes = tsc.compileResolved(job);
  final Uint8List zplBytes = zpl.compileResolved(job);
}
```

---

## Simple vs Resolved Workflows

| Workflow | Method Call | Best Used For | Key Characteristic |
| :--- | :--- | :--- | :--- |
| **Simple** | `final bytes = tsc.compile(builder);` | Automated batch printing, headless servers, backend microservices, non-interactive background print jobs. | Direct compilation from `LabelBuilder` to `Uint8List` in a single call. |
| **Resolved (Safe)** | `final job = builder.resolve();`<br>`LabelPreview.resolved(job: job);`<br>`final bytes = tsc.compileResolved(job);` | Interactive UI applications, print confirmation dialogs, multi-protocol preview benches. | Freezes the layout into an immutable `ResolvedLabel` to guarantee that what the user previewed is what prints. |

---

## Architecture & Transport Boundary

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
> **Transport is application-owned.** Portakal is a command generation and layout engine. Physical communication (Bluetooth Low Energy, USB, Serial, or TCP Network Sockets) is handled by your application or custom transport layer.

---

## The Byte-Safe Contract

All Portakal compilers (`facade.compile()`, `facade.compileResolved()`) and protocol-native builders (`printer.toBytes()`) return **`Uint8List`**.

`Uint8List` is the authoritative binary representation. String decodings (such as ASCII or Latin-1 representations) are diagnostic compatibility views only.

```dart
// ✅ RIGHT: Pass raw Uint8List bytes directly to your transport sink
final Uint8List bytes = tsc.compileResolved(job);
await transport.write(bytes);

// ❌ WRONG: Converting binary bytes through UTF-8 strings corrupts raster matrices & control bytes
final string = utf8.decode(bytes); // DANGEROUS: Throws or alters non-UTF-8 bytes
await transport.write(utf8.encode(string));
```

### Conceptual Transport Integrations

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
  // Transmit raw bytes to your BLE plugin's write characteristic
  await writeCharacteristic.write(bytes, withoutResponse: false);
}
```

#### USB / Serial (Conceptual)
```dart
Future<void> sendToUsbPrinter(dynamic usbEndpoint, Uint8List bytes) async {
  // Transmit raw bytes to your USB interface
  await usbEndpoint.write(bytes);
}
```

---

## 🎨 19 Practical Real-World Printing Examples

The [`example/`](example/) application contains **19 production-style, copyable printing templates** across real-world domains with live visual preview, 9-protocol compilation, and raw byte inspection:

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
> Physical continuous receipt length is normally content and paper feed driven; example preview heights are illustrative.

---

## Preview Unicode Support vs Printer Hardware Encoding

- **Flutter Visual Preview**: Renders any Unicode script (including Khmer, Thai, Japanese, Arabic, and European accents) using the host platform typography engine.
- **Physical Thermal Printers**: Process text according to their firmware command interpreter and memory architecture:
  - Standard label/receipt printers use 8-bit code pages (CP437, CP850, CP1252) and only support Latin-1 or specific regional subsets.
  - ZPL printers in UTF-8 mode (`^CI28`) can process Unicode text if appropriate font ROM cards (e.g. Swiss 721 / Andale) are installed on the device.
  - For complex Asian scripts on legacy printers lacking Unicode ROM fonts, convert text into a 1-bit monochrome raster bitmap via `imageToMonochrome()` before transmission.
- **`Preview support != printer-native Unicode support`**. If a compiler cannot encode a character in the active code page, Portakal throws an **`EncodingError`** (or `UnsupportedCharacterException`).

---

## Protocol Choice Guide

Printers are classified by their **implemented command language**, not solely by manufacturer brand:

| Protocol | Implemented Command Language | Typical Applications |
| :--- | :--- | :--- |
| **TSC (TSPL2)** | Printers implementing TSPL-compatible commands | Product price labels, barcode stickers, courier shipping tags |
| **ZPL II** | Printers implementing ZPL-compatible commands | Enterprise logistics, warehouse bin tags, cross-border shipping |
| **ESC/POS** | Printers implementing ESC/POS-compatible commands | Restaurant dining receipts, retail POS slips, kitchen tickets |
| **EPL2** | Printers implementing EPL2-compatible commands | Small courier parcels, retail shelf price tags |
| **CPCL** | Printers implementing CPCL-compatible commands | Mobile ticketing, meter reading, delivery route receipts |
| **DPL** | Printers implementing DPL-compatible commands | Industrial asset tracking, compliance labeling |
| **IPL** | Printers implementing IPL-compatible commands | High-throughput manufacturing and warehouse workflows |
| **SBPL** | Printers implementing SBPL-compatible commands | High-resolution medical, electronics, and parcel labels |
| **Star PRNT**| Printers implementing Star PRNT-compatible commands | Hospitality POS receipts, cloud kitchen order tickets |

> [!TIP]
> **Tested Protocols Definition**: In the example gallery, `testedProtocols` indicates that *this specific example's layout successfully compiles through those Portakal protocol implementations in the test suite under `UnsupportedFeaturePolicy.throwError`*. Always consult your physical printer's programming manual for supported command emulations.

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
