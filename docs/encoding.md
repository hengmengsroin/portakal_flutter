# Character Encodings & Code Pages Guide

Thermal and label printers rely on legacy 8-bit code pages to print accented and international characters. This guide details Portakal's character encoding model, code page tables, and error policies.

---

## 1. The Encoding Mental Model

International character printing requires understanding three distinct translation stages:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Dart Unicode String (e.g. "Café €")                      │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Host-Side Code Page Encoder (CodePageEncoder)            │
│    Translates Unicode code points to 8-bit bytes:           │
│    'é' -> 0x82 (CP437) or 0x82 (CP850)                      │
│    '€' -> 0xD5 (CP858) or 0x80 (CP1252)                     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Printer-Side Code Page Selector Command                  │
│    Instructs printer firmware which character ROM to use:   │
│    ESC/POS:  ESC t 19  (CP858)                              │
│    TSC:      CODEPAGE 858                                   │
│    ZPL:      ^CI28 (UTF-8) or ^CI0 (USA)                    │
└─────────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Host-side byte encoding is NOT the same concept as the printer's code page table number.**
>
> An ESC/POS printer might map CP858 to table ID `19`, while a Star printer maps it to table ID `4`, and an off-brand printer maps it to table ID `14`. Portakal encapsulates host-side byte translation and protocol-standard selector commands, but physical hardware verification is essential.

---

## 2. Supported Code Pages (`PrinterCodePage`)

| Enum Value | Name | Description | Key Supported Glyphs |
| :--- | :--- | :--- | :--- |
| `PrinterCodePage.cp437` | CP437 | Standard IBM PC / US ASCII | Accented vowels (`ä, ö, ü, é, à`), math symbols (`±, °, ²`) |
| `PrinterCodePage.cp850` | CP850 | Multilingual Latin-1 | Western European characters (`é, à, è, ù, ç, ñ, Á, Í, Ó`) |
| `PrinterCodePage.cp858` | CP858 | Multilingual Latin-1 + Euro | Identical to CP850, with `0xD5` mapped to the Euro symbol (`€`) |
| `PrinterCodePage.cp1252` | CP1252 | Windows Western European | `€` at `0x80`, smart quotes (`“ ” ‘ ’`), copyright (`©`), trademark (`™`) |
| `PrinterCodePage.cp866` | CP866 | Cyrillic Russian | Full Russian alphabet (`А–Я, а–я`) |
| `PrinterCodePage.cp857` | CP857 | Turkish | Turkish specific characters (`Ğ, ğ, Ş, ş, İ, ı, ç, ö, ü`) |
| `PrinterCodePage.utf8` | UTF-8 | Multi-byte Unicode | Full global Unicode set (supported on ZPL II via `^CI28` and UTF-8 enabled firmware) |

---

## 3. Host-Side Encoding with `CodePageEncoder`

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  // 1. Create encoder for Western European with Euro support
  final encoder = getEncoder(PrinterCodePage.cp858);

  // 2. Encode string
  final Uint8List encodedBytes = encoder.encode('Total: 15.50 €');
  print('Encoded bytes: $encodedBytes');

  // 3. Handling unencodable characters (throws by default)
  try {
    // CP437 does not contain the Euro symbol (€) or Chinese characters
    final cp437Encoder = getEncoder(PrinterCodePage.cp437);
    cp437Encoder.encode('Total: 15.50 €');
  } on UnsupportedCharacterException catch (e) {
    print('Error: ${e.message}');
    print('Failed character: "${e.character}" (U+${e.codePoint.toRadixString(16).toUpperCase()})');
  }

  // 4. Safe Replacement Policy
  final cp437Encoder = getEncoder(PrinterCodePage.cp437);
  final safeBytes = cp437Encoder.encode(
    'Total: 15.50 €',
    replaceUnsupported: true, // Replaces unmapped characters with '?'
  );
  final safeString = String.fromCharCodes(safeBytes); // Produces "Total: 15.50 ?"
}
```

---

## 4. Protocol-Specific Encodings

Each native protocol builder provides typed encoding classes:

### ESC/POS (`EscPosEncoding`)
```dart
final printer = EscPosPrinter(
  encoding: const EscPosEncoding.cp858(), // Emits ESC t 19
);
// Or custom table ID for off-brand printers:
printer.encoding(const EscPosEncoding.custom(table: 14, codePage: PrinterCodePage.cp858));
```

### TSC (`TscEncoding`)
```dart
final printer = TscPrinter(
  encoding: const TscEncoding.cp1252(), // Emits CODEPAGE 1252
);
```

### ZPL (`ZplEncoding`)
```dart
// Default: UTF-8 with ^CI28
final printer = ZplPrinter(
  encoding: const ZplEncoding.utf8(),
);

// Legacy ASCII mode (no ^CI command)
final legacyPrinter = ZplPrinter(
  encoding: const ZplEncoding.legacy(),
);
```
