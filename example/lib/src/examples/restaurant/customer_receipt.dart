import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Customer dining and retail POS receipt (80mm media).
LabelBuilder buildCustomerReceiptLabel() {
  return label(const LabelConfig(width: 80, height: 80, copies: 1))
      // Brand Header
      .text('PORTAKAL CAFE', const TextOptions(x: 210, y: 20, size: 2, bold: true))
      .text('Riverside Blvd, Phnom Penh', const TextOptions(x: 215, y: 55, size: 1))
      .text('Tel: +855 23 888 999', const TextOptions(x: 240, y: 80, size: 1))
      .line(const LineOptions(x1: 20, y1: 105, x2: 620, y2: 105, thickness: 1))
      // Transaction Info
      .text('Receipt: #POS-8821', const TextOptions(x: 20, y: 120, size: 1))
      .text('Date: 2026-08-25 14:32', const TextOptions(x: 420, y: 120, size: 1))
      .line(const LineOptions(x1: 20, y1: 145, x2: 620, y2: 145, thickness: 1))
      // Item List
      .text('1 x Iced Latte (Large)', const TextOptions(x: 20, y: 165, size: 1, bold: true))
      .text('\$2.50', const TextOptions(x: 550, y: 165, size: 1))
      .text('1 x Butter Croissant', const TextOptions(x: 20, y: 195, size: 1, bold: true))
      .text('\$2.00', const TextOptions(x: 550, y: 195, size: 1))
      .text('1 x Mineral Water 500ml', const TextOptions(x: 20, y: 225, size: 1, bold: true))
      .text('\$1.00', const TextOptions(x: 550, y: 225, size: 1))
      .line(const LineOptions(x1: 20, y1: 260, x2: 620, y2: 260, thickness: 1))
      // Calculation Summary
      .text('Subtotal:', const TextOptions(x: 400, y: 275, size: 1))
      .text('\$5.50', const TextOptions(x: 550, y: 275, size: 1))
      .text('VAT / Tax (10%):', const TextOptions(x: 400, y: 300, size: 1))
      .text('\$0.55', const TextOptions(x: 550, y: 300, size: 1))
      .text('TOTAL:', const TextOptions(x: 400, y: 330, size: 2, bold: true))
      .text('\$6.05', const TextOptions(x: 530, y: 330, size: 2, bold: true))
      .line(const LineOptions(x1: 20, y1: 370, x2: 620, y2: 370, thickness: 1))
      // Tender & Payment
      .text('Payment: CASH USD', const TextOptions(x: 20, y: 385, size: 1))
      .text('Tendered: \$10.00', const TextOptions(x: 20, y: 410, size: 1))
      .text('Change: \$3.95', const TextOptions(x: 20, y: 435, size: 1, bold: true))
      // Digital Invoice QR Code
      .text('Scan for electronic tax receipt:', const TextOptions(x: 20, y: 475, size: 1))
      .qrcode(
        'https://receipt.portakal.io/r/POS-8821',
        const QRCodeOptions(x: 480, y: 440, cellWidth: 3),
      )
      .text('Thank you for dining with us!', const TextOptions(x: 210, y: 550, size: 1, bold: true));
}

final customerReceiptCase = ExampleCase(
  id: 'customer_receipt',
  title: 'Customer Dining Receipt',
  description:
      'Itemized customer dining receipt featuring formatted item rows, tax computations, cash tender details, and an e-invoice QR code.',
  category: ExampleCategory.restaurant,
  recommendedMedia: '80mm Continuous',
  sourcePath: 'lib/src/examples/restaurant/customer_receipt.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildCustomerReceiptLabel,
  quickSnippet: '''
final job = buildCustomerReceiptLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
