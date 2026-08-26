import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Flagship Logistics & Courier Shipping Label (100mm × 150mm).
LabelBuilder buildShippingLabel() {
  return label(const LabelConfig(width: 100, height: 150, copies: 1))
      // Main Boundary Frame
      .box(const BoxOptions(x: 10, y: 10, width: 780, height: 1180, thickness: 3))
      // Courier Header
      .text('PORTAKAL EXPRESS', const TextOptions(x: 30, y: 30, size: 3, bold: true))
      .text('PRIORITY AIR / GROUND', const TextOptions(x: 480, y: 35, size: 2, bold: true))
      .line(const LineOptions(x1: 10, y1: 85, x2: 790, y2: 85, thickness: 2))
      // FROM (Shipper) Section Box
      .text('FROM / SHIPPER:', const TextOptions(x: 30, y: 105, size: 1, bold: true))
      .text('Portakal Fulfillment Central', const TextOptions(x: 30, y: 130, size: 2, bold: true))
      .text('100 Logistics Boulevard, Suite 400', const TextOptions(x: 30, y: 165, size: 1))
      .text('Phnom Penh, Cambodia 12000', const TextOptions(x: 30, y: 195, size: 1))
      .text('Phone: +855 23 999 111', const TextOptions(x: 30, y: 225, size: 1))
      .line(const LineOptions(x1: 10, y1: 260, x2: 790, y2: 260, thickness: 2))
      // TO (Consignee) Section Box
      .text('SHIP TO / CONSIGNEE:', const TextOptions(x: 30, y: 280, size: 1, bold: true))
      .text('SOK DARA', const TextOptions(x: 30, y: 310, size: 3, bold: true))
      .text('House #42, Street 7', const TextOptions(x: 30, y: 360, size: 2))
      .text('Sangkat Svay Dangkum', const TextOptions(x: 30, y: 395, size: 2))
      .text('SIEM REAP, CAMBODIA 17252', const TextOptions(x: 30, y: 435, size: 2, bold: true))
      .text('Phone: +855 12 345 678', const TextOptions(x: 30, y: 475, size: 2))
      .line(const LineOptions(x1: 10, y1: 520, x2: 790, y2: 520, thickness: 2))
      // Routing & Destination Sort Block
      .box(const BoxOptions(x: 30, y: 540, width: 740, height: 110, thickness: 2))
      .text('DEST HUB: REP-01', const TextOptions(x: 50, y: 555, size: 3, bold: true))
      .text('SORT ROUTE: NW-04', const TextOptions(x: 460, y: 555, size: 3, bold: true))
      .text('SERVICE LEVEL: EXPRESS NEXT-DAY', const TextOptions(x: 50, y: 610, size: 1, bold: true))
      .text('WEIGHT: 2.85 KG (BILLABLE: 3.0 KG)', const TextOptions(x: 460, y: 610, size: 1))
      .line(const LineOptions(x1: 10, y1: 670, x2: 790, y2: 670, thickness: 2))
      // Tracking Number & Large Barcode
      .text('TRACKING #:', const TextOptions(x: 30, y: 690, size: 1, bold: true))
      .text('PKL202608250001', const TextOptions(x: 30, y: 720, size: 3, bold: true))
      .barcode(
        'PKL202608250001',
        BarcodeOptions.typed(
          x: 40,
          y: 780,
          symbology: BarcodeSymbology.code128,
          height: 150,
          readable: 1,
        ),
      )
      .line(const LineOptions(x1: 10, y1: 990, x2: 790, y2: 990, thickness: 2))
      // QR Code Tracking & Handling Notes
      .text('Scan for real-time proof of delivery and GPS routing:', const TextOptions(x: 30, y: 1010, size: 1))
      .text('SPECIAL HANDLING: FRAGILE / KEEP DRY', const TextOptions(x: 30, y: 1045, size: 1, bold: true))
      .text('Portakal Express Global Network - 2026', const TextOptions(x: 30, y: 1130, size: 1))
      .qrcode(
        'https://track.portakal.io/PKL202608250001',
        const QRCodeOptions(x: 600, y: 1010, cellWidth: 4),
      );
}

final shippingCase = ExampleCase(
  id: 'shipping_label',
  title: 'Cross-Border Shipping Label (100×150mm)',
  description:
      'Comprehensive courier logistics label with sender/recipient address blocks, destination hub routing box, Code128 tracking barcode, and proof-of-delivery QR code.',
  category: ExampleCategory.logistics,
  recommendedMedia: '100mm × 150mm',
  sourcePath: 'lib/src/examples/logistics/shipping_label.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildShippingLabel,
  quickSnippet: '''
final job = buildShippingLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
