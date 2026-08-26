import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Master carton and inventory stock label with Barcode and QR code (80mm × 50mm).
LabelBuilder buildInventoryItemLabel() {
  return label(const LabelConfig(width: 80, height: 50, copies: 1))
      .box(const BoxOptions(x: 10, y: 10, width: 620, height: 380, thickness: 2))
      // Product Name
      .text('USB-C TO HDMI ADAPTER 4K', const TextOptions(x: 25, y: 25, size: 2, bold: true))
      .line(const LineOptions(x1: 25, y1: 65, x2: 605, y2: 65, thickness: 1))
      // SKU, Lot, and Quantity Metadata
      .text('SKU: ADP-USBC-01', const TextOptions(x: 25, y: 80, size: 2, bold: true))
      .text('LOT: L20260801', const TextOptions(x: 25, y: 115, size: 1))
      .text('PKG QTY: 50 PCS', const TextOptions(x: 25, y: 145, size: 2, bold: true))
      .text('Origin: Factory 04', const TextOptions(x: 25, y: 185, size: 1))
      // Code128 Barcode
      .barcode(
        'ADP-USBC-01',
        BarcodeOptions.typed(
          x: 25,
          y: 220,
          symbology: BarcodeSymbology.code128,
          height: 70,
          readable: 1,
        ),
      )
      // WMS Inventory Asset QR Code
      .qrcode(
        'https://inv.portakal.internal/sku/ADP-USBC-01?lot=L20260801',
        const QRCodeOptions(x: 430, y: 85, cellWidth: 4),
      )
      .text('WMS Scan ID', const TextOptions(x: 450, y: 240, size: 1, bold: true))
      .line(const LineOptions(x1: 25, y1: 320, x2: 605, y2: 320, thickness: 1))
      .text('PORTAKAL SUPPLY CHAIN SYSTEMS', const TextOptions(x: 180, y: 340, size: 1));
}

final inventoryItemCase = ExampleCase(
  id: 'inventory_item_label',
  title: 'Inventory Item & Lot Tag',
  description:
      'Master carton and inventory label combining SKU identification, lot tracking number, batch quantity, Code128 barcode, and WMS lookup QR code.',
  category: ExampleCategory.warehouse,
  recommendedMedia: '80mm × 50mm',
  sourcePath: 'lib/src/examples/warehouse/inventory_item_label.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildInventoryItemLabel,
  quickSnippet: '''
final job = buildInventoryItemLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
