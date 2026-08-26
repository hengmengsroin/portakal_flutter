import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Compact parcel routing sticker with prominent destination hub and route ID (60mm × 40mm).
LabelBuilder buildSmallParcelLabel() {
  return label(const LabelConfig(width: 60, height: 40, copies: 1))
      .box(const BoxOptions(x: 10, y: 10, width: 460, height: 300, thickness: 2))
      // Huge Destination Hub Code
      .text('DEST: KPC', const TextOptions(x: 25, y: 25, size: 3, bold: true))
      .text('Route: 04', const TextOptions(x: 310, y: 30, size: 2, bold: true))
      .line(const LineOptions(x1: 25, y1: 75, x2: 455, y2: 75, thickness: 2))
      // Package Identifier & Weight
      .text('PKG-10294', const TextOptions(x: 25, y: 90, size: 2, bold: true))
      .text('WT: 2.4 KG', const TextOptions(x: 310, y: 90, size: 2, bold: true))
      // Routing Barcode
      .barcode(
        'PKG-10294',
        BarcodeOptions.typed(
          x: 40,
          y: 145,
          symbology: BarcodeSymbology.code128,
          height: 80,
          readable: 1,
        ),
      )
      .line(const LineOptions(x1: 25, y1: 260, x2: 455, y2: 260, thickness: 1))
      .text('SORT: BELT 2  -  FLIGHT PK-301', const TextOptions(x: 80, y: 275, size: 1, bold: true));
}

final smallParcelCase = ExampleCase(
  id: 'small_parcel_label',
  title: 'Compact Parcel Routing Tag',
  description:
      'Compact courier routing sticker highlighting oversized destination airport/hub code, delivery route, parcel weight, and Code128 barcode.',
  category: ExampleCategory.logistics,
  recommendedMedia: '60mm × 40mm',
  sourcePath: 'lib/src/examples/logistics/small_parcel_label.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildSmallParcelLabel,
  quickSnippet: '''
final job = buildSmallParcelLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
