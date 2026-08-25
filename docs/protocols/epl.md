# EPL2 Protocol Guide

EPL2 (Eltron Programming Language 2) is a line-oriented page description language for Eltron and legacy Zebra desktop label printers.

---

## 1. Overview & Scope
- **Builder Class**: `EplPrinter`
- **Compiler Facade**: `epl.compile(labelBuilder)`
- **Parser**: `parseEPL(String code)`
- **Primary Targets**: Zebra LP2844, TLP2844, GC420, and EPL2-compatible label printers.

---

## 2. Minimal Working Example

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = EplPrinter()
    ..clearBuffer()
    ..labelWidth(600)
    ..labelLength(800)
    ..text(x: 30, y: 30, content: 'EPL2 SHIPPING LABEL', font: '3')
    ..barcodeCode128(x: 30, y: 100, height: 70, content: 'EPL-998877')
    ..print(copies: 1);

  final Uint8List bytes = printer.toBytes();
}
```

---

## 3. Command Lifecycle & Framing
1. **Clear Image Buffer**: `clearBuffer()` emits `N` (mandatory at start of page).
2. **Page Dimensions**: `labelWidth(w)` (`q<w>`), `labelLength(l)` (`Q<l>,<gap>`).
3. **Element Placement**: Text (`A`), Barcodes (`B`), 2D QR (`b`), Drawing (`LO`, `X`, `LW`), Bitmaps (`GW`).
4. **Print Execution**: `print(copies: n)` emits `P<n>`.

---

## 4. Text & Typography
- **Command**: `A x, y, rotation, font, hMult, vMult, reverse, "data"`.
- **Fonts**: `'1'` (8x12), `'2'` (10x16), `'3'` (12x20), `'4'` (14x24), `'5'` (32x48).
- **Rotation**: `EplRotation.r0`, `r90`, `r180`, `r270`.

---

## 5. Binary-Safe Graphic Write (`GW`)
- `printer.graphicsWrite(x, y, bitmap)` emits `GW x, y, widthBytes, height, <binaryData>` followed by LF (`0x0A`).
- **Binary Inversion**: Bitwise inverted automatically for EPL printhead polarity.

---

## 6. Geometric Primitives
- **Line Set**: `printer.line(x, y, width, height)` emits `LO`.
- **Box**: `printer.box(x, y, thickness, endX, endY)` emits `X`.
- **Erase Line / White Area**: `printer.erase(x, y, width, height)` emits `LW`.

---

## 7. Hardware Validation Status
- **Automated Test Suite**: **PASS** (Level 1 Byte-Verified across all feature cases).
