# Portakal Universal Hardware Validation Bench

Interactive Flutter developer utility for physical printer testing and Level 2 / Level 3 evidence collection across all 9 Portakal-supported printer protocols.

---

## 1. Purpose

The Portakal Hardware Validation Bench provides a clean, transport-decoupled harness to execute deterministic protocol command streams against real thermal and label printers.

### Supported Protocols:
1. **ESC/POS** (`EscPosPrinter` — Epson standard thermal receipt protocol)
2. **TSC / TSPL2** (`TscPrinter` — TSC label and receipt printer protocol)
3. **ZPL II** (`ZplPrinter` — Zebra Programming Language II)
4. **EPL2** (`EplPrinter` — Eltron Programming Language 2)
5. **CPCL** (`CpclPrinter` — Comtec / Zebra Mobile receipt & label protocol)
6. **DPL** (`DplPrinter` — Datamax Programming Language with CR endings)
7. **IPL** (`IplPrinter` — Intermec Printer Language with F90–F99 format lifecycle)
8. **SBPL** (`SbplPrinter` — SATO Barcode Printer Language with ESC A / ESC Z)
9. **Star Line / PRNT** (`StarPrntPrinter` — Star Micronics Line Mode protocol)

---

## 2. Developer Validation Workflow

```
1. Select Protocol (Dropdown)
        ↓
2. Connect Printer (Bluetooth / BLE / USB Transport)
        ↓
3. Run D00 Capability Probe
        ↓
4. Evaluate Output (PASS or N/S-DEVICE)
        ↓
5. Execute Protocol Feature Cases (Text, Encodings, Barcode, QR, Raster, Copies)
        ↓
6. Scan & Verify Payloads (Barcode / QR Barcode Reader)
        ↓
7. Export Verified Session JSON (Telemetry, Diagnostics, Golden SHAs)
```

### Important Protocol Capability Rule:
> [!WARNING]
> **A successful transport write does NOT automatically prove protocol support.**
> Low-cost POS or dual-mode printers may accept raw bytes over BLE without throwing a transport error, but will print unparsed command text (e.g. literal `^XA...^XZ` or `! 0 200 200...`) or ignore control sequences if the internal firmware lacks the corresponding command interpreter.
>
> Always run the **D00 Capability Probe** first and verify physical output before running complex layout cases.

---

## 3. Architecture & Separation of Concerns

```
Protocol Validation Suite (example)
        ↓
Portakal Native Builders (packages/portakal_core)
        ↓
Uint8List Command Bytes (Exact Binary Stream)
        ↓
HardwarePrinterTransport (flutter_thermal_printer / Transport Layer)
        ↓
Physical Hardware (BLE / USB / Network)
```

- **`packages/portakal_core`**: Responsible solely for protocol command generation and binary semantics.
- **`HardwarePrinterTransport`**: Decoupled transport layer responsible for discovery, connection, and raw byte transmission.
- **`example` App**: Responsible for UI, protocol switching, diagnostics, golden SHA verification, operator evaluation, and JSON evidence export.
