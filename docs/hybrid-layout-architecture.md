# Portakal Hybrid Layout Architecture

Portakal 1.2 implements **Hybrid Layout DX**: combining intuitive sequential document authoring with pixel-precise exact canvas placement, compiled down to 9 target printer languages and rendered in high-resolution preview.

---

## 1. Architectural Principles & Non-Goals

### Architectural Philosophy
- **Minimal Semantic AST Additions**: The AST adds only two concrete, target-agnostic layout nodes: `RowElement` and `DividerElement`.
- **Authoring-Time Lowering**: `sequentialLabel(...)` and `.table(...)` are purely fluent authoring helpers that compute deterministic geometry at build time and emit standard AST nodes.
- **Pure-Dart Core**: `portakal_core` remains 100% pure-Dart with zero dependencies on Flutter, `dart:ui`, or native C++ layout engines.

### Explicit Non-Goals
- **No Generic Layout Tree**: No widget tree, no `TableElement`, no `FlexElement`, no `ColumnElement` in the AST.
- **No C++ / Yoga / Layout Engine**: Geometry is calculated directly in pure Dart without external binary overhead.
- **No Intrinsic Text Measurement / Auto-Wrapping**: Thermal printers format text according to firmware ROM font geometries. Host-side font metrics are not assumed. Single-line cells preserve predictability across hardware.
- **No Pagination Engine**: Continuous and fixed-height media boundaries are managed predictably by configured dimensions.
- **No Flutter Widget Tree in Core**: `portakal_core` generates pure command bytes; UI preview widgets reside strictly in `portakal_flutter`.

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
|                    Minimal Semantic AST Layer                     |
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
|  - Authentic barcode commands     |   |  - Unstyled padding isolation     |
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
