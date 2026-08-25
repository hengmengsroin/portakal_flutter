# SBPL Protocol Guide

SBPL (SATO Barcode Printer Language) is the standard command set for SATO industrial and desktop thermal barcode printers.

---

## 1. Overview & Scope
- **Builder Class**: `SbplPrinter`
- **Compiler Facade**: `sbpl.compile(labelBuilder)`
- **Parser**: `parseSBPL(String code)`
- **Primary Targets**: SATO CL4NX, CL6NX, CT4-LX, and compatible industrial printers.

---

## 2. Minimal Working Example

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = SbplPrinter()
    ..startLabel()
    ..printSpeed(3)
    ..text(h: 50, v: 50, font: 'M', content: 'SATO SBPL INDUSTRIAL')
    ..barcodeCode128(h: 50, v: 120, height: 70, content: 'SATO-9988')
    ..quantity(1)
    ..endLabel();

  final Uint8List bytes = printer.toBytes();
}
```

---

## 3. Command Lifecycle & Framing
1. **Start Label**: `startLabel()` emits `<ESC>A` (`0x1B 0x41`).
2. **Speed**: `printSpeed(speed)` emits `<ESC>CS<n>`.
3. **Coordinates & Elements**: Horizontal (`<ESC>H<dots>`) and Vertical (`<ESC>V<dots>`) position followed by element command.
4. **Quantity**: `quantity(copies)` emits `<ESC>Q<n>`.
5. **End Label**: `endLabel()` emits `<ESC>Z` (`0x1B 0x5A`).

> [!IMPORTANT]
> **Command Clarification (`<ESC>CS`)**: In SATO SBPL specification, `<ESC>CS<n>` sets the **Print Speed** parameter. It does **not** clear the print buffer. Buffer clearing occurs automatically on `<ESC>A` framing.

---

## 4. Text & Barcodes
- **Text**: `text(h: x, v: y, font: 'M', content: '...')` (fonts: `'XU'`, `'XS'`, `'XM'`, `'XB'`, `'XL'`, `'M'`, `'U'`).
- **1D Barcode**: `barcodeCode128(h: x, v: y, height: 70, content: '...')` emits `<ESC>BG`.
- **2D QR Code**: `qrCode(h: x, v: y, content: '...', cellWidth: 4)` emits `<ESC>2D30`.
- **Rectangle / Box**: `box(h: x, v: y, width: w, height: h, thickness: t)` emits `<ESC>FW`.

---

## 5. Unsupported SDK Features (N/S-SDK)
- **Generic Raster Bitmaps**: Custom raster images are currently unsupported (`N/S-SDK`) on SBPL.

---

## 6. Hardware Validation Status
- **Automated Test Suite**: **PASS** (Level 1 Byte-Verified across all supported SBPL cases).
