# Portakal 1.2 Phase 12C — Hybrid Layout ESC/POS Hardware Validation

Physical validation record for the Portakal 1.2 Hybrid Layout document engine on physical thermal printer hardware.

---

## 1. Hardware & Test Session Details

| Parameter | Value |
| :--- | :--- |
| **Device Model** | `Printer001-328F` (Multi-Emulation Bluetooth Direct Thermal) |
| **Manufacturer** | Unknown / Generic POS |
| **Transport** | BLE (Bluetooth Low Energy) & Raw Byte Stream |
| **Protocol** | ESC/POS |
| **Physical Paper Media** | 80mm Continuous Direct Thermal Roll |
| **Configured Label Size** | 80mm × 80mm (203 DPI) |
| **Validation Date** | 2026-08-26 |
| **Binary Artifact Path** | [`hardware_validation/phase12c_hybrid_escpos.bin`](phase12c_hybrid_escpos.bin) |
| **Byte Length** | 360 bytes |
| **Binary SHA-256** | `2d911e1bbbe58215ea3de77da830efdc492a9a08877f223a550214357bb94191` |

---

## 2. Test Job Definition

```dart
final receipt = sequentialLabel(
  const LabelConfig(width: 80, height: 80, unit: Unit.mm),
)
  ..text('PORTAKAL 1.2', const TextOptions(bold: true, size: 2))
  ..divider()
  ..row('Coffee', r'$5.00')
  ..row('Tea', r'$2.50')
  ..divider()
  ..row('TOTAL', r'$7.50', bold: true)
  ..text('Thank you')
  ..space(10)
  ..rowCells(
    children: [
      LabelCell.flex(1, text: 'UNDERLINE', underline: true),
      LabelCell.flex(1, text: 'RIGHT', align: LabelTextAlign.right),
    ],
  )
  ..barcode(
    'PKL-12-HW',
    BarcodeOptions.typed(
      x: 20,
      y: 420,
      symbology: BarcodeSymbology.code128,
      height: 50,
      readable: 1,
    ),
  );

final ResolvedLabel job = receipt.resolve();
final Uint8List bytes = compileToESCPOS(job);
```

---

## 3. Physical Verification Results

| Item | Expected Physical Behavior | Observed Physical Result | Status |
| :--- | :--- | :--- | :---: |
| **A. Header** | `PORTAKAL 1.2` centered/prominent, 2x magnification | Cleanly printed in double-height/double-width bold font | **PASS** |
| **B. First Row** | `Coffee` on left, `$5.00` on right on ONE physical line | Printed on single physical line with 33 spaces padding; no wrapping | **PASS** |
| **C. Second Row** | `Tea` on left, `$2.50` on right on ONE physical line | Printed on single physical line aligned consistently with Row 1 | **PASS** |
| **D. Dividers** | Semantic separator line across usable receipt width | `--------------------------------------------` printed as single clean row | **PASS** |
| **E. TOTAL Row** | `TOTAL` and `$7.50` on single physical line, bold text | Printed on single physical line; bold applied to text segments only | **PASS** |
| **F. Style Reset** | `Thank you` following bold TOTAL row | Printed in standard regular Font A; zero bold style leakage | **PASS** |
| **G. Underline Test**| `UNDERLINE` cell underline style isolation | Underline strictly isolated to letters `UNDERLINE`; padding unstyled | **PASS** |
| **H. Line Feeds** | Compact document flow without extraneous blank lines | Exactly one physical line per row/divider; no unexpected extra feeds | **PASS** |
| **I. Code 128 Barcode** | Scannable 1D barcode with human-readable interpretation | Scanned with optical scanner, decodes exact payload `PKL-12-HW` | **PASS** |
| **J. Partial Cut** | Partial paper cut executed at receipt termination | Partial cut executed cleanly without clipping barcode footer | **PASS** |

---

## 4. Preview vs Physical Output Comparison

| Attribute | PreviewScene / Flutter UI Preview | Physical Hardware Output (`Printer001-328F`) |
| :--- | :--- | :--- |
| **Typography** | TrueType vector fonts (Roboto/Inter) | Printer ROM Font A (12×24 dot matrix) |
| **Divider Rendering** | Continuous high-resolution 1px vector line | Monospaced ASCII hyphen glyphs (`-`) |
| **Right Alignment** | Pixel-exact proportional boundary | Monospaced character grid boundary (column 45/48) |
| **Visual Legibility** | High fidelity | Crisp, high-contrast, fully operational thermal receipt |

---

## 5. Summary & Verdict

The Portakal 1.2 Hybrid Layout path (`sequentialLabel` $\rightarrow$ `RowElement` / `DividerElement` $\rightarrow$ `StreamRowFormatter` $\rightarrow$ ESC/POS) is **physically validated and fully operational** on `Printer001-328F`.
