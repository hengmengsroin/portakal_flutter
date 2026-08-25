# Portakal Core Architecture & Concepts

This document explains the design principles, byte-native contract, builder styles, error hierarchy, and diagnostic parsers in Portakal 1.0.

---

## 1. Dual-Layer Architecture

Portakal is architected into two primary layers depending on your requirements:

```
┌─────────────────────────────────────────────────────────────┐
│                   A. Universal AST Layer                    │
│      LabelBuilder  →  ResolvedLabel  →  facade.compile()     │
│   (Target-agnostic layout, markup, SVG preview, conversion) │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│               B. Protocol-Native Builders Layer             │
│   EscPosPrinter, TscPrinter, ZplPrinter, EplPrinter, etc.   │
│       (1:1 Hardware control, custom escape sequences)       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
                        Uint8List Bytes
                               │
                               ▼
                    PrinterTransport (I/O)
```

### When to Use Each Layer

| Use Case | Recommended Approach | Reason |
| :--- | :--- | :--- |
| **Multi-Printer Applications** | **Universal `LabelBuilder`** | Write one layout once; compile to ZPL for warehouse Zebra printers, TSC for desktop printers, or ESC/POS for receipts. |
| **Visual Label Preview** | **Universal `LabelBuilder`** | Directly previewable via pure Dart SVG (`renderPreview`) or Flutter widget (`LabelPreview`). |
| **Maximum Hardware Precision** | **Native Protocol Builder** | Gives 1:1 control over hardware initialization, printhead density, speed, format buffers, and cutter controls. |
| **POS Receipt Workflows** | **`EscPosPrinter` / `StarPrntPrinter`** | Direct access to receipt formatting, justification, font magnification, drawer kicks, and paper cuts. |

---

## 2. The Byte-Native Contract

In Portakal 1.0, the authoritative output type for all compilers and native builders is strictly `Uint8List`:

```dart
// Facade compilation
Uint8List bytes = zpl.compile(labelBuilder);

// Native builder output
Uint8List bytes = printer.toBytes();
```

### Byte Safety Rules

> [!CAUTION]
> **Never decode printer streams as UTF-8 or treat them as Dart `String` objects.**
>
> Thermal printer streams contain raw binary data (e.g. packed 1-bit bitmap matrices in TSC `BITMAP`, EPL `GW`, ESC/POS `GS v 0`), non-ASCII code page bytes (CP437, CP850, CP1252), and non-printable control characters (`0x00`, `0x1B`, `0x1D`).
>
> Running `utf8.decode(bytes)` on binary printer streams will corrupt the payload with replacement characters (`\uFFFD`) and cause syntax errors on physical hardware.

- **Authoritative Stream**: `Uint8List` represents the exact byte sequence sent over the wire.
- **String Serializers**: Legacy String functions (e.g. `compileToZPL`) are deprecated 1:1 textual byte views for diagnostic logging only. **Never UTF-8 encode a compatibility string back into bytes for transmission.**

---

## 3. Unsupported Feature Policy

When compiling a universal `LabelBuilder` to a protocol that does not support a requested layout element (for example, attempting to render a `CircleElement` or `EllipseElement` on an ESC/POS or DPL printer), Portakal enforces a strict compilation policy:

```dart
enum UnsupportedFeaturePolicy {
  /// Throws an UnsupportedFeatureError when an unmapped element is encountered.
  throwError,

  /// Silently omits unsupported elements from the compiled byte stream.
  ignore,
}
```

### Default Behavior: `throwError`
By default, all compiler facades use `UnsupportedFeaturePolicy.throwError`. Silent loss of printed output (e.g. missing barcodes or borders) in production environments is dangerous.

```dart
final myLabel = label(const LabelConfig(width: 80, height: 60))
    .circle(const CircleOptions(x: 100, y: 100, diameter: 80));

// Throws UnsupportedFeatureError because ESC/POS lacks native circle primitives:
final bytes = escpos.compile(myLabel);

// Opt into intentional omission:
final safeBytes = escpos.compile(
  myLabel,
  policy: UnsupportedFeaturePolicy.ignore,
);
```

---

## 4. Error Hierarchy

All Portakal exceptions inherit from the base `PortakalError` class:

```
PortakalError (abstract Exception)
├── InvalidConfigError
├── UnsupportedFeatureError
└── EncodingError
    └── UnsupportedCharacterException
```

### Catching Errors

```dart
try {
  final bytes = tsc.compile(myLabel);
} on UnsupportedCharacterException catch (e) {
  print('Character "${e.character}" cannot be encoded in code page ${e.codePage.name}');
} on EncodingError catch (e) {
  print('Encoding failed: ${e.message}');
} on UnsupportedFeatureError catch (e) {
  print('Element "${e.featureName}" not supported on this protocol: ${e.message}');
} on InvalidConfigError catch (e) {
  print('Invalid configuration: ${e.message}');
} on PortakalError catch (e) {
  print('Portakal error: ${e.message}');
}
```

---

## 5. Diagnostic Parsers

Portakal includes 9 built-in parsers:
- **7 Text / Command-Oriented Parsers**: `parseTSC`, `parseZPL`, `parseEPL`, `parseCPCL`, `parseDPL`, `parseIPL`, `parseSBPL`.
- **2 Binary Parsers**: `parseESCPOS`, `parseStarPRNT`.

```dart
import 'package:portakal_core/portakal_core.dart';

void main() {
  final zplCode = '^XA^FO50,50^A0N,30,30^FDHello Zebra^FS^XZ';
  final result = zpl.parse(zplCode);

  print('Parsed commands: ${result.commands.length}');
  print('Extracted elements: ${result.elements.length}');
}
```

### Parser Scope & Boundaries
> [!NOTE]
> Parsers are **diagnostic and structural inspection tools**, not lossless universal decompilers. They are designed for approximate preview reconstruction, syntax validation (`facade.validate()`), and telemetry debugging. Complex printer macro programming, conditional control logic, and hardware-specific firmware scripting are preserved as unparsed raw commands.
