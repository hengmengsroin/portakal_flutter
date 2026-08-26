# Universal LabelBuilder & Sequential Layout Guide

Portakal 1.2 introduces **Hybrid Layout DX**: two complementary authoring models sharing the same deterministic compilation pipeline and preview renderer:
- **`label(config)`**: Exact-canvas coordinate layout. Retains existing legacy exact-canvas semantics without performing sequential progression.
- **`sequentialLabel(config)`**: Document-style vertical layout with automatic progression, semantic rows, dividers, and tables.

---

## 1. Authoring Entry Points

### A. Document Mode: `sequentialLabel`
For receipts, tickets, invoices, and standard labels that flow vertically from top to bottom:

```dart
import 'package:portakal_core/portakal_core.dart';

final receipt = sequentialLabel(
  const LabelConfig(
    width: 80,
    height: 80,
    unit: Unit.mm,
  ),
);

receipt
  .text('PORTAKAL CAFE', const TextOptions(size: 2, bold: true))
  .text('Riverside Blvd, Phnom Penh')
  .divider()
  .row('Latte', r'$2.50')
  .row('Cake', r'$3.00')
  .divider()
  .row('TOTAL', r'$5.50', bold: true);

final job = receipt.resolve();
```

### B. Exact Canvas Mode: `label`
For complex badges, asset tags, or graphics requiring absolute coordinate placement:

```dart
final badge = label(
  const LabelConfig(
    width: 60,
    height: 40,
    unit: Unit.mm,
  ),
);

badge
  .box(const BoxOptions(x: 10, y: 10, width: 460, height: 300, thickness: 2))
  .text('VISITOR', const TextOptions(x: 30, y: 30, size: 2, bold: true))
  .qrcode('https://example.com', const QRCodeOptions(x: 300, y: 100, cellWidth: 4));
```

> [!NOTE]
> `label(config)` retains the existing exact-canvas API and legacy coordinate semantics. It does not perform sequential advancement.

---

## 2. Sequential Layout Rhythm & Spacing

When created via `sequentialLabel(config, {int? margin, int? lineAdvance})`:
- **Default Margin**: Computed as `2.5mm` converted to dots based on the target DPI (e.g. 20 dots at 203 DPI, 30 dots at 300 DPI).
- **Default Line Advance**: Computed as `3.5mm` converted to dots based on the target DPI (e.g. 28 dots at 203 DPI, 41 dots at 300 DPI).
- Explicit `margin` and `lineAdvance` arguments are specified in **dots**.

### Sequential Spacing & Dividers
- **`space(int amount)`**: Advances the vertical document position (`currentY`) by `amount` dots without emitting any AST node.
- **`divider({int thickness = 1, int? advance, int? margin})`**: Emits a semantic `DividerElement` across the usable width and advances vertical state.

---

## 3. The Exact Coordinate Escape Hatch

Inside a `sequentialLabel`:
- **Coordinate-free text** (`options.x == null && options.y == null`) $\rightarrow$ Positioned at `_startX` and `_currentY`, advancing `_currentY` by `_lineAdvance`.
- **Sequential elements** (`row()`, `rowCells()`, `table().row()`, `divider()`) $\rightarrow$ Positioned at `_currentY` and advance the vertical document position.
- **`space(dots)`** $\rightarrow$ Explicitly advances the vertical document position without emitting an AST node.
- **Any element with explicit coordinates** (e.g. `text` with `x` or `y`, `barcode`, `qrcode`, `box`, `line`, `circle`, `ellipse`, `image`, `reverse`, `erase`) $\rightarrow$ Placed at exact coordinates and **does not advance `_currentY`**.

This enables clean progressive disclosure and mixed layouts:
```dart
final doc = sequentialLabel(config);

doc.text('Customer Invoice');
doc.row('Invoice #', 'INV-2026-001');

// Exact box and QR code placed independently without altering document progression:
doc.box(const BoxOptions(x: 10, y: 500, width: 600, height: 120));
doc.qrcode('https://pay.example.com', const QRCodeOptions(x: 480, y: 510, cellWidth: 3));

doc.text('Thank you for your business!');
```

---

## 4. Semantic Rows and Tables

### A. Simple Left/Right Pairs: `row()`
Emits a semantic `RowElement` with a 3:1 column ratio (left cell left-aligned, right cell right-aligned):
```dart
doc.row('Subtotal:', r'$165.00');
doc.row('TOTAL:', r'$181.50', bold: true, size: 2);
```

### B. Custom Horizontal Composition: `rowCells()`
For non-standard ratios, 3+ columns, or mixed fixed/flex widths:
```dart
doc.rowCells(
  children: [
    LabelCell.fixed(120, text: 'ITEM-402', bold: true),
    LabelCell.flex(3, text: 'Direct Thermal Labels'),
    LabelCell.flex(1, text: r'$8.00', align: LabelTextAlign.right),
  ],
);
```

### C. Repeated Column Structures: `table()`
Creates a `LabelTable` authoring helper sharing the parent's sequential vertical document state:
```dart
final itemsTable = doc.table(
  columns: [
    LabelColumn.flex(3),
    LabelColumn.flex(1, align: LabelTextAlign.center),
    LabelColumn.flex(1, align: LabelTextAlign.right),
    LabelColumn.flex(1, align: LabelTextAlign.right),
  ],
  gap: 10,
);

itemsTable
  ..row(['Description', 'Qty', 'Unit', 'Total'], bold: true)
  ..divider()
  ..row(['Thermal Printer 203 DPI', '2', r'$45.00', r'$90.00'])
  ..row(['Direct Thermal Labels', '5', r'$8.00', r'$40.00']);
```

---

## 5. Type-Safe Barcode Configuration

Portakal 1.2 introduces `BarcodeSymbology` and `BarcodeOptions.typed`:

```dart
// Type-safe authoring for universally supported symbologies:
builder.barcode(
  'ITEM-10294',
  BarcodeOptions.typed(
    x: 40,
    y: 145,
    symbology: BarcodeSymbology.code128,
    height: 80,
    readable: 1,
  ),
);
```

### Universally Supported Typed Symbologies:
- `BarcodeSymbology.code128`: Code 128 (auto subset B/C).
- `BarcodeSymbology.code39`: Code 39 (3 of 9).

### Legacy String Escape Hatch:
The classic constructor remains non-deprecated and fully functional for printer-specific or non-universal symbologies:
```dart
builder.barcode(
  '1234567890128',
  const BarcodeOptions(
    x: 20,
    y: 130,
    type: 'EAN13',
    height: 60,
    readable: 1,
  ),
);
```

---

## 6. Cross-Protocol Lowering & Fidelity Guarantees

| Element | 7 Page Protocols (TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL) | 2 Stream Protocols (ESC/POS, Star PRNT) | PreviewScene |
|---|---|---|---|
| **`RowElement`** | Positioned text fields with deterministic resolved X coordinates | Single formatted text line allocated across monospaced character grid | Full visual bounding layout with precise typography |
| **`DividerElement`** | Native geometric horizontal line | Textual ASCII separator line (`---`) | High-resolution vector line |
| **`BarcodeElement`** | Native barcode commands (`^BC`/`^B3`, `c6`/`c0`, `ESC BG`/`ESC B1`, etc.) | Native barcode command bytes (ESC/POS `GS k 73`/`69`, Star `ESC b 5`/`1`) | High-contrast visual barcode pattern |

### Alignment Fidelity
- **PreviewScene & ZPL**: Native bounded center/right text alignment.
- **ESC/POS & Star PRNT**: Monospaced space-padded grid alignment.
- **TSC / EPL / CPCL / DPL / IPL / SBPL**: Anchor at cell start boundary (left-aligned) for reliable cross-firmware rendering.

### Stream Protocol Capacity & `charsPerLine`
- Default capacity: 58mm class $\rightarrow$ 32 characters; 80mm class $\rightarrow$ 48 characters.
- Overrides: `compileToESCPOS(job, charsPerLine: 42)` or `compileToStarPRNT(job, charsPerLine: 42)`.
- Stream row formatting truncates safely by Unicode scalar values without splitting UTF-16 surrogate pairs. Monospaced column allocation does not guarantee visual glyph width for complex scripts (Khmer, emoji, CJK) where printer firmware shaping governs physical output.

---

## 7. Resolve-Once Workflow

Always resolve the builder once and use the resulting `ResolvedLabel` for preview and compilation:

```dart
final job = builder.resolve();

// 1. Preview
final svgXml = renderPreview(job);

// 2. Compile to Target Printer
final Uint8List escposBytes = escpos.compileResolved(job);
final Uint8List zplBytes = zpl.compileResolved(job);
```
