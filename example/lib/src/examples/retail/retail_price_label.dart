import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Flagship Retail Shelf Price Label (40mm × 30mm).
LabelBuilder buildRetailPriceLabel() {
  return label(const LabelConfig(width: 40, height: 30, copies: 1))
      // Store Branding Header
      .text('PORTAKAL MART', const TextOptions(x: 15, y: 15, size: 1, bold: true))
      .line(const LineOptions(x1: 15, y1: 38, x2: 305, y2: 38, thickness: 1))
      // Product Name and Unit
      .text('Organic Whole Milk', const TextOptions(x: 15, y: 48, size: 1, bold: true))
      .text('Volume: 1 Liter', const TextOptions(x: 15, y: 72, size: 1))
      // Price Emphasis
      .text('\$3.50', const TextOptions(x: 195, y: 45, size: 3, bold: true))
      // SKU Identifier
      .text('SKU: MILK-001', const TextOptions(x: 15, y: 105, size: 1))
      // EAN-13 Product Barcode
      .barcode(
        '1234567890128',
        const BarcodeOptions(
          x: 20,
          y: 130,
          type: 'EAN13',
          height: 60,
          readable: 1,
        ),
      )
      .line(const LineOptions(x1: 15, y1: 220, x2: 305, y2: 220, thickness: 1))
      .text('Tax Included  -  Direct Thermal', const TextOptions(x: 40, y: 226, size: 1));
}

final retailPriceCase = ExampleCase(
  id: 'retail_price_label',
  title: 'Retail Product Price Label',
  description:
      'Standard 40×30mm shelf price tag featuring store branding, product volume, prominent price styling, SKU, and EAN-13 barcode.',
  category: ExampleCategory.retail,
  recommendedMedia: '40mm × 30mm',
  sourcePath: 'lib/src/examples/retail/retail_price_label.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildRetailPriceLabel,
  quickSnippet: '''
final job = buildRetailPriceLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
