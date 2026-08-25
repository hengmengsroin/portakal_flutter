import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Compact enterprise asset management sticker (50mm × 25mm).
LabelBuilder buildAssetTagLabel() {
  return label(const LabelConfig(width: 50, height: 25, copies: 1))
      .box(const BoxOptions(x: 5, y: 5, width: 390, height: 190, thickness: 2))
      // Reverse IT Asset Header
      .box(const BoxOptions(x: 5, y: 5, width: 390, height: 32, thickness: 2))
      .text('IT ASSET PROPERTY', const TextOptions(x: 95, y: 12, size: 1, bold: true))
      .reverse(const ReverseOptions(x: 5, y: 5, width: 390, height: 32))
      // Hardware Asset Details
      .text('MacBook Pro 14"', const TextOptions(x: 15, y: 48, size: 2, bold: true))
      .text('Asset: IT-000184', const TextOptions(x: 15, y: 80, size: 1, bold: true))
      .text('Dept: Engineering', const TextOptions(x: 15, y: 105, size: 1))
      .text('Do Not Remove', const TextOptions(x: 15, y: 130, size: 1))
      .barcode(
        'IT000184',
        const BarcodeOptions(
          x: 15,
          y: 150,
          type: '128',
          height: 35,
          readable: 0,
        ),
      )
      // Asset Inventory QR Code
      .qrcode(
        'https://assets.portakal.internal/tag/IT-000184',
        const QRCodeOptions(x: 275, y: 45, cellWidth: 3),
      );
}

final assetTagCase = ExampleCase(
  id: 'asset_tag',
  title: 'IT Hardware Asset Tag',
  description:
      'Durable enterprise equipment tag combining reverse property header, asset inventory number, assigned department, and quick-scan QR code.',
  category: ExampleCategory.assetManagement,
  recommendedMedia: '50mm × 25mm',
  sourcePath: 'lib/src/examples/asset/asset_tag.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
  },
  buildLabel: buildAssetTagLabel,
  quickSnippet: '''
final job = buildAssetTagLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
