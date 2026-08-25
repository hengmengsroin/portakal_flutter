# IPL Protocol Guide

IPL (Intermec Printer Language) is an industrial barcode and label command set designed for Intermec and Honeywell EasyCoder industrial printers.

---

## 1. Overview & Scope
- **Builder Class**: `IplPrinter`
- **Compiler Facade**: `ipl.compile(labelBuilder)`
- **Parser**: `parseIPL(String code)`
- **Primary Targets**: Intermec PM43, PC43, PX4i, and Honeywell EasyCoder printers.

---

## 2. Minimal Working Example

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = IplPrinter()
    ..advancedMode()
    ..programMode()
    ..eraseFormat(90)
    ..createFormat(90)
    ..labelLength(600)
    ..text(x: 50, y: 50, text: 'INTERMEC IPL TEST')
    ..barcode(y: 120, height: 70, content: 'IPL-998877')
    ..exitProgramMode()
    ..selectFormat(90)
    ..print(batchCount: 1, quantity: 1);

  final Uint8List bytes = printer.toBytes();
}
```

---

## 3. Strict 7-Phase Command Lifecycle

IPL commands operate in two distinct hardware modes: **Program Mode** (defining formats in printer memory) and **Print Mode** (executing stored formats).

```
┌─────────────────────────────────────────────────────────────┐
│ 1. advancedMode()      →  <STX><ESC>C<ETX>                  │
│    Enables advanced format command processing.              │
├─────────────────────────────────────────────────────────────┤
│ 2. programMode()       →  <STX><ESC>P<ETX>                  │
│    Enters Program Mode for format definition.               │
├─────────────────────────────────────────────────────────────┤
│ 3. eraseFormat(n)      →  <STX>E<n><ETX>                    │
│    Clears existing format memory slot n.                    │
├─────────────────────────────────────────────────────────────┤
│ 4. createFormat(n)     →  <STX>F<n><ETX>                    │
│    Opens format n and defines text, barcode, and lines.     │
├─────────────────────────────────────────────────────────────┤
│ 5. exitProgramMode()   →  <STX>R<ETX>                       │
│    Exits Program Mode and returns to Print Mode.            │
├─────────────────────────────────────────────────────────────┤
│ 6. selectFormat(n)     →  <STX><ESC>E<n><ETX>               │
│    Selects stored format n for printing / data entry.       │
├─────────────────────────────────────────────────────────────┤
│ 7. print(...)          →  <STX><US><batch>;<RS><qty><ETB><ETX>
│    Executes print batch and dispenses media.                │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. NVRAM Safety Convention (Format Slots F90–F99)

> [!CAUTION]
> **IPL writes formats directly into printer NVRAM / Flash storage.**
>
> Format numbers `1` through `89` are commonly reserved for persistent factory or user templates stored in the printer. Portakal test suites, automated fixtures, and hardware validation scripts strictly use format slots **`F90` through `F99`** to prevent overwriting existing production formats.

---

## 5. Fields & Symbologies
- **Text Field**: `textField(fieldNumber: 1, y: 50, content: '...', font: '0')`.
- **1D Barcode**: `barcodeField(fieldNumber: 2, y: 120, height: 70, content: '...')`.
- **2D QR Code**: `qrCode(fieldNumber: 3, y: 220, cellWidth: 4, content: '...')`.
- **Box / Line**: `boxField(...)`, `lineField(...)`.

---

## 6. Unsupported SDK Features (N/S-SDK)
- **Generic Raster Bitmaps**: Custom raster images are currently unsupported (`N/S-SDK`) on IPL.

---

## 7. Hardware Validation Status
- **Automated Test Suite**: **PASS** (Level 1 Byte-Verified across all supported IPL cases).
