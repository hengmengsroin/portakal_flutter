import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Flagship Warehouse Location and Storage Bin Identifier (100mm × 50mm).
LabelBuilder buildLocationBinLabel() {
  return label(const LabelConfig(width: 100, height: 50, copies: 1))
      .box(const BoxOptions(x: 10, y: 10, width: 780, height: 380, thickness: 3))
      // Zone and Aisle Hierarchical Header
      .text('ZONE A  -  AISLE 03  -  RACK 07', const TextOptions(x: 30, y: 30, size: 2, bold: true))
      .line(const LineOptions(x1: 30, y1: 75, x2: 760, y2: 75, thickness: 2))
      // Huge Bin Identifier for Forklift Operators
      .text('BIN', const TextOptions(x: 30, y: 100, size: 2))
      .text('B12', const TextOptions(x: 30, y: 140, size: 4, bold: true))
      // Location Barcode
      .barcode(
        'A-03-07-B12',
        BarcodeOptions.typed(
          x: 280,
          y: 110,
          symbology: BarcodeSymbology.code128,
          height: 100,
          readable: 1,
        ),
      )
      .line(const LineOptions(x1: 30, y1: 270, x2: 760, y2: 270, thickness: 1))
      .text('FACILITY: LOGISTICS HUB 1 (EAST WING)', const TextOptions(x: 30, y: 290, size: 1, bold: true))
      .text('Scan barcode to confirm pick and putaway operations', const TextOptions(x: 30, y: 325, size: 1));
}

final locationBinCase = ExampleCase(
  id: 'location_bin_label',
  title: 'Warehouse Location Bin Label',
  description:
      'Heavy-duty bin and shelf location identifier with giant human-readable coordinates, hierarchical zone indicators, and a Code128 rack barcode.',
  category: ExampleCategory.warehouse,
  recommendedMedia: '100mm × 50mm',
  sourcePath: 'lib/src/examples/warehouse/location_bin_label.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildLocationBinLabel,
  quickSnippet: '''
final job = buildLocationBinLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
