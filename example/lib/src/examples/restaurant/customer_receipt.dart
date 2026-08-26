import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Customer dining and retail POS receipt (80mm media) authored using sequential document layout.
LabelBuilder buildCustomerReceiptLabel() {
  final receipt = sequentialLabel(const LabelConfig(width: 80, height: 80, copies: 1));

  receipt
      // Brand Header
      .text('PORTAKAL CAFE', const TextOptions(size: 2, bold: true))
      .text('Riverside Blvd, Phnom Penh', const TextOptions(size: 1))
      .text('Tel: +855 23 888 999', const TextOptions(size: 1))
      .divider()
      // Transaction Info
      .row('Receipt: #POS-8821', 'Date: 2026-08-25 14:32')
      .divider();

  // Item List using table
  final itemsTable = receipt.table(
    columns: [
      LabelColumn.flex(3),
      LabelColumn.flex(1, align: LabelTextAlign.right),
    ],
  );

  itemsTable
    ..row(['1 x Iced Latte (Large)', r'$2.50'], bold: true)
    ..row(['1 x Butter Croissant', r'$2.00'], bold: true)
    ..row(['1 x Mineral Water 500ml', r'$1.00'], bold: true);

  receipt
      .divider()
      // Calculation Summary
      .row('Subtotal:', r'$5.50')
      .row('VAT / Tax (10%):', r'$0.55')
      .row('TOTAL:', r'$6.05', bold: true, size: 2)
      .divider()
      // Tender & Payment
      .row('Payment:', 'CASH USD')
      .row('Tendered:', r'$10.00')
      .row('Change:', r'$3.95', bold: true)
      .space(10)
      // Digital Invoice QR Code (demonstrating exact coordinate escape hatch in sequential document)
      .text('Scan for electronic tax receipt:', const TextOptions(size: 1));

  receipt.qrcode(
    'https://receipt.portakal.io/r/POS-8821',
    const QRCodeOptions(x: 480, y: 440, cellWidth: 3),
  );

  receipt.text('Thank you for dining with us!', const TextOptions(x: 210, y: 550, size: 1, bold: true));

  return receipt;
}

final customerReceiptCase = ExampleCase(
  id: 'customer_receipt',
  title: 'Customer Dining Receipt',
  description:
      'Itemized customer dining receipt authored with sequential document flow, semantic dividers, item table, and tax computations.',
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
