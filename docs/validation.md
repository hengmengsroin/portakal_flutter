# Hardware Validation & Evidence Framework

To eliminate guesswork and avoid misleading compatibility claims, Portakal uses a deterministic 3-level hardware validation framework.

---

## 1. The 3-Level Verification Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│ Level 1: Byte Verified (Automated Suite)                    │
│ Exact binary stream output matches golden SHA-256 hashes    │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Level 2: Device Command Acceptance (Real Printer)           │
│ Firmware parses command stream without fault or buffer stall│
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Level 3: Physical Output Verified (Laser Scan & Visual)     │
│ Barcode reader decodes payload; layout & typography verified│
└─────────────────────────────────────────────────────────────┘
```

### Verification Status Definitions
- **`PASS`**: Physically validated through Level 2 (command acceptance) and Level 3 (media feed, optical scan, visual clarity).
- **`PARTIAL`**: Level 2 command acceptance succeeded, but Level 3 physical output exhibited minor dialect or formatting differences.
- **`FAIL`**: Stream resulted in command syntax error, printer lockup, or corrupted output.
- **`N/T`**: Not tested on physical hardware yet.
- **`N/S-SDK`**: Feature not currently supported in Portakal SDK (e.g. DPL raster).
- **`N/S-DEVICE`**: Feature or protocol emulation not supported in printer firmware (e.g. ZPL on generic non-Zebra devices).

> [!WARNING]
> **A successful transport write does NOT constitute Level 2 validation.**
>
> Many thermal printers accept arbitrary byte streams over Bluetooth or USB without throwing a write error, but will print raw command text (e.g. literal `^XA...^XZ` or `! 0 200...`) or ignore formatting if the firmware lacks that protocol's command interpreter.

---

## 2. The D00 Capability Probe

Before executing complex multi-element labels, always run a **D00 Capability Probe** for that protocol.

A D00 probe tests whether the printer firmware actually recognizes and interprets the protocol's framing commands or simply prints them as unformatted text:

```dart
// Example: D00 Probe for ESC/POS
final probe = EscPosPrinter()
  ..initialize()
  ..text('ESC/POS D00 PROBE')
  ..feedLines(2);

final Uint8List probeBytes = probe.toBytes();
```

---

## 3. Offline Deterministic Test Harness (`tool/hardware_cases.dart`)

Portakal includes a pure-Dart CLI tool to generate deterministic test cases, hex dumps, and evidence manifests:

```bash
# Generate a specific test case (e.g. H06 Barcode for ZPL)
dart run packages/portakal_core/tool/hardware_cases.dart --protocol zpl --case H06 --output ./out/zpl

# Generate all test cases for ESC/POS
dart run packages/portakal_core/tool/hardware_cases.dart --protocol escpos --all --output ./out/escpos

# List all test cases and status
dart run packages/portakal_core/tool/hardware_cases.dart --list
```

### Artifacts Produced:
- `<case>.bin`: The exact raw binary byte payload sent to the printer.
- `<case>.hex`: 16-byte offset hex dump for visual inspection.
- `<case>.json`: Metadata manifest containing payload, SHA-256 hash, and parameters.
