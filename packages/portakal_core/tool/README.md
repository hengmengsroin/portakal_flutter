# Portakal Hardware Validation Harness

Deterministic command-stream generator for physical and emulated printer hardware validation across all 9 supported printer languages (**TSC, ESC/POS, ZPL II, EPL2, CPCL, DPL, IPL, SBPL, Star Line Mode**).

---

## Purpose

The harness generates deterministic, reproducible binary command artifacts (`.bin`), formatted hex dumps (`.hex`), and structured evidence manifests (`.json`) for each test case without coupling to a network, USB, or Bluetooth transport stack.

---

## CLI Usage

### Generate a Single Test Case

```bash
dart run tool/hardware_cases.dart --protocol zpl --case H07 --output ./out/zpl
```

Produces:
- `out/zpl/H07.bin` — exact binary command stream
- `out/zpl/H07.hex` — 16-byte offset hex dump
- `out/zpl/H07.json` — evidence seed manifest with SHA-256 and expected payload

### Generate All Cases for a Protocol

```bash
dart run tool/hardware_cases.dart --protocol escpos --all --output ./out/escpos
```

Generates all supported test cases for the protocol along with `out/escpos/manifest.json`.

### List Test Cases and Support Status

```bash
dart run tool/hardware_cases.dart --list
```

Or for a specific protocol:

```bash
dart run tool/hardware_cases.dart --list --protocol tsc
```

---

## Supported Case Taxonomy

| Case ID | Feature Scope | Description |
| :--- | :--- | :--- |
| **`H01`** | Text & Alignment | ASCII text formatting (`PORTAKAL 123 ABC xyz`) with test header. |
| **`H02-CPxxx`** | Code Page Encoding | Parameterized international character sets (`CP437`, `CP858`, `CP850`, `CP1252`, `CP857`, `CP866`, `UTF8`). |
| **`H04`** | Rotation | 0°, 90°, 180°, 270° orientation commands. |
| **`H05`** | Font Scaling | 1x normal, 2x medium, 4x large magnification multipliers. |
| **`H06`** | 1D Barcode | Code 128 symbology (`PORTAKAL123456`). |
| **`H07`** | 2D QR Code | QR Code payload (`https://example.com/portakal-hw-test`). |
| **`H08`** | Primitives | Box rectangles, lines, and circles. |
| **`H09`** | Raster Bitmap | Canonical 64×64 1-bit bitmap fixture. |
| **`H10`** | Multi-Copy Batch | Print batch / copies configuration. |
| **`H11`** | Cutter | Paper cut commands (ESC/POS, Star). |
| **`H12`** | Reset / Framing | Printer hardware initialization / clear commands. |

---

## Safety Policy & Controls

1. **Transport Isolation:** Tooling generates static files on disk; no network sockets, USB endpoints, or Bluetooth connections are opened.
2. **IPL NVRAM Protection:** IPL test cases strictly use reserved format slots **`F90`–`F99`** to prevent overwriting user formats stored in printer memory.
3. **Actuator Safety:** Cash drawer kick pulses are omitted from automated generation.

---

## Physical Hardware Execution Pipeline

```
Portakal Harness ──▶ <case>.bin ──▶ Raw Delivery (nc / lpr / cat) ──▶ Physical Printer
                                                                           │
                                                                           ▼
Evidence Record  ◀── Scan/Photo Capture ◀── Visual/Barcode Verification ────┘
```

For TCP printers:
```bash
nc -w 3 192.168.1.100 9100 < out/zpl/H07.bin
```
