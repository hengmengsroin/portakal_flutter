import 'package:portakal_core/portakal_core.dart';
import 'package:test/test.dart';

void main() {
  group('BarcodeSymbology & BarcodeOptions.typed Convenience API', () {
    test('A. All enum identifiers map to exact canonical strings', () {
      expect(BarcodeSymbology.code128.identifier, equals('128'));
      expect(BarcodeSymbology.code39.identifier, equals('39'));
      expect(BarcodeSymbology.ean13.identifier, equals('EAN13'));
      expect(BarcodeSymbology.ean8.identifier, equals('EAN8'));
      expect(BarcodeSymbology.upca.identifier, equals('UPCA'));
      expect(BarcodeSymbology.upce.identifier, equals('UPCE'));
      expect(BarcodeSymbology.itf.identifier, equals('ITF'));
      expect(BarcodeSymbology.codabar.identifier, equals('CODABAR'));
    });

    test('B. Typed constructor lowers into exact canonical identifier', () {
      for (final symbology in BarcodeSymbology.values) {
        final options = BarcodeOptions.typed(
          x: 10,
          y: 20,
          symbology: symbology,
          height: 50,
        );
        expect(options.type, equals(symbology.identifier));
      }
    });

    test('C. Typed and legacy options field equivalence', () {
      final typed = BarcodeOptions.typed(
        x: 15,
        y: 25,
        symbology: BarcodeSymbology.code39,
        height: 60,
        readable: 1,
        rotation: 90,
        narrow: 2,
        wide: 5,
        alignment: 2,
      );

      const legacy = BarcodeOptions(
        x: 15,
        y: 25,
        type: '39',
        height: 60,
        readable: 1,
        rotation: 90,
        narrow: 2,
        wide: 5,
        alignment: 2,
      );

      expect(typed.x, equals(legacy.x));
      expect(typed.y, equals(legacy.y));
      expect(typed.type, equals(legacy.type));
      expect(typed.height, equals(legacy.height));
      expect(typed.readable, equals(legacy.readable));
      expect(typed.rotation, equals(legacy.rotation));
      expect(typed.narrow, equals(legacy.narrow));
      expect(typed.wide, equals(legacy.wide));
      expect(typed.alignment, equals(legacy.alignment));
    });

    test('D. Legacy BarcodeOptions constructor remains const-constructible', () {
      const opt1 = BarcodeOptions(
        x: 10,
        y: 20,
        type: '128',
        height: 50,
      );
      const opt2 = BarcodeOptions(
        x: 10,
        y: 20,
        type: '128',
        height: 50,
      );

      expect(identical(opt1, opt2), isTrue);
    });

    test('E. Compiler byte equivalence across all 9 protocols (TSC, ZPL, EPL, ESC/POS, CPCL, DPL, IPL, SBPL, Star PRNT)', () {
      final config = const LabelConfig(width: 80, height: 50);

      for (final sym in [BarcodeSymbology.code128, BarcodeSymbology.code39]) {
        final legacyBuilder = label(config)
          ..barcode('ITEM1234', BarcodeOptions(x: 10, y: 20, type: sym.identifier, height: 40, readable: 1));
        final typedBuilder = label(config)
          ..barcode('ITEM1234', BarcodeOptions.typed(x: 10, y: 20, symbology: sym, height: 40, readable: 1));

        final legacyJob = legacyBuilder.resolve();
        final typedJob = typedBuilder.resolve();

        // 1. TSC
        expect(tsc.compileResolved(typedJob), equals(tsc.compileResolved(legacyJob)));
        // 2. ZPL
        expect(zpl.compileResolved(typedJob), equals(zpl.compileResolved(legacyJob)));
        // 3. EPL
        expect(epl.compileResolved(typedJob), equals(epl.compileResolved(legacyJob)));
        // 4. ESC/POS
        expect(compileToESCPOS(typedJob), equals(compileToESCPOS(legacyJob)));
        // 5. CPCL
        expect(cpcl.compileResolved(typedJob), equals(cpcl.compileResolved(legacyJob)));
        // 6. DPL
        expect(dpl.compileResolved(typedJob), equals(dpl.compileResolved(legacyJob)));
        // 7. IPL
        expect(ipl.compileResolved(typedJob), equals(ipl.compileResolved(legacyJob)));
        // 8. SBPL
        expect(sbpl.compileResolved(typedJob), equals(sbpl.compileResolved(legacyJob)));
        // 9. Star PRNT
        expect(compileToStarPRNT(typedJob), equals(compileToStarPRNT(legacyJob)));
      }
    });

    test('F. PreviewScene produces identical visual layout for typed vs legacy', () {
      final config = const LabelConfig(width: 80, height: 50);

      final legacyJob = (label(config)
            ..barcode('1234567890128', const BarcodeOptions(x: 10, y: 10, type: 'EAN13', height: 40)))
          .resolve();

      final typedJob = (label(config)
            ..barcode('1234567890128', BarcodeOptions.typed(x: 10, y: 10, symbology: BarcodeSymbology.ean13, height: 40)))
          .resolve();

      final legacySvg = renderPreview(legacyJob);
      final typedSvg = renderPreview(typedJob);

      expect(typedSvg, equals(legacySvg));
    });

    test('G. Arbitrary legacy string escape hatch remains fully operational', () {
      const customOptions = BarcodeOptions(
        x: 10,
        y: 20,
        type: 'CUSTOM_VENDOR_CODE_93',
        height: 40,
      );
      expect(customOptions.type, equals('CUSTOM_VENDOR_CODE_93'));
    });

    test('H. High-Value Regression Protection: EAN13 strictly maps to EAN13 and not Code128', () {
      final ean13Opt = BarcodeOptions.typed(
        x: 10,
        y: 20,
        symbology: BarcodeSymbology.ean13,
        height: 40,
      );
      expect(ean13Opt.type, equals('EAN13'));
      expect(ean13Opt.type, isNot(equals('128')));
      expect(ean13Opt.type, isNot(equals('39')));

      final code128Opt = BarcodeOptions.typed(
        x: 10,
        y: 20,
        symbology: BarcodeSymbology.code128,
        height: 40,
      );
      expect(code128Opt.type, equals('128'));
      expect(code128Opt.type, isNot(equals('EAN13')));

      final code39Opt = BarcodeOptions.typed(
        x: 10,
        y: 20,
        symbology: BarcodeSymbology.code39,
        height: 40,
      );
      expect(code39Opt.type, equals('39'));
      expect(code39Opt.type, isNot(equals('128')));
    });
  });
}
