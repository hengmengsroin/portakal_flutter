# Hardware Compatibility & Validation Evidence

This document tracks physical printer models and protocol validation evidence collected using the Portakal Hardware Validation Bench.

---

## 1. Verified Hardware Models

| Printer Model | Connection | Protocol | Verified Dialect Scope | Status | Evidence Path |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **`Printer001-328F`** | BLE | **ESC/POS** | Text, CP437, Scaling (1x/2x/4x), Code128 barcode, QR Code, 64×64 Raster, Partial Cut, Reset | **PASS** | [`hardware_validation/escpos/Printer001_328F/BLE/manifest.json`](../hardware_validation/escpos/Printer001_328F/BLE/manifest.json) |
| **`Printer001-328F`** | BLE | **TSC (TSPL2)** | Text, CP437/CP850/CP1252, Scaling, Code128, QR Code, BOX/BAR/CIRCLE primitives, BITMAP raster, Copies, CLS | **PASS** | [`hardware_validation/tsc/Printer001_328F/BLE/manifest.json`](../hardware_validation/tsc/Printer001_328F/BLE/manifest.json) |
| **`Printer001-328F`** | BLE | **ZPL II** | D00-ZPL Capability Probe: Literal `^XA` printed. Firmware lacks ZPL emulation. | **N/S-DEVICE** | [`hardware_validation/zpl/Printer001_328F/BLE/manifest.json`](../hardware_validation/zpl/Printer001_328F/BLE/manifest.json) |

*Full Device Profile: [`hardware_validation/devices/Printer001_328F/device.json`](../hardware_validation/devices/Printer001_328F/device.json)*

---

## 2. Detailed Physical Test Cases (`Printer001-328F`)

### 1. ESC/POS Protocol Mode (Receipt Emulation) — PASS
- **D00 / D01 Probes**: Raw ASCII and `ESC @` reset accepted cleanly.
- **H01 Baseline**: Bold text, center alignment, line feeds, and partial paper cut.
- **H02 International Characters**: CP437 accented characters (`ä ö ü ß ± °`) rendered with correct glyph shapes.
- **H05 Magnification**: 1x, 2x, and 4x width/height multipliers verified.
- **H06 1D Barcode**: Code 128 barcode scanned with exact payload `PORTAKAL123456`.
- **H07 2D QR Code**: QR Code scanned with exact URL `https://example.com/portakal-hw-test`.
- **H09 Raster Bitmap**: 64×64 1-bit raster graphic printed with zero row skew.
- **H11 Paper Cutter**: `GS V` partial cut executed cleanly without cutting into receipt footer.

### 2. TSC / TSPL2 Protocol Mode (Label Emulation) — PASS
- **D00-TSC Probe**: `SIZE` + `GAP` + `CLS` + `TEXT` + `PRINT 1` minimal label executed.
- **H01 Baseline**: Resident scalable font placed at exact dot coordinates.
- **H02 Code Pages**: CP437, CP850 (`é à è ù ç ñ`), and CP1252 (`“ ” © ®`) visually verified.
- **H06 / H07 Barcode & QR**: Code 128 and QR Code laser-scanned with verified payloads.
- **H08 Primitives**: `BOX`, `BAR`, and `CIRCLE` commands rendered crisply.
- **H09 1-Bit BITMAP**: Binary-safe raster image rendered with correct polarity and alignment.
- **H10 Multi-Copy Batch**: `PRINT 1, 3` dispensed exactly 3 physical labels.

### 3. ZPL II Protocol Mode — N/S-DEVICE
- **D00-ZPL Probe**: Transmitted `^XA...^XZ` bytes printed as raw textual lines.
- **Reason**: The physical printer model tested is a dual-mode ESC/POS + TSPL2 printer without ZPL II emulation firmware. This is documented as `N/S-DEVICE` (device-level limitation, not an SDK defect).

---

## 3. Submitting Community Hardware Evidence

If you validate Portakal on additional printer models, you can export session evidence directly from the `example` application and submit a PR with:
1. `manifest.json` exported from the validation bench.
2. Photo of the physical printout and barcode scan confirmation.
3. Updated row in [`COMPATIBILITY_MATRIX.md`](../hardware_validation/COMPATIBILITY_MATRIX.md).
