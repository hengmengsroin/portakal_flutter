import 'package:test/test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('Printer profile integration', () {
    test('uses profile DPI', () {
      final resolved = label(LabelConfig(
        width: 100,
        height: 50,
        printer: 'tsc-te310',
      )).resolve();
      expect(resolved.dpi, equals(300)); // TE310 is 300 DPI
    });

    test('uses profile width when not specified', () {
      // Epson TM-T88VI is 80mm wide
      final resolved = label(LabelConfig(
        width: 80,
        printer: 'epson-tm-t88vi',
      )).resolve();
      expect(resolved.dpi, equals(203));
    });

    test('user config overrides profile', () {
      final resolved = label(LabelConfig(
        width: 50,
        dpi: 600,
        printer: 'tsc-te200',
      )).resolve();
      expect(resolved.dpi, equals(600)); // User override
    });

    test('ignores unknown printer profile', () {
      final resolved = label(LabelConfig(
        width: 40,
        printer: 'unknown-model',
      )).resolve();
      expect(resolved.dpi, equals(203)); // Default
    });
  });
}
