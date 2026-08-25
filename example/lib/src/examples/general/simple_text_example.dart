import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Minimal beginner template showing text, boxes, lines, and QR codes.
LabelBuilder buildSimpleTextLabel() {
  return label(const LabelConfig(width: 60, height: 40, copies: 1))
      .box(const BoxOptions(x: 10, y: 10, width: 460, height: 300, thickness: 2))
      .text('Hello Portakal', const TextOptions(x: 30, y: 30, size: 2, bold: true))
      .text('Universal Thermal & Label SDK', const TextOptions(x: 30, y: 80, size: 1))
      .line(const LineOptions(x1: 30, y1: 120, x2: 450, y2: 120, thickness: 1))
      .text('Scan for documentation:', const TextOptions(x: 30, y: 145, size: 1))
      .text('portakal.dev', const TextOptions(x: 30, y: 175, size: 1, bold: true))
      .qrcode(
        'https://pub.dev/packages/portakal_core',
        const QRCodeOptions(x: 310, y: 140, cellWidth: 4),
      );
}

final simpleTextCase = ExampleCase(
  id: 'simple_text',
  title: 'Simple Text & Frame',
  description:
      'Beginner starter template demonstrating absolute text positioning, framing box, divider line, and QR code.',
  category: ExampleCategory.gettingStarted,
  recommendedMedia: '60mm × 40mm',
  sourcePath: 'lib/src/examples/general/simple_text_example.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildSimpleTextLabel,
  quickSnippet: '''
final job = buildSimpleTextLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
