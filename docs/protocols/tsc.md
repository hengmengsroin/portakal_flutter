# TSC / TSPL2 Protocol Guide

TSPL / TSPL2 (TSC Printer Language) is widely used in desktop and industrial barcode and shipping label printers (TSC, Xprinter, Gprinter, Rongta, etc.).

---

## 1. Overview & Scope
- **Builder Class**: `TscPrinter`
- **Compiler Facade**: `tsc.compile(labelBuilder)`
- **Parser**: `parseTSC(String code)`
- **Primary Targets**: Label and shipping printers supporting TSPL / TSPL2 command sets.

---

## 2. Minimal Working Example

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = TscPrinter()
    ..sizeMm(widthMm: 80, heightMm: 50)
    ..gapMm(distanceMm: 3, offsetMm: 0)
    ..direction(TscDirection.normal)
    ..cls()
    ..text(x: 30, y: 30, text: 'SHIPPING LABEL', font: TscResidentFont.font3)
    ..barcode(x: 30, y: 100, type: TscBarcodeType.code128, height: 70, content: 'TRACK-123')
    ..print(copies: 1);

  final Uint8List bytes = printer.toBytes();
}
```

---

## 3. Command Lifecycle & Framing
1. **Dimensions**: `sizeDots(width, height)` or `sizeMm(width, height)` emits `SIZE <w> mm, <h> mm`.
2. **Gap**: `gapDots()` or `gapMm()` emits `GAP <d> mm, <o> mm`.
3. **Direction**: `direction(TscDirection.topToBottom)` emits `DIRECTION 1`.
4. **Buffer Clear**: `cls()` emits `CLS` (mandatory before rendering).
5. **Drawing**: Position text, barcodes, boxes, lines, circles, and bitmaps.
6. **Print Execution**: `print(copies: n)` emits `PRINT <m>, <n>`.

---

## 4. Text & Typography
- **Resident Fonts**: `'1'` (8x12), `'2'` (12x20), `'3'` (16x24), `'4'` (24x32), `'5'` (32x48), `'0'` (scalable).
- **Multipliers**: `xMultiplication: 1..8`, `yMultiplication: 1..8`.
- **Rotation**: `rotation: TscRotation.r0`, `r90`, `r180`, `r270`.

---

## 5. Character Encodings & Code Pages
- **Encoding Command**: Emits `CODEPAGE <name>`.
- **Supported Modes**:
  - `TscEncoding.cp437()` (`CODEPAGE 437`)
  - `TscEncoding.cp850()` (`CODEPAGE 850`)
  - `TscEncoding.cp858()` (`CODEPAGE 858`)
  - `TscEncoding.cp1252()` (`CODEPAGE 1252`)
  - `TscEncoding.cp866()` (`CODEPAGE 866`)
  - `TscEncoding.cp857()` (`CODEPAGE 857`)
  - `TscEncoding.utf8()` (`CODEPAGE UTF-8`)

---

## 6. Barcodes & 2D QR Codes
- **1D Barcodes**: `printer.barcode(x, y, type: TscBarCode.code128, height: h, content: '...')`.
- **2D QR Codes**: `printer.qrcode(x: 30, y: 150, content: 'https://example.com', cellWidth: 5)`.

---

## 7. Geometric Drawing Primitives
- **Box**: `printer.box(x: 10, y: 10, endX: 500, endY: 300, thickness: 2)`.
- **Bar / Line**: `printer.bar(x: 10, y: 50, width: 490, height: 2)`.
- **Circle**: `printer.circle(x: 100, y: 100, diameter: 60, thickness: 2)`.
- **Ellipse**: `printer.ellipse(x: 100, y: 100, width: 80, height: 40, thickness: 2)`.
- **Reverse**: `printer.reverse(x: 20, y: 20, width: 200, height: 40)`.
- **Erase**: `printer.erase(x: 50, y: 50, width: 100, height: 20)`.

---

## 8. Binary-Safe Raster Graphics (BITMAP)
`printer.bitmap(x, y, bitmap)` emits `BITMAP x,y,widthBytes,height,mode,data`:
- **Binary-Safe**: Packed binary bytes follow the command directly.
- **Polarity**: Standard TSPL binary polarity (1 = Black).

---

## 9. Hardware Validation Status
- **Printer001-328F (BLE)**: **PASS** (Level 1, Level 2, Level 3 verified for Text, Code128, QR, CP437/850/1252, Primitives, BITMAP, Multi-copy).
