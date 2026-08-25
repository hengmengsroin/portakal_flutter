# ESC/POS Protocol Guide

ESC/POS (Epson Standard Code for Point of Sale) is the industry standard command set for thermal receipt printers, POS stations, and kitchen order printers.

---

## 1. Overview & Scope
- **Builder Class**: `EscPosPrinter`
- **Compiler Facade**: `escpos.compile(labelBuilder)`
- **Parser**: `parseESCPOS(Uint8List data)`
- **Primary Targets**: POS receipt printers (Epson TM series, Bixolon, Star POS, generic Chinese POS receipt printers).

---

## 2. Minimal Working Example

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = EscPosPrinter()
    ..initialize()
    ..align(EscPosAlignment.center)
    ..bold(true)
    ..textSize(width: 2, height: 2)
    ..textLine('STORE RECEIPT')
    ..bold(false)
    ..textSize(width: 1, height: 1)
    ..align(EscPosAlignment.left)
    ..feedLines(1)
    ..textLine('Item 1              \$10.00')
    ..textLine('Item 2              \$15.00')
    ..feedLines(1)
    ..bold(true)
    ..textLine('Total:              \$25.00')
    ..bold(false)
    ..feedLines(3)
    ..cut();

  final Uint8List bytes = printer.toBytes();
}
```

---

## 3. Command Lifecycle & Framing
- **Initialize**: `printer.initialize()` emits `ESC @` (`0x1B 0x40`).
- **Text Flow**: Commands are appended sequentially; lines wrap based on printer character width.
- **Line Feeds**: `printer.feedLines(n)` emits `ESC d <n>`.
- **Cutter**: `printer.cut({bool partial = true})` emits `GS V 1` (partial) or `GS V 0` (full).

---

## 4. Text & Typography
- **Alignment**: `align: 'left'`, `'center'`, `'right'` (emits `ESC a <0|1|2>`).
- **Styles**: `bold: true` (emits `ESC E 1`), `underline: true` (emits `ESC - 1`).
- **Scaling**: `size: 1..8` multiplier (emits `GS ! <n>`).

---

## 5. Character Encodings & Code Pages
- **Host Encoding**: `EscPosEncoding` maps characters via `CodePageEncoder`.
- **Table Selector**: Emits `ESC t <tableNumber>`.
- **Standard Tables**:
  - `EscPosEncoding.cp437()` (table 0)
  - `EscPosEncoding.cp850()` (table 2)
  - `EscPosEncoding.cp858()` (table 19)
  - `EscPosEncoding.cp1252()` (table 16)
  - `EscPosEncoding.cp866()` (table 17)
  - `EscPosEncoding.cp857()` (table 13)
- **Custom Tables**:
  ```dart
  printer.encoding(const EscPosEncoding.custom(table: 14, codePage: PrinterCodePage.cp858));
  ```

> [!WARNING]
> **Dialect Variance**: Code page table numbers (`ESC t <n>`) vary across printer manufacturers. If international characters render incorrectly, check your printer's self-test page for its specific code table mapping.

---

## 6. Barcodes & 2D QR Codes
- **1D Barcode**: `printer.barcode('123456789012', type: 'EAN13', height: 60)` emits `GS k`.
- **2D QR Code**: `printer.qrcode('https://example.com', size: 4)` emits `GS ( k` function blocks.

---

## 7. Raster Graphics
- `printer.image(monochromeBitmap)` emits `GS v 0` (standard 8-dot column packed raster data).

---

## 8. Raw Escape Sequences
```dart
// Emit drawer kick pulse: ESC p 0 25 250
printer.rawBytes(Uint8List.fromList([0x1B, 0x70, 0x00, 0x19, 0xFA]));
```

---

## 9. Unsupported SDK Features
- Geometric drawing primitives (`CircleElement`, `EllipseElement`, `ReverseElement`) are not natively supported in receipt mode. In Universal AST compilation, these throw `UnsupportedFeatureError` by default.

---

## 10. Hardware Validation Status
- **Printer001-328F (BLE)**: **PASS** (Level 1, Level 2, Level 3 verified for Text, Code128, QR, CP437, Raster, Cut).
