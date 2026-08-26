import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// High-visibility warehouse expiry stock alert label (60mm × 40mm).
LabelBuilder buildExpiryStockLabel() {
  return label(const LabelConfig(width: 60, height: 40, copies: 1))
      // Reverse Alert Header Block
      .box(const BoxOptions(x: 10, y: 10, width: 460, height: 42, thickness: 2))
      .text('EXPIRY ALERT', const TextOptions(x: 130, y: 18, size: 2, bold: true))
      .reverse(const ReverseOptions(x: 10, y: 10, width: 460, height: 42))
      // Drug & Stock Details
      .text('Paracetamol 500mg', const TextOptions(x: 20, y: 65, size: 2, bold: true))
      .text('Batch: PCM-2401', const TextOptions(x: 20, y: 105, size: 1))
      .text('Stock Qty: 24 Boxes', const TextOptions(x: 260, y: 105, size: 1, bold: true))
      .line(const LineOptions(x1: 20, y1: 135, x2: 460, y2: 135, thickness: 1))
      // Prominent Expiration Warning
      .text('EXPIRES: 15 SEP 2026', const TextOptions(x: 20, y: 150, size: 2, bold: true))
      // Tracking Barcode
      .barcode(
        'PCM-2401-EXP',
        BarcodeOptions.typed(
          x: 40,
          y: 195,
          symbology: BarcodeSymbology.code128,
          height: 60,
          readable: 1,
        ),
      )
      .text('Action: Prioritize FIFO Dispatch', const TextOptions(x: 80, y: 285, size: 1));
}

final expiryStockCase = ExampleCase(
  id: 'expiry_stock_label',
  title: 'Warehouse Expiry Alert Label',
  description:
      'High-visibility inventory alert utilizing monochrome reverse styling, prominent expiration date, batch ID, package quantity, and Code128 barcode.',
  category: ExampleCategory.pharmacy,
  recommendedMedia: '60mm × 40mm',
  sourcePath: 'lib/src/examples/pharmacy/expiry_stock_label.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
  },
  buildLabel: buildExpiryStockLabel,
  quickSnippet: '''
final job = buildExpiryStockLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
