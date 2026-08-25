# Protocol-Native Builders Guide

Portakal provides 9 dedicated native protocol builders for direct, 1:1 hardware control over command sequences, resident font metrics, printer initialization, memory buffers, and physical actuators.

---

## 1. Native Builders Overview

| Protocol | Builder Class | Target Hardware | Default Coordinate Origin |
| :--- | :--- | :--- | :--- |
| **ESC/POS** | `EscPosPrinter` | POS receipt printers (Epson, Bixolon, Star, generic) | Top-left (line stream) |
| **TSC** | `TscPrinter` | TSC, TSPL2, and compatible thermal label printers | Top-left (dots / mm) |
| **ZPL II** | `ZplPrinter` | Zebra, Honeywell, and ZPL II industrial label printers | Top-left (`^FO` / dots) |
| **EPL2** | `EplPrinter` | Eltron, Zebra desktop, and legacy page printers | Top-left (dots) |
| **CPCL** | `CpclPrinter` | Comtec, Zebra mobile, and portable receipt/label printers | Top-left (dots) |
| **DPL** | `DplPrinter` | Datamax-O'Neil industrial label printers (CR line endings) | Top-left (row/col) |
| **IPL** | `IplPrinter` | Intermec / Honeywell industrial printers (F90–F99 slots) | Top-left (points) |
| **SBPL** | `SbplPrinter` | SATO industrial printers (`<ESC>A` ... `<ESC>Z` framing) | Top-left (`<ESC>H<ESC>V`) |
| **Star PRNT** | `StarPrntPrinter` | Star Micronics Line Mode POS receipt printers | Top-left (line stream) |

---

## 2. The Universal Native Builder Contract

Every native builder implements a consistent, non-destructive contract:

### 1. `toBytes() -> Uint8List`
- **Idempotent**: Calling `.toBytes()` returns a `Uint8List` snapshot of the accumulated binary buffer.
- **Non-Consuming**: It does not reset, flush, or mutate internal state. You can call `.toBytes()` multiple times safely.

### 2. `reset()`
- **Local Memory Clear**: Re-initializes the internal byte writer, resets field counters, and restores default encodings.
- **Emits No Hardware Commands**: Calling `.reset()` performs zero I/O and appends nothing to the byte stream.

### 3. Safe Raw Passthrough
- `rawBytes(Uint8List bytes)`: Appends arbitrary binary bytes without modification.
- `rawAscii(String ascii)`: Appends ASCII strings; throws `UnsupportedCharacterException` on non-ASCII characters.

---

## 3. Native Builder Quick References

### ESC/POS Native Builder (`EscPosPrinter`)
```dart
final printer = EscPosPrinter()
  ..initialize()
  ..align(EscPosAlignment.center)
  ..bold(true)
  ..textLine('Receipt Title')
  ..bold(false)
  ..align(EscPosAlignment.left)
  ..feedLines(2)
  ..barcode(content: '123456789012', type: EscPosBarcodeType.ean13, height: 60)
  ..feedLines(3)
  ..cut();

final Uint8List bytes = printer.toBytes();
```

### TSC / TSPL2 Native Builder (`TscPrinter`)
```dart
final printer = TscPrinter()
  ..sizeMm(widthMm: 80, heightMm: 50)
  ..gapMm(distanceMm: 3, offsetMm: 0)
  ..direction(TscDirection.normal)
  ..cls()
  ..text(x: 30, y: 30, text: 'Shipping Label', font: TscResidentFont.font3)
  ..barcode(x: 30, y: 100, type: TscBarcodeType.code128, height: 70, content: 'TRACK-123')
  ..print(copies: 1);

final Uint8List bytes = printer.toBytes();
```

### ZPL II Native Builder (`ZplPrinter`)
```dart
final printer = ZplPrinter()
  ..startFormat()
  ..printWidth(800)
  ..labelLength(1200)
  ..fieldOrigin(50, 50)
  ..font(ZplFont.font0, height: 30, width: 30)
  ..fieldData('Order #998877')
  ..fieldOrigin(50, 120)
  ..barcodeCode128(height: 80, content: 'ORD-998877')
  ..printQuantity(1)
  ..endFormat();

final Uint8List bytes = printer.toBytes();
```

### IPL Native Builder (`IplPrinter` — Honeywell / Intermec)
```dart
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
```

---

## 4. Lifecycle & Sequencing Rules

Unlike high-level AST compilers that auto-frame jobs, native builders give you full authority over command order:

1. **Initialize / Frame**: Call initialization (`initialize()`, `startFormat()`, `cls()`, or `advancedMode()`).
2. **Configure Geometry & Encodings**: Set label dimensions, speed, darkness, and code pages.
3. **Emit Records / Elements**: Append text, barcodes, 2D codes, and drawing primitives in sequence.
4. **Execute Print**: Call `print()`, `endFormat()`, or `cut()` to finalize the hardware command batch.
5. **Retrieve Bytes**: Call `.toBytes()` to obtain the final `Uint8List`.
