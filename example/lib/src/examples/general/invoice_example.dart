import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Flagship Commercial Invoice template (80mm × 100mm).
LabelBuilder buildInvoiceLabel() {
  return label(const LabelConfig(width: 80, height: 100, copies: 1))
      // Corporate Header
      .text('PORTAKAL ENTERPRISES', const TextOptions(x: 20, y: 25, size: 2, bold: true))
      .text('100 Silicon Way, Tech Park', const TextOptions(x: 20, y: 65, size: 1))
      .text('Tax ID: 9948-2810-01', const TextOptions(x: 20, y: 95, size: 1))
      // Invoice Metadata
      .text('INVOICE', const TextOptions(x: 430, y: 25, size: 3, bold: true))
      .text('No: INV-2026-001', const TextOptions(x: 430, y: 85, size: 1))
      .text('Date: 2026-08-25', const TextOptions(x: 430, y: 115, size: 1))
      // Header Separator
      .line(const LineOptions(x1: 20, y1: 150, x2: 620, y2: 150, thickness: 2))
      // Table Column Headers
      .text('Description', const TextOptions(x: 20, y: 170, size: 1, bold: true))
      .text('Qty', const TextOptions(x: 340, y: 170, size: 1, bold: true))
      .text('Unit', const TextOptions(x: 410, y: 170, size: 1, bold: true))
      .text('Total', const TextOptions(x: 520, y: 170, size: 1, bold: true))
      .line(const LineOptions(x1: 20, y1: 200, x2: 620, y2: 200, thickness: 1))
      // Item 1
      .text('Thermal Printer 203 DPI', const TextOptions(x: 20, y: 220, size: 1))
      .text('2', const TextOptions(x: 340, y: 220, size: 1))
      .text('\$45.00', const TextOptions(x: 410, y: 220, size: 1))
      .text('\$90.00', const TextOptions(x: 520, y: 220, size: 1))
      // Item 2
      .text('Direct Thermal Labels (Roll)', const TextOptions(x: 20, y: 260, size: 1))
      .text('5', const TextOptions(x: 340, y: 260, size: 1))
      .text('\$8.00', const TextOptions(x: 410, y: 260, size: 1))
      .text('\$40.00', const TextOptions(x: 520, y: 260, size: 1))
      // Item 3
      .text('Barcode Scanner USB', const TextOptions(x: 20, y: 300, size: 1))
      .text('1', const TextOptions(x: 340, y: 300, size: 1))
      .text('\$35.00', const TextOptions(x: 410, y: 300, size: 1))
      .text('\$35.00', const TextOptions(x: 520, y: 300, size: 1))
      // Calculation Section
      .line(const LineOptions(x1: 20, y1: 350, x2: 620, y2: 350, thickness: 1))
      .text('Subtotal:', const TextOptions(x: 410, y: 375, size: 1))
      .text('\$165.00', const TextOptions(x: 520, y: 375, size: 1))
      .text('Tax (10%):', const TextOptions(x: 410, y: 410, size: 1))
      .text('\$16.50', const TextOptions(x: 520, y: 410, size: 1))
      .text('TOTAL:', const TextOptions(x: 410, y: 455, size: 2, bold: true))
      .text('\$181.50', const TextOptions(x: 520, y: 455, size: 2, bold: true))
      // Verification Barcode & QR Box
      .box(const BoxOptions(x: 20, y: 530, width: 600, height: 160, thickness: 2))
      .barcode(
        'INV2026001',
        const BarcodeOptions(
          x: 40,
          y: 555,
          type: '128',
          height: 60,
          readable: 1,
        ),
      )
      .qrcode(
        'https://pay.portakal.io/inv/INV-2026-001',
        const QRCodeOptions(x: 470, y: 550, cellWidth: 3),
      );
}

final invoiceCase = ExampleCase(
  id: 'invoice',
  title: 'Commercial Invoice (80×100mm)',
  description:
      'Standard enterprise invoice with corporate header, multi-row line items, calculation totals, Code128 barcode, and payment QR.',
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
