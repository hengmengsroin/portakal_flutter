import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Demonstrates international script rendering and printer encoding differences.
LabelBuilder buildUnicodeTextLabel() {
  return label(const LabelConfig(width: 70, height: 50, copies: 1))
      .box(const BoxOptions(x: 10, y: 10, width: 540, height: 380, thickness: 2))
      .text('INTERNATIONAL SCRIPTS', const TextOptions(x: 25, y: 25, size: 2, bold: true))
      .line(const LineOptions(x1: 25, y1: 65, x2: 525, y2: 65, thickness: 1))
      // English
      .text('English: Portakal Thermal SDK', const TextOptions(x: 25, y: 80, size: 1))
      // French Accents (Latin-1 / CP1252)
      .text('Français: Café and Crème Brûlée', const TextOptions(x: 25, y: 115, size: 1))
      // Khmer (Complex script)
      .text('ភាសាខ្មែរ: សួស្តីកម្ពុជា (Hello Cambodia)', const TextOptions(x: 25, y: 155, size: 1))
      // Japanese (CJK)
      .text('日本語: サーマルプリンター 印刷テスト', const TextOptions(x: 25, y: 195, size: 1))
      .line(const LineOptions(x1: 25, y1: 240, x2: 525, y2: 240, thickness: 1))
      .text(
        'Note: Preview renders full Unicode.\nPrinter hardware requires UTF-8 / font ROM.',
        const TextOptions(x: 25, y: 255, size: 1),
      )
      .qrcode(
        'https://portakal.dev/unicode-guide',
        const QRCodeOptions(x: 410, y: 280, cellWidth: 3),
      );
}

final unicodeTextCase = ExampleCase(
  id: 'unicode_text',
  title: 'Multilingual & International Text',
  description:
      'Demonstrates international scripts (English, French, Khmer, Japanese). '
      'Visual preview renders full Unicode via Flutter; raw printer output depends on device font ROM, code pages, or bitmap rendering.',
  category: ExampleCategory.advanced,
  recommendedMedia: '70mm × 50mm',
  sourcePath: 'lib/src/examples/general/unicode_text_example.dart',
  testedProtocols: {
    ExampleProtocol.zpl,
  },
  buildLabel: buildUnicodeTextLabel,
  quickSnippet: '''
final job = buildUnicodeTextLabel().resolve();
final bytes = zpl.compileResolved(job);
''',
);
