import 'package:portakal_flutter/portakal_flutter.dart';
import '../../hardware/raster_fixture.dart';
import '../example_case.dart';

/// Label with embedded 1-bit monochrome logo bitmap.
LabelBuilder buildBitmapLogoLabel() {
  final bitmap = createCanonicalRaster64x64Bitmap();

  return label(const LabelConfig(width: 60, height: 40, copies: 1))
      .image(bitmap, const ImageOptions(x: 20, y: 20))
      .text('PORTAKAL', const TextOptions(x: 100, y: 25, size: 2, bold: true))
      .text('Certified Hardware Quality', const TextOptions(x: 100, y: 65, size: 1))
      .text('Batch: PKL-2026-08', const TextOptions(x: 100, y: 95, size: 1))
      .barcode(
        'PKL9948201',
        BarcodeOptions.typed(
          x: 40,
          y: 140,
          symbology: BarcodeSymbology.code128,
          height: 50,
          readable: 1,
        ),
      )
      .qrcode(
        'https://portakal.dev/verify/PKL-2026-08',
        const QRCodeOptions(x: 340, y: 130, cellWidth: 4),
      );
}

final bitmapLogoCase = ExampleCase(
  id: 'bitmap_logo',
  title: 'Monochrome Logo & Branding',
  description:
      'Demonstrates embedding 1-bit raster graphics / logos alongside structured text and barcodes.',
  category: ExampleCategory.advanced,
  recommendedMedia: '60mm × 40mm',
  sourcePath: 'lib/src/examples/general/bitmap_logo_example.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.escpos,
    ExampleProtocol.starprnt,
  },
  buildLabel: buildBitmapLogoLabel,
  quickSnippet: '''
final job = buildBitmapLogoLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
