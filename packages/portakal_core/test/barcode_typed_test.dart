import 'dart:convert';
import 'package:portakal_core/portakal_core.dart';
import 'package:test/test.dart';

void main() {
  group('BarcodeSymbology & BarcodeOptions.typed Convenience API (Semantic Safety)', () {
    test('A. Universal BarcodeSymbology enum contains exactly verified universal symbologies', () {
      expect(BarcodeSymbology.values, equals([BarcodeSymbology.code128, BarcodeSymbology.code39]));
      expect(BarcodeSymbology.code128.identifier, equals('128'));
      expect(BarcodeSymbology.code39.identifier, equals('39'));
    });

    test('B. Typed constructor lowers into exact canonical identifier', () {
      final opt128 = BarcodeOptions.typed(
        x: 10,
        y: 20,
        symbology: BarcodeSymbology.code128,
        height: 50,
      );
      expect(opt128.type, equals('128'));

      final opt39 = BarcodeOptions.typed(
        x: 10,
        y: 20,
        symbology: BarcodeSymbology.code39,
        height: 50,
      );
      expect(opt39.type, equals('39'));
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

    test('E. Cross-protocol byte equivalence for BOTH code128 and code39 across all 9 protocols', () {
      const config = LabelConfig(width: 80, height: 50);

      for (final sym in BarcodeSymbology.values) {
        final legacyJob = (label(config)
              ..barcode('ITEM1234', BarcodeOptions(x: 10, y: 20, type: sym.identifier, height: 40, readable: 1)))
            .resolve();
        final typedJob = (label(config)
              ..barcode('ITEM1234', BarcodeOptions.typed(x: 10, y: 20, symbology: sym, height: 40, readable: 1)))
            .resolve();

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

    test('F. Semantic identity proof: Code 39 emits authentic protocol-specific commands', () {
      const config = LabelConfig(width: 80, height: 50);

      final job128 = (label(config)
            ..barcode('CODE128DATA', BarcodeOptions.typed(x: 10, y: 20, symbology: BarcodeSymbology.code128, height: 40)))
          .resolve();
      final job39 = (label(config)
            ..barcode('CODE39DATA', BarcodeOptions.typed(x: 10, y: 20, symbology: BarcodeSymbology.code39, height: 40)))
          .resolve();

      // 1. TSC: "128" vs "39"
      final tsc128 = ascii.decode(tsc.compileResolved(job128));
      final tsc39 = ascii.decode(tsc.compileResolved(job39));
      expect(tsc128, contains('"128"'));
      expect(tsc39, contains('"39"'));

      // 2. ZPL: ^BC vs ^B3
      final zpl128 = ascii.decode(zpl.compileResolved(job128));
      final zpl39 = ascii.decode(zpl.compileResolved(job39));
      expect(zpl128, contains('^BC'));
      expect(zpl39, contains('^B3'));

      // 3. EPL: typeCode '1' (Code128) vs '3' (Code39)
      final epl128 = ascii.decode(epl.compileResolved(job128));
      final epl39 = ascii.decode(epl.compileResolved(job39));
      expect(epl128, contains(',1,'));
      expect(epl39, contains(',3,'));

      // 4. ESC/POS: Function B type 73 (Code128) vs 69 (Code39)
      final esc128 = compileToESCPOS(job128);
      final esc39 = compileToESCPOS(job39);
      expect(esc128, containsAllInOrder([0x1D, 0x6B, 73]));
      expect(esc39, containsAllInOrder([0x1D, 0x6B, 69]));

      // 5. CPCL: BARCODE 128 vs BARCODE 39
      final cpcl128 = ascii.decode(cpcl.compileResolved(job128));
      final cpcl39 = ascii.decode(cpcl.compileResolved(job39));
      expect(cpcl128, contains('BARCODE 128'));
      expect(cpcl39, contains('BARCODE 39'));

      // 6. DPL: typeCode 'E' (Code128) vs 'A' (Code39)
      final dpl128 = ascii.decode(dpl.compileResolved(job128));
      final dpl39 = ascii.decode(dpl.compileResolved(job39));
      expect(dpl128, contains('1E'));
      expect(dpl39, contains('1A'));

      // 7. IPL: B1;...;c0;...
      final ipl128 = ascii.decode(ipl.compileResolved(job128));
      final ipl39 = ascii.decode(ipl.compileResolved(job39));
      expect(ipl128, contains('c0;'));
      expect(ipl39, contains('c0;'));

      // 8. SBPL: typeCode "BG" (Code128) vs "B1" (Code39)
      final sbpl128 = ascii.decode(sbpl.compileResolved(job128));
      final sbpl39 = ascii.decode(sbpl.compileResolved(job39));
      expect(sbpl128, contains('BG'));
      expect(sbpl39, contains('B1'));

      // 9. Star PRNT: typeCode 5 (Code128) vs 1 (Code39)
      final star128 = compileToStarPRNT(job128);
      final star39 = compileToStarPRNT(job39);
      expect(star128, containsAllInOrder([0x1B, 0x62, 5]));
      expect(star39, containsAllInOrder([0x1B, 0x62, 1]));
    });

    test('G. PreviewScene produces identical visual layout for typed vs legacy', () {
      const config = LabelConfig(width: 80, height: 50);

      final legacyJob = (label(config)
            ..barcode('ITEM1234', const BarcodeOptions(x: 10, y: 10, type: '128', height: 40)))
          .resolve();

      final typedJob = (label(config)
            ..barcode('ITEM1234', BarcodeOptions.typed(x: 10, y: 10, symbology: BarcodeSymbology.code128, height: 40)))
          .resolve();

      final legacySvg = renderPreview(legacyJob);
      final typedSvg = renderPreview(typedJob);

      expect(typedSvg, equals(legacySvg));
    });

    test('H. Arbitrary legacy string escape hatch remains fully operational', () {
      const ean13Options = BarcodeOptions(
        x: 10,
        y: 20,
        type: 'EAN13',
        height: 40,
      );
      expect(ean13Options.type, equals('EAN13'));

      const customOptions = BarcodeOptions(
        x: 10,
        y: 20,
        type: 'CUSTOM_VENDOR_CODE_93',
        height: 40,
      );
      expect(customOptions.type, equals('CUSTOM_VENDOR_CODE_93'));
    });
  });
}
