# Portakal Hybrid Layout Architecture

Portakal 1.2 implements **Hybrid Layout DX**: combining intuitive sequential document authoring with pixel-precise exact canvas placement, compiled down to 9 target printer languages and rendered in high-resolution preview.

---

## 1. Architectural Principles & Non-Goals

### Non-Goals
- **No Flutter layout dependency in core**: `portakal_core` remains 100% pure-Dart with zero dependencies on `dart:ui` or Flutter layout.
- **No Yoga / Flexbox C++ engine**: Sizing is deterministic and pure-Dart.
- **No Intrinsic text measurement**: Thermal printers format text according to firmware ROM font geometries; host-side font metrics are not assumed.
- **No TableElement in AST**: Tables are authoring-time helpers that lower into horizontal `RowElement`s.
- **No Wrapping / Multi-line cell auto-wrap in 1.2**: Single-line physical cells preserve predictability.

---

## 2. Layered Architecture

```
+-------------------------------------------------------------------+
|                        Authoring Layer                            |
|                                                                   |
|   label(config)                 sequentialLabel(config)           |
|   (Exact Coordinates)           (Document Flow & Rhythms)         |
|                                   - row(left, right)              |
|                                   - rowCells([LabelCell, ...])    |
|                                   - table(columns: [...])         |
|                                   - divider()                     |
|                                   - space(dots)                   |
|                                   - exact coordinate escape hatch |
+-------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                  Deterministic Geometry Allocator                 |
|                                                                   |
|   LayoutGeometry.allocateColumns(startX, availableWidth, gap)     |
|   - Fixed column reservation                                      |
|   - Remainder assigned to final FLEX column                       |
+-------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                        Semantic AST Layer                         |
|                                                                   |
|   - RowElement(y, startX, width, size, [RowCellElement, ...])     |
|   - DividerElement(y, startX, width, thickness)                   |
|   - TextElement, BarcodeElement, BoxElement, LineElement, etc.    |
+-------------------------------------------------------------------+
                                  |
         +------------------------+------------------------+
         |                                                 |
         v                                                 v
+-----------------------------------+   +-----------------------------------+
|     7 Page Protocol Compilers     |   |    2 Stream Protocol Compilers    |
| (TSC, ZPL, EPL, CPCL, DPL, IPL,   |   |        (ESC/POS, Star PRNT)       |
|              SBPL)                |   |                                   |
|                                   |   |  StreamRowFormatter               |
|  - RowElement -> positioned text  |   |  - RowElement -> formatted line   |
|  - DividerElement -> vector line  |   |  - DividerElement -> ASCII line   |
+-----------------------------------+   +-----------------------------------+
         |                                                 |
         +------------------------+------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                    PreviewScene & SVG Renderer                    |
|                                                                   |
|   - Visual bounding box layout for RowElement                     |
|   - Vector line for DividerElement                                |
+-------------------------------------------------------------------+
```

---

## 3. Sizing & Geometry Contract

- **Fixed Units**: `LabelCell.fixed(dots)` reserves exact physical width.
- **Flex Units**: `LabelCell.flex(weight)` divides remaining space proportionally.
- **Remainder Rule**: To guarantee exact boundary alignment without roundoff drift, remainder pixels are assigned to the last flex cell.
- **Stream Character Grid**: Stream receipts map fixed/flex proportions across standard 32-col (58mm) or 48-col (80mm) monospaced character widths, overridable via `charsPerLine`.

---

## 4. Barcode Semantic Safety

- **`BarcodeSymbology`**: Restricted strictly to symbologies whose semantic identity is preserved authentically across all 9 protocol compilers:
  - `code128 ('128')`
  - `code39 ('39')`
- **`BarcodeOptions.typed`**: Factory constructor setting canonical `type: symbology.identifier`.
- **String Escape Hatch**: `const BarcodeOptions(type: '...')` remains non-deprecated and fully functional for custom or printer-specific symbologies (e.g. `type: 'EAN13'`).
