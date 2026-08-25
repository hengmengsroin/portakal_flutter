# Raw Data & Escape Sequence Passthrough

Portakal provides dedicated raw APIs to inject custom hardware escape sequences, proprietary vendor commands, and non-standard control codes into both Universal AST and Native Protocol streams.

---

## 1. The Two Canonical Raw APIs

```
┌─────────────────────────────────────────────────────────────┐
│ 1. rawBytes(Uint8List bytes)                                │
│    - Preserves exact 0x00..0xFF binary gamut                │
│    - Defensively copies input list for immutability         │
│    - Safe for binary raster, cutter triggers, pulse codes   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 2. rawAscii(String asciiCommand)                            │
│    - Converts printable ASCII (0x00..0x7F) directly         │
│    - Validates ASCII boundaries                             │
│    - Throws UnsupportedCharacterException on non-ASCII      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Using Raw APIs in Universal `LabelBuilder`

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final labelBuilder = label(const LabelConfig(width: 80, height: 60))
    .text('Label Content', const TextOptions(x: 20, y: 20))
    // Inject raw ASCII command
    .rawAscii('GAP 3 mm, 0 mm\n')
    // Inject exact raw binary escape sequence (e.g. ESC @ reset: 0x1B, 0x40)
    .rawBytes(Uint8List.fromList([0x1B, 0x40]));

  final Uint8List compiledBytes = tsc.compile(labelBuilder);
}
```

---

## 3. Using Raw APIs in Native Builders

Every native protocol builder includes `.rawBytes()` and `.rawAscii()`:

```dart
final escpos = EscPosPrinter()
  ..initialize()
  ..text('Standard Text')
  // Inject vendor drawer kick pulse: ESC p 0 25 250 (0x1B 0x70 0x00 0x19 0xFA)
  ..rawBytes(Uint8List.fromList([0x1B, 0x70, 0x00, 0x19, 0xFA]))
  ..cut();
```

---

## 4. Defensive Copying & Immutability

When you pass a `Uint8List` or `List<int>` to `rawBytes()` or `RawElement.bytes()`, Portakal creates a defensive clone via `Uint8List.fromList(...)`.

Mutating the source list after passing it to the builder does **not** corrupt the internal builder state or compiled byte stream:

```dart
final buffer = Uint8List.fromList([0x1B, 0x40]);
final labelBuilder = label(const LabelConfig(width: 50, height: 30))
    .rawBytes(buffer);

// Modifying the source buffer later is safe:
buffer[0] = 0xFF; // Does NOT affect labelBuilder internal state
```

---

## 5. ASCII Validation & Error Behavior

`rawAscii()` requires pure 7-bit ASCII characters (code points 0 to 127). Passing non-ASCII characters (such as `€`, `é`, or non-Latin glyphs) throws an `UnsupportedCharacterException`:

```dart
try {
  builder.rawAscii('Price: 10 €'); // '€' is U+20AC (non-ASCII)
} on UnsupportedCharacterException catch (e) {
  print('Rejected non-ASCII command: ${e.message}');
  // Solution: Use builder.text() with appropriate CodePage or builder.rawBytes()
}
```

---

## 6. Deprecated `raw(Object)`

The untyped `raw(Object)` method is deprecated and targeted for removal in Portakal 2.0. Replace existing calls as follows:

```dart
// OLD (Deprecated)
builder.raw('CLS\n');
builder.raw([0x1B, 0x40]);

// NEW (Portakal 1.0)
builder.rawAscii('CLS\n');
builder.rawBytes(Uint8List.fromList([0x1B, 0x40]));
```
