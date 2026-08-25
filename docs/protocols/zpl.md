# ZPL II Protocol Guide

ZPL II (Zebra Programming Language II) is the standard command language for Zebra industrial, desktop, and mobile label printers.

---

## 1. Overview & Scope
- **Builder Class**: `ZplPrinter`
- **Compiler Facade**: `zpl.compile(labelBuilder)`
- **Parser**: `parseZPL(String code)`
- **Primary Targets**: Zebra ZT/ZD series, Honeywell, and ZPL II emulation thermal printers.

---

## 2. Minimal Working Example

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final printer = ZplPrinter()
    ..startFormat()
    ..printWidth(800)
    ..labelLength(1200)
    ..fieldOrigin(50, 50)
    ..font(ZplFont.font0, height: 30, width: 30)
    ..fieldData('Order #998877')
    ..fieldOrigin(50, 120)
    ..barcodeCode128(height: 80, content: 'ORD-998877')
    ..fieldOrigin(50, 240)
    ..qrCode(content: 'https://example.com/998877')
    ..printQuantity(1)
    ..endFormat();

  final Uint8List bytes = printer.toBytes();
}
```

---

## 3. Command Lifecycle & Framing
- **Job Start**: `startFormat()` emits `^XA`.
- **Job Dimensions**: `printWidth(w)` emits `^PW<w>`, `labelLength(h)` emits `^LL<h>`.
- **Field Framing**: `fieldOrigin(x, y)` (`^FO`) + Field Data (`^FD`) + Field Separator (`^FS`).
- **Copies**: `printQuantity(copies)` emits `^PQ<copies>`.
- **Job End**: `endFormat()` emits `^XZ`.

---

## 4. Character Encodings & UTF-8 (`^CI28`)
- **Default Mode**: `ZplEncoding.utf8()` emits `^CI28` directly following `^XA`.
- **Field Hex Escaping**: Text containing control characters (`^`, `~`, `_`) is automatically escaped via `^FH` and hexadecimal representations (e.g. `_5E`).
- **Legacy ASCII Mode**: `ZplEncoding.legacy()` omits `^CI` and emits 7-bit ASCII text.

---

## 5. Barcodes & 2D QR Codes
- **Code 128**: `printer.barcodeCode128(height: 80, content: '...')` emits `^BC`.
- **QR Code**: `printer.qrCode(content: '...', cellWidth: 5)` emits `^BQ`.

---

## 6. Drawing Primitives & Graphics
- **Graphic Box / Line**: `printer.graphicBox(width, height, thickness)` emits `^GB`.
- **Graphic Circle**: `printer.graphicCircle(diameter, thickness)` emits `^GC`.
- **Graphic Ellipse**: `printer.graphicEllipse(width, height, thickness)` emits `^GE`.
- **Raster Bitmap**: `printer.graphicField(bitmap)` emits `^GFA` (ASCII hex-encoded raster bitmap).

---

## 7. Hardware Validation Status
- **Printer001-328F (BLE)**: **N/S-DEVICE**
  - The physical `Printer001-328F` device tested is a dual-mode POS/label printer lacking internal ZPL II emulation firmware. When ZPL bytes are transmitted, the device prints literal `^XA...^XZ` text lines.
  - This is documented as `N/S-DEVICE` (physical firmware capability constraint, not an SDK defect).
