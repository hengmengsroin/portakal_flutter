# CPCL Protocol Guide

CPCL (Comtec Printer Control Language) is a session-based command set designed for portable and mobile thermal receipt/label printers (Zebra QLn, ZQ series, Comtec).

---

## 1. Overview & Scope
- **Builder Class**: `CpclPrinter`
- **Compiler Facade**: `cpcl.compile(labelBuilder)`
- **Parser**: `parseCPCL(String code)`
- **Primary Targets**: Zebra mobile printers, portable parking enforcement printers, route delivery receipt printers.

---

## 2. Minimal Working Example

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = CpclPrinter()
    ..session(offset: 0, height: 600, quantity: 1)
    ..pageWidth(800)
    ..text(x: 30, y: 30, font: '0', size: '2', content: 'MOBILE DELIVERY RECEIPT')
    ..barcodeCode128(x: 30, y: 100, height: 60, content: 'DELIV-1234')
    ..print();

  final Uint8List bytes = printer.toBytes();
}
```

---

## 3. Command Lifecycle & Framing
1. **Session Header**: `session({offset, height, quantity})` emits `! <offset> 200 200 <height> <quantity>`.
2. **Page Width**: `pageWidth(w)` emits `PAGE-WIDTH <w>`.
3. **Session Termination**: `print()` emits `PRINT` followed by LF (`0x0A`).

---

## 4. Text & Typography
- **Command**: `TEXT font size x y "content"`.
- **Scaling / Magnification**: `setMag(w, h)` emits `SETMAG <w> <h>`.

---

## 5. Barcodes & 2D QR Codes
- **1D Barcode**: `barcodeCode128(x, y, height, content)` emits `BARCODE 128 1 1 <height> <x> <y> <content>`.
- **2D QR Code**: `qrCode(x: 30, y: 180, content: '...')` emits `BARCODE QR`.

---

## 6. Drawing & Raster Graphics
- **Box**: `box(x, y, endX, endY, thickness)` emits `BOX <x> <y> <endX> <endY> <thickness>`.
- **Line**: `line(x1, y1, x2, y2, thickness)` emits `LINE <x1> <y1> <x2> <y2> <thickness>`.
- **Expanded Graphics (EG)**: `expandedGraphics(x, y, bitmap)` emits `EG <widthBytes> <height> <x> <y> <hexData>`.

> [!NOTE]
> **CG Binary Graphics**: The binary compressed graphics (`CG`) command path is currently `N/S-SDK`. Raster images are compiled using standard `EG` hex representation.

---

## 7. Hardware Validation Status
- **Automated Test Suite**: **PASS** (Level 1 Byte-Verified across all feature cases).
