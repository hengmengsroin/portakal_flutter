import 'dart:convert';
import 'package:portakal_core/portakal_core.dart';
import 'package:test/test.dart';

void main() {
  group('BarcodeSymbology & BarcodeOptions.typed Convenience API (Slice 5C Correctness)', () {
    test('A. Universal BarcodeSymbology enum contains verified universal symbologies (code128 and code39)', () {
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
        // 7. IPL (Both code128 and code39 tested)
        expect(ipl.compileResolved(typedJob), equals(ipl.compileResolved(legacyJob)));
        // 8. SBPL
        expect(sbpl.compileResolved(typedJob), equals(sbpl.compileResolved(legacyJob)));
        // 9. Star PRNT
        expect(compileToStarPRNT(typedJob), equals(compileToStarPRNT(legacyJob)));
      }
    });

    test('F. Same-payload IPL semantic difference proof: Code 128 emits c6 and Code 39 emits c0', () {
      const config = LabelConfig(width: 80, height: 50);
      const payload = 'PORTAKAL123';

      final job128 = (label(config)
            ..barcode(payload, BarcodeOptions.typed(x: 10, y: 20, symbology: BarcodeSymbology.code128, height: 40)))
          .resolve();
      final job39 = (label(config)
            ..barcode(payload, BarcodeOptions.typed(x: 10, y: 20, symbology: BarcodeSymbology.code39, height: 40)))
          .resolve();

      final ipl128 = latin1.decode(ipl.compileResolved(job128));
      final ipl39 = latin1.decode(ipl.compileResolved(job39));

      expect(ipl128, isNot(equals(ipl39)));
      expect(ipl128, contains('\x02B1;o0;f0;c6;h40;w2;d0,20;\x03\n\x02PORTAKAL123\x03\n'));
      expect(ipl39, contains('\x02B1;o0;f0;c0;h40;w2;d0,20;\x03\n\x02PORTAKAL123\x03\n'));
    });

    test('G. Semantic identity proof: Authentic protocol-specific selectors across all 9 protocols', () {
      const config = LabelConfig(width: 80, height: 50);

      final job128 = (label(config)
            ..barcode('TESTDATA', BarcodeOptions.typed(x: 10, y: 20, symbology: BarcodeSymbology.code128, height: 40)))
          .resolve();
      final job39 = (label(config)
            ..barcode('TESTDATA', BarcodeOptions.typed(x: 10, y: 20, symbology: BarcodeSymbology.code39, height: 40)))
          .resolve();

      // 1. TSC: "128" vs "39"
      expect(ascii.decode(tsc.compileResolved(job128)), contains('"128"'));
      expect(ascii.decode(tsc.compileResolved(job39)), contains('"39"'));

      // 2. ZPL: ^BC vs ^B3
      expect(ascii.decode(zpl.compileResolved(job128)), contains('^BC'));
      expect(ascii.decode(zpl.compileResolved(job39)), contains('^B3'));

      // 3. EPL: typeCode '1' vs '3'
      expect(ascii.decode(epl.compileResolved(job128)), contains(',1,'));
      expect(ascii.decode(epl.compileResolved(job39)), contains(',3,'));

      // 4. ESC/POS: 73 (Code128) vs 69 (Code39)
      expect(compileToESCPOS(job128), containsAllInOrder([0x1D, 0x6B, 73]));
      expect(compileToESCPOS(job39), containsAllInOrder([0x1D, 0x6B, 69]));

      // 5. CPCL: BARCODE 128 vs BARCODE 39
      expect(ascii.decode(cpcl.compileResolved(job128)), contains('BARCODE 128'));
      expect(ascii.decode(cpcl.compileResolved(job39)), contains('BARCODE 39'));

      // 6. DPL: '1E' (Code128) vs '1A' (Code39)
      expect(ascii.decode(dpl.compileResolved(job128)), contains('1E'));
      expect(ascii.decode(dpl.compileResolved(job39)), contains('1A'));

      // 7. IPL: 'c6;' (Code128) vs 'c0;' (Code39)
      expect(latin1.decode(ipl.compileResolved(job128)), contains('c6;'));
      expect(latin1.decode(ipl.compileResolved(job39)), contains('c0;'));

      // 8. SBPL: "BG" (Code128) vs "B1" (Code39)
      expect(ascii.decode(sbpl.compileResolved(job128)), contains('BG'));
      expect(ascii.decode(sbpl.compileResolved(job39)), contains('B1'));

      // 9. Star PRNT: 5 (Code128) vs 1 (Code39)
      expect(compileToStarPRNT(job128), containsAllInOrder([0x1B, 0x62, 5]));
      expect(compileToStarPRNT(job39), containsAllInOrder([0x1B, 0x62, 1]));
    });

    test('H. Native IplBarcodeType enum value verification', () {
      expect(IplBarcodeType.code128.code, equals(6));
      expect(IplBarcodeType.code39.code, equals(0));
      expect(IplBarcodeType.qrCode.code, equals(21));
    });

    test('I. Arbitrary legacy string escape hatch preserves c0 on IPL and remains functional', () {
      const ean13Options = BarcodeOptions(
        x: 10,
        y: 20,
        type: 'EAN13',
        height: 40,
      );
      expect(ean13Options.type, equals('EAN13'));

      const config = LabelConfig(width: 80, height: 50);
      final ean13Job = (label(config)..barcode('1234567890128', ean13Options)).resolve();
      final iplEan13 = latin1.decode(ipl.compileResolved(ean13Job));
      // Preserves historical fallback c0 for arbitrary strings
      expect(iplEan13, contains('c0;'));
    });

    test('J. PreviewScene produces identical visual layout for typed vs legacy', () {
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
  });
}
