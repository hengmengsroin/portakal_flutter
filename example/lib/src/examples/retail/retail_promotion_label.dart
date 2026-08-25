import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Retail promotional clearance/sale tag with reverse header and strike-through line.
LabelBuilder buildRetailPromotionLabel() {
  return label(const LabelConfig(width: 50, height: 40, copies: 1))
      // Reverse Header Block
      .box(const BoxOptions(x: 10, y: 10, width: 380, height: 40, thickness: 2))
      .text('SPECIAL OFFER', const TextOptions(x: 100, y: 18, size: 2, bold: true))
      .reverse(const ReverseOptions(x: 10, y: 10, width: 380, height: 40))
      // Product Name & Weight
      .text('Arabica Coffee Beans', const TextOptions(x: 15, y: 60, size: 1, bold: true))
      .text('500g Whole Bean', const TextOptions(x: 15, y: 85, size: 1))
      // Original Price with Strike-Through Line composition
      .text('WAS \$12.00', const TextOptions(x: 15, y: 115, size: 1))
      .line(const LineOptions(x1: 15, y1: 125, x2: 120, y2: 125, thickness: 2))
      // Promotional Price & Discount Badge Box
      .text('NOW \$9.99', const TextOptions(x: 15, y: 140, size: 2, bold: true))
      .box(const BoxOptions(x: 230, y: 105, width: 150, height: 45, thickness: 2))
      .text('SAVE 17%', const TextOptions(x: 245, y: 115, size: 2, bold: true))
      // Promotional Code128 Barcode
      .barcode(
        'PROMO-CF99',
        const BarcodeOptions(
          x: 25,
          y: 200,
          type: '128',
          height: 60,
          readable: 1,
        ),
      )
      .text('Valid while supplies last', const TextOptions(x: 90, y: 290, size: 1));
}

final retailPromotionCase = ExampleCase(
  id: 'retail_promotion_label',
  title: 'Promotion & Discount Tag',
  description:
      'High-impact promotional sale tag featuring a reverse header, strike-through line composition over original price, bold discount badge, and Code128 barcode.',
  category: ExampleCategory.retail,
  recommendedMedia: '50mm × 40mm',
  sourcePath: 'lib/src/examples/retail/retail_promotion_label.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
  },
  buildLabel: buildRetailPromotionLabel,
  quickSnippet: '''
final job = buildRetailPromotionLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
