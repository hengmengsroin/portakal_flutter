# 🍊 Portakal Example Gallery & Hardware Validation Bench

Interactive Flutter developer utility featuring a **20-use-case practical gallery** and a **hardware validation test bench** for testing physical printers across all 9 Portakal protocols.

---

## 1. Running the Example Application

Launch the application on your preferred desktop, mobile, or web target:

```bash
# macOS Desktop
flutter run -d macos

# Windows Desktop
flutter run -d windows

# Android / iOS (requires Bluetooth permissions configured)
flutter run -d <device-id>
```

---

## 2. Example Use Case Gallery

The gallery contains **20 realistic, copyable printing templates** across 8 domains. Every example demonstrates the canonical **Preview-Before-Print** workflow:

```
Example Template (LabelBuilder)
       ↓
builder.resolve() (Immutable ResolvedLabel)
       ├── LabelPreview.resolved(job) (Flutter Visual Preview)
       └── compileExample(protocol, job) (Raw Uint8List Command Bytes)
             ↓
       Raw Byte & Hex Inspector / Hardware Print
```

### Use Case Catalog

| Category | Example | Media Size | Key Features | Tested Protocols |
| :--- | :--- | :--- | :--- | :--- |
| **Getting Started** | [Simple Text & Frame](lib/src/examples/general/simple_text_example.dart) | 60×40mm | Text positioning, bounding frame, divider line, QR code | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Retail** | [Retail Product Price Label](lib/src/examples/retail/retail_price_label.dart) | 40×30mm | Store branding, bold price emphasis, SKU, EAN-13 barcode | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Retail** | [Promotion & Discount Tag](lib/src/examples/retail/retail_promotion_label.dart) | 50×40mm | Reverse header, strike-through line composition, discount badge, Code128 | TSC, ZPL, EPL, CPCL |
| **Pharmacy** | [Medicine Price & Batch Label](lib/src/examples/pharmacy/medicine_price_label.dart) | 50×30mm | Amoxicillin dosage, batch ID, expiry date, price, Code128 | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Pharmacy** | [Prescription Dosage & Usage Label](lib/src/examples/pharmacy/medicine_usage_label.dart) | 70×50mm | Patient name, dosage frequency, treatment duration, Rx QR code | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Pharmacy** | [Warehouse Expiry Alert Label](lib/src/examples/pharmacy/expiry_stock_label.dart) | 60×40mm | Reverse alert banner, large expiration date, stock quantity, Code128 | TSC, ZPL, EPL, CPCL |
| **Restaurant** | [Kitchen Order Ticket (KOT)](lib/src/examples/restaurant/kitchen_ticket.dart) | 80mm Cont. | Large table ID, order timestamp, item modifiers, allergy alert box | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Restaurant** | [Customer Dining Receipt](lib/src/examples/restaurant/customer_receipt.dart) | 80mm Cont. | Column alignment, itemized totals, tax calculation, e-invoice QR | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Warehouse** | [Warehouse Location Bin Label](lib/src/examples/warehouse/location_bin_label.dart) | 100×50mm | Large bin ID (B12), aisle/rack hierarchy, Code128 rack barcode | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Warehouse** | [Inventory Item & Lot Tag](lib/src/examples/warehouse/inventory_item_label.dart) | 80×50mm | SKU, lot identifier, package quantity, Code128, WMS asset QR | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Logistics** | [Cross-Border Shipping Label](lib/src/examples/logistics/shipping_label.dart) | 100×150mm | Sender/consignee boxes, hub routing block, Code128, tracking QR | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Logistics** | [Compact Parcel Routing Tag](lib/src/examples/logistics/small_parcel_label.dart) | 60×40mm | Large destination hub code (DEST: KPC), route ID, parcel weight | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Tickets & Badges** | [Conference Admission Ticket](lib/src/examples/tickets/event_ticket.dart) | 80×50mm | Event branding, date/time, hall/seat, ticket number, gate QR | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Tickets & Badges** | [Service Queue Number Ticket](lib/src/examples/tickets/queue_ticket.dart) | 60mm Cont. | Oversized queue number (A-042), wait time, position, timestamp | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **Tickets & Badges** | [Visitor Attendance Badge](lib/src/examples/tickets/visitor_badge.dart) | 80×50mm | High-contrast reverse header, visitor/host details, validity date, QR | TSC, ZPL, EPL, CPCL |
| **Asset Management** | [IT Hardware Asset Tag](lib/src/examples/asset/asset_tag.dart) | 50×25mm | Reverse property banner, asset serial ID, department, asset QR | TSC, ZPL, EPL, CPCL |
| **General / Advanced** | [Structured Table & Column Layout](lib/src/examples/general/table_layout_example.dart) | 80×90mm | Multi-column table layout, mixed fixed/flex columns, alignment, divider thickness, Code128 | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL, Star PRNT, ESC/POS |
| **General / Advanced** | [Commercial Invoice](lib/src/examples/general/invoice_example.dart) | 80×100mm | Corporate header, multi-row line items, calculation totals, barcode, QR | TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL |
| **General / Advanced** | [Monochrome Logo & Branding](lib/src/examples/general/bitmap_logo_example.dart) | 60×40mm | Embedded 64×64 1-bit monochrome raster bitmap, barcode, QR | TSC, ZPL, EPL, CPCL, ESC/POS, Star PRNT |
| **General / Advanced** | [Multilingual & International Text](lib/src/examples/general/unicode_text_example.dart) | 70×50mm | English, French accents, Khmer, Japanese scripts with encoding guidance | ZPL (UTF-8) |

---

## 3. Developer Features in Detail Page

Each example screen offers:
- **Visual Preview (`LabelPreview.resolved`)**: Live canvas rendering with zoom and DPI resolution scaling.
- **Protocol Compiler & Code Generator**: Switch between all 9 printer languages (`TSC`, `ESC/POS`, `ZPL`, `EPL`, `CPCL`, `DPL`, `IPL`, `SBPL`, `Star PRNT`).
- **Honest Unsupported Feature UX**: Reports protocol limitations (e.g. geometric boxes on ESC/POS stream printers) using `UnsupportedFeaturePolicy.throwError`.
- **Raw Byte Inspector**: Displays exact byte counts, formatted hex dumps (`0000: 1B 40 ...`), ASCII diagnostic interpretation, and clipboard copy.
- **Hardware Printing**: Transmits compiled byte payloads over Bluetooth/USB via decoupled `HardwarePrinterTransport`.

---

## 4. Hardware Validation Bench

Tap the **Flask icon** in the Gallery AppBar to open the dedicated **Hardware Validation Bench** for Level 2 & Level 3 physical printer testing.

```
1. Select Protocol (ESC/POS, TSC, ZPL, EPL, CPCL, DPL, IPL, SBPL, Star PRNT)
        ↓
2. Connect Printer (Bluetooth Low Energy / USB / Network Transport)
        ↓
3. Run D00 Capability Probe
        ↓
4. Execute Protocol Feature Cases (Text, Code Pages, Barcode, QR, Raster, Copies)
        ↓
5. Scan & Verify Payloads (Physical Barcode Reader / Visual Inspection)
        ↓
6. Export Verified Session JSON (Telemetry, Diagnostics, Golden SHAs)
```
