import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Flagship Commercial Invoice template (80mm × 100mm).
LabelBuilder buildInvoiceLabel() {
  final invoice = sequentialLabel(const LabelConfig(width: 80, height: 100, copies: 1));

  invoice
      // Corporate Header
      .row('PORTAKAL ENTERPRISES', 'INVOICE', size: 2, bold: true)
      .row('100 Silicon Way, Tech Park', 'No: INV-2026-001')
      .row('Tax ID: 9948-2810-01', 'Date: 2026-08-25')
      // Header Separator
      .divider();

  // Invoice Line Items Table
  final itemsTable = invoice.table(
    columns: [
      LabelColumn.flex(3),
      LabelColumn.flex(1, align: LabelTextAlign.center),
      LabelColumn.flex(1, align: LabelTextAlign.right),
      LabelColumn.flex(1, align: LabelTextAlign.right),
    ],
  );

  itemsTable
    ..row(['Description', 'Qty', 'Unit', 'Total'], bold: true)
    ..divider()
    ..row(['Thermal Printer 203 DPI', '2', r'$45.00', r'$90.00'])
    ..row(['Direct Thermal Labels (Roll)', '5', r'$8.00', r'$40.00'])
    ..row(['Barcode Scanner USB', '1', r'$35.00', r'$35.00']);

  invoice
      .divider()
      // Calculation Section
      .row('Subtotal:', r'$165.00')
      .row('Tax (10%):', r'$16.50')
      .row('TOTAL:', r'$181.50', bold: true, size: 2)
      .space(10);

  // Verification Barcode & QR Box (demonstrating exact coordinate escape hatch)
  invoice.box(const BoxOptions(x: 20, y: 530, width: 600, height: 160, thickness: 2));
  invoice.barcode(
    'INV2026001',
    BarcodeOptions.typed(
      x: 40,
      y: 555,
      symbology: BarcodeSymbology.code128,
      height: 60,
      readable: 1,
    ),
  );
  invoice.qrcode(
    'https://pay.portakal.io/inv/INV-2026-001',
    const QRCodeOptions(x: 470, y: 550, cellWidth: 3),
  );

  return invoice;
}

final invoiceCase = ExampleCase(
  id: 'invoice',
  title: 'Commercial Invoice (80×100mm)',
  description:
      'Standard enterprise invoice authored with sequential document flow, repeated column tables, financial totals, and exact QR/barcode verification block.',
  category: ExampleCategory.advanced,
  recommendedMedia: '80mm × 100mm',
  sourcePath: 'lib/src/examples/general/invoice_example.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildInvoiceLabel,
  quickSnippet: '''
final job = buildInvoiceLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
