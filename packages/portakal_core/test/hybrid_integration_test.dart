import 'dart:convert';
import 'package:portakal_core/portakal_core.dart';
import 'package:test/test.dart';

void main() {
  group('Portakal 1.2 Hybrid Layout — Cross-Protocol Integration Suite', () {
    test('1. Cross-Protocol Row Integration Test across all 9 printer compilers', () {
      final receipt = sequentialLabel(
        const LabelConfig(width: 80, height: 80, unit: Unit.mm),
      )
        ..text('PORTAKAL CAFE')
        ..divider()
        ..row('Coffee', r'$5.00')
        ..row('Tea', r'$2.50')
        ..divider()
        ..row('TOTAL', r'$7.50', bold: true);

      final job = receipt.resolve();

      // All 9 protocol compilers compile successfully from the SAME job:
      final tscBytes = tsc.compileResolved(job);
      final zplBytes = zpl.compileResolved(job);
      final eplBytes = epl.compileResolved(job);
      final escposBytes = compileToESCPOS(job);
      final cpclBytes = cpcl.compileResolved(job);
      final dplBytes = dpl.compileResolved(job);
      final iplBytes = ipl.compileResolved(job);
      final sbplBytes = sbpl.compileResolved(job);
      final starBytes = compileToStarPRNT(job);

      expect(tscBytes, isNotEmpty);
      expect(zplBytes, isNotEmpty);
      expect(eplBytes, isNotEmpty);
      expect(escposBytes, isNotEmpty);
      expect(cpclBytes, isNotEmpty);
      expect(dplBytes, isNotEmpty);
      expect(iplBytes, isNotEmpty);
      expect(sbplBytes, isNotEmpty);
      expect(starBytes, isNotEmpty);

      // Verify stream row single-line LF formatting
      final escposText = ascii.decode(escposBytes.where((b) => b >= 32 || b == 10).toList());
      expect(escposText, contains('Coffee'));
      expect(escposText, contains(r'$5.00'));
      expect(escposText, contains('TOTAL'));

      // Verify PreviewScene renders
      final svg = renderPreview(job);
      expect(svg, contains('PORTAKAL CAFE'));
      expect(svg, contains('Coffee'));
      expect(svg, contains(r'$5.00'));
    });

    test('2. Cross-Protocol Table Integration Test (Description | Qty | Total)', () {
      final invoice = sequentialLabel(
        const LabelConfig(width: 80, height: 100, unit: Unit.mm),
      );

      final table = invoice.table(
        columns: [
          LabelColumn.flex(3),
          LabelColumn.flex(1, align: LabelTextAlign.center),
          LabelColumn.flex(1, align: LabelTextAlign.right),
        ],
        gap: 10,
      );

      table
        ..row(['Item Description', 'Qty', 'Total'], bold: true)
        ..divider()
        ..row(['Thermal Labels', '5', r'$40.00'])
        ..row(['Printer Ribbon', '1', r'$15.00'])
        ..space(10);

      final job = invoice.resolve();

      // Compile across all 9
      expect(tsc.compileResolved(job), isNotEmpty);
      expect(zpl.compileResolved(job), isNotEmpty);
      expect(epl.compileResolved(job), isNotEmpty);
      expect(compileToESCPOS(job), isNotEmpty);
      expect(cpcl.compileResolved(job), isNotEmpty);
      expect(dpl.compileResolved(job), isNotEmpty);
      expect(ipl.compileResolved(job), isNotEmpty);
      expect(sbpl.compileResolved(job), isNotEmpty);
      expect(compileToStarPRNT(job), isNotEmpty);

      final svg = renderPreview(job);
      expect(svg, contains('Item Description'));
      expect(svg, contains('Thermal Labels'));
    });

    test('3. Exact Coordinate Escape-Hatch Regression Test', () {
      final doc = sequentialLabel(
        const LabelConfig(width: 80, height: 100, unit: Unit.mm, dpi: 203),
      );

      // Sequential 1
      doc.text('Sequential Header'); // y = 20, advances to 48

      // Exact x/y element
      doc.text('Exact Overlay', const TextOptions(x: 50, y: 300)); // does not advance currentY

      // Exact box
      doc.box(const BoxOptions(x: 10, y: 400, width: 200, height: 50)); // does not advance currentY

      // Sequential 2
      doc.text('Sequential Item'); // y = 48, advances to 76

      final job = doc.resolve();
      final texts = job.elements.whereType<TextElement>().toList();

      expect(texts[0].content, equals('Sequential Header'));
      expect(texts[0].options.y, equals(20)); // Margin

      expect(texts[1].content, equals('Exact Overlay'));
      expect(texts[1].options.x, equals(50));
      expect(texts[1].options.y, equals(300));

      expect(texts[2].content, equals('Sequential Item'));
      expect(texts[2].options.y, equals(48)); // 20 + 28 line advance
    });

    test('4. 203 DPI vs 300 DPI physical metric scaling', () {
      final label203 = sequentialLabel(
        const LabelConfig(width: 80, height: 80, unit: Unit.mm, dpi: 203),
      )..text('Line 1')..text('Line 2');

      final label300 = sequentialLabel(
        const LabelConfig(width: 80, height: 80, unit: Unit.mm, dpi: 300),
      )..text('Line 1')..text('Line 2');

      final job203 = label203.resolve();
      final job300 = label300.resolve();

      final texts203 = job203.elements.whereType<TextElement>().toList();
      final texts300 = job300.elements.whereType<TextElement>().toList();

      // 203 DPI: margin = 20 dots (2.5mm), advance = 28 dots (3.5mm)
      expect(texts203[0].options.y, equals(20));
      expect(texts203[1].options.y, equals(48));

      // 300 DPI: margin = 30 dots (2.5mm), advance = 41 dots (3.5mm)
      expect(texts300[0].options.y, equals(30));
      expect(texts300[1].options.y, equals(71));
    });

    test('5. Stream receipt character capacity (58mm vs 80mm vs override)', () {
      final receipt58 = sequentialLabel(
        const LabelConfig(width: 58, height: 50, unit: Unit.mm),
      )..row('Left', 'Right');

      final receipt80 = sequentialLabel(
        const LabelConfig(width: 80, height: 50, unit: Unit.mm),
      )..row('Left', 'Right');

      final job58 = receipt58.resolve();
      final job80 = receipt80.resolve();

      // 58mm -> 32 cols base capacity
      final bytes58 = compileToESCPOS(job58);
      final line58 = utf8.decode(bytes58).split('\n').firstWhere((l) => l.contains('Left'));
      expect(line58.length, lessThanOrEqualTo(32));

      // 80mm -> 48 cols base capacity
      final bytes80 = compileToESCPOS(job80);
      final line80 = utf8.decode(bytes80).split('\n').firstWhere((l) => l.contains('Left'));
      expect(line80.length, lessThanOrEqualTo(48));

      // Override charsPerLine: 42
      final bytesOverride = compileToESCPOS(job80, charsPerLine: 42);
      final lineOverride = utf8.decode(bytesOverride).split('\n').firstWhere((l) => l.contains('Left'));
      expect(lineOverride.length, lessThanOrEqualTo(42));
    });
  });
}
