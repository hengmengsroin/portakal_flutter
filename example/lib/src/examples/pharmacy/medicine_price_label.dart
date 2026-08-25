import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Flagship Medicine Inventory and Shelf Price Label (50mm × 30mm).
LabelBuilder buildMedicinePriceLabel() {
  return label(const LabelConfig(width: 50, height: 30, copies: 1))
      // Drug Name and Strength
      .text('AMOXICILLIN 500mg', const TextOptions(x: 15, y: 15, size: 2, bold: true))
      .text('10 Capsules (Oral)', const TextOptions(x: 15, y: 50, size: 1))
      // Price Emphasis
      .text('\$4.50', const TextOptions(x: 275, y: 40, size: 2, bold: true))
      .line(const LineOptions(x1: 15, y1: 78, x2: 385, y2: 78, thickness: 1))
      // Batch & Expiry Information
      .text('Batch: AMX240801', const TextOptions(x: 15, y: 90, size: 1))
      .text('EXP: 08/2028', const TextOptions(x: 230, y: 90, size: 1, bold: true))
      // Inventory Barcode
      .barcode(
        'AMX240801',
        const BarcodeOptions(
          x: 25,
          y: 125,
          type: '128',
          height: 55,
          readable: 1,
        ),
      )
      .text('Rx Only  -  Keep in dry place', const TextOptions(x: 60, y: 215, size: 1));
}

final medicinePriceCase = ExampleCase(
  id: 'medicine_price_label',
  title: 'Medicine Price & Batch Label',
  description:
      'Pharmacy inventory and shelf tag for Amoxicillin displaying drug name, strength, dosage form, batch identifier, expiration date, unit price, and Code128 barcode.',
  category: ExampleCategory.pharmacy,
  recommendedMedia: '50mm × 30mm',
  sourcePath: 'lib/src/examples/pharmacy/medicine_price_label.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildMedicinePriceLabel,
  quickSnippet: '''
final job = buildMedicinePriceLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
