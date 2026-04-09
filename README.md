# 🍊 portakal_flutter

Universal printer language SDK for Flutter & Dart — **TSC, ZPL, EPL, ESC/POS, CPCL, DPL, IPL, SBPL, Star PRNT** and more.

Text, images, and printer-native barcode/QR commands. **Pure Dart, zero runtime dependencies.**

[![Tests](https://img.shields.io/badge/tests-392_passing-brightgreen)]()
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.11-blue)]()
[![License](https://img.shields.io/badge/license-MIT-purple)]()

> **Note:** Barcode/QR generation is NOT in this package. Use [`etiket`](https://github.com/productdevbook/etiket) for barcode & QR code generation (SVG/PNG). Portakal sends printer-native barcode/QR commands (the printer's built-in encoder) OR accepts pre-rendered images for pixel-perfect output.

---

## Features

- 🖨️ **9 printer languages** — TSC, ZPL, EPL, ESC/POS, CPCL, DPL, IPL, SBPL, Star PRNT
- 🔄 **Cross-compilation** — convert between any supported languages
- 🏷️ **Fluent label builder** — design labels with a clean, chainable API
- 📝 **HTML-like markup** — `<label><text>Hello</text></label>` DSL
- 🔍 **Parsers** — parse raw printer commands back to structured data
- 👁️ **SVG preview** — render labels as SVG strings for visual inspection
- ✅ **Validation** — check command ordering, parameter ranges, and structure
- 🖼️ **Image processing** — RGBA to monochrome with 4 dithering algorithms
- 📇 **17 printer profiles** — Epson, Zebra, TSC, Star, Bixolon, Citizen, SATO, Honeywell
- 💯 **Pure Dart** — no Flutter dependency, works on server, CLI, and mobile

## Installation

```yaml
dependencies:
  portakal_flutter: ^0.1.0
```

## Quick Start

### Build & compile a label

```dart
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/lang/tsc.dart';
import 'package:portakal_flutter/src/lang/zpl.dart';
import 'package:portakal_flutter/src/types.dart';

// Build a label with the fluent API
final myLabel = label(LabelConfig(width: 40, height: 30, unit: Unit.mm))
    .text('Hello World', TextOptions(x: 10, y: 10, font: '2', size: 2))
    .box(BoxOptions(x: 5, y: 5, width: 310, height: 230, thickness: 2))
    .circle(CircleOptions(x: 250, y: 150, diameter: 60));

// Compile to TSC
final tscCode = tsc.compile(myLabel);
// SIZE 40 mm,30 mm
// GAP 3 mm,0 mm
// CLS
// TEXT 10,10,"2",0,2,2,"Hello World"
// BOX 5,5,315,235,2
// CIRCLE 250,150,60,1
// PRINT 1

// Same label → ZPL
final zplCode = zpl.compile(myLabel);
// ^XA
// ^FO10,10^A0N,60,60^FDHello World^FS
// ^FO5,5^GB310,230,2^FS
// ^FO250,150^GC60,1^FS
// ^XZ
```

### HTML-like markup

```dart
import 'package:portakal_flutter/src/markup.dart';
import 'package:portakal_flutter/src/lang/tsc.dart';

final code = tsc.compile(markup('''
  <label width="100mm" height="150mm" dpi="203">
    <text x="10" y="10" size="2" bold>FROM: Warehouse A</text>
    <text x="10" y="40" size="3" bold>TO: John Doe</text>
    <text x="10" y="80">123 Main St, New York, NY 10001</text>
    <line x1="5" y1="110" x2="780" y2="110" thickness="2" />
    <box x="5" y="5" width="780" height="1170" border="3" />
  </label>
'''));
```

### Cross-compilation

```dart
import 'package:portakal_flutter/src/convert.dart';

// Convert TSC code to ZPL
final result = convert(tscCode, 'tsc', 'zpl');
print(result.output); // ZPL string

// Convert ZPL to ESC/POS (binary)
final receipt = convert(zplCode, 'zpl', 'escpos');
print(receipt.output); // Uint8List
```

### Parse printer commands

```dart
import 'package:portakal_flutter/src/lang/tsc.dart';
import 'package:portakal_flutter/src/lang/zpl.dart';

// Parse TSC
final tscResult = tsc.parse('SIZE 40 mm,30 mm\nCLS\nTEXT 10,10,"2",0,1,1,"Hello"\nPRINT 1');
print(tscResult.commands.length); // 4
print(tscResult.widthDots);       // 320
print(tscResult.elements.length); // 1 (TextElement)

// Parse ZPL
final zplResult = zpl.parse('^XA^FO10,10^A0N,30,30^FDHello^FS^XZ');
print(zplResult.commands.length); // 6
```

### SVG preview

```dart
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/lang/tsc.dart';
import 'package:portakal_flutter/src/types.dart';

final svg = tsc.preview(
  label(LabelConfig(width: 40, height: 30))
      .text('Preview Test', TextOptions(x: 10, y: 10, size: 2))
      .box(BoxOptions(x: 5, y: 5, width: 310, height: 230, thickness: 2)),
);
// Returns SVG string — render in a WebView or save to file
```

### Validate commands

```dart
import 'package:portakal_flutter/src/lang/tsc.dart';
import 'package:portakal_flutter/src/lang/zpl.dart';

// Validate TSC
final r = tsc.validate('SIZE 40 mm,30 mm\nCLS\nTEXT 10,10,"2",0,1,1,"Hi"\nPRINT 1');
print(r.valid);    // true
print(r.errors);   // 0

// Catch errors
final bad = tsc.validate('TEXT 10,10,"2",0,1,1,"No CLS"\nPRINT 1');
print(bad.valid);  // false
print(bad.issues); // [CLS must appear before label elements]
```

### Image processing

```dart
import 'dart:typed_data';
import 'package:portakal_flutter/src/image.dart';

// Convert RGBA pixels to monochrome bitmap
final rgba = Uint8List(100 * 100 * 4); // 100x100 RGBA image
final bitmap = imageToMonochrome(rgba, 100, 100);
// bitmap.data — 1-bit packed bitmap
// bitmap.bytesPerRow — bytes per scanline

// Use with label builder
final myLabel = label(LabelConfig(width: 40, height: 30))
    .image(bitmap, ImageOptions(x: 10, y: 10));
```

### Printer profiles

```dart
import 'package:portakal_flutter/src/profiles.dart';

// Get a specific profile
final profile = getProfile('zebra-zd420');
print(profile?.dpi);        // 203
print(profile?.language);   // zpl
print(profile?.dotsPerLine); // 864

// Find by USB vendor ID
final epsonPrinters = findByVendorId(0x04B8);

// Find by language
final zplPrinters = findByLanguage('zpl');

// Use with label builder — auto-sets DPI
final myLabel = label(LabelConfig(
  width: 40, height: 30,
  printer: 'tsc-te310', // Uses 300 DPI from profile
));
```

### Receipt formatting (ESC/POS)

```dart
import 'package:portakal_flutter/src/receipt.dart';

// Format a receipt line
final line = formatPair('Hamburger', '\$12.99', 32);
// "Hamburger                 $12.99"

// Word wrap
final lines = wordWrap('This is a long text that needs wrapping', 20);
// ["This is a long text", "that needs wrapping"]

// Table
final rows = formatTable(
  [Column(width: 20), Column(width: 8, align: 'right'), Column(width: 4, align: 'right')],
  [['Hamburger', '\$12.99', 'x2'], ['Fries', '\$4.99', 'x1']],
  32,
);
```

## Supported Languages

| Language | Compile | Parse | Preview | Validate |
|----------|---------|-------|---------|----------|
| **TSC/TSPL2** | ✅ | ✅ | ✅ | ✅ Full |
| **ZPL II** | ✅ | ✅ | ✅ | ✅ Full |
| **EPL2** | ✅ | ✅ | ✅ | ℹ️ Basic |
| **ESC/POS** | ✅ | ✅ | ✅ | ℹ️ Basic |
| **CPCL** | ✅ | ✅ | ✅ | ℹ️ Basic |
| **DPL** | ✅ | ✅ | ✅ | ℹ️ Basic |
| **IPL** | ✅ | ✅ | ✅ | ℹ️ Basic |
| **SBPL** | ✅ | ✅ | ✅ | ℹ️ Basic |
| **Star PRNT** | ✅ | ✅ | ✅ | ℹ️ Basic |

## Label Elements

| Element | Description | TSC | ZPL | EPL | ESC/POS | CPCL |
|---------|-------------|-----|-----|-----|---------|------|
| `text` | Text with font, size, rotation | ✅ | ✅ | ✅ | ✅ | ✅ |
| `image` | Monochrome bitmap | ✅ | ✅ | ✅ | ✅ | ✅ |
| `box` | Rectangle with optional radius | ✅ | ✅ | ✅ | — | ✅ |
| `line` | Line between two points | ✅ | ✅ | ✅ | — | ✅ |
| `circle` | Circle with thickness | ✅ | ✅ | — | — | — |
| `ellipse` | Ellipse | ✅ | — | — | — | — |
| `reverse` | Invert colors in region | ✅ | — | — | — | — |
| `erase` | Clear region to white | ✅ | — | — | — | — |
| `raw` | Raw command passthrough | ✅ | ✅ | ✅ | ✅ | ✅ |

## Dithering Algorithms

Four algorithms for converting images to 1-bit monochrome:

| Algorithm | Best For |
|-----------|----------|
| `threshold` | Simple graphics, logos, barcodes |
| `floydSteinberg` | Photos, gradients (best quality) |
| `atkinson` | Retro aesthetic, lighter output |
| `ordered` | Fast, predictable patterns |

## API Reference

### Language Modules

Each language module (`tsc`, `zpl`, `epl`, `escpos`, `cpcl`, `dpl`, `ipl`, `sbpl`, `starprnt`) exports:

```dart
String    compile(LabelBuilder builder)  // Label → printer commands
Result    parse(String code)             // Printer commands → structured data
String    preview(LabelBuilder builder)  // Label → SVG string
Result    validate(String code)          // Check command validity
```

### Core Functions

```dart
LabelBuilder  label(LabelConfig config)                           // Create label builder
LabelBuilder  markup(String source)                               // Parse HTML-like markup
ConvertResult convert(String code, String from, String to, {...}) // Cross-compile
String        renderPreview(ResolvedLabel label)                  // SVG preview
Result        validate(String code, String language)              // Validate commands
```

## Development

```bash
# Run tests
flutter test

# Run a specific test
flutter test test/tsc_test.dart

# Static analysis
flutter analyze
```

## Credits

Dart/Flutter port of [portakal](https://github.com/productdevbook/portakal) by [productdevbook](https://github.com/productdevbook).

## License

MIT
