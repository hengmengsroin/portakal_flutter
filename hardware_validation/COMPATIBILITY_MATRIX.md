# Portakal Hardware Compatibility Matrix

This document tracks physical hardware validation runs across supported thermal and label printer protocols.

## Status Legend
- **PASS**: Physically validated with Level 2 (command acceptance) and Level 3 (media output / barcode scan / visual verification).
- **PARTIAL**: Physically validated with Level 2 acceptance, but Level 3 exhibits minor dialect or hardware limitations.
- **FAIL**: Protocol commands rejected or corrupted by physical device.
- **N/S-DEVICE**: Protocol or feature not supported by the physical printer hardware/firmware.
- **N/T**: Not tested against physical hardware.

---

## Validated Hardware Matrix

| Device ID / Model | Manufacturer | Connection | Tested Protocol | Verified Dialect Scope | Status | Evidence Path |
| :--- | :--- | :--- | :--- | :--- | :---: | :--- |
| **`Printer001-328F`** | Unknown / Generic | BLE | **ESC/POS** | **ESC/POS Verified Subset**<br>(Text, CP437, Scaling, Code128, QR, Raster, Partial Cut, Reset) | **PASS** | [`hardware_validation/escpos/Printer001_328F/BLE/manifest.json`](escpos/Printer001_328F/BLE/manifest.json) |
| **`Printer001-328F`** | Unknown / Generic | BLE | **TSC** | **TSC / TSPL2 Verified Subset**<br>(Text, CP437/CP850/CP1252, Scaling, Code128, QR, Primitives, Raster, Copies, CLS) | **PASS** | [`hardware_validation/tsc/Printer001_328F/BLE/manifest.json`](tsc/Printer001_328F/BLE/manifest.json) |
| **`Printer001-328F`** | Unknown / Generic | BLE | **ZPL II** | **ZPL II Emulation**<br>(D00-ZPL Capability Probe: Literal `^XA` printed) | **N/S-DEVICE** | [`hardware_validation/zpl/Printer001_328F/BLE/manifest.json`](zpl/Printer001_328F/BLE/manifest.json) |

*Unified Device Profile: [`hardware_validation/devices/Printer001_328F/device.json`](devices/Printer001_328F/device.json)*

---

## Detailed Physical Validation Cases for Printer001-328F

### 1. ESC/POS Protocol Mode (Receipt Emulation) — PASS

| Case ID | Case Title | Bytes | SHA-256 | Level 2 (Device) | Level 3 (Physical) | Verified Feature Detail |
| :--- | :--- | :---: | :--- | :---: | :---: | :--- |
| **D00** | Pure ASCII Probe | 16 | `68b65287...` | **PASS** | **PASS** | Raw ASCII string printed cleanly without control commands |
| **D01** | Minimal ESC/POS Probe | 18 | `ec86cbca...` | **PASS** | **PASS** | `ESC @` reset accepted, ASCII string printed |
| **H01-NOCUT** | ASCII Baseline (No Cut) | 76 | `97194073...` | **PASS** | **PASS** | Center title, bold text, left alignment, 3 line feeds |
| **H01** | ASCII Baseline Canonical | 77 | `a10d4f8a...` | **PASS** | **PASS** | Receipt layout with partial cut |
| **H02-CP437** | CP437 Accented Characters | 44 | `7f75d33f...` | **PASS** | **PASS** | `ä ö ü ß ± °` visually verified with correct shapes |
| **H05** | Font Magnification | 75 | `68f079da...` | **PASS** | **PASS** | 1x, 2x, 4x width/height sizing verified |
| **H06** | 1D Barcode Code 128 | 58 | `b2149b14...` | **PASS** | **PASS** | Scanned payload matches exact `PORTAKAL123456` |
| **H07** | 2D QR Code | 82 | `4041b61c...` | **PASS** | **PASS** | Scanned payload matches exact URL `https://example.com/portakal-hw-test` |
| **H09** | 1-Bit Raster Bitmap (64×64) | 577 | `6fb45d9b...` (stream)<br>`5316b8b3...` (raw matrix) | **PASS** | **PASS** | 64×64 raster matrix verified (border, checkerboard, diagonal, stripes) |
| **H11** | Partial Paper Cut | 43 | `7bfcb9cb...` | **PASS** | **PASS** | `GS V` partial cut executed; paper feed intact, footer not clipped |
| **H12** | Reset / Initialize | 2 | `f5ca68c4...` | **PASS** | **N/A** | `ESC @` executed without fault; printer remained online |

---

### 2. TSC / TSPL2 Protocol Mode (Label Emulation) — PASS

| Case ID | Case Title | Bytes | SHA-256 | Level 2 (Device) | Level 3 (Physical) | Verified Feature Detail |
| :--- | :--- | :---: | :--- | :---: | :---: | :--- |
| **D00-TSC** | Minimal TSC Probe | 60 | `001a1db7...` | **PASS** | **PASS** | SIZE + CLS + TEXT + PRINT 1 minimal job |
| **H01** | ASCII Baseline | 165 | `678f23ec...` | **PASS** | **PASS** | Scalable resident font, 2x body text, exact coordinate placement |
| **H02-CP437** | CP437 Latin Encodings | 114 | `a01ec3a6...` | **PASS** | **PASS** | `ä ö ü ß ± °` visually verified |
| **H02-CP850** | CP850 Multilingual Latin-1 | 129 | `da15e985...` | **PASS** | **PASS** | `é à è ù ç ñ Á Í Ó` visually verified |
| **H02-CP1252** | CP1252 Windows 1252 | 133 | `9ec1106e...` | **PASS** | **PASS** | `é à è “ ” ‘ ’ © ®` visually verified |
| **H05** | Font Scaling (1x, 2x, 4x) | 169 | `f79f0477...` | **PASS** | **PASS** | 1x, 2x, 4x font scaling without clipping |
| **H06** | 1D Barcode Code 128 | 123 | `2b8ea4b0...` | **PASS** | **PASS** | Scanned payload matches exact `PORTAKAL123456` |
| **H07** | 2D QR Code | 140 | `1cb547b7...` | **PASS** | **PASS** | Scanned payload matches exact URL `https://example.com/portakal-hw-test` |
| **H08** | Drawing Primitives | 134 | `fb87be8b...` | **PASS** | **PASS** | BOX, BAR, and CIRCLE rendered crisply |
| **H09** | 1-Bit Raster Bitmap (64×64) | 631 | `743515de...` (stream)<br>`5316b8b3...` (raw matrix) | **PASS** | **PASS** | BITMAP command rendered with correct polarity and zero row skew |
| **H10** | Multiple Copies (3 Labels) | 104 | `ff636d93...` | **PASS** | **PASS** | `PRINT 1, 3` emitted; exactly 3 physical labels dispensed |
| **H12** | Initialization & CLS | 5 | `95a70659...` | **PASS** | **N/A** | CLS buffer clear executed; follow-up job printed cleanly |

---

### 3. ZPL II Protocol Mode (Capability Probe) — N/S-DEVICE

| Case ID | Case Title | Bytes | SHA-256 | Level 2 (Device) | Level 3 (Physical) | Verified Feature Detail |
| :--- | :--- | :---: | :--- | :---: | :---: | :--- |
| **D00-ZPL** | Minimal ZPL II Probe | 52 | `4b684949...` | **N/S-DEVICE** | **N/S-DEVICE** | Transmitted `^XA...^XZ` printed as literal text lines. Firmware lacks ZPL emulation. |

---

## Important Notice on Device Support
*Validation on `Printer001-328F` confirms dual-mode compatibility (ESC/POS and TSC/TSPL2 subsets) for this specific multi-emulation Bluetooth hardware. ZPL II emulation is not supported by this printer.*
