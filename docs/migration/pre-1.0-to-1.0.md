# Migrating to Portakal 1.0

This guide provides before-and-after recipes for upgrading applications from pre-1.0 (`0.1.x` / `0.2.x` / `0.3.0` development builds) to the frozen Portakal 1.0 API contract.

---

## 1. Receipt Column Renaming (`ReceiptColumn`)

To avoid naming collisions with Flutter's built-in `Column` layout widget, the receipt table column class was renamed to `ReceiptColumn`.

```dart
// OLD (pre-1.0)
import 'package:portakal_core/portakal_core.dart';

final table = formatTable(
  [
    Column(width: 20, align: 'left'),
    Column(width: 10, align: 'right'),
  ],
  [
    ['Coffee', '\$3.50'],
    ['Muffin', '\$2.50'],
  ],
  32,
);

// NEW (Portakal 1.0)
import 'package:portakal_core/portakal_core.dart';

final table = formatTable(
  [
    const ReceiptColumn(width: 20, align: 'left'),
    const ReceiptColumn(width: 10, align: 'right'),
  ],
  [
    ['Coffee', '\$3.50'],
    ['Muffin', '\$2.50'],
  ],
  32,
);
```

> [!NOTE]
> In `portakal_flutter`, `portakal_core` is re-exported with `hide Column`, so you can use Flutter's `Column` widget and Portakal's `ReceiptColumn` in the same Dart file without import prefixes.

---

## 2. Facade `.compile()` Returns `Uint8List`

All language compiler facades (`tsc.compile`, `zpl.compile`, `escpos.compile`, etc.) now return `Uint8List` byte streams instead of `String`.

```dart
// OLD (pre-1.0: returned String)
String zplText = zpl.compile(builder);

// NEW (Portakal 1.0: returns Uint8List)
Uint8List zplBytes = zpl.compile(builder);
```

> [!CAUTION]
> **Do not `utf8.decode()` printer streams for hardware transmission.**
>
> Pass the returned `Uint8List` directly to your socket or transport layer. Printer streams contain raw binary raster data and 8-bit code page bytes that will be corrupted if decoded as UTF-8.

---

## 3. Deprecated `compileBytes` Unified to `compile`

The temporary `compileBytes()` method is deprecated and aliased directly to `.compile()`.

```dart
// OLD (pre-1.0)
Uint8List bytes = tsc.compileBytes(builder);

// NEW (Portakal 1.0)
Uint8List bytes = tsc.compile(builder);
```

---

## 4. Typed Raw Data (`rawBytes` / `rawAscii`)

The untyped `raw(Object)` method is deprecated in favor of explicit binary and ASCII methods:

```dart
// OLD (pre-1.0: accepted untyped Object)
builder.raw('CLS\n');
builder.raw([0x1B, 0x40]);

// NEW (Portakal 1.0: typed and boundary-checked)
builder.rawAscii('CLS\n');
builder.rawBytes(Uint8List.fromList([0x1B, 0x40]));
```

---

## 5. Explicit Character Encoding Subsystem

Legacy encoding helper functions (`encodeText`, `encodeTextForPrinter`, `EncodedSegment`, `CodePage`) are deprecated in favor of `PrinterCodePage` and `CodePageEncoder`:

```dart
// OLD (pre-1.0)
final bytes = encodeTextForPrinter('Café', CodePage.cp437);

// NEW (Portakal 1.0)
final encoder = getEncoder(PrinterCodePage.cp437);
final Uint8List bytes = encoder.encode('Café');
```

---

## 6. Deprecation Summary & 2.0 Removal Target

The following legacy symbols remain functional with `@Deprecated` annotations in Portakal 1.x and will be removed in 2.0:

| Deprecated Symbol | 1.0 Replacement | Notes |
| :--- | :--- | :--- |
| `typedef Column = ReceiptColumn;` | `ReceiptColumn` | Resolves collision with Flutter `Column`. |
| `facade.compileBytes(...)` | `facade.compile(...)` | Unified to canonical byte-native API. |
| `LabelBuilder.raw(Object)` | `rawBytes()` / `rawAscii()` | Eliminates untyped Object coercion. |
| `RawElement({required Object content})` | `RawElement.bytes()` / `RawElement.ascii()` | Defensively copies bytes; validates ASCII. |
| `compileToTSC(...)`, `compileToZPL(...)`, etc. | `tsc.compile(...)`, `zpl.compile(...)`, etc. | String serializers deprecated as inspection views. |
| `encodeText(...)`, `encodeTextForPrinter(...)` | `CodePageEncoder.encode(...)` | Explicit code page encoding subsystem. |
| `enum CodePage`, `class EncodedSegment` | `enum PrinterCodePage` | Replaced by unified enum. |
