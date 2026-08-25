# Star PRNT / Line Mode Protocol Guide

Star PRNT covers Star Micronics thermal receipt and POS printers operating in **Star Line Mode**.

---

## 1. Overview & Scope
- **Builder Class**: `StarPrntPrinter`
- **Compiler Facade**: `starprnt.compile(labelBuilder)`
- **Parser**: `parseStarPRNT(Uint8List data)`
- **Primary Targets**: Star TSP100, TSP650, TSP700, and compatible Star POS printers in Star Line Mode.

---

## 2. Minimal Working Example

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = StarPrntPrinter()
    ..initialize()
    ..text('STAR POS RECEIPT', align: 'center', bold: true)
    ..feedLines(1)
    ..text('Item Description     \$12.50')
    ..text('Sales Tax             \$1.00')
    ..feedLines(1)
    ..text('Total Due:           \$13.50', bold: true)
    ..feedLines(3)
    ..cut();

  final Uint8List bytes = printer.toBytes();
}
```

---

## 3. Command Lifecycle & Framing
- **Initialize**: `initialize()` emits `ESC @` (`0x1B 0x40`).
- **Text & Flow**: Emits text followed by LF (`0x0A`).
- **Line Feeds**: `feedLines(n)` emits `ESC a <n>`.
- **Cutter**: `cut({bool partial = true})` emits `ESC d 1` (partial) or `ESC d 0` (full).

---

## 4. Character Encodings & Code Pages
- **Command**: Emits `ESC GS t <tableNumber>`.
- **Supported Modes**: `StarPrntEncoding.cp437()`, `cp850()`, `cp858()`, `cp1252()`, `cp866()`, `cp857()`.

---

## 5. Barcodes & 2D QR Codes
- **1D Barcode**: `barcode('123456789012', type: 'Code128', height: 60)` emits `ESC b` function blocks.
- **2D QR Code**: `qrcode('https://example.com', size: 4)` emits `ESC GS y S` QR function blocks.

---

## 6. Raster Graphics Framing (`ESC * r`)
- `printer.image(monochromeBitmap)` wraps raster bit image data in Star Line Mode raster framing:
  - Start Raster Mode: `ESC * r A`
  - Transfer Bit Image Data: `ESC * r m x y d1...dk`
  - End Raster Mode: `ESC * r B`

---

## 7. Hardware Validation Status
- **Automated Test Suite**: **PASS** (Level 1 Byte-Verified across all supported Star PRNT cases).
