# Universal LabelBuilder Guide

The Universal `LabelBuilder` allows you to define target-agnostic labels and receipts in a single fluent structure, which can then be compiled to any supported printer language, rendered to SVG, or previewed in Flutter.

---

## 1. Initializing `LabelBuilder`

Create a builder using the top-level `label()` function with a `LabelConfig`:

```dart
import 'package:portakal_core/portakal_core.dart';

final builder = label(
  const LabelConfig(
    width: 80,         // Width in units (default: mm)
    height: 50,        // Height in units
    dpi: 203,          // Target printhead resolution (default: 203)
    unit: Unit.mm,     // Unit.mm, Unit.inch, or Unit.dot
    speed: 4,          // Print speed in inches/sec (optional)
    density: 8,        // Print darkness/density (optional)
    gap: 3,            // Label gap in mm (optional)
  ),
);
```

---

## 2. Adding Visual Elements

### Text
```dart
builder.text(
  'Invoice Item',
  const TextOptions(
    x: 20,
    y: 20,
    size: 2,          // Font scaling multiplier (1..8)
    bold: true,
    font: '0',        // Resident font ID
  ),
);
```

### 1D Barcode
```dart
builder.barcode(
  'ORD-998877',
  const BarcodeOptions(
    x: 20,
    y: 70,
    type: '128',      // Code 128
    height: 60,       // Barcode height in dots
    showText: true,   // Human-readable interpretation line
  ),
);
```

### 2D QR Code
```dart
builder.qrcode(
  'https://example.com/order/998877',
  const QRCodeOptions(
    x: 20,
    y: 160,
    cellWidth: 5,     // QR module size (1..10)
  ),
);
```

### Geometric Primitives
```dart
// Rectangle Box
builder.box(const BoxOptions(x: 10, y: 10, width: 620, height: 380, thickness: 2));

// Horizontal or Vertical Line
builder.line(const LineOptions(x1: 10, y1: 60, x2: 630, y2: 60, thickness: 2));

// Circle
builder.circle(const CircleOptions(x: 300, y: 200, diameter: 100));

// Ellipse
builder.ellipse(const EllipseOptions(x: 300, y: 200, width: 120, height: 60));

// Reverse Area (Invert black/white pixels)
builder.reverse(const ReverseOptions(x: 20, y: 20, width: 200, height: 30));

// Erase Area (Clear pixels to white)
builder.erase(const EraseOptions(x: 50, y: 50, width: 100, height: 20));
```

### Monochrome Bitmaps
```dart
// Add a 1-bit monochrome bitmap
builder.image(monochromeBitmap, const ImageOptions(x: 20, y: 250));
```

---

## 3. Print Copies Precedence

You can specify the number of print copies either in `LabelConfig` or by calling `.print([copies])`:

```dart
// Method 1: On builder directly (takes highest precedence)
builder.print(3);

// Validation: copies <= 0 throws InvalidConfigError immediately
builder.print(0); // THROWS InvalidConfigError
```

### Precedence Model
1. Explicit `.print(copies)` call on builder.
2. `LabelConfig.copies` if `.print()` was not invoked.
3. Default of `1` if neither was specified.

---

## 4. Compiling to Protocol Bytes

Compile your label directly with any language facade:

```dart
// Compile to TSC (TSPL2)
final tscBytes = tsc.compile(builder);

// Compile to ZPL II
final zplBytes = zpl.compile(builder);

// Compile to EPL2
final eplBytes = epl.compile(builder);

// Compile to ESC/POS with explicit UnsupportedFeaturePolicy
final escposBytes = escpos.compile(
  builder,
  policy: UnsupportedFeaturePolicy.ignore,
);
```

---

## 5. Cross-Language Conversion

Portakal can convert command strings or labels between supported languages via AST translation:

```dart
final zplString = '^XA^FO50,50^A0N,30,30^FDHello Zebra^FS^XZ';

// Convert ZPL to TSC
final ConvertResult result = convert(zplString, 'zpl', 'tsc');
print('Converted TSC: ${result.output}');
```

---

## 6. Previewing Labels

### Pure Dart SVG Preview
```dart
final resolved = builder.resolve();
final String svgXml = renderPreview(resolved);
```

### Flutter Widget Preview (`portakal_flutter`)
```dart
import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

Widget buildPreview(LabelBuilder builder) {
  return LabelPreview(
    label: builder,
    showMeta: true,      // Display dimensions and DPI metadata bar
    backgroundColor: Colors.white,
  );
}
```
