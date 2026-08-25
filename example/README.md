# Portakal Universal Hardware Validation Bench

Interactive Flutter developer utility for physical printer testing and Level 2 / Level 3 evidence collection across all 9 Portakal-supported printer protocols.

> [!NOTE]
> This application is an **interactive test bench and evidence harness** for developers and QA engineers. It is not a runtime dependency for apps integrating `portakal_core` or `portakal_flutter`.

---

## 1. Running the Validation Bench

Launch the interactive bench on your preferred desktop or mobile target:

```bash
# macOS Desktop
flutter run -d macos -t example/lib/main.dart

# Windows Desktop
flutter run -d windows -t example/lib/main.dart

# Android / iOS (requires Bluetooth permissions configured)
flutter run -d <device-id> -t example/lib/main.dart
```

---

## 2. Developer Validation Workflow

```
1. Select Protocol (ESC/POS, TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL, Star)
        ↓
2. Connect Printer (Bluetooth Low Energy / USB / Network Transport)
        ↓
3. Run D00 Capability Probe
        ↓
4. Evaluate Output (PASS or N/S-DEVICE)
        ↓
5. Execute Protocol Feature Cases (Text, Code Pages, Barcode, QR, Raster, Copies)
        ↓
6. Scan & Verify Payloads (Physical Barcode Reader / Visual Inspection)
        ↓
7. Export Verified Session JSON (Telemetry, Diagnostics, Golden SHAs)
```

---

## 3. Important Protocol Capability Warning

> [!WARNING]
> **A successful transport write does NOT automatically prove protocol support.**
>
> Many low-cost POS or dual-mode label printers accept raw bytes over Bluetooth or USB without throwing a transport error, but will print unparsed command text (e.g. literal `^XA...^XZ` or `! 0 200 200...`) or ignore control sequences if the internal firmware lacks that protocol's command interpreter.
>
> Always run the **D00 Capability Probe** first and verify physical output before running complex layout cases.

---

## 4. Architecture & Decoupling

```
Protocol Validation Suite (example)
        ↓
Portakal Native Builders (packages/portakal_core)
        ↓
Uint8List Command Bytes (Exact Binary Stream)
        ↓
HardwarePrinterTransport (Transport Layer)
        ↓
Physical Hardware (BLE / USB / TCP Port 9100)
```

- **`packages/portakal_core`**: Responsible solely for protocol command generation and binary semantics.
- **`HardwarePrinterTransport`**: Decoupled transport layer responsible for discovery, connection, and raw byte transmission.
- **`example` App**: Responsible for UI, protocol switching, diagnostics, golden SHA verification, operator evaluation, and JSON evidence export.
